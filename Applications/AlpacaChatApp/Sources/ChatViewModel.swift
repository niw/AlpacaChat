//
//  ChatViewModel.swift
//  AlpacaChatApp
//
//  Created by Yoshimasa Niwa on 3/19/23.
//

import AlpacaChat
import Foundation
import os

extension String: Error {
}

@MainActor
final class ChatViewModel: ObservableObject {
    private var chat: Chat?

    @Published
    var isLoading: Bool = false

    @Published
    var messages: [Message] = []

    func prepare() async {
        guard chat == nil else {
            return
        }

        do {
            isLoading = true
            guard let modelURL = Bundle.main.url(forResource: "model", withExtension: "bin") else {
                throw "Model not found."
            }

            let contextSize: Int32
            let isLowMemory: Bool
#if targetEnvironment(simulator)
            contextSize = 2048
            isLowMemory = false
#else
            let memorySize = os_proc_available_memory()
            if memorySize > 6 * 1024 * 1024 * 1024 {
                contextSize = 2048
                isLowMemory = false
            } else {
                contextSize = 512
                isLowMemory = true
            }
#endif
            let model = try await Model.load(from: modelURL, contextSize: contextSize, isLowMemory: isLowMemory)
            chat = Chat(model: model)
        } catch {
            let message = Message(sender: .system, text: "Failed to load model.")
            messages.append(message)
        }
        isLoading = false
    }

    func send(message text: String) async {
        let requestMessage = Message(sender: .user, text: text)
        messages.append(requestMessage)

        guard let chat = chat else {
            let message = Message(sender: .system, text: "Chat is unavailable.")
            messages.append(message)
            return
        }

        do {
            var responseMessage = Message(sender: .system, isLoading: true, text: "")
            messages.append(responseMessage)
            let responseMessageIndex = messages.endIndex - 1
            for try await token in chat.predictTokens(for: text) {
                responseMessage.isLoading = false
                responseMessage.text += token
                messages[responseMessageIndex] = responseMessage
            }
        } catch {
            let message = Message(sender: .system, text: error.localizedDescription)
            messages.append(message)
        }
    }
}
