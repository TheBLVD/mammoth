//
//  BlueskyAPI+Requests.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.timeZone = .init(secondsFromGMT: 0)
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    return f
}()

private let backupDateFormatter = ISO8601DateFormatter()

private let decoder: JSONDecoder = {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .custom({ decoder in
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        
        if let date = dateFormatter.date(from: str) {
            return date
        }
        
        // Workaround for server date format issues
        let strWithoutTimeZone = str
            .components(separatedBy: "+")
            .first ?? ""
        if let date = dateFormatter.date(from: String(strWithoutTimeZone)) {
            return date
        }
        
        if let date = backupDateFormatter.date(from: str) {
            return date
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Invalid date string: \(str) Locale: \(dateFormatter.locale.identifier)")
    })
    return d
}()

private let encoder: JSONEncoder = {
    let e = JSONEncoder()
    e.dateEncodingStrategy = .formatted(dateFormatter)
    return e
}()

// MARK: - Request Methods

extension BlueskyAPI {
    
    // MARK: GET
    
    func get(
        _ path: String,
        queryItems: [String: Any?] = [:]
    ) async throws {
        
        _ = try await request(
            path: path,
            method: .get,
            queryItems: queryItems)
    }
    
    func get<T: Decodable>(
        _ path: String,
        queryItems: [String: Any?] = [:]
    ) async throws -> T {
        
        let data = try await request(
            path: path,
            method: .get,
            queryItems: queryItems)
        
        return try await decode(T.self, from: data)
    }
    
    // MARK: POST
    
    private func _post(
        path: String,
        jsonBody: Codable?,
        authorization: Authorization = .accessToken
    ) async throws -> Data? {
        
        let body: HTTP.Body?
        if let jsonBody {
            let jsonData = try encoder.encode(jsonBody)
            body = .init(
                contentType: .applicationJson,
                data: jsonData)
        } else {
            body = nil
        }
        
        return try await request(
            path: path,
            method: .post,
            body: body,
            authorization: authorization)
    }
    
    func post(
        _ path: String,
        jsonBody: Codable? = nil
    ) async throws {
        
        _ = try await _post(
            path: path,
            jsonBody: jsonBody)
    }
    
    func post<T: Decodable>(
        _ path: String,
        jsonBody: Codable? = nil
    ) async throws -> T {
        
        let data = try await _post(
            path: path,
            jsonBody: jsonBody)
        
        return try await decode(T.self, from: data)
    }
    
    func post<T: Decodable>(
        _ path: String,
        jsonBody: Codable? = nil,
        authorization: Authorization
    ) async throws -> T {
        
        let data = try await _post(
            path: path,
            jsonBody: jsonBody,
            authorization: authorization)
        
        return try await decode(T.self, from: data)
    }
    
    func post<T: Decodable>(
        _ path: String,
        body: HTTP.Body
    ) async throws -> T {
        
        let data = try await request(
            path: path,
            method: .post,
            body: body)
        
        return try await decode(T.self, from: data)
    }
    
    // MARK: DELETE
    
    func delete(_ path: String) async throws {
        _ = try await request(
            path: path,
            method: .delete)
    }
    
}

// MARK: - Decoding

extension BlueskyAPI {
    
    func decode<T: Decodable>(_ type: T.Type, from data: Data?)
    async throws -> T {
        let task = Task(priority: .medium) {
            try decoder.decode(T.self, from: data ?? Data())
        }
        return try await task.value
    }
    
}
