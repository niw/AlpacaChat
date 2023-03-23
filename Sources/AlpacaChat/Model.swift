//
//  Model.swift
//  AlpacaChat
//
//  Created by Yoshimasa Niwa on 3/18/23.
//

import Foundation
import AlpacaChatObjC

public struct Model {
    var model: ALPChatModel

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public static func load(from url: URL, contextSize: Int32 = 512, isLowMemory: Bool = false) async throws -> Self {
        let model = try ALPChatModel.load(from: url, contextSize: contextSize, isLowMemory: isLowMemory)
        return Model(model: model)
    }
}
