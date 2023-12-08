//
//  ChannelOwner.swift
//  Mammoth
//
//  Created by Riley Howard on 11/21/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

public class ChannelOwner: Codable {
    /// Example: "tchambers"
    public let username: String
    /// Example: "indieweb.social"
    public let domain: String
    /// Example: "tchambers@indieweb.social"
    public let acct: String
    /// example: "Tim Chambers"
    public let displayName: String

    init() {
        self.username = ""
        self.domain = ""
        self.acct = ""
        self.displayName = ""
    }

    init(username: String, domain: String, acct: String, displayName: String) {
        self.username = username
        self.domain = domain
        self.acct = acct
        self.displayName = displayName
    }
    
    private enum CodingKeys: String, CodingKey {
        case username
        case domain
        case acct
        case displayName = "display_name"
    }
}

extension ChannelOwner: Equatable {
    static public func ==(lhs: ChannelOwner, rhs: ChannelOwner) -> Bool {
       return lhs.username == rhs.username &&
        lhs.domain == rhs.domain &&
        lhs.acct == rhs.acct &&
        lhs.displayName == rhs.displayName
    }
}
