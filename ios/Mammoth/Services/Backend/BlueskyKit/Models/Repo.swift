//
//  Repo.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension Model {
    enum Repo { }
}

extension Model.Repo {
    
    struct StrongRef: LexiconType {
        static var type: String { "com.atproto.repo.strongRef" }
        
        var uri: String
        var cid: String
    }
    
}

extension Model.Repo.StrongRef {
    
    init(to post: Model.Feed.PostView) {
        uri = post.uri
        cid = post.cid
    }
    
}
