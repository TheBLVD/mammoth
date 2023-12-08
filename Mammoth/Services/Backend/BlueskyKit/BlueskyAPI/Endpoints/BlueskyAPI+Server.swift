//
//  API+Server.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension BlueskyAPI {
    
    struct AuthResponse: Codable {
        var did: String
        var handle: String
        
        var accessJwt: String
        var refreshJwt: String
    }
    
    func createSession(identifier: String, password: String)
    async throws -> AuthResponse {
        
        struct Body: Codable {
            var identifier: String
            var password: String
        }
        let body = Body(
            identifier: identifier,
            password: password)
        
        return try await post(
            "com.atproto.server.createSession",
            jsonBody: body,
            authorization: .none)
    }
    
    func refreshSession(refreshToken: String)
    async throws -> AuthResponse {
        try await post(
            "com.atproto.server.refreshSession",
            authorization: .bearer(token: refreshToken))
    }
    
}
