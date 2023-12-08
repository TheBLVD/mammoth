//
//  Poll.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 04/03/2019.
//  Copyright © 2019 Shihab Mehboob. All rights reserved.
//

import Foundation

public class Poll: Codable {
    /// The poll ID.
    public var id: String
    /// Poll expired?
    public var expired: Bool
    /// The time the poll expires.
    public var expiresAt: String?
    /// Whether the poll allows multiple choices.
    public var multiple: Bool
    /// The poll vote count.
    public var votesCount: Int
    /// Voted?
    public var voted: Bool?
    /// Options.
    public var options: [PollOptions]
    
    public var ownVotes: [Int]?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case expired
        case expiresAt = "expires_at"
        case multiple
        case votesCount = "votes_count"
        case voted
        case options
        case ownVotes = "own_votes"
    }
    
    public init(id: String,
                expired: Bool,
                expiresAt: String? = nil,
                multiple: Bool,
                votesCount: Int,
                voted: Bool? = nil,
                options: [PollOptions],
                ownVotes: [Int]? = nil) {
        self.id = id
        self.expired = expired
        self.expiresAt = expiresAt
        self.multiple = multiple
        self.votesCount = votesCount
        self.voted = voted
        self.options = options
        self.ownVotes = ownVotes ?? nil
    }
}

public class PollOptions: Codable {
    /// The poll title.
    public var title: String
    /// Poll votes count.
    public var votesCount: Int?
    
    private enum CodingKeys: String, CodingKey {
        case title
        case votesCount = "votes_count"
    }
    
    public init(title: String,
                votesCount: Int? = nil) {
        self.title = title
        self.votesCount = votesCount
    }
}

public class PollPost: Codable {
    public let options: [String]
    public let expiresIn: Int
    public let multiple: Bool?
    public let hideTotals: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case options
        case expiresIn = "expires_in"
        case multiple
        case hideTotals = "hide_totals"
    }
}

extension Poll: Equatable {}

public func ==(lhs: Poll, rhs: Poll) -> Bool {
    let areEqual = lhs.id == rhs.id &&
        lhs.id == rhs.id
    
    return areEqual
}
