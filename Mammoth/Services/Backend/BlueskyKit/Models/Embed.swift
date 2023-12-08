//
//  Embed.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension Model {
    enum Embed { }
}

extension Model.Embed {
    
    typealias EmbedUnion = Model.Union4<
        Images,
        External,
        Record,
        RecordWithMedia
    >
    
    typealias EmbedViewUnion = Model.Union4<
        Images.View,
        External.View,
        Record.View,
        RecordWithMedia.View
    >
    
}

// MARK: - Images

extension Model.Embed {
    
    struct Images: LexiconType {
        static var type: String { "app.bsky.embed.images" }
        
        var images: [Self.Image]
    }
    
}

extension Model.Embed.Images {
    
    struct Image: LexiconType {
        static var type: String { "app.bsky.embed.images#image" }
        
        var image: Model.Blob
        var alt: String
    }
    
    struct View: LexiconType {
        static var type: String { "app.bsky.embed.images#view" }
        
        var images: [ViewImage]
    }
    
    struct ViewImage: LexiconType {
        static var type: String { "app.bsky.embed.images#viewImage" }
        
        var thumb: String?
        var fullsize: String?
        var alt: String?
    }
    
}

// MARK: - External

extension Model.Embed {
    
    struct External: LexiconType {
        static var type: String { "app.bsky.embed.external" }
        
        var external: Self.External
    }
    
}

extension Model.Embed.External {
    
    struct External: LexiconType {
        static var type: String { "app.bsky.embed.external#external" }
        
        var uri: String
        var title: String
        var description: String
//        var thumb: Model.Blob?
    }
    
    struct View: LexiconType {
        static var type: String { "app.bsky.embed.external#view" }
        
        var external: ViewExternal
    }
    
    struct ViewExternal: LexiconType {
        static var type: String { "app.bsky.embed.external#viewExternal" }
        
        var uri: String
        var title: String
        var description: String
        var thumb: String?
    }
    
}

// MARK: - Record

extension Model.Embed {
    
    struct Record: LexiconType {
        static var type: String { "app.bsky.embed.record" }
        
        var record: Model.Repo.StrongRef
    }
    
}

extension Model.Embed.Record {
    
    struct View: LexiconType {
        static var type: String { "app.bsky.embed.record#view" }
        
        var record: Model.Union4<
            ViewRecord,
            ViewNotFound,
            ViewBlocked,
            Model.Feed.GeneratorView
        >
    }
    
    struct ViewRecord: LexiconType {
        static var type: String { "app.bsky.embed.record#viewRecord" }
        
        var uri: String
        var cid: String
        var author: Model.Actor.ProfileViewBasic
        var value: Model.Feed.Post
        var indexedAt: Date
        var embeds: [Model.Embed.EmbedViewUnion]?
    }
    
    struct ViewNotFound: LexiconType {
        static var type: String { "app.bsky.embed.record#viewNotFound" }
        
        var uri: String
    }
    
    struct ViewBlocked: LexiconType {
        static var type: String { "app.bsky.embed.record#viewBlocked" }
        
        var uri: String
    }
    
}

// MARK: - Record with media

extension Model.Embed {
    
    struct RecordWithMedia: LexiconType {
        static var type: String { "app.bsky.embed.recordWithMedia" }
        
        var record: Model.Embed.Record
        var media: Model.Union2<
            Model.Embed.Images,
            Model.Embed.External
        >
    }
    
}

extension Model.Embed.RecordWithMedia {
    
    struct View: LexiconType {
        static var type: String { "app.bsky.embed.recordWithMedia#view" }
        
        var record: Model.Embed.Record.View
        var media: Model.Union2<
            Model.Embed.Images.View,
            Model.Embed.External.View
        >
    }
    
}

// MARK: - Convenience Methods

extension Model.Embed.EmbedViewUnion {
    
    func images() -> [Model.Embed.Images.ViewImage] {
        if let v = value(Model.Embed.Images.View.self) {
            return v.images
        }
        if let v = value(Model.Embed.RecordWithMedia.View.self) {
            if let v = v.media.value(Model.Embed.Images.View.self) {
                return v.images
            }
        }
        return []
    }
    
    func external() -> Model.Embed.External.ViewExternal? {
        if let v = value(Model.Embed.External.View.self) {
            return v.external
        }
        if let v = value(Model.Embed.RecordWithMedia.View.self) {
            if let v = v.media.value(Model.Embed.External.View.self) {
                return v.external
            }
        }
        return nil
    }
    
    func record() -> Model.Embed.Record.View? {
        if let v = value(Model.Embed.Record.View.self) {
            return v
        }
        if let v = value(Model.Embed.RecordWithMedia.View.self) {
            return v.record
        }
        return nil
    }
    
}
