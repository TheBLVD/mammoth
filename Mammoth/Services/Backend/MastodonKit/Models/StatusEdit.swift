//
//  StatusEdit.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 29/11/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

public class StatusEdit: Codable {
    /// The Account which posted the status.
    public let account: Account?
    /// Body of the status; this will contain HTML (remote HTML already sanitized).
    public var content: String
    /// The time the status was created.
    public let createdAt: String
    /// An array of Emoji.
    public let emojis: [Emoji]
    /// Whether media attachments should be hidden by default.
    public let sensitive: Bool?
    /// If not empty, warning text that should be displayed before the actual content.
    public let spoilerText: String
    /// An array of attachments.
    public let mediaAttachments: [Attachment]
    /// The status poll.
//    public let poll: Poll?

    private enum CodingKeys: String, CodingKey {
        case account
        case content
        case createdAt = "created_at"
        case emojis
        case sensitive
        case spoilerText = "spoiler_text"
        case mediaAttachments = "media_attachments"
//        case poll
    }
}
