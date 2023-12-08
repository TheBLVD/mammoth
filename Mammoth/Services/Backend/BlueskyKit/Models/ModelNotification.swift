//
//  Notification.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension Model {
    
    struct Notification: LexiconType {
        static var type: String { "app.bsky.notification.listNotifications#notification" }
        
        var uri: String
        var cid: String
        var indexedAt: Date
        
        var author: Model.Actor.ProfileViewBasic
        var reason: Reason
        var reasonSubject: String?
        
        var record: Union4<
            Model.Feed.Post,
            Model.Feed.Like,
            Model.Feed.Repost,
            Model.Graph.Follow
        >
        var isRead: Bool
        
        enum Reason: String, Codable {
            case like
            case reply
            case mention
            case repost
            case quote
            case follow
        }
    }
    
}
