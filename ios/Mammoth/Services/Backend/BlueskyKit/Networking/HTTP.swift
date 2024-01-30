//
//  HTTP.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

struct HTTP {
    
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }
    
    enum Authorization {
        case bearer(token: String)
    }
    
    enum ContentType: String {
        case applicationJson = "application/json"
        case imageJpeg = "image/jpeg"
    }
    
    struct Body {
        var contentType: ContentType
        var data: Data
    }
    
    enum Error: Swift.Error {
        case networkFailure
        case invalidResponse
        case statusCode(Int)
    }
    
    let timeoutInterval: TimeInterval
    
    init(timeoutInterval: TimeInterval = 60) {
        self.timeoutInterval = timeoutInterval
    }
    
    func request(
        url: URL,
        method: Method,
        headers: [String: String],
        authorization: Authorization?,
        body: Body?
    ) async throws -> Data? {
        
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: timeoutInterval)
        
        request.httpMethod = method.rawValue
        
        for (header, value) in headers {
            request.setValue(value,
                forHTTPHeaderField: header)
        }
        
        if let authorization {
            switch authorization {
            case .bearer(let token):
                request.setValue(
                    "Bearer \(token)",
                    forHTTPHeaderField: "Authorization")
            }
        }
        
        if let body {
            request.setValue(
                body.contentType.rawValue,
                forHTTPHeaderField: "Content-Type")
            
            request.httpBody = body.data
        }
        
        return try await withCheckedThrowingContinuation { c in
            let task = URLSession.shared.dataTask(with: request) {
                data, response, error in
                
                guard error == nil else {
                    return c.resume(throwing: Error.networkFailure)
                }
                guard let response = response as? HTTPURLResponse else {
                    return c.resume(throwing: Error.invalidResponse)
                }
                let statusCode = response.statusCode
                guard (200 ..< 300) ~= statusCode else {
                    return c.resume(throwing: Error.statusCode(statusCode))
                }
                c.resume(returning: data)
            }
            task.resume()
        }
    }
    
}
