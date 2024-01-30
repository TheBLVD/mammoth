//
//  API+Identity.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension BlueskyAPI {
    
    struct ResolveHandleResponse: Decodable {
        var did: String?
    }
    
    func resolveHandle(
        handle: String
    ) async throws -> ResolveHandleResponse {
        
        try await get(
            "com.atproto.identity.resolveHandle",
            queryItems: ["handle": handle])
    }
    
}
