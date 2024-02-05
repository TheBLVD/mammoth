//
//  StatusSourceType.swift
//  Mammoth
//
//  Created by Riley Howard on 10/25/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

public enum StatusSourceType: String, Codable {
    /// The various source types
    case Unknown // Not returned by server, but just in case...
    case Follows
    case FriendsOfFriends
    case MammothPick
    case SmartList
}
