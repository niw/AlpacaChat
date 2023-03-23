//
//  ALPChat.mm
//  AlpacaChatObjC
//
//  Created by Yoshimasa Niwa on 3/16/23.
//

#import "ALPChat.h"
#import "ALPChatModel.h"

#include <chat.h>

#include <atomic>
#include <vector>

NSString * const ALPChatModelErrorDomain = @"ALPChatModelErrorDomain";

@implementation ALPChatModel
{
@public
    llama_model _model;
    gpt_vocab _vocab;
}

+ (ALPChatModel *)loadFromURL:(NSURL *)URL
                  contextSize:(int)contextSize
                        error:(NSError **)error
{
    gpt_vocab vocab;
    llama_model model;

    if (!llama_model_load(URL.fileSystemRepresentation, model, vocab, contextSize)) {
        if (error) {
            NSString * const failureReason = [[NSString alloc] initWithFormat:@"failed to load model: %@", URL];
            NSDictionary * const userInfo = @{
                NSLocalizedFailureReasonErrorKey: failureReason
            };
            *error = [[NSError alloc] initWithDomain:ALPChatModelErrorDomain
                                                code:ALPChatModelErrorCodeFailedToLoad
                                            userInfo:userInfo];
        }
        return nil;
    }

    return [[ALPChatModel alloc] initWithModel:model vocab:vocab];
}

- (instancetype)initWithModel:(const llama_model &)model vocab:(const gpt_vocab &)vocab
{
    if (self = [super init]) {
        _model = model;
        _vocab = vocab;
    }
    return self;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    abort();
}

- (void)dealloc
{
    ggml_free(_model.ctx);
}

@end

// MARK: -

@interface ALPChatPredicationCancellable : NSObject <ALPChatCancellable>

@end

@implementation ALPChatPredicationCancellable
{
@public
    std::atomic<bool> _cancelled;
}

- (instancetype)init
{
    if (self = [super init]) {
        _cancelled.store(false);
    }
    return self;
}

- (void)cancel
{
    _cancelled.store(true);
}

@end

// MARK: -

NSString * const ALPChatErrorDomain = @"ALPChatErrorDomain";

@implementation ALPChat
{
    ALPChatModel *_model;
    dispatch_queue_t _workerQueue;

    gpt_params _params;

    std::mt19937 _rng;

    int _n_past;
    int _n_remaining_tokens;

    //std::vector<gpt_vocab::id> _initial_tokens;
    std::vector<gpt_vocab::id> _request_tokens;
    std::vector<gpt_vocab::id> _response_tokens;

    std::vector<gpt_vocab::id> _embd;
    std::vector<gpt_vocab::id> _last_n_tokens;

    std::vector<float> _logits;
    size_t _mem_per_token;

    bool _prepared;
}

- (instancetype)initWithModel:(ALPChatModel *)model
{
    if (self = [super init]) {
        _model = model;
        _workerQueue = dispatch_queue_create("ALPChat.workerQueue", DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL);
        dispatch_async(_workerQueue, ^{
            [self _alp_worker_initialize];
        });
    }
    return self;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    abort();
}

- (void)_alp_worker_initialize
{
    // Use mostly default values.
    _params.temp = 0.1f;
    _params.n_threads = (int32_t)std::thread::hardware_concurrency();
#if DEBUG
    fprintf(stderr, "%s: hardware concurrency = %d\n", __func__, (int32_t) std::thread::hardware_concurrency());
    fprintf(stderr, "%s: n_threads = %d\n", __func__, _params.n_threads);
#endif // DEBUG

    const int32_t seed = (int32_t)time(NULL);
    _rng = std::mt19937(seed);

    _n_past = 0;
    _n_remaining_tokens = 0;

    //_initial_tokens = ::llama_tokenize(_model->_vocab, " Below is an instruction that describes a task. Write a response that appropriately completes the request.\n\n", true);
    _request_tokens = ::llama_tokenize(_model->_vocab, "## Instruction:\n\n", true);
    _response_tokens = ::llama_tokenize(_model->_vocab, "\n## Response:\n\n", false);

    _last_n_tokens = std::vector<gpt_vocab::id>(_params.repeat_last_n);
    std::fill(_last_n_tokens.begin(), _last_n_tokens.end(), 0);
}

- (id<ALPChatCancellable>)predictTokensForPrompt:(NSString *)prompt
                                    tokenHandler:(nullable void (^)(NSString *token))tokenHandler
                               completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler
{
    ALPChatPredicationCancellable * const cancellable = [[ALPChatPredicationCancellable alloc] init];
    dispatch_async(_workerQueue, ^{
        [self _alp_worker_predictTokensForPrompt:prompt
                                    tokenHandler:tokenHandler
                               completionHandler:completionHandler
                                     cancellable:cancellable];
    });
    return cancellable;
}

- (void)_alp_worker_predictTokensForPrompt:(NSString *)prompt
                              tokenHandler:(nullable void (^)(NSString *token))tokenHandler
                         completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler
                               cancellable:(ALPChatPredicationCancellable *)cancellable
{
    std::vector<gpt_vocab::id> input_tokens;

    if (!_prepared) {
        // Determine the required inference memory per token.
        // This takes some duration.
        llama_eval(_model->_model, _params.n_threads, 0, { 0, 1, 2, 3 }, _logits, _mem_per_token);

        // Add the initial instruction.
        //input_tokens.insert(input_tokens.end(), _initial_tokens.begin(), _initial_tokens.end());

        // We may want to slide the input window along with the context,
        // but for now we restrict to the context length.
        _n_remaining_tokens = _model->_model.hparams.n_ctx; // - (int)input_tokens.size();

        _prepared = true;
    }

    input_tokens.insert(input_tokens.end(), _request_tokens.begin(), _request_tokens.end());

    const char * const promptCString = [prompt cStringUsingEncoding:NSUTF8StringEncoding];
    std::vector<gpt_vocab::id> prompt_tokens = ::llama_tokenize(_model->_vocab, promptCString, false);
    input_tokens.insert(input_tokens.end(), prompt_tokens.begin(), prompt_tokens.end());
    input_tokens.insert(input_tokens.end(), _response_tokens.begin(), _response_tokens.end());

    _n_remaining_tokens -= _request_tokens.size() + prompt_tokens.size() + _response_tokens.size();

    int n_consumed_input_tokens = 0;
    bool is_input_tokens_consumed = false;

    while (_n_remaining_tokens > 0) {
        if (cancellable->_cancelled.load()) {
            if (completionHandler) {
                NSError * const error = [[NSError alloc] initWithDomain:ALPChatErrorDomain
                                                                   code:ALPChatErrorCodeCancelled
                                                               userInfo:nil];
                completionHandler(error);
            }
            return;
        }
#if DEBUG
        fprintf(stderr, "\nremaining_tokens = %d\n", _n_remaining_tokens);
#endif // DEBUG

        // Predict
        if (_embd.size() > 0) {
#if DEBUG
            const int64_t t_start_sample_us = ggml_time_us();
            fprintf(stderr, "start predicting...\n");
#endif // DEBUG
            if (!llama_eval(_model->_model, _params.n_threads, _n_past, _embd, _logits, _mem_per_token)) {
                if (completionHandler) {
                    NSError * const error = [[NSError alloc] initWithDomain:ALPChatErrorDomain
                                                                       code:ALPChatErrorCodeFailedToPredict
                                                                   userInfo:nil];
                    completionHandler(error);
                }
                return;
            }
#if DEBUG
            fprintf(stderr, "done %8.2f ms\n", (ggml_time_us() - t_start_sample_us) / 1000.0f);
#endif // DEBUG
        }

        _n_past += _embd.size();
        _embd.clear();

        if (n_consumed_input_tokens >= input_tokens.size()) {
            is_input_tokens_consumed = true;
        }

        if (is_input_tokens_consumed) {
            const float top_k = _params.top_k;
            const float top_p = _params.top_p;
            const float temp  = _params.temp;
            const float repeat_penalty = _params.repeat_penalty;

            const int n_vocab = _model->_model.hparams.n_vocab;

            gpt_vocab::id ident = llama_sample_top_p_top_k(_model->_vocab, _logits.data() + (_logits.size() - n_vocab), _last_n_tokens, repeat_penalty, top_k, top_p, temp, _rng);

            _last_n_tokens.erase(_last_n_tokens.begin());
            _last_n_tokens.push_back(ident);

            // add it to the context
            _embd.push_back(ident);

            // decrement remaining sampling budget
            --_n_remaining_tokens;
        } else {
            while (n_consumed_input_tokens < input_tokens.size()) {
#if DEBUG
                fprintf(stderr, "%6d -> '%s'\n", input_tokens[n_consumed_input_tokens], _model->_vocab.id_to_token.at(input_tokens[n_consumed_input_tokens]).c_str());
#endif // DEBUG

                _embd.push_back(input_tokens[n_consumed_input_tokens]);

                _last_n_tokens.erase(_last_n_tokens.begin());
                _last_n_tokens.push_back(input_tokens[n_consumed_input_tokens]);
                ++n_consumed_input_tokens;

                if (_embd.size() > _params.n_batch) {
                    break;
                }
            }
        }

#if DEBUG
        {
#else
        if (is_input_tokens_consumed) {
#endif // DEBUG
            for (auto ident : _embd) {
                const char *tokenCString = _model->_vocab.id_to_token[ident].c_str();
#if DEBUG
                printf("%s", tokenCString);

                if (is_input_tokens_consumed) {
#endif // DEBUG
                    if (tokenHandler) {
                        NSString * const tokenString = [[NSString alloc] initWithUTF8String:tokenCString];
                        tokenHandler(tokenString);
                    }
#if DEBUG
                }
#endif // DEBUG
            }
#if DEBUG
            fflush(stdout);
#endif // DEBUG
        }

        if (_embd.size() > 0 && _embd.back() == 2) {
#if DEBUG
            fprintf(stderr, " [end of text]\n");
#endif // DEBUG
            if (completionHandler) {
                completionHandler(nil);
            }
            return;
        }
    }

    if (completionHandler) {
        NSError * const error = [[NSError alloc] initWithDomain:ALPChatErrorDomain
                                                           code:ALPChatErrorCodeNoRemainingTokens
                                                       userInfo:nil];
        completionHandler(error);
    }
}

@end
