//
//  Channel.swift
//  Mammoth
//
//  Created by Riley Howard on 8/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

public class Channel: Codable {
    /// The channel ID
    public let id: String
    /// The channel title
    public let title: String
    /// General info about the channel
    public let description: String
    /// Channel icon (unicode character for FontAwesome)
    public let icon: String?
    /// Channel owner / maintainer
    public let owner: ChannelOwner?
    
    init() {
        self.id = ""
        self.title = ""
        self.description = ""
        self.icon = nil
        self.owner = ChannelOwner(username: "", domain: "", acct: "", displayName: "")
    }

    init(id: String, title: String, description: String = "", icon: String? = nil, owner: ChannelOwner? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.owner = owner
    }
}
extension Channel: Equatable {
    static public func ==(lhs: Channel, rhs: Channel) -> Bool {
       return lhs.id == rhs.id
    }
}
