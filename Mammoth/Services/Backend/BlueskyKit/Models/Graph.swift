//
//  Graph.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension Model {
    enum Graph { }
}

extension Model.Graph {
    
    struct Follow: LexiconType {
        static var type: String { "app.bsky.graph.follow" }
        
        var createdAt: Date
        var subject: String
    }
    
    struct Block: LexiconType {
        static var type: String { "app.bsky.graph.block" }
        
        var createdAt: Date
        var subject: String
    }
    
}
