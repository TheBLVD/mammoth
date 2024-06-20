//
//  SuggestedService.swift
//  Mammoth
//
//  Created by Benoit Nolens on 12/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

struct AccountService {
    
    static func currentUser(_ client: Client? = nil) async throws -> Account? {
        do {
            let request = Accounts.currentUser()
            if client != nil {
                return try await ClientService.runRequest(client: client!, request: request)
            } else {
                return try await ClientService.runRequest(request: request)
            }
        } catch let error {
            log.error("error fetching accounts - \(error)")
            return nil
        }
    }
    
    static func user(withId id: String, client: Client? = nil) async throws -> Account? {
        do {
            let request = Accounts.account(id: id)
            if client != nil {
                return try await ClientService.runRequest(client: client!, request: request)
            } else {
                return try await ClientService.runRequest(request: request)
            }
        } catch let error {
            log.error("error fetching accounts - \(error)")
            return nil
        }
    }
    
    /// Used to get an account details from that instance
    /// - Parameter account: account to look up
    /// - Returns: Optional full account from the host server
    static func lookup(_ account: Account) async -> Account? {
        let searchname = account.acct
        let request = Accounts.lookup(acct: searchname)
        let server = account.server
        let client = Client(baseURL:"https://\(server)")
        return await withCheckedContinuation { continuation in
            // Do the account look up
            client.run(request) { (statuses) in
                if let error = statuses.error {
                    log.error("error in lookup for \(account.username )")
                    log.error("error :\(error)")
                    continuation.resume(returning: nil)
                    return
                }
                if let account = (statuses.value) {
                    continuation.resume(returning: account)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    static func lookup(_ fullAcct: String, serverName: String = AccountsManager.shared.currentAccountClient.baseHost) async -> Account? {
        let request = Accounts.lookup(acct: fullAcct)
        let client = Client(baseURL: "https://\(serverName)")
        return await withCheckedContinuation { continuation in
            // Do the account look up
            client.run(request) { (statuses) in
                if let error = statuses.error {
                    log.error("error in lookup for \(fullAcct)")
                    log.error("error :\(error)")
                    continuation.resume(returning: nil)
                    return
                }
                if let account = (statuses.value) {
                    continuation.resume(returning: account)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
        
    // moth.social user recommendations API
    // fallback to suggested recommendations from current instance
    static func getFollowRecommentations(fullAcct: String) async throws -> [Account] {
        do {
            let request = Accounts.followRecommendationsV3(fullAcct)
            let result = try await ClientService.runFeatureRequest(request: request)
            return result
        } catch let error {
            log.debug("FollowRecommentations failed to Moth.social: \(error)")
            let request = Accounts.followSuggestionsV2()
            let suggestions = try await ClientService.runRequest(request: request)
            let result = suggestions.map({ suggestion in
                suggestion.account
            })
            return result
        }
    }
    
    static func follow(userId: String) async throws -> Relationship {
        let request = Accounts.follow(id: userId, reblogs: true)
        let result = try await ClientService.runRequest(request: request)
        return result
    }
    
    static func unfollow(userId: String) async throws -> Relationship {
        let request = Accounts.unfollow(id: userId)
        let result = try await ClientService.runRequest(request: request)
        return result
    }
    
    static func followers(userId: String, instanceName: String? = nil, range: RequestRange = .default) async throws -> ([Account], Pagination?) {
        if let instanceName, !instanceName.isEmpty {
            let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken
            let client = Client(baseURL: "https://\(instanceName)", accessToken: accessToken)
            let request = Accounts.followers(id: userId, range: range)
            return try await ClientService.runPaginatedRequest(client: client, request: request)
        } else {
            let request = Accounts.followers(id: userId, range: range)
            return try await ClientService.runPaginatedRequest(request: request)
        }
    }
    
    static func following(userId: String, instanceName: String? = nil, range: RequestRange = .default) async throws -> ([Account], Pagination?) {
        if let instanceName, !instanceName.isEmpty {
            let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken
            let client = Client(baseURL: "https://\(instanceName)", accessToken: accessToken)
            let request = Accounts.following(id: userId, range: range)
            return try await ClientService.runPaginatedRequest(client: client, request: request)
        } else {
            let request = Accounts.following(id: userId, range: range)
            return try await ClientService.runPaginatedRequest(request: request)
        }
    }
    
    @discardableResult
    static func mute(userId: String, durationInSeconds duration: Int) async throws -> Relationship {
        let request = Accounts.mute(id: userId, durationInSeconds: duration)
        return try await ClientService.runRequest(request: request)
    }
    
    @discardableResult
    static func unmute(userId: String) async throws -> Relationship {
        let request = Accounts.unmute(id: userId)
        return try await ClientService.runRequest(request: request)
    }
    
    @discardableResult
    static func block(userId: String) async throws -> Relationship {
        let request = Accounts.block(id: userId)
        return try await ClientService.runRequest(request: request)
    }
    
    @discardableResult
    static func unblock(userId: String) async throws -> Relationship {
        let request = Accounts.unblock(id: userId)
        return try await ClientService.runRequest(request: request)
    }
    
    static func mutes(range: RequestRange = .default) async throws -> ([Account], Pagination?) {
        let request = Mutes.all(range: range)
        return try await ClientService.runPaginatedRequest(request: request)
    }
    
    static func blocks(range: RequestRange = .default) async throws -> ([Account], Pagination?) {
        let request = Blocks.all(range: range)
        return try await ClientService.runPaginatedRequest(request: request)
    }
    
    // Mastodon.com web client do not seem to use the webfinger function
    static func webfinger(user: UserCardModel, serverName: String) async -> String? {
        do {
            guard let acct = user.account?.acct, let username = user.account?.username else  {
                throw NSError(domain: "Bad properties", code: 400)
            }
            
            let request = URLRequest(url: URL(string: "https://\(serverName)/.well-known/webfinger?resource=acct:\(acct)")!)
            let (data, _) = try await URLSession.shared.data(for: request)
            guard !data.isEmpty else { return nil }
            
            let json = try JSONDecoder().decode(WebFinger.self, from: data)
            let ur = json.aliases.first { x in
                x.contains("@")
            }
            return "\(ur?.replacingOccurrences(of: "/@\(username)", with: "").replacingOccurrences(of: "https://", with: "") ?? "")"
        } catch let error {
            log.error("Error from webfinger: \(error)")
            return nil
        }
    }
    
    static func statuses(userId: String, excludeReplies: Bool, excludeReblogs: Bool, range: RequestRange = .default, serverName: String? = nil) async throws -> [Status] {
        let request = Accounts.statuses(id: userId, excludeReplies: excludeReplies, excludeReblogs: excludeReblogs, range: range)
        if let serverName, let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken {
            let client = Client(baseURL: "https://\(serverName)", accessToken: accessToken)
            let result = try await ClientService.runRequest(client: client, request: request)
            return result
        } else {
            let result = try await ClientService.runRequest(request: request)
            return result
        }
    }
    
    static func profilePosts(user: UserCardModel, range: RequestRange = .default, serverName: String? = nil) async throws -> (pinned: [Status], statuses: [Status], cursorId: String?) {
        let account: Account? = user.account
        guard let account = account else { throw NSError(domain: "Invalid account", code: 400) }
        
        async let statuses = AccountService.statuses(userId: account.id, excludeReplies: true, excludeReblogs: true, range: range, serverName: serverName)
        async let pinned = AccountService.pinned(userId: account.id, range: range, serverName: serverName)
        let result = try await [pinned, statuses]
        return (pinned: result[0], statuses: result[1].filter({ $0.visibility != .direct }), cursorId: result[1].last?.id)
    }
    
    static func profilePostsAndReplies(user: UserCardModel, range: RequestRange = .default, serverName: String? = nil) async throws -> (pinned: [Status], statuses: [Status], cursorId: String?) {
        let account: Account? = user.account
        guard let account = account else { throw NSError(domain: "Invalid account", code: 400) }
        
        async let statuses = AccountService.statuses(userId: account.id, excludeReplies: false, excludeReblogs: false, range: range, serverName: serverName)
        async let pinned = AccountService.pinned(userId: account.id, range: range, serverName: serverName)
        let result = try await [pinned, statuses]
        return (pinned: result[0], statuses: result[1].filter({ $0.visibility != .direct }), cursorId: result[1].last?.id)
    }
    
    static func pinned(userId: String, range: RequestRange = .default, serverName: String? = nil) async throws -> [Status] {
        let request = Accounts.statuses(id: userId, pinnedOnly: true, range: range)
        if let serverName, let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken {
            let client = Client(baseURL: "https://\(serverName)", accessToken: accessToken)
            let result = try await ClientService.runRequest(client: client, request: request)
            return result.map({
                $0.pinned = true
                return $0
            })
        } else {
            let result = try await ClientService.runRequest(request: request)
            return result.map({
                $0.pinned = true
                return $0
            })
        }
    }
    
    static func mentionsSent(range: RequestRange = .default) async throws -> ([Status], cursorId: String?) {
        guard let current = AccountsManager.shared.currentAccount as? MastodonAcctData else { throw NSError(domain: "Invalid account", code: 400) }
        let result = try await AccountService.statuses(userId: current.account.id, excludeReplies: false, excludeReblogs: true, range: range)
        let filtered = result.filter({
            // Show quote posts if the post is also mention a user (not only the quoted user)
            if $0.quotePostCard() != nil && $0.mentions.count > 1 {
                return true
            }
            
            // Hide quote posts with no other mention from mentions list
            if let quotePost = $0.quotePostCard(), let mention = $0.mentions.first, mention.url == quotePost.url  {
                return false
            }

            return !$0.mentions.isEmpty
        })
        
        return (filtered, cursorId: result.last?.id)
    }
    
    static func updateDisplayName(displayName: String) async throws -> Account {
        let request = Accounts.updateCurrentUser(displayName: displayName,
                                                 note: nil,
                                                 avatar: nil,
                                                 header: nil)
        let result = try await ClientService.runRequest(request: request)
        return result
    }

    static func updateAvatar(image: UIImage, compressionQuality: CGFloat) async throws -> Account {
        let avatarSizeLimit = 2000000 // ~2 MB limit for Mastodon avatar
        let compressionQuality = compressionQualityForImage(image, sizeLimit: avatarSizeLimit)
        log.debug("updateAvatar called to set image with quality:\(compressionQuality) size:\(image.jpegData(compressionQuality: compressionQuality)?.count ?? 0)")
        return try await self.retryWithLowerQuality(image: image, compressionQuality: compressionQuality) { quality in
            let request = Accounts.updateCurrentUser(displayName: nil,
                                                     note: nil,
                                                     avatar: .jpeg(image.jpegData(compressionQuality: quality)),
                                                     header: nil)
            let result = try await ClientService.runRequest(request: request)
            return result
        }
    }
    
    static func updateHeader(image: UIImage, compressionQuality: CGFloat) async throws -> Account {
        return try await self.retryWithLowerQuality(image: image, compressionQuality: 0.8) { quality in
            let request = Accounts.updateCurrentUser(displayName: nil,
                                                     note: nil,
                                                     avatar: nil,
                                                     header: .jpeg(image.jpegData(compressionQuality: quality)))
            let result = try await ClientService.runRequest(request: request)
            return result
        }
    }
    
    @discardableResult
    static func enableNotifications(user: Account) async throws -> Relationship {
        let request = Accounts.updateNotify(id: user.id, notify: true)
        let result = try await ClientService.runRequest(request: request)
        return result
    }
    
    @discardableResult
    static func disableNotifications(user: Account) async throws -> Relationship {
        let request = Accounts.updateNotify(id: user.id, notify: false)
        let result = try await ClientService.runRequest(request: request)
        return result
    }
    
    @discardableResult
    static func enableReposts(user: Account) async throws -> Relationship {
        let request = Accounts.updateRepost(id: user.id, repost: true)
        let result = try await ClientService.runRequest(request: request)
        return result
    }
    
    @discardableResult
    static func disableReposts(user: Account) async throws -> Relationship {
        let request = Accounts.updateRepost(id: user.id, repost: false)
        let result = try await ClientService.runRequest(request: request)
        return result
    }
    
    @discardableResult
    static func report(user: Account, withPolicy fetchPolicy: StatusService.FetchPolicy = StatusService.FetchPolicy.regular) async throws -> Report? {
        switch(fetchPolicy) {
        case .regular:
            let request = Reports.report(accountID: user.id, statusIDs: [], reason: "")
            let result = try await ClientService.runRequest(request: request)
            return result
        case .retryLocally:
            return try await self.runTaskWithLocalRetry(forAccount: user) { id in
                let request = Reports.report(accountID: id, statusIDs: [], reason: "")
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        case .onlyLocal:
            return try await self.runTaskLocally(forAccount: user) { id in
                let request = Reports.report(accountID: id, statusIDs: [], reason: "")
                let result = try await ClientService.runRequest(request: request)
                return result
            }
        }
    }
    
    static func getLocalAccount(account: Account) async throws -> Account? {
        let result = await AccountService.lookup(account.remoteFullOriginalAcct)
        return result
    }
}

extension AccountService {
    static func compressionQualityForImage(_ image: UIImage, sizeLimit: Int) -> CGFloat {
        // Return a compression quality that will make the image fit within the size limit
        var quality = 1.0
        var computedSize: Int
        repeat {
            computedSize = image.jpegData(compressionQuality: quality)?.count ?? 0
            if computedSize > sizeLimit {
                quality -= 0.1
            }
        } while (computedSize > sizeLimit)
        log.debug("Computed image quality of \(quality) for image size \(computedSize)")
        return quality
    }

    /// If the task fails, retry it with a lower compression quality, until the quality is zero
    static func retryWithLowerQuality<Model>(image: UIImage, compressionQuality: CGFloat,
                                             task: (_ quality: CGFloat) async throws -> Model) async throws -> Model {
        log.debug("retryWithLowerQuality image size:\(image.jpegData(compressionQuality: compressionQuality)?.count), quality: \(compressionQuality)")
        do {
            return try await task(compressionQuality)
        } catch let error {
            log.error("error sending image with quality:\(compressionQuality) - \(error)")
            if compressionQuality <= 0 {
                log.error("throwing error: \(error)")
                throw error
            }
            return try await retryWithLowerQuality(image: image, compressionQuality: compressionQuality - 0.1, task: task)
        }
    }
}

// MARK: - Helpers
extension AccountService {
    /// Executes a task. If it fails because of "Record not found"
    /// we'll search for the account on the user's instance and retry the action using the local account
    static func runTaskWithLocalRetry<Model>(forAccount account: Account, task: (_ id: String) async throws -> Model?) async throws -> Model? {
        do {
            return try await task(account.id)
        } catch let error {
            do {
                switch error as? ClientError {
                case .mastodonError(let message):
                    if message == "Record not found" {
                        return try await self.runTaskLocally(forAccount: account, task: task)
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
    static func runTaskLocally<Model>(forAccount account: Account, task: (_ id: String) async throws -> Model?) async throws -> Model? {
        do {
            if let localAccount = try await AccountService.getLocalAccount(account: account) {
                return try await task(localAccount.id)
            } else {
                // throw so caller can handle all error cases
                throw NSError(domain: "Cant find local id", code: 401)
            }
        } catch let error {
            throw error
        }
    }
}
