//
//  StatusService.swift
//  Mammoth
//
//  Created by Benoit Nolens on 26/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

// swiftlint:disable:next type_body_length
struct StatusService {
    
    enum FetchPolicy {
        case retryLocally   // search for the local status if the request fails with a "Record not found"
        case onlyLocal      // search for the local status and use that id to execute the task
        case regular        // execute the task using the status id passed as attribute
    }
    
    static func like(postCard: PostCardModel, withPolicy fetchPolicy: FetchPolicy = FetchPolicy.regular) async throws -> PostCardModel? {
        switch postCard.data {
        case .mastodon(let status):
            switch(fetchPolicy) {
            case .regular:
                if let id = status.reblog?.id ?? status.id {
                    let request = Statuses.favourite(id: id)
                    let result = try await ClientService.runRequest(request: request)
                    return PostCardModel(status: result)
                }
            case .retryLocally:
                return try await self.runTaskWithLocalRetry(forStatus: status) { id,_  in
                    let request = Statuses.favourite(id: id)
                    let result = try await ClientService.runRequest(request: request)
                    return PostCardModel(status: result)
                }
            case .onlyLocal:
                return try await self.runTaskLocally(forStatus: status) { id,_ in
                    let request = Statuses.favourite(id: id)
                    let result = try await ClientService.runRequest(request: request)
                    return PostCardModel(status: result)
                }
            }
            return nil
            
        case .bluesky(let postVM):
            let like = Model.Feed.Like(
                createdAt: Date(),
                subject: .init(to: postVM.post))
            
            guard let account = AccountsManager.shared.currentAccount as? BlueskyAcctData
            else { return postCard }
            
            let ref = try await account.api.createRecord(
                repo: account.userID,
                record: like)
            
            var newPostVM = postVM
            newPostVM.post.viewer?.like = ref.uri
            postCard.data = .bluesky(newPostVM)
            return postCard
        }
    }
    
    static func unlike(postCard: PostCardModel, withPolicy fetchPolicy: FetchPolicy = FetchPolicy.regular) async throws -> PostCardModel? {
        switch postCard.data {
        case .mastodon(let status):
            switch(fetchPolicy) {
            case .regular:
                if let id = status.reblog?.id ?? status.id {
                    let request = Statuses.unfavourite(id: id)
                    let result = try await ClientService.runRequest(request: request)
                    return PostCardModel(status: result)
                }
            case .retryLocally:
                return try await self.runTaskWithLocalRetry(forStatus: status) { id,_ in
                    let request = Statuses.unfavourite(id: id)
                    let result = try await ClientService.runRequest(request: request)
                    return PostCardModel(status: result)
                }
            case .onlyLocal:
                return try await self.runTaskLocally(forStatus: status) { id,_ in
                    let request = Statuses.unfavourite(id: id)
                    let result = try await ClientService.runRequest(request: request)
                    return PostCardModel(status: result)
                }
            }
            return nil
        
        case .bluesky(let postVM):
            guard let likeURI = postVM.post.viewer?.like
            else { return postCard }
            
            guard let account = AccountsManager.shared.currentAccount as? BlueskyAcctData
            else { return postCard }
            
            try await account.api.deleteRecord(uri: likeURI)
            
            var newPostVM = postVM
            newPostVM.post.viewer?.like = nil
            postCard.data = .bluesky(newPostVM)
            return postCard
        }
    }
    
    static func repost(postCard: PostCardModel, withPolicy fetchPolicy: FetchPolicy = FetchPolicy.regular) async throws -> PostCardModel? {
        switch postCard.data {
        case .mastodon(let status):
            switch(fetchPolicy) {
            case .regular:
                if let id = status.reblog?.id ?? status.id {
                    let request = Statuses.reblog(id: id)
                    let result = try await ClientService.runRequest(request: request)
                    return PostCardModel(status: result)
                }
            case .retryLocally:
                return try await self.runTaskWithLocalRetry(forStatus: status) { id,_ in
                    let request = Statuses.reblog(id: id)
                    let result = try await ClientService.runRequest(request: request)
                    return PostCardModel(status: result)
                }
            case .onlyLocal:
                return try await self.runTaskLocally(forStatus: status) { id,_ in
                    let request = Statuses.reblog(id: id)
                    let result = try await ClientService.runRequest(request: request)
                    return PostCardModel(status: result)
                }
            }
            return nil
            
        case .bluesky(let postVM):
            let repost = Model.Feed.Repost(
                createdAt: Date(),
                subject: .init(to: postVM.post))
            
            guard let account = AccountsManager.shared.currentAccount as? BlueskyAcctData
            else { return postCard }
            
            let ref = try await account.api.createRecord(
                repo: account.userID,
                record: repost)
            
            var newPostVM = postVM
            newPostVM.post.viewer?.repost = ref.uri
            postCard.data = .bluesky(newPostVM)
            return postCard
        }
    }
    
    static func unRepost(postCard: PostCardModel, withPolicy fetchPolicy: FetchPolicy = FetchPolicy.regular) async throws -> PostCardModel? {
        switch postCard.data {
        case .mastodon(let status):
            switch(fetchPolicy) {
            case .regular:
                if let id = status.reblog?.id ?? status.id {
                    let request = Statuses.unreblog(id: id)
                    let result = try await ClientService.runRequest(request: request)
                    return PostCardModel(status: result)
                }
            case .retryLocally:
                return try await self.runTaskWithLocalRetry(forStatus: status) { id,_ in
                    let request = Statuses.unreblog(id: id)
                    let result = try await ClientService.runRequest(request: request)
                    return PostCardModel(status: result)
                }
            case .onlyLocal:
                return try await self.runTaskLocally(forStatus: status) { id,_ in
                    let request = Statuses.unreblog(id: id)
                    let result = try await ClientService.runRequest(request: request)
                    return PostCardModel(status: result)
                }
            }
            return nil
            
        case .bluesky(let postVM):
            guard let repostURI = postVM.post.viewer?.repost
            else { return postCard }
            
            guard let account = AccountsManager.shared.currentAccount as? BlueskyAcctData
            else { return postCard }
            
            try await account.api.deleteRecord(uri: repostURI)
            
            var newPostVM = postVM
            newPostVM.post.viewer?.repost = nil
            postCard.data = .bluesky(newPostVM)
            return postCard
        }
    }
    
    static func bookmark(status: Status, withPolicy fetchPolicy: FetchPolicy = FetchPolicy.regular) async throws -> Status? {
        switch(fetchPolicy) {
        case .regular:
            if let id = status.reblog?.id ?? status.id {
                let request = Bookmarks.bookmark(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        case .retryLocally:
            return try await self.runTaskWithLocalRetry(forStatus: status) { id,_ in
                let request = Bookmarks.bookmark(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        case .onlyLocal:
            return try await self.runTaskLocally(forStatus: status) { id,_ in
                let request = Bookmarks.bookmark(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        }
        
        return nil
    }
    
    static func unbookmark(status: Status, withPolicy fetchPolicy: FetchPolicy = FetchPolicy.regular) async throws -> Status? {
        switch(fetchPolicy) {
        case .regular:
            if let id = status.reblog?.id ?? status.id {
                let request = Bookmarks.unbookmark(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        case .retryLocally:
            return try await self.runTaskWithLocalRetry(forStatus: status) { id,_ in
                let request = Bookmarks.unbookmark(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        case .onlyLocal:
            return try await self.runTaskLocally(forStatus: status) { id,_ in
                let request = Bookmarks.unbookmark(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        }

        return nil
    }
    
    static func pin(status: Status, withPolicy fetchPolicy: FetchPolicy = FetchPolicy.regular) async throws -> Status? {
        switch(fetchPolicy) {
        case .regular:
            if let id = status.reblog?.id ?? status.id {
                let request = Statuses.pin(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        case .retryLocally:
            return try await self.runTaskWithLocalRetry(forStatus: status) { id,_ in
                let request = Statuses.pin(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        case .onlyLocal:
            return try await self.runTaskLocally(forStatus: status) { id,_ in
                let request = Statuses.pin(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        }
        
        return nil
    }
    
    static func unpin(status: Status, withPolicy fetchPolicy: FetchPolicy = FetchPolicy.regular) async throws -> Status? {
        switch(fetchPolicy) {
        case .regular:
            if let id = status.reblog?.id ?? status.id {
                let request = Statuses.unpin(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        case .retryLocally:
            return try await self.runTaskWithLocalRetry(forStatus: status) { id,_ in
                let request = Statuses.unpin(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        case .onlyLocal:
            return try await self.runTaskLocally(forStatus: status) { id,_ in
                let request = Statuses.unpin(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        }
        
        return nil
    }
    
    static func delete(status: Status, withPolicy fetchPolicy: FetchPolicy = FetchPolicy.regular) async throws -> Empty? {
        switch(fetchPolicy) {
        case .regular:
            if let id = status.reblog?.id ?? status.id {
                let request = Statuses.delete(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        case .retryLocally:
            return try await self.runTaskWithLocalRetry(forStatus: status) { id,_ in
                let request = Statuses.delete(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        case .onlyLocal:
            return try await self.runTaskLocally(forStatus: status) { id,_ in
                let request = Statuses.delete(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        }

        return nil
    }
    
    static func fetchStatus(status: Status, withPolicy fetchPolicy: FetchPolicy = FetchPolicy.regular) async throws -> Status? {
        switch(fetchPolicy) {
        case .regular:
            if let id = status.reblog?.id ?? status.id {
                let request = Statuses.status(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        case .retryLocally:
            return try await self.runTaskWithLocalRetry(forStatus: status) { id,_ in
                let request = Statuses.status(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        case .onlyLocal:
            return try await self.runTaskLocally(forStatus: status) { id,_ in
                let request = Statuses.status(id: id)
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        }

        return nil
    }
    
    static func fetchStatus(id statusId: String?, instanceName: String) async throws -> Status? {
        if let id = statusId {
            let request = Statuses.status(id: id)
            let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken
            let client = Client(baseURL: "https://\(instanceName)", accessToken: accessToken)
            let result = try await ClientService.runRequest(client: client, request: request)
            return result
        }
        
        return nil
    }
    
    static func fetchMothStatus(id statusId: String?) async throws -> Status? {
        if let id = statusId {
            let request = Statuses.status(id: id)
            let result = try await ClientService.runMothRequest(request: request)
            return result
        }
        
        return nil
    }

    static func getLocalStatus(status: Status) async throws -> Status? {
        if let url = status.reblog?.uri ?? status.uri {
           let request = Search.search(query: url, resolve: true)
           let result = try await ClientService.runRequest(request: request)
           return result.statuses.first
       }
       return nil
    }
    
    static func getOriginalStatus(status: Status) async throws -> Status? {
        if let id = status.originalId {
            let request = Statuses.status(id: id)
            let serverName = status.serverName
            guard let serverName = serverName else { return nil }
            let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken
            let client = Client(
                baseURL: "https://\(serverName)",
                accessToken: accessToken
            )
           
            let result = try await ClientService.runRequest(client: client, request: request)
            return result
        }
        return nil
    }
    
    static func fetchContext(status: Status, instanceName: String? = nil, withPolicy fetchPolicy: FetchPolicy = FetchPolicy.regular) async throws -> Context? {
        
        switch(fetchPolicy) {
        case .regular:
            if let id = status.reblog?.id ?? status.id {
                let request = Statuses.context(id: id)
                if let instanceName, !instanceName.isEmpty {
                    let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken
                    let client = Client(baseURL: "https://\(instanceName)", accessToken: accessToken)
                    return try await ClientService.runRequest(client: client, request: request)
                } else {
                    return try await ClientService.runRequest(request: request)
                }
            }
        case .retryLocally:
            return try await self.runTaskWithLocalRetry(forStatus: status) { id,_ in
                let request = Statuses.context(id: id)
                if let instanceName, !instanceName.isEmpty {
                    let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken
                    let client = Client(baseURL: "https://\(instanceName)", accessToken: accessToken)
                    return try await ClientService.runRequest(client: client, request: request)
                } else {
                    return try await ClientService.runRequest(request: request)
                }
            }
        case .onlyLocal:
            return try await self.runTaskLocally(forStatus: status) { id,_ in
                let request = Statuses.context(id: id)
                if let instanceName, !instanceName.isEmpty {
                    let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken
                    let client = Client(baseURL: "https://\(instanceName)", accessToken: accessToken)
                    return try await ClientService.runRequest(client: client, request: request)
                } else {
                    return try await ClientService.runRequest(request: request)
                }
            }
        }
        
        return nil
    }
    
    static func likes(id statusId: String?, instanceName: String? = nil, range: RequestRange = .default) async throws -> ([Account], Pagination?) {
        if let id = statusId {
            if let instanceName, !instanceName.isEmpty {
                let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken
                let client = Client(baseURL: "https://\(instanceName)", accessToken: accessToken)
                let request = Statuses.favouritedBy(id: id, range: range)
                return try await ClientService.runPaginatedRequest(client: client, request: request)
            } else {
                let request = Statuses.favouritedBy(id: id, range: range)
                return try await ClientService.runPaginatedRequest(request: request)
            }
        }
        
        return ([], nil)
    }
    
    static func reposts(id statusId: String?, instanceName: String? = nil, range: RequestRange = .default) async throws -> ([Account], Pagination?) {
        if let id = statusId {
            if let instanceName, !instanceName.isEmpty {
                let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken
                let client = Client(baseURL: "https://\(instanceName)", accessToken: accessToken)
                let request = Statuses.rebloggedBy(id: id, range: range)
                return try await ClientService.runPaginatedRequest(client: client, request: request)
            } else {
                let request = Statuses.rebloggedBy(id: id, range: range)
                return try await ClientService.runPaginatedRequest(request: request)
            }
        }
        
        return ([], nil)
    }
    
    @discardableResult
    static func report(accountID: String, status: Status, withPolicy fetchPolicy: FetchPolicy = FetchPolicy.regular) async throws -> Report? {
        
        switch(fetchPolicy) {
        case .regular:
            if let id = status.reblog?.id ?? status.id {
                let request = Reports.report(accountID: status.account?.id ?? "", statusIDs: [id], reason: "")
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        case .retryLocally:
            return try await self.runTaskWithLocalRetry(forStatus: status) { id, accountId in
                let request = Reports.report(accountID: accountId ?? "", statusIDs: [id], reason: "")
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        case .onlyLocal:
            return try await self.runTaskLocally(forStatus: status) { id, accountId in
                let request = Reports.report(accountID: accountId ?? "", statusIDs: [id], reason: "")
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        }
        
        return nil
    }
}

// MARK: - Helpers
extension StatusService {
    /// Executes a task (like, bookmark, repost, etc). If it fails because of "Record not found"
    /// we'll search for the status on the user's instance and retry the action using the local status
    static func runTaskWithLocalRetry<Model>(forStatus status: Status, task: (_ id: String, _ accountId: String?) async throws -> Model?) async throws -> Model? {
        do {
            return try await task(status.reblog?.id ?? status.id ?? "", status.account?.id)
        } catch let error {
            do {
                switch error as? ClientError {
                case .mastodonError(let message):
                    if message == "Record not found" {
                        return try await self.runTaskLocally(forStatus: status, task: task)
                    }
                default: break
                }
                
                log.error("Error running task with local retry: \(error)")
                throw error
            } catch let error {
                throw error
            }
        }
    }
    
    /// Search for the status on the user's instance and call the action using the local status
    static func runTaskLocally<Model>(forStatus status: Status, task: (_ id: String, _ accountId: String?) async throws -> Model?) async throws -> Model? {
        do {
            do {
                guard let originalId = (status.reblog ?? status)?.originalId else {
                    throw NSError(domain: "No original id", code: 401)
                }
                
                return try await task(originalId, status.account?.id)
            } catch {
                let localStatus = try await StatusService.getLocalStatus(status: status)
                if let localId = localStatus?.reblog?.id ?? localStatus?.id {
                    return try await task(localId, localStatus?.account?.id)
                } else {
                    // throw so caller can handle all error cases
                    throw NSError(domain: "Cant find local id", code: 401)
                }
            }
            
        } catch let error {
            throw error
        }
    }
}
