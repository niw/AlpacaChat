//
//  ChatViewModel.swift
//  AlpacaChatApp
//
//  Created by Yoshimasa Niwa on 3/19/23.
//

import AlpacaChat
import Foundation

struct ChatMessage: Identifiable {
    var id: UUID
    var sender: String
    var text: String
}

@MainActor
final class ChatViewModel: ObservableObject {
    private var chat: Chat?

    @Published
    var isLoading: Bool = false

    @Published
    var messages: [ChatMessage] = []

    func prepare() async throws {
        isLoading = true

        guard chat == nil else {
            return
        }

        guard let modelURL = Bundle.main.url(forResource: "model", withExtension: "bin") else {
            return
        }
        let model = try await Model.load(from: modelURL)
        chat = Chat(model: model)

        isLoading = false
    }

    func sendMessage(sender: String, text: String) async throws {
        let message = ChatMessage(id: UUID(), sender: sender, text: text)
        messages.append(message)

        guard let chat = chat else {
            return
        }

        var replyText = ""
        for try await token in chat.predictTokens(for: text) {
            replyText += token
        }

        let reply = ChatMessage(id: UUID(), sender: "Alpaca", text: replyText)
        messages.append(reply)
    }
}
