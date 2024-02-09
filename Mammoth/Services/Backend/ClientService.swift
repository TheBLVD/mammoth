//
//  ClientService.swift
//  Mammoth
//
//  Created by Benoit Nolens on 12/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation


/// Defaults to using the current user's instance as the baseURL
/// Optionally the request can be sent to Moth.social
/// runMothRequest is specific to make api request to the Moth.Social API
struct ClientService {
    static var mothClient: Client? {
        var mothClient: Client? = nil
        if AccountsManager.shared.currentAccount != nil {
            mothClient = AccountsManager.shared.currentAccountMothClient
        } else {
            log.error("mothClient called with no current account")
        }
        return mothClient
    }

    static var featureClient: Client? {
        var featureClient: Client? = nil
        if AccountsManager.shared.currentAccount != nil {
            featureClient = AccountsManager.shared.currentAccountFeatureClient
        } else {
            log.error("featureClient called with no current account")
        }
        return featureClient
    }

   static func runRequest<Model>(request: Request<Model>) async throws -> Model {
       guard AccountsManager.shared.currentAccount != nil else {
           let error = NSError(domain: "runRequest called with no current account", code: 401)
           log.error("\(error)")
           throw error
       }
       let client = AccountsManager.shared.currentAccountClient
       return try await self.runRequest(client: client, request: request)
    }
    
    static func runPaginatedRequest<Model>(request: Request<Model>) async throws -> (Model, Pagination?) {
        guard AccountsManager.shared.currentAccount != nil else {
            let error = NSError(domain: "runRequest called with no current account", code: 401)
            log.error("\(error)")
            throw error
        }
        let client = AccountsManager.shared.currentAccountClient
        return try await self.runPaginatedRequest(client: client, request: request)
     }
    
    static func runMothRequest<Model>(request: Request<Model>) async throws -> Model {
        if let mothClient = mothClient {
            return try await self.runRequest(client: mothClient, request: request)
        } else {
            let error = NSError(domain: "runRequest called with no current account", code: 401)
            log.error("\(error)")
            throw error
        }
    }
    
    static func runFeatureRequest<Model>(request: Request<Model>) async throws -> Model {
        if let featureClient = featureClient {
            return try await self.runRequest(client: featureClient, request: request)
        } else {
            let error = NSError(domain: "runRequest called with no current account", code: 401)
            log.error("\(error)")
            throw error
        }
    }

    static func runRequest<Model>(client: Client, request: Request<Model>) async throws -> Model {
         return try await withCheckedThrowingContinuation { continuation in
             client.run(request) { (result) in
                 switch result {
                 case .success(let data, _):
                     continuation.resume(returning: data)
                 case .failure(let error):
                     continuation.resume(throwing: error)
                 }
             }
         }
     }
    
    static func runPaginatedRequest<Model>(client: Client, request: Request<Model>) async throws -> (Model, Pagination?) {
         return try await withCheckedThrowingContinuation { continuation in
             client.run(request) { (result) in
                 switch result {
                 case .success(let data, let pagination):
                     continuation.resume(returning: (data, pagination))
                 case .failure(let error):
                     continuation.resume(throwing: error)
                 }
             }
         }
     }
}
