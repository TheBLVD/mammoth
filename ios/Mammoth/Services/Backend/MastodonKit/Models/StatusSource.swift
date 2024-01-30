//
//  StatusSource.swift
//  Mammoth
//
//  Created by Riley Howard on 10/25/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

public class StatusSource: Codable {
    /// The source type
    public let source: StatusSourceType
    /// The source title
    public let title: String?
    /// Originating account
    public let account: Account
    /// Channel ID (optional)
    public let channelID: String?
    
    private enum CodingKeys: String, CodingKey {
        case source
        case title
        case account = "originating_account"
        case channelID = "channel_id"
    }
    
    init(source: StatusSourceType, title: String?, account: Account, channelID: String?) {
        self.source = source
        self.title = title
        self.account = account
        self.channelID = channelID
    }
}

extension StatusSource: Equatable {
    static public func ==(lhs: StatusSource, rhs: StatusSource) -> Bool {
       return lhs.source == rhs.source &&
              lhs.title == rhs.title &&
              lhs.account == rhs.account
    }
}
