//
//  ALPChat.h
//  AlpacaChatObjC
//
//  Created by Yoshimasa Niwa on 3/16/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ALPChatModel;

FOUNDATION_EXPORT NSString * const ALPChatErrorDomain;

NS_ENUM(NSUInteger, ALPChatErrorCode) {
    ALPChatErrorCodeUnknown = 0,
    ALPChatErrorCodeCancelled,
    ALPChatErrorCodeFailedToPredict,
    ALPChatErrorCodeNoRemainingTokens,
};

@protocol ALPChatCancellable <NSObject>

- (void)cancel;

@end

@interface ALPChat : NSObject

- (instancetype)initWithModel:(ALPChatModel *)model NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (id<ALPChatCancellable>)predictTokensForPrompt:(NSString *)prompt
                                    tokenHandler:(nullable void (^)(NSString *token))tokenHandler
                               completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler
NS_SWIFT_NAME(predictTokens(for:tokenHandler:completionHandler:));

@end

NS_ASSUME_NONNULL_END
