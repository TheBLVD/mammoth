//
//  API+Graph.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension BlueskyAPI {
    
    struct FollowersResponse: Codable {
        var followers: [Model.Actor.ProfileView]
        var cursor: String?
    }
    
    struct FollowsResponse: Codable {
        var follows: [Model.Actor.ProfileView]
        var cursor: String?
    }
    
    func getUserFollowers(userID: String, limit: Int = 100, cursor: String?)
    async throws -> FollowersResponse {
        try await get(
            "app.bsky.graph.getFollowers",
            queryItems: [
                "actor": userID,
                "limit": limit,
                "cursor": cursor,
            ])
    }
    
    func getUserFollows(userID: String, limit: Int = 100, cursor: String?)
    async throws -> FollowsResponse {
        try await get(
            "app.bsky.graph.getFollows",
            queryItems: [
                "actor": userID,
                "limit": limit,
                "cursor": cursor,
            ])
    }
    
    func muteActor(id: String) async throws {
        struct Body: Codable { var actor: String }
        let body = Body(actor: id)
        
        return try await post(
            "app.bsky.graph.muteActor",
            jsonBody: body)
    }
    
    func unmuteActor(id: String) async throws {
        struct Body: Codable { var actor: String }
        let body = Body(actor: id)
        
        return try await post(
            "app.bsky.graph.unmuteActor",
            jsonBody: body)
    }

    
}
