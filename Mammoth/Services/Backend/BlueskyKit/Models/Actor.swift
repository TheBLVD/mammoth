//
//  Actor.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension Model {
    enum Actor { }
}

extension Model.Actor {
    
    struct ProfileViewBasic: LexiconType {
        static var type: String { "app.bsky.actor.defs#profileViewBasic" }
        
        var did: String
        var handle: String
        var displayName: String?
        var avatar: String?
        var viewer: ViewerState?
    }
    
    struct ProfileView: LexiconType {
        static var type: String { "app.bsky.actor.defs#profileViewBasic" }
        
        var did: String
        var handle: String
        var displayName: String?
        var description: String?
        var avatar: String?
        var viewer: ViewerState?
    }
    
    struct ProfileViewDetailed: LexiconType {
        static var type: String { "app.bsky.actor.defs#profileViewDetailed" }
        
        var did: String
        var handle: String
        var displayName: String?
        var description: String?
        var avatar: String?
        var banner: String?
        var followersCount: Int?
        var followsCount: Int?
        var postsCount: Int?
        var indexedAt: Date?
        var viewer: ViewerState?
    }
    
    struct ViewerState: LexiconType {
        static var type: String { "app.bsky.actor.defs#viewerState" }
        
        var following: String?
        var followedBy: String?
        
        var blocking: String?
        var blockedBy: Bool?
        
        var muted: Bool?
    }
    
}

extension Model.Actor.ProfileView {
    
    var uiHandle: String { "@\(handle)" }
    var uiDisplayName: String {
        let name = displayName ?? handle
        return name.trimmingCharacters(in: .whitespaces)
    }
    
}

extension Model.Actor.ProfileViewBasic {
    
    var uiHandle: String { "@\(handle)" }
    var uiDisplayName: String {
        let name = displayName ?? handle
        return name.trimmingCharacters(in: .whitespaces)
    }
    
}

extension Model.Actor.ProfileViewDetailed {
    
    var uiHandle: String { "@\(handle)" }
    var uiDisplayName: String {
        let name = displayName ?? handle
        return name.trimmingCharacters(in: .whitespaces)
    }
    
}

extension Model.Actor.ViewerState {
    
    func isBlocked() -> Bool { blocking != nil }
    func isMuted() -> Bool { muted == true }
    
}
