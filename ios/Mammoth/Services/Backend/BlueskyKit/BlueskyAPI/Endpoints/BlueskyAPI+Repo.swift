//
//  API+Repo.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension BlueskyAPI {
    
    private struct CreateBody<T: LexiconType>: Codable {
        var repo: String
        var collection: String
        var record: T
    }
    
    struct UploadBlobResponse: Decodable {
        var blob: Model.Blob
    }
    
    func createRecord<T: LexiconType>(
        repo: String,
        record: T
    ) async throws -> Model.Repo.StrongRef {
        
        let body = CreateBody(
            repo: repo,
            collection: T.type,
            record: record)
        
        return try await post(
            "com.atproto.repo.createRecord",
            jsonBody: body)
    }
    
    func deleteRecord(uri: String) async throws {
        let str = uri.dropFirst(5) // at://
        let parts = str.components(separatedBy: "/")
        
        guard parts.count == 3 else {
            throw Error.invalidURI
        }
        
        struct Body: Codable {
            var repo: String
            var collection: String
            var rkey: String
        }
        let body = Body(
            repo: parts[0],
            collection: parts[1],
            rkey: parts[2])
        
        return try await post(
            "com.atproto.repo.deleteRecord",
            jsonBody: body)
    }
    
    func uploadBlob(
        data: Data,
        contentType: HTTP.ContentType
    ) async throws -> UploadBlobResponse {
        
        try await post(
            "com.atproto.repo.uploadBlob",
            body: HTTP.Body(
                contentType: contentType,
                data: data))
    }
    
}
