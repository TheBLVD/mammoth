//
//  RelationshipSeveranceEventType.swift
//  Mammoth
//
//  Created by Joey Despiuvas on 28/03/24
//  Copyright © 2024 The BLVD. All rights reserved.
//

import Foundation

public enum RelationshipSeveranceEventType: String, Codable, CaseIterable {
    /// A moderator suspended a whole domain
    case domain_block
    /// The user blocked a whole domain
    case user_domain_block
    ///A moderator suspended a specific account
    case account_suspension
}
