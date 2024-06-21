//
//  FollowManager.swift
//  Mammoth
//
//  Created by Riley Howard on 2/24/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

// Support familiarFollowers ("Common Followers")



// Notes:
//      - now storing Relationship records in the cache directory
//      - also storing in a folder w/ the current user's full name for easy deletion later
//          (can't use currentUser.id as that could be the same # for two accounts
//          on two different servers)

/// Called when the status of a Follow relationship changes.
/// userInfo dictionary:
/// - "localID": The local ID of the 'other person' (OPTIONAL)
/// - "followStatus": Current relationship status
/// - "accountID": The account ID from the original Account; maybe remote, maybe local (OPTIONAL)
/// - "currentUserFullAcct" - Full user account name of the requesttor/user (foo@bar.social)
/// - "otherUserFullAcct" - Full user account name of the account being un/followed (foo@bar.social)
/// - "relationship" - updated relationship
/// - "followedByStatus" - FollowStatus of the updated relationship to the current Account
public let didChangeFollowStatusNotification = Notification.Name("didChangeFollowStatusNotification")

// swiftlint:disable:next type_body_length
class FollowManager {

    static let shared = FollowManager()

    enum FollowStatus: String {
        case unknown
        case inProgress             // network request has been made
        case notFollowing           // default (not following)
        case followRequested        // asked to follow
        case following              // am following
        case unfollowRequested      // asked to unfollow
        case followAwaitingApproval // awaiting approval
    }
    
    enum NetworkUpdateType: String {
        case none                   // no need to make a network request
        case force                  // request a network update
        case whenUncertain          // will request if not .following and not .notFollowing
    }
    
    /// Follow/unfollow requests that are incomplete (happening now) are tracked here.
    /// Use full account name since IDs may change due to local/remte
    var requestedFollows: [String] = []
    var requestedUnfollows: [String] = []
    
    /// Accounts we've asked for network updates on
    var updatesRequested: [String] = []
    
    /// Get the Follow status of a given account for AccountsManager.shared.currentUser()
    ///
    /// - Parameter account: Can be a local or remote account
    /// - Parameter requestUpdate: Should the FollowManager try to update the follow status?
    /// - Returns: Current relationship status
    @discardableResult
    public func followStatusForAccount(_ account: Account, requestUpdate: NetworkUpdateType = .none) -> FollowStatus {
        let currentUserFullAcct: String = AccountsManager.shared.currentUser()?.fullAcct ?? ""
        guard currentUserFullAcct != "" else {
            log.error("Expected AccountsManager.shared.currentUser()?.fullAcct to be valid")
            return .unknown
        }

        var currentStatus: FollowStatus = .unknown
        if requestedFollows.contains(account.fullAcct) {
            currentStatus = .followRequested
        } else if requestedUnfollows.contains(account.fullAcct) {
            currentStatus = .unfollowRequested
        } else if updatesRequested.contains(account.fullAcct) {
            currentStatus = .inProgress
        } else {
            // If we have a record on disk, use it.
            // These records are only valid for local IDs.
            do {
                let relationship = try Disk.retrieve("\(currentUserFullAcct)/profiles/\(account.fullAcct)/relationshipPro.json", from: .caches, as: Relationship.self)
                log.debug("M_FOLLOW", #function + " account: \(account.username) read from disk")
                if relationship.following {
                    currentStatus = .following
                } else if !relationship.following && relationship.requested {
                    currentStatus = .followAwaitingApproval
                } else {
                    currentStatus = .notFollowing
                }
            } catch {
                // no record on disk; that's fine
            }
        }
        
        // Kick off an update if requested
        var networkRequest = false
        if requestUpdate == .force {
            networkRequest = true
        }
        if requestUpdate == .whenUncertain {
            if currentStatus != .following && currentStatus != .notFollowing && currentStatus != .inProgress {
                networkRequest = true
            }
        }
        if networkRequest {
            self.updateFollowStatusForAccount(account)
        }
        
        log.debug("M_FOLLOW", #function + " account: \(account.username) status:\(currentStatus)")
        return currentStatus
    }
    
    /// Get the Followed By Status of a given account for AccountsManager.shared.currentUser()
    ///
    /// - Parameter account: Can be a local or remote account
    /// - Parameter requestUpdate: Should the FollowManager try to update the follow status?
    /// - Returns: Current relationship status of the account to the current user as followedBy true/false
    public func followedByStatusForAccount(_ account: Account, requestUpdate: NetworkUpdateType = .none) -> FollowStatus {
        let currentUserFullAcct: String = AccountsManager.shared.currentUser()?.fullAcct ?? ""
        guard currentUserFullAcct != "" else {
            log.error("Expected AccountsManager.shared.currentUser()?.fullAcct to be valid")
            return .unknown
        }
        // set status to unknown until value from disk or updated from network
        var currentStatus: FollowStatus = .unknown

            // If we have a record on disk, use it.
            // These records are only valid for local IDs.
            do {
                let relationship = try Disk.retrieve("\(currentUserFullAcct)/profiles/\(account.fullAcct)/relationshipPro.json", from: .caches, as: Relationship.self)
                log.debug("M_FOLLOWEDBY", #function + " account: \(account.username) read from disk")
                currentStatus = relationship.followedBy ? .following : .notFollowing
            } catch {
                // no record on disk; that's fine
            }
        
        
        // Kick off an update if requested
        var networkRequest = false
        if requestUpdate == .force {
            networkRequest = true
        }
        if requestUpdate == .whenUncertain {
            if currentStatus != .following && currentStatus != .notFollowing && currentStatus != .inProgress{
                networkRequest = true
            }
        }
        if networkRequest {
            self.updateFollowStatusForAccount(account)
        }
        
        log.debug("M_FOLLOWEDBY", #function + " account: \(account.username) status:\(currentStatus)")
        return currentStatus
    }

    
    /// Request to update the follow status of the given account
    ///
    /// - Parameter account: The account to folllow
    private func updateFollowStatusForAccount(_ account: Account) {
        guard AccountsManager.shared.currentUser() != nil else {
            log.error("Expected AccountsManager.shared.currentUser() to be valid")
            return
        }
        guard let currentUserFullAcct = AccountsManager.shared.currentUser()?.fullAcct else {
            log.error("Expected AccountsManager.shared.currentUser() to be valid")
            return
        }

        log.debug("M_FOLLOW", #function + " account: \(account.username)")
        self.updatesRequested.append(account.fullAcct)
        self.notifyUpdatedStatus(account: account, currentUserFullAcct: currentUserFullAcct, status: .inProgress)
        
        let isLocalID = (AccountsManager.shared.currentUser()?.server == account.server)
        let currentClient = AccountsManager.shared.currentAccountClient
        if isLocalID {
            self.updateRelationshipForLocalAccount(account, currentUserFullAcct: currentUserFullAcct, currentClient: currentClient)
        } else {
            // Get the account to be local, then do the check

            // Do the search, then the following
            let request = Accounts.lookup(acct: account.acct)
            currentClient.run(request) { (statuses) in
                if let error = statuses.error {
                    log.error("error searching for \(account.acct) : \(error)")
                }
                if let account = (statuses.value) {
                    DispatchQueue.main.async {
                        self.updateRelationshipForLocalAccount(account, currentUserFullAcct: currentUserFullAcct, currentClient: currentClient)
                    }
                }
            }
        }
    }
    
    
    /// Request to follow a given account from AccountsManager.shared.currentUser()
    ///
    /// - Parameter account: The account to folllow
    public func followAccount(_ account: Account) {
        log.debug("M_FOLLOW", #function + " account: \(account.username)")
        let currentUser = AccountsManager.shared.currentUser()
        let currentUserFullAcct: String = currentUser?.fullAcct ?? ""
        guard currentUserFullAcct != "" else {
            log.error("Expected AccountsManager.shared.currentUser()?.fullAcct to be valid")
            return
        }
        
        self.requestedFollows.append(account.fullAcct)
        self.notifyUpdatedStatus(account: account, currentUserFullAcct: currentUserFullAcct, status: .followRequested)
        
        // Optimization: if this account is on the currentUser's server, we can just follow
        // that ID. Otherwise, we need to do the lookup first.
        if currentUser?.server == account.server {
            log.debug("M_FOLLOW", #function + " treated like a local account")
            self.followLocalAccount(account, currentUserFullAcct: currentUserFullAcct)
        } else {
            // Do the search, then the following
            log.debug("M_FOLLOW", #function + " treated like a remote account")
            let request = Accounts.lookup(acct: account.acct)
            let currentClient = AccountsManager.shared.currentAccountClient
            currentClient.run(request) { (statuses) in
                if let error = statuses.error {
                    log.error("error searching for \(account.acct) : \(error)")
                    self.requestedFollows.remove(at: self.requestedFollows.firstIndex(of: account.fullAcct)!)
                }
                if let account = (statuses.value) {
                    DispatchQueue.main.async {
                        self.followLocalAccount(account, currentUserFullAcct: currentUserFullAcct)
                    }
                }
            }
        }
    }
    
    public func followAccountAsync(_ account: Account) async throws -> Relationship? {
        log.debug("M_FOLLOW", #function + " account: \(account.username)")
        do {
            let currentUser = AccountsManager.shared.currentUser()
            let currentUserFullAcct: String = currentUser?.fullAcct ?? ""
            guard currentUserFullAcct != "" else {
                log.error("Expected AccountsManager.shared.currentUser()?.fullAcct to be valid")
                return nil
            }
            
            self.requestedFollows.append(account.fullAcct)
            DispatchQueue.main.async {
                self.notifyUpdatedStatus(account: account, currentUserFullAcct: currentUserFullAcct, status: .followRequested)
            }
            
            // Optimization: if this account is on the currentUser's server, we can just follow
            // that ID. Otherwise, we need to do the lookup first.
            if currentUser?.server == account.server {
                log.debug("M_FOLLOW", #function + " treated like a local account")
                return try await self.followLocalAccountAsync(account, currentUserFullAcct: currentUserFullAcct)
            } else {
                // Do the search, then the following
                log.debug("M_FOLLOW", #function + " treated like a remote account")
                
                if let account = await AccountService.lookup(account.remoteFullOriginalAcct) {
                    return try await self.followLocalAccountAsync(account, currentUserFullAcct: currentUserFullAcct)
                }
                
            }
        } catch let error {
            log.error("error searching for \(account.acct) : \(error)")
            self.requestedFollows.remove(at: self.requestedFollows.firstIndex(of: account.fullAcct)!)
            return nil
        }
        
        return nil
    }
    
    
    /// Request to follow a given account  from AccountsManager.shared.currentUser()
    ///
    /// - Parameter localAccount: The local account to folllow
    private func followLocalAccount(_ localAccount: Account, currentUserFullAcct: String) {
        log.debug("M_FOLLOW", #function + " localAccount: \(localAccount.username)")

        // Make the network request
        let request = Accounts.follow(id: localAccount.id, reblogs: true)
        let currentClient = AccountsManager.shared.currentAccountClient
        currentClient.run(request) { (statuses) in
            if let indexOfRequestedFollows = self.requestedFollows.firstIndex(of: localAccount.fullAcct) {
                self.requestedFollows.remove(at: indexOfRequestedFollows)
            }
            if let error = statuses.error {
                log.error("Unable to follow \(localAccount.acct) error: \(error)")
            }
            if let relationship = statuses.value {
                DispatchQueue.main.async {
                    self.storeAndNotifyUpdatedStatus(localAccount: localAccount, relationship: relationship, currentUserFullAcct: currentUserFullAcct)
                }
            }
        }
    }
    
    private func followLocalAccountAsync(_ localAccount: Account, currentUserFullAcct: String) async throws -> Relationship? {
        log.debug("M_FOLLOW", #function + " localAccount: \(localAccount.username)")

        do {
            // Make the network request
            let relationship = try await AccountService.follow(userId: localAccount.id)
            
            if let indexOfRequestedFollows = self.requestedFollows.firstIndex(of: localAccount.fullAcct) {
                self.requestedFollows.remove(at: indexOfRequestedFollows)
            }
            
            DispatchQueue.main.async {
                self.storeAndNotifyUpdatedStatus(localAccount: localAccount, relationship: relationship, currentUserFullAcct: currentUserFullAcct)
            }
            
            return relationship
        } catch let error {
            log.error("Unable to follow \(localAccount.acct) error: \(error)")
            throw error
        }
    }
    
    
    /// Request to UNfollow a given account from AccountsManager.shared.currentUser()
    ///
    /// - Parameter account: The account to unfolllow
    public func unfollowAccount(_ account: Account) {
        log.debug("M_FOLLOW", #function + " account: \(account.username)")
        let currentUser = AccountsManager.shared.currentUser()
        let currentUserFullAcct: String = currentUser?.fullAcct ?? ""
        guard currentUserFullAcct != "" else {
            log.error("Expected AccountsManager.shared.currentUser()?.fullAcct to be valid")
            return
        }

        self.requestedUnfollows.append(account.fullAcct)
        self.notifyUpdatedStatus(account: account, currentUserFullAcct: currentUserFullAcct, status: .unfollowRequested)

        // Optimization: if this account is on the currentUser's server, we can just unfollow
        // that ID. Otherwise, we need to do the lookup first.
        if currentUser?.server == account.server {
            log.debug("M_FOLLOW", #function + " treated like a local account")
            self.unfollowLocalAccount(account, currentUserFullAcct: currentUserFullAcct)
        } else {
            // Do the search, then the unfollowing
            log.debug("M_FOLLOW", #function + " treated like a remote account")
            let request = Accounts.lookup(acct: account.acct)
            let currentClient = AccountsManager.shared.currentAccountClient
            currentClient.run(request) { (statuses) in
                if let error = statuses.error {
                    log.error("error searching for \(account.acct) : \(error)")
                    self.requestedUnfollows.remove(at: self.requestedUnfollows.firstIndex(of: account.fullAcct)!)
                }
                if let account = (statuses.value) {
                    DispatchQueue.main.async {
                        self.unfollowLocalAccount(account, currentUserFullAcct: currentUserFullAcct)
                    }
                }
            }
        }
    }
    
    public func unfollowAccountAsync(_ account: Account) async throws -> Relationship? {
        log.debug("M_FOLLOW", #function + " account: \(account.username)")
  
        do {
            let currentUser = AccountsManager.shared.currentUser()
            let currentUserFullAcct: String = currentUser?.fullAcct ?? ""
            guard currentUserFullAcct != "" else {
                log.error("Expected AccountsManager.shared.currentUser()?.fullAcct to be valid")
                return nil
            }

            DispatchQueue.main.async {
                self.requestedUnfollows.append(account.fullAcct)
                self.notifyUpdatedStatus(account: account, currentUserFullAcct: currentUserFullAcct, status: .unfollowRequested)
            }
            
            // Optimization: if this account is on the currentUser's server, we can just unfollow
            // that ID. Otherwise, we need to do the lookup first.
            if currentUser?.server == account.server {
                log.debug("M_FOLLOW", #function + " treated like a local account")
                return try await self.unfollowLocalAccountAsync(account, currentUserFullAcct: currentUserFullAcct)
            } else {
                // Do the search, then the unfollowing
                log.debug("M_FOLLOW", #function + " treated like a remote account")

                if let account = await AccountService.lookup(account.remoteFullOriginalAcct) {
                    return try await self.unfollowLocalAccountAsync(account, currentUserFullAcct: currentUserFullAcct)
                }
            }
        } catch let error {
            log.error("error searching for \(account.acct) : \(error)")
            self.requestedUnfollows.remove(at: self.requestedUnfollows.firstIndex(of: account.fullAcct)!)
        }

        return nil
    }
    
    
    /// Request to UNfollow a given account  from AccountsManager.shared.currentUser()
    ///
    /// - Parameter localAccount: The local account to UNfolllow
    private func unfollowLocalAccount(_ localAccount: Account, currentUserFullAcct: String) {
        log.debug("M_FOLLOW", #function + " localAccount: \(localAccount.username)")

        // Make the network request
        let request = Accounts.unfollow(id: localAccount.id)
        let currentClient = AccountsManager.shared.currentAccountClient
        currentClient.run(request) { (statuses) in
            if let indexOfRequestedUnfollows = self.requestedUnfollows.firstIndex(of: localAccount.fullAcct) {
                self.requestedUnfollows.remove(at: indexOfRequestedUnfollows)
            }
            if let error = statuses.error {
                log.error("Unable to unfollow \(localAccount.acct) - Error: \(error)")
            }
            if let relationship = statuses.value {
                DispatchQueue.main.async {
                    self.storeAndNotifyUpdatedStatus(localAccount: localAccount, relationship: relationship, currentUserFullAcct: currentUserFullAcct)
                }
            }
        }
    }
    
    private func unfollowLocalAccountAsync(_ localAccount: Account, currentUserFullAcct: String) async throws -> Relationship? {
        log.debug("M_FOLLOW", #function + " localAccount: \(localAccount.username)")
        do {
            // Make the network request
            let relationship = try await AccountService.unfollow(userId: localAccount.id)
            DispatchQueue.main.async {
                if let indexOfRequestedUnfollows = self.requestedUnfollows.firstIndex(of: localAccount.fullAcct) {
                    self.requestedUnfollows.remove(at: indexOfRequestedUnfollows)
                }

                self.storeAndNotifyUpdatedStatus(localAccount: localAccount, relationship: relationship, currentUserFullAcct: currentUserFullAcct)
            }
            return relationship
        } catch let error {
            log.error("Unable to unfollow \(localAccount.acct) - Error: \(error)")
        }
        
        return nil
    }
    
    
    func relationshipForAccount(_ account: Account, requestUpdate: Bool) -> Relationship? {
        log.debug("M_FOLLOW", #function + " account: \(account.username)")
        
        let currentUserFullAcct: String = AccountsManager.shared.currentUser()?.fullAcct ?? ""
        guard currentUserFullAcct != "" else {
            log.error("Expected AccountsManager.shared.currentUser()?.fullAcct to be valid")
            return nil
        }
        
        var relationship: Relationship? = nil
        do {
            relationship = try Disk.retrieve("\(currentUserFullAcct)/profiles/\(account.fullAcct)/relationshipPro.json", from: .caches, as: Relationship.self)
        } catch {
            // no record on disk; that's fine
        }
        
        // Kick off an update if requested
        if requestUpdate {
            self.updateRelationshipForAccount(account)
        }
        
        return relationship
    }
    
    
    /// Account has their social graph set to public (default) or to private
    ///  private accounts will still show a number of following/followed so we have to actually fetch part of the list to know
    /// - Parameter account: account to look up
    /// - Returns: If the account's social graph is public or private
    func publicSocialGraphForAccount(_ account: Account) async -> Bool {
        log.debug("M_FOLLOW_SOCIAL_GRAPH", #function + " account: \(account.username)")
        let accountLookup = await AccountService.lookup(account)
        let server = account.server
        let currentClient = Client(baseURL:"https://\(server)")
        // accountLook may fail and return nil
        guard let accountLookupId = accountLookup?.id as? String else {
            log.warning("accountLookup returned nil for account: \(account)")
            return false
        }
        let request = Accounts.following(id: accountLookupId, range: RequestRange.limit(5))
        // continuation is available to bridge async functions
        return await withCheckedContinuation { continuation in
            // Do the account following fetch
            currentClient.run(request) { (statuses) in
                if let error = statuses.error {
                    log.error("Failed to fetch following: \(error)")
                    continuation.resume(returning: false)
                }
                if let stat = (statuses.value) {
                    log.debug("Able to fetch following for account: \(!stat.isEmpty)")
                    continuation.resume(returning: !stat.isEmpty)
                }
            }
        }
    }
        
    /// Request to update the relationship to the given account
    ///
    /// - Parameter account: The account to folllow
    private func updateRelationshipForAccount(_ account: Account) {
        guard AccountsManager.shared.currentUser() != nil else {
            log.error("Expected AccountsManager.shared.currentUser() to be valid")
            return
        }
        guard let currentUserFullAcct = AccountsManager.shared.currentUser()?.fullAcct else {
            log.error("Expected AccountsManager.shared.currentUser() to be valid")
            return
        }
        
        log.debug("M_FOLLOW", #function + " account: \(account.username)")
        
        let isLocalID = (AccountsManager.shared.currentUser()?.server == account.server)
        let currentClient = AccountsManager.shared.currentAccountClient
        if isLocalID {
            self.updateRelationshipForLocalAccount(account, currentUserFullAcct: currentUserFullAcct, currentClient: currentClient)
        } else {
            // Get the account to be local, then do the check
            
            // Do the search, then the following
            let request = Accounts.lookup(acct: account.acct)
            currentClient.run(request) { (statuses) in
                if let error = statuses.error {
                    log.error("error searching for \(account.acct) : \(error)")
                }
                if let account = (statuses.value) {
                    DispatchQueue.main.async {
                        self.updateRelationshipForLocalAccount(account, currentUserFullAcct: currentUserFullAcct, currentClient: currentClient)
                    }
                }
            }
        }
    }
    
    
    /// Request an updated relationship status from the network
    ///
    /// - Parameter localAccount: The local account to folllow
    /// - Parameter currentUserID: The ID of the current user
    /// - Parameter currentClient: The client to use
    private func updateRelationshipForLocalAccount(_ localAccount: Account, currentUserFullAcct: String, currentClient: Client) {
        log.debug("M_FOLLOW", #function + " localAccount: \(localAccount.username)")
        let request = Accounts.relationships(ids: [localAccount.id])
        currentClient.run(request) { (statuses) in
            if let stat = (statuses.value) {
                if stat.count > 0 {
                    DispatchQueue.main.async {
                        let relationship = stat[0]
                        self.storeAndNotifyUpdatedStatus(localAccount: localAccount, relationship: relationship, currentUserFullAcct: currentUserFullAcct)
                    }
                }
            }
        }
    }


    
    /// If the status has changed, store the record and post a notification about the change
    ///
    /// - Parameter localAccount: The local account to folllow
    /// - Parameter relationship: The updated relationship
    /// - Parameter currentUserID: The ID of the current user
    private func storeAndNotifyUpdatedStatus(localAccount: Account, relationship: Relationship, currentUserFullAcct: String) {
        log.debug("M_FOLLOW", #function + " localAccount: \(localAccount.username)")
        let newStatus: FollowStatus
        
        // No longer waiting for a network reqeust here
        if let indexOfRequestedUpdate = self.updatesRequested.firstIndex(of: localAccount.fullAcct) {
            self.updatesRequested.remove(at: indexOfRequestedUpdate)
        }

        // First see if any requests are pending;
        // otherwise, use the status from the result.
        if requestedFollows.contains(localAccount.fullAcct) {
            newStatus = .followRequested
        } else if requestedUnfollows.contains(localAccount.fullAcct) {
            newStatus = .unfollowRequested
        } else if relationship.following {
            newStatus = .following
        } else if !relationship.following && relationship.requested {
            newStatus = .followAwaitingApproval
        } else {
            newStatus = .notFollowing
        }
        
        do {
            try Disk.save(relationship, to: .caches, as: "\(currentUserFullAcct)/profiles/\(localAccount.fullAcct)/relationshipPro.json")
        } catch {
            log.error("Error saving relationship to Disk")
        }
        self.notifyUpdatedStatus(localAccount: localAccount, currentUserFullAcct: currentUserFullAcct, relationship: relationship, status: newStatus)
    }

    
    private func notifyUpdatedStatus(account: Account? = nil, localAccount: Account? = nil, currentUserFullAcct: String, relationship: Relationship? = nil, status: FollowStatus) {
        var userInfoDict: [String : Any] = [
            "followStatus": status.rawValue,
            "currentUserFullAcct": currentUserFullAcct
        ]
        if relationship != nil {
            userInfoDict["relationship"] = relationship
            if let followedBy = relationship?.followedBy {
                userInfoDict["followedByStatus"] = followedBy ? FollowStatus.following.rawValue : FollowStatus.notFollowing.rawValue
            }
        }

        if account != nil {
            userInfoDict["otherUserFullAcct"] = account!.fullAcct
        } else if localAccount != nil {
            userInfoDict["otherUserFullAcct"] = localAccount!.fullAcct
        }

        let username = ((account != nil) ? account?.username : localAccount?.username) ?? "unknown"
        log.debug("M_FOLLOW", #function + " posting notification for: " + username + ", status:\(status)")
        NotificationCenter.default.post(name: didChangeFollowStatusNotification, object: self, userInfo: userInfoDict)
    }
    
    
    public func clearCache() {
        let currentUserFullAcct: String = AccountsManager.shared.currentUser()?.fullAcct ?? ""
        if !currentUserFullAcct.isEmpty {
            do {
                try Disk.remove("\(currentUserFullAcct)/profiles/", from: .caches)
            } catch {
                log.error("error clearing follow manager cache: \(error)")
            }
        }
        requestedFollows = []
        requestedUnfollows = []
        updatesRequested = []
    }
}



