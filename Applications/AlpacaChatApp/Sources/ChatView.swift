//
//  ChatView.swift
//  AlpacaChatApp
//
//  Created by Yoshimasa Niwa on 3/18/23.
//

import SwiftUI

struct MessageRowView: View {
    let message: Message

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
struct ChatView: View {
    @StateObject
    private var viewModel = ChatViewModel()

    @State
    private var inputText: String = ""

   

    var body: some View {
           VStack {
               List {
                   ForEach(viewModel.messages) { message in
                       MessageRowView(message: message)
                   }
                   .listRowSeparator(.hidden)
            }
            HStack {
                if viewModel.isLoading {
                    ProgressView {
                        Text("Loading...")
                    }
                } else {
                    TextField("Type your message...", text: $inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button {
                        Task {
                            let text = inputText
                            inputText = ""
                            await viewModel.send(message: text)
                        }
                    } label: {
                        Image(systemName: "paperplane")
                    }
                    .padding(.horizontal, 6.0)
                }
            }
            .padding(.all)
        }
        .navigationTitle("Chat")
        .task {
            await viewModel.prepare()
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
