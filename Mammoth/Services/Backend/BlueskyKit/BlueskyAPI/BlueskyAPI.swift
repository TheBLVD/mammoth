//
//  API.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

private let baseURL = "https://bsky.social/xrpc"

protocol BlueskyAPIDelegate: AnyObject {
    func onUpdateTokenSet(_ tokenSet: BlueskyAPI.TokenSet)
}

class BlueskyAPI {
    
    struct TokenSet: Codable {
        var accessToken: String
        var refreshToken: String
    }
    
    enum Authorization {
        case accessToken
        case bearer(token: String)
        case none
    }
    
    enum Error: Swift.Error {
        case invalidURL
        case invalidURI
    }
    
    private let tokenManager: BlueskyAPITokenManager
    private let http = HTTP()
    
    init(tokenSet: TokenSet) {
        tokenManager = BlueskyAPITokenManager(tokenSet: tokenSet)
        
        Task { await self.tokenManager.setDelegate(self) }
    }
    
}

extension BlueskyAPI: BlueskyAPITokenManagerDelegate {
    
    func getRefreshedTokens(refreshToken: String)
    async throws -> BlueskyAPI.TokenSet {
        
        let response = try await refreshSession(refreshToken: refreshToken)
        
        return BlueskyAPI.TokenSet(
            accessToken: response.accessJwt,
            refreshToken: response.refreshJwt)
    }
    
    func onUpdateTokenSet(_ tokenSet: BlueskyAPI.TokenSet) {
        guard var account = AccountsManager.shared.currentAccount
            as? BlueskyAcctData
        else { return }
        
        account.tokenSet = tokenSet
        AccountsManager.shared.updateAccount(account)
    }
    
}

// MARK: - Requests

extension BlueskyAPI {
    
    func request(
        path: String,
        method: HTTP.Method,
        queryItems: [String: Any?] = [:],
        body: HTTP.Body? = nil,
        authorization: Authorization = .accessToken
    ) async throws -> Data? {
        
        let url = try url(
            baseURL: baseURL,
            path: path,
            queryItems: queryItems)
        
        let authorization = try await httpAuth(
            for: authorization)
        
        return try await http.request(
            url: url,
            method: method,
            headers: [:],
            authorization: authorization,
            body: body)
    }
    
    private func url(
        baseURL: String,
        path: String,
        queryItems: [String: Any?]
    ) throws -> URL {
        
        let urlString = ([baseURL] + [path])
            .joined(separator: "/")
        
        guard var urlComponents = URLComponents(string: urlString)
        else { throw Error.invalidURL }
        
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems.compactMap {
                guard let value = $0.value else { return nil }
                return URLQueryItem(
                    name: $0.key,
                    value: String(describing: value))
            }
        }
        
        guard let url = urlComponents.url
        else { throw Error.invalidURL }
        
        return url
    }
    
    private func httpAuth(for auth: Authorization)
    async throws -> HTTP.Authorization? {
        
        switch auth {
        case .accessToken:
            let token = try await tokenManager.getAccessToken()
            return .bearer(token: token)
            
        case .bearer(let token):
            return .bearer(token: token)
            
        case .none:
            return nil
        }
    }
    
}
