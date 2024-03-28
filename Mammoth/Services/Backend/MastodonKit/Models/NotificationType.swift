//
//  NotificationType.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/17/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public enum NotificationType: String, Codable, CaseIterable {
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
    
//  TODO: handle these notification types.
//    case adminSignup
//    case adminReport
//    case severed_relationships
    
    private enum CodingKeys: String, CodingKey {
        case mention
        case reblog
        case favourite
        case follow
        case direct
        case poll
        case status
        case update
        case follow_request
//        case adminSignup = "admin.signup"
//        case adminReport = "admin.report"
//        case severed_relationships
    }
}
