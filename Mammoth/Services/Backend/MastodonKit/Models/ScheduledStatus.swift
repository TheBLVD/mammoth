//
//  ScheduledStatus.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 27/01/2019.
//  Copyright © 2019 Shihab Mehboob. All rights reserved.
//

import Foundation

public class ScheduledStatus: Codable {
    /// The ID of the status.
    public var id: String
    /// The time the status was scheduled for.
    public let scheduledAt: String
    /// The status params.
    public let params: StatusPara
    /// An array of attachments.
    public let mediaAttachments: [Attachment]
    
    private enum CodingKeys: String, CodingKey {
        case id
        case scheduledAt = "scheduled_at"
        case params
        case mediaAttachments = "media_attachments"
    }
}

extension ScheduledStatus: Equatable {}

public func ==(lhs: ScheduledStatus, rhs: ScheduledStatus) -> Bool {
    let areEqual = lhs.id == rhs.id &&
        lhs.id == rhs.id
    
    return areEqual
}

