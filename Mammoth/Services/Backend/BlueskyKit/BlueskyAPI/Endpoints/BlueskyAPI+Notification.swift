//
//  API+Notification.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension BlueskyAPI {
    
    struct NotificationCountResponse: Decodable {
        var count: Int
    }
    
    struct NotificationsResponse: Decodable {
        var notifications: [FailableDecodable<Model.Notification>]
        var cursor: String?
    }
    
    func getUnreadNotificationCount()
    async throws -> NotificationCountResponse {
        try await get("app.bsky.notification.getUnreadCount")
    }
    
    func getNotifications(limit: Int = 100, cursor: String?)
    async throws -> NotificationsResponse {
        try await get(
            "app.bsky.notification.listNotifications",
            queryItems: [
                "limit": limit,
                "cursor": cursor,
            ])
    }
    
    func updateNotificationSeen(seenAt: Date) async throws {
        struct Body: Codable {
            var seenAt: Date
        }
        let body = Body(seenAt: seenAt)
        
        try await post(
            "app.bsky.notification.updateSeen",
            jsonBody: body)
    }
    
}
