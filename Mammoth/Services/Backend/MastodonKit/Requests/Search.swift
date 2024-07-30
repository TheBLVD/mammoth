//
//  Search.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public struct Search {
    /// Searches for content.
    ///
    /// - Parameters:
    ///   - query: The search query.
    ///   - resolve: Whether to resolve non-local accounts.
    /// - Returns: Request for `Results`.
    public static func search(query: String, resolve: Bool? = nil) -> Request<Results> {
        let parameters = [
            Parameter(name: "q", value: query),
            Parameter(name: "limit", value: "10"),
            Parameter(name: "resolve", value: resolve.flatMap(trueOrNil))
        ]
        let method = HTTPMethod.get(.parameters(parameters))
        return Request<Results>(path: "/api/v2/search", method: method)
    }
    
    public static func searchOne(query: String, resolve: Bool? = nil) -> Request<Results> {
        let parameters = [
            Parameter(name: "q", value: query),
            Parameter(name: "limit", value: "1"),
            Parameter(name: "resolve", value: resolve.flatMap(trueOrNil))
        ]
        let method = HTTPMethod.get(.parameters(parameters))
        return Request<Results>(path: "/api/v2/search", method: method)
    }

    public static func searchAccounts(query: String, limit: Int? = nil, following: Bool? = nil) -> Request<Results
    > {
        let toLimitBounds = between(1, and: 80, default: 80)
        let parameters = [
            Parameter(name: "q", value: query),
            Parameter(name: "resolve", value: "true"),
            Parameter(name: "type", value: "accounts"),
            Parameter(name: "limit", value: limit.map(toLimitBounds).flatMap(toOptionalString)),
            Parameter(name: "following", value: following.flatMap(trueOrNil))
        ]

        let method = HTTPMethod.get(.parameters(parameters))
        return Request<Results>(path: "/api/v2/search", method: method)
    }

    public static func searchPosts(query: String) -> Request<Results> {
        let parameters = [
            Parameter(name: "q", value: query),
            Parameter(name: "resolve", value: "true"),
            Parameter(name: "type", value: "statuses"),
            Parameter(name: "limit", value: "50"),
        ]
        let method = HTTPMethod.get(.parameters(parameters))
        return Request<Results>(path: "/api/v2/search", method: method)
    }

    public static func searchTags(query: String) -> Request<Results> {
        let parameters = [
            Parameter(name: "q", value: query),
            Parameter(name: "type", value: "hashtags"),
            Parameter(name: "limit", value: "50"),
        ]
        let method = HTTPMethod.get(.parameters(parameters))
        return Request<Results>(path: "/api/v2/search", method: method)
    }
    
    public static func searchAutocompleteAccounts(query: String) -> Request<[Account]> {
        // https://moth.social/api/v1/accounts/search?q=stro&resolve=false&limit=4
        // Using a v1 api for account autocomplete because there seems to be compatibility issues with moth.social and mastodon.social.
        // If this breaks, we should check what masto:web is doing. If they move account search in composer back to v2, we should as well.
        let parameters = [
            Parameter(name: "q", value: query),
            Parameter(name: "resolve", value: "true"),
            Parameter(name: "limit", value: "5")
        ]
        let method = HTTPMethod.get(.parameters(parameters))
        return Request<[Account]>(path: "/api/v1/accounts/search", method: method)
    }
}
