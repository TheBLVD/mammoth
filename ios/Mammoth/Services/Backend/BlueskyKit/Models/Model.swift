//
//  Models.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

enum Model { }

extension Model {
    
    struct Blob: LexiconType {
        static var type: String { "blob" }
        
        struct Ref: Codable {
            var link: String
            enum CodingKeys: String, CodingKey {
                case link = "$link"
            }
        }
        
        let type: String = Self.type
        
        var ref: Ref
        var mimeType: String
        var size: Int
        
        enum CodingKeys: String, CodingKey {
            case type = "$type"
            case ref
            case mimeType
            case size
        }
    }
    
}
