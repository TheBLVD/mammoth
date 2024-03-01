//
//  Account.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Account: Codable, Hashable {
    /// The ID of the account.
    public let id: String
    /// The username of the account.
    public let username: String
    /// Equals username for local users, includes @domain for remote ones.
    public let acct: String
    /// The account's display name.
    public let displayName: String
    /// Biography of user.
    public let note: String
    /// URL of the user's profile page (can be remote).
    public let url: String
    /// URL to the avatar image.
    public let avatar: String
    /// URL to the avatar static image
    public let avatarStatic: String
    /// URL to the header image.
    public let header: String
    /// URL to the header static image
    public let headerStatic: String
    /// Boolean for when the account cannot be followed without waiting for approval first.
    public let locked: Bool
    /// The time the account was created.
    public let createdAt: String?
    /// The number of followers for the account.
    public var followersCount: Int
    /// The number of accounts the given account is following.
    public var followingCount: Int
    /// The number of statuses the account has made.
    public let statusesCount: Int
    /// An array of Emoji.
    public let emojis: [Emoji]
    
    public let fields: [HashType]

    /// A 3-5 word description of the account
    /// Optional, as this is a Mammoth addition
    public let summary: String?

    public let bot: Bool
    public let lastStatusAt: String?
    public let discoverable: Bool?
    
    public let source: AccountSource?

    private enum CodingKeys: String, CodingKey {
        case id
        case username
        case acct
        case displayName = "display_name"
        case note
        case url
        case avatar
        case avatarStatic = "avatar_static"
        case header
        case headerStatic = "header_static"
        case locked
        case createdAt = "created_at"
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case statusesCount = "statuses_count"
        case fields
        case emojis
        case summary
        case bot
        case lastStatusAt = "last_status_at"
        case discoverable
        case source
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public init(id: String,
                username: String,
                acct: String,
                displayName: String,
                note: String,
                url: String,
                avatar: String,
                avatarStatic: String,
                header: String,
                headerStatic: String,
                locked: Bool,
                createdAt: String,
                followersCount: Int,
                followingCount: Int,
                statusesCount: Int,
                fields: [HashType],
                emojis: [Emoji],
                summary: String? = nil,
                bot: Bool,
                lastStatusAt: String? = nil,
                discoverable: Bool? = nil,
                source: AccountSource? = nil) {
        self.id = id
        self.username = username
        self.acct = acct
        self.displayName = displayName
        self.note = note
        self.url = url
        self.avatar = avatar
        self.avatarStatic = avatarStatic
        self.header = header
        self.headerStatic = headerStatic
        self.locked = locked
        self.createdAt = createdAt
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.statusesCount = statusesCount
        self.fields = fields
        self.emojis = emojis
        self.summary = summary
        self.bot = bot
        self.lastStatusAt = lastStatusAt
        self.discoverable = discoverable
        self.source = source
    }
}


public class AccountSource: Codable {
    public let privacy: String?
    public let sensitive: Bool
    public let language: String?
    
    private enum CodingKeys: String, CodingKey {
        case privacy
        case sensitive
        case language
    }
}


public extension Account {
    
    /// The account server, regardless of whether it's on the user's same server.
    /// Example: "mammoth@moth.social" would return "moth.social"
    var server: String {
        var server = ""
        if let otherUserURL = URL(string: self.url) {
            server = otherUserURL.host ?? ""
        }
        return server
    }
    
    static func server(fromUrl url: String) -> String {
        var server = ""
        if let otherUserURL = URL(string: url) {
            server = otherUserURL.host ?? ""
        }
        return server
    }
    
    
    /// The fully formed acct regardless whether it's on the user's same server.
    /// Example: "mammoth" would return "mammoth@moth.social"
    var fullAcct: String {
        // lowercase to increase chances of == succeeding
        // when comparing accounts from various sources
        return remoteFullOriginalAcct.lowercased()
    }
    
    /// The fully formed acct with original letter casing.
    ///  "rileyhBat@moth.social" will return it as it is on the servers
    /// Example: username "Mammoth" would return "Mammoth@moth.social"
    var remoteFullOriginalAcct: String {
        // If the username and acct are the same, then this
        // account is on the same server as the user.
        var remoteFullOriginalAcct: String
        if username == acct {
            remoteFullOriginalAcct = acct + "@" + self.server
        } else {
            remoteFullOriginalAcct = self.acct
        }
        return remoteFullOriginalAcct
    }

}

extension Account {
    
    convenience init(_ user: Model.Actor.ProfileViewBasic) {
        self.init(
            id: user.did,
            username: user.handle,
            acct: user.handle,
            displayName: user.displayName ?? "",
            note: "note",
            url: "url",
            avatar: user.avatar ?? "",
            avatarStatic: user.avatar ?? "",
            header: "",
            headerStatic: "",
            locked: false,
            createdAt: "",
            followersCount: 0,
            followingCount: 0,
            statusesCount: 0,
            fields: [],
            emojis: [],
            bot: false)
    }
    
}
