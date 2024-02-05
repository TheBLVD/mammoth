//
//  DiffSections.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 29/04/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class DiffSections: Codable, Equatable, Hashable {
    public let id: Int
    public let title: String
    public var image: String
    
    public enum CodingKeys: String, CodingKey {
        case id
        case title
        case image
    }
    
    init(id: Int, title: String, image: String) {
        self.id = id
        self.title = title
        self.image = image
    }
    
    public static func ==(lhs: DiffSections, rhs: DiffSections) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        image = try container.decode(String.self, forKey: .image)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(image, forKey: .image)
    }
}

