//
//  ChatView.swift
//  AlpacaChatApp
//
//  Created by Yoshimasa Niwa on 3/18/23.
//

import SwiftUI

struct ChatView: View {
    @StateObject
    private var viewModel = ChatViewModel()

    @State
    private var inputText: String = ""

    var body: some View {
           VStack {
               List {
                   ForEach(viewModel.messages) { message in
                       MessageView(message: message)
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
