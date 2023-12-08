//
//  NotificationType.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/17/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public enum NotificationType: String, Codable {
    /// The user has been mentioned.
    case mention
    /// The status message has been reblogged.
    case reblog
    /// The status message has been favourited.
    case favourite
    /// The user has a new follower.
    case follow
    /// The user has a new direct message.
    case direct
    /// A poll the user has voted on has ended.
    case poll
    
    case status
    case update
    case follow_request
    
//    case admin: NotificationTypeAdmin?
}

public enum NotificationTypeAdmin: String, Codable {
    case adminSignup
    case adminReport
    
    private enum CodingKeys: String, CodingKey {
        case adminSignup = "admin.sign_up"
        case adminReport = "admin.report"
    }
}
