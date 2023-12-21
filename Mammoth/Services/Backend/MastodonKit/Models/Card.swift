//
//  Card.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Card: Codable {
    /// The url associated with the card.
    public let url: String?
    /// The title of the card.
    public let title: String
    /// The card description.
    public let description: String
    /// The image associated with the card, if any.
    public let image: URL?
    /// The type of card.
    public let type: CardType
    /// The author's name.
    public let authorName: String?
    /// The author's url.
    public let authorUrl: String?
    /// The provider's name.
    public let providerName: String?
    /// The provider's url.
    public let providerUrl: String?
    /// The card HTML.
    public let html: String?
    /// The card's width.
    public let width: Int?
    /// The card's height.
    public let height: Int?
    /// Blur hash
    public let blurhash: String?
    
    private enum CodingKeys: String, CodingKey {
        case url
        case title
        case description
        case image
        case type
        case authorName = "author_name"
        case authorUrl = "author_url"
        case providerName = "provider_name"
        case providerUrl = "provider_url"
        case html
        case width
        case height
        case blurhash
    }

    public init(url: String?, title: String, description: String, image: URL? = nil, type: CardType, authorName: String? = nil, authorUrl: String? = nil, providerName: String? = nil, providerUrl: String? = nil, html: String? = nil, width: Int? = nil, height: Int? = nil, blurhash: String? = nil) {
        self.url = url
        self.title = title
        self.description = description
        self.image = image
        self.type = type
        self.authorName = authorName
        self.authorUrl = authorUrl
        self.providerName = providerName
        self.providerUrl = providerUrl
        self.html = html
        self.width = width
        self.height = height
        self.blurhash = blurhash
    }
}


