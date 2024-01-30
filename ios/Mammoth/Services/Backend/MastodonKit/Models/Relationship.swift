//
//  Relationship.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Relationship: Codable, Equatable {
    public static func == (lhs: Relationship, rhs: Relationship) -> Bool {
        return lhs.id == rhs.id &&
        lhs.following == rhs.following &&
        lhs.followedBy == rhs.followedBy &&
        lhs.blocking == rhs.blocking &&
        lhs.muting == rhs.muting &&
        lhs.mutingNotifications == rhs.mutingNotifications &&
        lhs.requested == rhs.requested &&
        lhs.domainBlocking == rhs.domainBlocking &&
        lhs.showingReblogs == rhs.showingReblogs &&
        lhs.note == rhs.note &&
        lhs.notifying == rhs.notifying
    }
    
    /// Target account id.
    public let id: String
    /// Whether the user is currently following the account.
    public let following: Bool
    /// Whether the user is currently being followed by the account.
    public let followedBy: Bool
    /// Whether the user is currently blocking the account.
    public let blocking: Bool
    /// Whether the user is currently muting the account.
    public let muting: Bool
    /// Whether the user is also muting notifications
    public let mutingNotifications: Bool
    /// Whether the user has requested to follow the account.
    public let requested: Bool
    /// Whether the user is currently blocking the user's domain.
    public let domainBlocking: Bool
    /// Whether the user's reblogs are displayed on the home timeline.
    public let showingReblogs: Bool
    
    public let note: String
    public let notifying: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case following
        case followedBy = "followed_by"
        case blocking
        case muting
        case mutingNotifications = "muting_notifications"
        case requested
        case domainBlocking = "domain_blocking"
        case showingReblogs = "showing_reblogs"
        case note
        case notifying
    }
}
