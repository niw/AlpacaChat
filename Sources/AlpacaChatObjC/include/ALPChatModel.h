//
//  ALPChatModel.h
//  AlpacaChatObjC
//
//  Created by Yoshimasa Niwa on 3/16/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const ALPChatModelErrorDomain;

NS_ENUM(NSUInteger, ALPChatModelErrorCode) {
    ALPChatModelErrorCodeUnknown = 0,
    ALPChatModelErrorCodeFailedToLoad
};

@interface ALPChatModel : NSObject

+ (nullable ALPChatModel *)loadFromURL:(NSURL *)URL error:(NSError * _Nullable * _Nullable)error;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
