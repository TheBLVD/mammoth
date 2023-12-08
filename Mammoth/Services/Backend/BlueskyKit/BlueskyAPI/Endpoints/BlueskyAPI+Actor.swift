//
//  API+Actor.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension BlueskyAPI {
    
    struct SearchActorsResponse: Codable {
        var actors: [Model.Actor.ProfileView]
        var cursor: String?
    }
    
    struct SearchActorsTypeaheadResponse: Codable {
        var actors: [Model.Actor.ProfileViewBasic]
    }
    
    func getUserProfile(id: String)
    async throws -> Model.Actor.ProfileViewDetailed {
        try await get(
            "app.bsky.actor.getProfile",
            queryItems: ["actor": id])
    }
    
    func searchUsers(
        term: String,
        limit: Int = 50,
        cursor: String?
    ) async throws -> SearchActorsResponse {
        try await get(
            "app.bsky.actor.searchActors",
            queryItems: [
                "term": term,
                "limit": limit,
                "cursor": cursor,
            ])
    }
    
    func searchUsersTypeahead(
        term: String,
        limit: Int = 50
    ) async throws -> SearchActorsTypeaheadResponse {
        try await get(
            "app.bsky.actor.searchActorsTypeahead",
            queryItems: [
                "term": term,
                "limit": limit,
            ])
    }
    
}
