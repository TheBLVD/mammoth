//
//  BlueskyPostViewModel.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

struct BlueskyPostViewModel {
    
    enum QuotedPost {
        case post(Post)
        case notFound
        
        struct Post {
            var viewRecord: Model.Embed.Record.ViewRecord
            var images: [Model.Embed.Images.ViewImage]
        }
        
        init(_ recordView: Model.Embed.Record.View) {
            if let viewRecord = recordView.record
                .value(Model.Embed.Record.ViewRecord.self) {
                
                let post = Post(
                    viewRecord: viewRecord,
                    images: viewRecord.embeds?.first?.images() ?? [])
                
                self = .post(post)
                
            } else {
                self = .notFound
            }
        }
    }
    
    struct FeedGenerator {
        var feedGenerator: Model.Feed.GeneratorView
        
        init?(_ recordView: Model.Embed.Record.View) {
            guard let feedGenerator = recordView.record
                .value(Model.Feed.GeneratorView.self)
            else { return nil }
            
            self.feedGenerator = feedGenerator
        }
    }
    
    var post: Model.Feed.PostView
    
    var images: [Model.Embed.Images.ViewImage]
    var externalLink: Model.Embed.External.ViewExternal?
    var quotedPost: QuotedPost?
    var linkedFeedGenerator: FeedGenerator?
    
    var isAuthorMe: Bool
    
    init(post: Model.Feed.PostView, myUserID: String) {
        self.post = post
        
        images = post.embed?.images() ?? []
        externalLink = post.embed?.external()
        
        let record = post.embed?.record()
        quotedPost = record.map { QuotedPost($0) }
        linkedFeedGenerator = record.flatMap { FeedGenerator($0) }
        
        isAuthorMe = post.author.did == myUserID
    }
    
}
