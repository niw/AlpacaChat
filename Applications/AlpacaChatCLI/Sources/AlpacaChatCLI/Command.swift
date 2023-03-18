//
//  Command.swift
//  AlpacaChatCLI
//
//  Created by Yoshimasa Niwa on 3/18/23.
//

import Foundation
import AlpacaChat
import ArgumentParser
import Darwin

@main
struct Command: AsyncParsableCommand {
    @Option(name: .shortAndLong, help: "Path to model file.")
    var modelPath: String

    mutating func run() async throws {
        let modelURL = URL(fileURLWithPath: modelPath)
        let model = try await Model.load(from: modelURL)
        let chat = Chat(model: model)

        while true {
            print("> ", terminator: "")
            guard let prompt = readLine() else {
                break
            }
            guard !prompt.isEmpty else {
                continue
            }

            for try await token in chat.predictTokens(for: prompt) {
                print(token, terminator: "")
                fflush(stdout)
            }
            print("")
        }
    }
}
