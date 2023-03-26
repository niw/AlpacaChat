//
//  ChatViewModel.swift
//  AlpacaChatApp
//
//  Created by Yoshimasa Niwa on 3/19/23.
//

import AlpacaChat
import Foundation
import os

private extension Duration {
    var seconds: Double {
        Double(components.seconds) + Double(components.attoseconds) / 1.0e18
    }
}

@MainActor
final class ChatViewModel: ObservableObject {
    enum State {
        case none
        case loading
        case completed
    }

    private var chat: Chat?

    @Published
    var state: State = .none

    @Published
    var messages: [Message] = []

    func prepare() async {
        guard chat == nil else {
            return
        }

        do {
            state = .loading
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
        state = .completed
    }

    func send(message text: String) async {
        let requestMessage = Message(sender: .user, state: .typed, text: text)
        messages.append(requestMessage)

        guard let chat = chat else {
            let message = Message(sender: .system, state: .error, text: "Chat is unavailable.")
            messages.append(message)
            return
        }

        do {
            var message = Message(sender: .system, text: "")
            messages.append(message)
            let messageIndex = messages.endIndex - 1

            var numberOfTokens = 0
            let duration = try await ContinuousClock().measure {
                for try await token in chat.predictTokens(for: text) {
                    message.state = .predicting
                    message.text += token

                    var updatedMessages = messages
                    updatedMessages[messageIndex] = message
                    messages = updatedMessages

                    numberOfTokens += 1
                }
            }
            message.state = .predicted(tokensPerSeconds: Double(numberOfTokens) / duration.seconds)
            messages[messageIndex] = message
        } catch {
            let message = Message(sender: .system, state: .error, text: error.localizedDescription)
            messages.append(message)
        }
    }
}
