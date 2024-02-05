//
//  RichText.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension Model {
    enum RichText { }
}

extension Model.RichText {
    
    struct Facet: LexiconType {
        static var type: String { "app.bsky.richtext.facet" }
        
        var index: ByteSlice
        var features: [Model.Union2<Mention, Link>]
    }
    
    struct Mention: LexiconType {
        static var type: String { "app.bsky.richtext.facet#mention" }
        
        var did: String
    }
    
    struct Link: LexiconType {
        static var type: String { "app.bsky.richtext.facet#link" }
        
        var uri: String
    }
    
    struct ByteSlice: LexiconType {
        static var type: String { "app.bsky.richtext.facet#byteSlice" }
        
        var byteStart: Int
        var byteEnd: Int
    }
    
}
