//
//  StatusParams.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 27/01/2019.
//  Copyright © 2019 Shihab Mehboob. All rights reserved.
//

import Foundation

public class StatusPara: Codable {
    /// Body of the status.
    public let text: String
    /// null or the ID of the status it replies to.
//    public let inReplyToID: String?
//    /// Media IDs
//    public let mediaIDs: [String]?
//    /// Whether media attachments should be hidden by default.
//    public let sensitive: Bool?
//    /// If not empty, warning text that should be displayed before the actual content.
//    public let spoilerText: String?
//    /// The visibility of the status.
//    public let visibility: Visibility
//    /// The time the status was scheduled for.
//    public let scheduledAt: String?
//    /// Application from which the status was posted.
//    public let applicationID: String
    
    private enum CodingKeys: String, CodingKey {
        case text
//        case inReplyToID = "in_reply_to_id"
//        case mediaIDs = "media_ids"
//        case sensitive
//        case spoilerText = "spoiler_text"
//        case visibility
//        case scheduledAt = "scheduled_at"
//        case applicationID = "application_id"
    }
}

