//
//  Hash.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 14/10/2018.
//  Copyright © 2018 Shihab Mehboob. All rights reserved.
//

import Foundation
import Meta
import MastodonMeta

public class HashType: Codable {
    
    public let name: String
    public let value: String
    public var metaValue: MastodonMetaContent?
    public let verifiedAt: String?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case value
        case verifiedAt = "verified_at"
    }
}

extension HashType {
    public func configureMetaValue(with emojis: MastodonContent.Emojis) {
        do {
            self.metaValue = try MastodonMetaContent.convert(document: MastodonContent(content: self.value, emojis: emojis))
        } catch {
            self.metaValue = MastodonMetaContent.convert(text: MastodonContent(content: self.value, emojis: emojis))
        }
    }
}

extension HashType: Equatable {
    public static func == (lhs: HashType, rhs: HashType) -> Bool {
        return lhs.name == rhs.name &&
        lhs.value == rhs.value &&
        lhs.verifiedAt == rhs.verifiedAt
    }
}
