//
//  BlueskyAPITokenManager.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import JWTDecode

private let safetyInterval: TimeInterval = 60

protocol BlueskyAPITokenManagerDelegate: AnyObject {
    func getRefreshedTokens(refreshToken: String)
    async throws -> BlueskyAPI.TokenSet
    
    func onUpdateTokenSet(_ tokenSet: BlueskyAPI.TokenSet)
}

actor BlueskyAPITokenManager {
    
    enum BlueskyAPITokenManagerError: Error { case noDelegate }
    
    private weak var delegate: BlueskyAPITokenManagerDelegate?
    
    private var tokenSet: BlueskyAPI.TokenSet
    private var tokenExpiration: Date
    
    private var refreshTokensTask: Task<String, Error>? = nil
    
    init(tokenSet: BlueskyAPI.TokenSet) {
        self.tokenSet = tokenSet
        self.tokenExpiration = Self.expiration(from: tokenSet)
    }
    
    func getAccessToken() async throws -> String {
        // If we are currently refreshing, wait for the in-progress task
        if let refreshTokensTask {
            return try await refreshTokensTask.value
        }
        
        // If the token isn't expired, return it
        let refreshTime = tokenExpiration - safetyInterval
        if Date() < refreshTime {
            return tokenSet.accessToken
        }
        
        // If the token is expired, refresh it
        let task = Task<String, Error> {
            guard let delegate else {
                throw BlueskyAPITokenManagerError.noDelegate
            }
            
            let tokenSet = try await delegate.getRefreshedTokens(
                refreshToken: tokenSet.refreshToken)
            
            self.tokenSet = tokenSet
            self.tokenExpiration = Self.expiration(from: tokenSet)
            
            delegate.onUpdateTokenSet(tokenSet)
            
            return tokenSet.accessToken
        }
        
        refreshTokensTask = task
        let accessToken = try await task.value
        refreshTokensTask = nil
        
        return accessToken
    }
    
    func setDelegate(_ delegate: BlueskyAPITokenManagerDelegate) {
        self.delegate = delegate
    }
    
    private static func expiration(from tokenSet: BlueskyAPI.TokenSet) -> Date {
        let jwt = try? JWTDecode.decode(jwt: tokenSet.accessToken)
        return jwt?.expiresAt ?? .distantFuture
    }
    
}
