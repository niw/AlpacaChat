//
//  MessageView.swift
//  AlpacaChatApp
//
//  Created by Yoshimasa Niwa on 3/20/23.
//

import SwiftUI

struct MessageView: View {
    var message: Message

    private struct SenderView: View {
        var sender: Message.Sender

        var body: some View {
            switch sender {
            case .user:
                Text("You")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            case .system:
                Text("Alpaca")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
    }

    private struct MessageContentView: View {
        var message: Message

        var body: some View {
            switch message.state {
            case .none:
                ProgressView()
            case .error:
                Text(message.text)
                    .foregroundColor(Color.red)
            case .typed:
                Text(message.text)
            case .predicting:
                HStack {
                    Text(message.text)
                    ProgressView()
                        .padding(.leading, 3.0)
                }
            case .predicted(tokensPerSeconds: let tokenPerSeconds):
                VStack(alignment: .leading) {
                    Text(message.text)
                    Text(String(format: "%.2f tokens/s", tokenPerSeconds))
                        .font(.footnote)
                        .foregroundColor(Color.gray)
                }
            }
        }
    }

    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6.0) {
                SenderView(sender: message.sender)
                MessageContentView(message: message)
                    .padding(12.0)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(12.0)
            }

            if message.sender == .system {
                Spacer()
            }
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MessageView(message: Message(sender: .user, state: .none, text: "none"))
            MessageView(message: Message(sender: .user, state: .error, text: "error"))
            MessageView(message: Message(sender: .user, state: .predicting, text: "predicting"))
            MessageView(message: Message(sender: .user, state: .predicted(tokensPerSeconds: 3.1415), text: "predicted"))
        }
    }
}
