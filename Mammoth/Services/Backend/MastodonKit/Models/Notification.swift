//
//  Notification.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Notificationt: Codable, Hashable {
    /// The notification ID.
    public var id: String
    /// The notification type.
    public let type: NotificationType
    /// The time the notification was created.
    public let createdAt: String
    /// The Account sending the notification to the user.
    public let account: Account
    /// The Status associated with the notification, if applicable.
    public var status: Status?
    /// Report that was the object of the notification. Attached when type of the notification is admin.report.
    public let report: Report?
    /// Summary of the event that caused follow relationships to be severed. Attached when type of the notification is severed_relationships.
    public let relationshipSeveranceEvent: RelationshipSeveranceEvent?

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case createdAt = "created_at"
        case account
        case status
        case report
        case relationshipSeveranceEvent = "relationship_severance_event"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public init(id: String,
                type: NotificationType,
                createdAt: String,
                account: Account,
                status: Status? = nil,
                report: Report? = nil,
                relationshipSeverance: RelationshipSeveranceEvent? = nil) {
        self.id = id
        self.type = type
        self.createdAt = createdAt
        self.account = account
        self.status = status
        self.report = report
        self.relationshipSeveranceEvent = relationshipSeverance
    }
}


extension Notificationt: Equatable {}

public func ==(lhs: Notificationt, rhs: Notificationt) -> Bool {
    let areEqual = lhs.id == rhs.id &&
        lhs.id == rhs.id
    
    return areEqual
}
