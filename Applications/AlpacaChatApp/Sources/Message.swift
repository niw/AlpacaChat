//
//  Message.swift
//  AlpacaChatApp
//
//  Created by Yoshimasa Niwa on 3/20/23.
//

import Foundation

struct Message: Identifiable {
    enum State {
        case none
        case error
        case typed
        case predicting
        case predicted(tokensPerSeconds: Double)
    }

    enum Sender {
        case user
        case system
    }

    var id = UUID()
    var sender: Sender
    var state: State = .none
    var text: String
}
