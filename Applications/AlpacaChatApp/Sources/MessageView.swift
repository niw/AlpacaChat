//
//  MessageView.swift
//  AlpacaChatApp
//
//  Created by Yoshimasa Niwa on 3/20/23.
//

import SwiftUI

struct MessageView: View {
    var message: Message

    @ViewBuilder
    private func senderLabel(for sender: Message.Sender) -> some View {
        switch sender {
        case .user:
            Text("You")
                .font(.caption)
                .foregroundColor(.secondary)
        case .system:
            Text("Alpaca")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func messageContent(for message: Message) -> some View {
        if message.isLoading {
            ProgressView()
        } else {
            Text(message.text)
                .padding(12.0)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(12.0)
        }
    }

    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6.0) {
                senderLabel(for: message.sender)
                messageContent(for: message)
            }

            if message.sender == .system {
                Spacer()
            }
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(message: Message(sender: .user, text: "Hello, world!"))
    }
}
