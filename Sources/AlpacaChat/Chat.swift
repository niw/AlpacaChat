//
//  Chat.swift
//  AlpacaChat
//
//  Created by Yoshimasa Niwa on 3/18/23.
//

import Foundation
import AlpacaChatObjC

public final class Chat {
    private let chat: ALPChat

    public init(model: Model) {
        chat = ALPChat(model: model.model)
    }

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func predictTokens(for prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            chat.predictTokens(for: prompt) { token in
                continuation.yield(token)
            } completionHandler: { error in
                continuation.finish(throwing: error)
            }
        }
    }
}
