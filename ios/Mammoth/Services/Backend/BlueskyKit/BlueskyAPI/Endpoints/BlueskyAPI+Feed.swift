//
//  API+Feed.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension BlueskyAPI {
    
    struct FeedGeneratorResponse: Decodable {
        var view: Model.Feed.GeneratorView
        var isOnline: Bool
        var isValid: Bool
    }
    
    struct FeedResponse: Decodable {
        var feed: [FailableDecodable<Model.Feed.FeedViewPost>]
        var cursor: String?
    }
    
    struct PostThreadResponse: Decodable {
        var thread: Model.Union3<
            Model.Feed.ThreadViewPost,
            Model.Feed.NotFoundPost,
            Model.Feed.BlockedPost
        >
    }
    
    struct LikesListResponse: Decodable {
        struct Like: Decodable {
            var createdAt: Date
            var indexedAt: Date
            var actor: Model.Actor.ProfileView
        }
        var likes: [Like]
        var cursor: String?
    }
    
    struct RepostsListResponse: Decodable {
        var repostedBy: [Model.Actor.ProfileView]
        var cursor: String?
    }
    
    func getFeedGenerator(
        feedURI: String
    ) async throws -> FeedGeneratorResponse {
        try await get(
            "app.bsky.feed.getFeedGenerator",
            queryItems: [
                "feed": feedURI
            ])
    }
    
    func getFeed(
        feedURI: String,
        limit: Int = 100,
        cursor: String?
    ) async throws -> FeedResponse {
        try await get(
            "app.bsky.feed.getFeed",
            queryItems: [
                "feed": feedURI,
                "limit": limit,
                "cursor": cursor,
            ])
    }
    
    func getTimeline(limit: Int = 100, cursor: String?)
    async throws -> FeedResponse {
        try await get(
            "app.bsky.feed.getTimeline",
            queryItems: [
                "limit": limit,
                "cursor": cursor,
            ])
    }
    
    func getUserTimeline(userID: String, limit: Int = 100, cursor: String?)
    async throws -> FeedResponse {
        try await get(
            "app.bsky.feed.getAuthorFeed",
            queryItems: [
                "actor": userID,
                "limit": limit,
                "cursor": cursor,
            ])
    }
    
    func getPostThread(postURI: String, depth: Int? = nil)
    async throws -> PostThreadResponse {
        try await get(
            "app.bsky.feed.getPostThread",
            queryItems: [
                "uri": postURI,
                "depth": depth,
            ])
    }
    
    func getPostLikes(postURI: String, limit: Int = 100, cursor: String?)
    async throws -> LikesListResponse {
        try await get(
            "app.bsky.feed.getLikes",
            queryItems: [
                "uri": postURI,
                "limit": limit,
                "cursor": cursor,
            ])
    }
    
    func getPostReposts(postURI: String, limit: Int = 100, cursor: String?)
    async throws -> RepostsListResponse {
        try await get(
            "app.bsky.feed.getRepostedBy",
            queryItems: [
                "uri": postURI,
                "limit": limit,
                "cursor": cursor,
            ])
    }
    
}
