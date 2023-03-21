//
//  Message.swift
//  AlpacaChatApp
//
//  Created by Yoshimasa Niwa on 3/20/23.
//

import Foundation

struct Message: Identifiable {
    enum Sender {
        case user
        case system
    }

    var id = UUID()
    var sender: Sender
    var isLoading: Bool = false
    var text: String
}
