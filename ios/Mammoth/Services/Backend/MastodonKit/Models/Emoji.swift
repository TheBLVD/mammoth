//
//  Emoji.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 1/1/18.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Emoji: Codable {
    /// The shortcode of the emoji
    public let shortcode: String
    /// URL to the emoji static image
    public let staticURL: URL
    /// URL to the emoji image
    public let url: URL

    private enum CodingKeys: String, CodingKey {
        case shortcode
        case staticURL = "static_url"
        case url
    }
}

extension Emoji: Equatable {
    public static func == (lhs: Emoji, rhs: Emoji) -> Bool {
        return lhs.shortcode == rhs.shortcode &&
        lhs.staticURL == rhs.staticURL &&
        lhs.url == rhs.url
    }
}
