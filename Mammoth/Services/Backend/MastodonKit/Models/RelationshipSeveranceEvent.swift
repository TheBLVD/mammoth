//
//  RelationshipSeveranceEvent.swift
//  Mammoth
//
//  Created by Joey Despiuvas on 28/03/24
//  Copyright © 2024 The BLVD. All rights reserved.
//

import Foundation

public class RelationshipSeveranceEvent: Codable {
    /// The ID of the relationship severance event in the database.
    public let id: String
    /// Type of event.
    public let type: RelationshipSeveranceEventType
    /// Whether the list of severed relationships is unavailable because the underlying issue has been purged.
    public let purged: Bool
    /// Name of the target of the moderation/block event. This is either a domain name or a user handle, depending on the event type.
    public let targetName: String
    /// Number of follow relationships (in either direction) that were severed.
    public let relationshipsCount: Int?
    /// When the event took place.
    public let createdAt: String
    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case purged
        case targetName = "target_name"
        case relationshipsCount = "relationships_count"
        case createdAt = "created_at"
    }
}
