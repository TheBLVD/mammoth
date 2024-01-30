//
//  Hashtag.swift
//  Mammoth
//
//  Created by Riley Howard on 2/13/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

public class Hashtag: Codable, Hashable {
    
    /// The name of the hashtag (without the #)
    public let hashtag: String
    /// A 3-5 word description of the hashtag
    public let summary: String?
    /// A longer description of the hashtag
    public let bio: String?


    private enum CodingKeys: String, CodingKey {
        case hashtag
        case summary
        case bio
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hashtag)
    }
    
    public init(hashtag: String,
                summary: String?,
                bio: String?) {
        self.hashtag = hashtag
        self.summary = summary
        self.bio = bio
    }
}

extension Hashtag: Equatable {
    
    static public func ==(lhs: Hashtag, rhs: Hashtag) -> Bool {
        let areEqual = lhs.hashtag == rhs.hashtag
        return areEqual
    }
    
}

