//
//  Conversation.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 03/04/2019.
//  Copyright © 2019 Shihab Mehboob. All rights reserved.
//

import Foundation

public class Conversation: Codable, Hashable {
    /// The conversation ID.
    public let id: String
    /// The involved accounts.
    public let accounts: [Account]
    /// The last status in the thread.
    public var lastStatus: Status?
    /// Whether the message has been read.
    public let unread: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id
        case accounts
        case lastStatus = "last_status"
        case unread
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Conversation: Equatable {}

public func ==(lhs: Conversation, rhs: Conversation) -> Bool {
    let areEqual = lhs.id == rhs.id &&
        lhs.id == rhs.id
    
    return areEqual
}

