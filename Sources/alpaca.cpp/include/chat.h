//
//  chat.h
//  alpaca.cpp
//
//  Created by Yoshimasa Niwa on 3/16/23.
//

#pragma once

#include <ggml.h>
#include <utils.h>

#include <map>
#include <string>
#include <vector>

// default hparams (LLaMA 7B)
struct llama_hparams {
    int32_t n_vocab = 32000;
    int32_t n_ctx   = 512;   // this is provided as user input?
    int32_t n_embd  = 4096;
    int32_t n_mult  = 256;
    int32_t n_head  = 32;
    int32_t n_layer = 32;
    int32_t n_rot   = 64;
    int32_t f16     = 1;
};

struct llama_layer {
    // normalization
    struct ggml_tensor * attention_norm;

    // attention
    struct ggml_tensor * wq;
    struct ggml_tensor * wk;
    struct ggml_tensor * wv;
    struct ggml_tensor * wo;

    // normalization
    struct ggml_tensor * ffn_norm;

    // ff
    struct ggml_tensor * w1;
    struct ggml_tensor * w2;
    struct ggml_tensor * w3;
};

struct llama_model {
    llama_hparams hparams;

    struct ggml_tensor * tok_embeddings;

    struct ggml_tensor * norm;
    struct ggml_tensor * output;

    std::vector<llama_layer> layers;

    // key + value memory
    struct ggml_tensor * memory_k;
    struct ggml_tensor * memory_v;

    //
    struct ggml_context * ctx;
    std::map<std::string, struct ggml_tensor *> tensors;
};

bool llama_model_load(const std::string &fname,
                      llama_model &model,
                      gpt_vocab &vocab,
                      int n_ctx);

bool llama_model_load_lowmem(const std::string &fname,
                             llama_model &model,
                             gpt_vocab &vocab,
                             int n_ctx);

bool llama_eval(const llama_model &model,
                const int n_threads,
                const int n_past,
                const std::vector<gpt_vocab::id> &embd_inp,
                std::vector<float> &embd_w,
                size_t &mem_per_token);
