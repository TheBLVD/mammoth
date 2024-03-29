//
//  Instance.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Instance: Codable {
    /// URI of the current instance.
//    public let uri: String
    /// The instance's title.
    public let title: String
    /// A description for the instance.
    public let description: String
    /// An email address which can be used to contact the instance administrator.
//    public let email: String
    /// The Mastodon version used by instance (as of version 1.3).
    public let version: String?
    /// Max toot characters for Pleroma (and supported) instances.
//    public let max_toot_chars: Int?
    /// Further instance stats
    public let usage: Usage
    /// The instance thumbnail.
//    public let thumbnail: String?
    
    public let domain: String
    
    public let configuration: PostConfiguration?
    
    public let rules: [Rules]?
}

public class Rules: Codable {
    public let text: String
}

public class PostConfiguration: Codable {
    public let statuses: PostConfigurationStatuses?
    public let urls: ConfigurationURLs?
    public let vapid: ConfigurationVAPID?
}

public class PostConfigurationStatuses: Codable {
    public let maxCharacters: Int
    
    private enum CodingKeys: String, CodingKey {
        case maxCharacters = "max_characters"
    }
}

public class ConfigurationURLs: Codable {
    public let streaming: String?
}

public class ConfigurationVAPID: Codable {
    public let publicKey: String?
    private enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
    }
}

public class Usage: Codable {
    /// User count
    public let users: UsersStats
}

public class UsersStats: Codable {
    /// User count
    public let activeMonth: Int
    
    private enum CodingKeys: String, CodingKey {
        case activeMonth = "active_month"
    }
}

public class tagInstances: Codable {
    public let instances: [tagInstance]
}

public class tagInstance: Codable {
    public let name: String
    public let users: String?
    public let activeUsers: Int?
    public let info: tagInstanceInfo?
    public let thumbnail: String?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case users
        case activeUsers = "active_users"
        case info
        case thumbnail
    }
}

public class tagInstanceInfo: Codable {
    public let shortDescription: String?
    public let fullDescription: String?
    public let categories: [String]?
    public let prohibitedContent: [String]?
    public let languages: [String]?
    
    private enum CodingKeys: String, CodingKey {
        case shortDescription = "short_description"
        case fullDescription = "full_description"
        case categories
        case prohibitedContent = "prohibited_content"
        case languages
    }
}

public class serverConstants: Codable {
    public let defaultVisibility: String?
    public let defaultPostingLanguage: String?

    private enum CodingKeys: String, CodingKey {
        case defaultVisibility = "posting:default:visibility"
        case defaultPostingLanguage = "posting:default:language"
    }
}
