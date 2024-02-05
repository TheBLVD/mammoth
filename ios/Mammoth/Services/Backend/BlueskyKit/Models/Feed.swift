//
//  Feed.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension Model {
    enum Feed { }
}

// MARK: - Post

private let decodeRecursionLimit = 20

extension Model.Feed {
    
    struct Post: LexiconType {
        static var type: String { "app.bsky.feed.post" }
        
        var createdAt: Date
        var text: String
        
        var facets: [Model.RichText.Facet]?
        var reply: ReplyRef?
        var embed: Model.Embed.EmbedUnion?
    }
    
}

extension Model.Feed.Post {
    
    struct ReplyRef: LexiconType {
        static var type: String { "app.bsky.feed.post#replyRef" }
        
        var root: Model.Repo.StrongRef
        var parent: Model.Repo.StrongRef
    }
    
}

// MARK: - Like

extension Model.Feed {
    
    struct Like: LexiconType {
        static var type: String { "app.bsky.feed.like" }
        
        var createdAt: Date
        var subject: Model.Repo.StrongRef
    }
    
}

// MARK: - Repost

extension Model.Feed {
    
    struct Repost: LexiconType {
        static var type: String { "app.bsky.feed.repost" }
        
        var createdAt: Date
        var subject: Model.Repo.StrongRef
    }
    
}

// MARK: - Refs

extension Model.Feed {
    
    struct PostView: LexiconType {
        static var type: String { "app.bsky.feed.defs#postView" }
        
        var uri: String
        var cid: String
        var indexedAt: Date
        var author: Model.Actor.ProfileViewBasic
        var record: Model.Feed.Post
        
        var embed: Model.Embed.EmbedViewUnion?
        
        var likeCount: Int?
        var replyCount: Int?
        var repostCount: Int?
        
        var viewer: ViewerState?
    }
    
    struct ViewerState: LexiconType {
        static var type: String { "app.bsky.feed.defs#viewerState" }
        
        var like: String?
        var repost: String?
    }
    
    struct FeedViewPost: LexiconType {
        static var type: String { "app.bsky.feed.defs#feedViewPost" }
        
        var post: PostView
        var reply: ReplyRef?
        var reason: Model.Union1<ReasonRepost>?
    }
    
    struct ReplyRef: LexiconType {
        static var type: String { "app.bsky.feed.defs#replyRef" }
        
        var root: PostView
        var parent: PostView
    }
    
    struct ReasonRepost: LexiconType {
        static var type: String { "app.bsky.feed.defs#reasonRepost" }
        
        var indexedAt: Date
        var by: Model.Actor.ProfileViewBasic
    }
    
    struct ThreadViewPost: LexiconType {
        static var type: String { "app.bsky.feed.defs#threadViewPost" }
        
        typealias NestedPost = Model.Union3<
            ThreadViewPost,
            NotFoundPost,
            BlockedPost
        >
        
        var post: PostView
        
        var parent: NestedPost?
        var replies: [NestedPost]?
        
        enum CodingKeys: String, CodingKey {
            case post
            case parent
            case replies
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            
            post = try values.decode(PostView.self, forKey: .post)
            replies = try values.decodeIfPresent([NestedPost].self, forKey: .replies)
            
            if decoder.codingPath.count < decodeRecursionLimit {
                parent = try values.decodeIfPresent(NestedPost.self, forKey: .parent)
            } else {
                parent = NestedPost(NotFoundPost(uri: ""))
            }
        }
    }
    
    struct NotFoundPost: LexiconType {
        static var type: String { "app.bsky.feed.defs#notFoundPost" }
        
        var uri: String
    }
    
    struct BlockedPost: LexiconType {
        static var type: String { "app.bsky.feed.defs#blockedPost" }
        
        var uri: String
        var blocked: Bool
    }
    
    struct GeneratorView: LexiconType {
        static var type: String { "app.bsky.feed.defs#generatorView" }
        
        var uri: String
        var cid: String
        var did: String?
        var indexedAt: Date
        
        var creator: Model.Actor.ProfileView
        
        var displayName: String
        var avatar: String?
        
        var description: String?
        var descriptionFacets: [Model.RichText.Facet]?
        
        var likeCount: Int?
        
        var viewer: GeneratorViewerState?
    }
    
    struct GeneratorViewerState: LexiconType {
        static var type: String { "app.bsky.feed.defs#generatorViewerState" }
        
        var like: String?
    }
    
}
