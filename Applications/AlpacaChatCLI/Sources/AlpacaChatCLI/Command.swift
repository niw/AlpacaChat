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
    @Option(name: .shortAndLong, help: "Context size.")
    var contextSize: Int32 = 2048
    @Flag(name: .shortAndLong, help: "Use low memory model loading.")
    var lowMemory: Bool = false

    mutating func run() async throws {
        let modelURL = URL(fileURLWithPath: modelPath)
        let model = try await Model.load(from: modelURL, contextSize: contextSize, isLowMemory: lowMemory)
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
