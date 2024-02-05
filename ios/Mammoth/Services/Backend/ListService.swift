//
//  ListService.swift
//  Mammoth
//
//  Created by Benoit Nolens on 16/10/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

struct ListService {
    
    @discardableResult
    static func add(accountID: String, listID: String) async throws -> Empty {
        let request = Lists.add(accountIDs: [accountID], toList: listID)
        let result = try await ClientService.runRequest(request: request)
        return result
    }
    
    @discardableResult
    static func remove(accountID: String, listID: String) async throws -> Empty {
        let request = Lists.remove(accountIDs: [accountID], fromList: listID)
        let result = try await ClientService.runRequest(request: request)
        return result
    }
    
    static func accounts(listID: String, range: RequestRange = .default) async throws -> ([Account], Pagination?) {
        let request = Lists.accounts(id: listID)
        let result = try await ClientService.runPaginatedRequest(request: request)
        return result
    }
}
