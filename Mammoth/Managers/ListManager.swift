//
//  ListManager.swift
//  Mammoth
//
//  Created by Riley Howard on 5/23/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

public let didChangeListsNotification = Notification.Name("didChangeListsNotification")

class ListManager {
    
    static let shared = ListManager()
    // This matches what is on the server
    // (Top Friends is titled "Top Friends on Mammoth"
    private var lists: [List] = []
    
    
    public init() {
        // Listen to account switch, and update the list of hashtags accordingly
        NotificationCenter.default.addObserver(self, selector: #selector(self.didSwitchAccount), name: didSwitchCurrentAccountNotification, object: nil)
        
        self.initializeList(forceNetworkUpdate: true)
    }
    
    
    // This will either load from storage, or kick off a network
    // request as approprate.
    private func initializeList(forceNetworkUpdate: Bool = false) {
        guard AccountsManager.shared.currentAccount != nil else {
            return
        }

        // Restore from disk
        let currentUserFullAcct: String = AccountsManager.shared.currentUser()?.fullAcct ?? ""
        if !currentUserFullAcct.isEmpty {
            do {
                lists = try Disk.retrieve("\(currentUserFullAcct)/lists.json", from: .caches, as: type(of: lists))
            } catch {
                // none from disk
            }
        }

        // If the list was empty from disk, or a new account, or at launch, make a network request
        if lists.isEmpty || forceNetworkUpdate {
            self.fetchLists()
        }
    }

        
    public func clearCache() {
        let currentUserFullAcct: String = AccountsManager.shared.currentUser()?.fullAcct ?? ""
        if !currentUserFullAcct.isEmpty {
            do {
                try Disk.remove("\(currentUserFullAcct)/lists.json", from: .documents)
            } catch {
                log.error("error clearing lists cache: \(error)")
            }
        }
        initializeList()
    }

    
    @objc func didSwitchAccount() {
        self.setLists(newLists: [])
        self.initializeList()
    }
    
    // For EXTERNAL use only
    public func isTitleEditable(_ list: List) -> Bool {
        return (list.title != "Top Friends")
    }

    public func topFriendsExists() -> Bool {
        return topFriendsID() != nil
    }
    
    public func topFriendsID() -> String? {
        if let topFriendsList = lists.first(where: { list in list.title == "Top Friends on Mammoth" }) {
            return topFriendsList.id
        } else {
            return nil
        }
    }
    
    public func allLists(includeTopFriends: Bool = true) -> [List] {
        if includeTopFriends {
            // Convert TFOM to TF
            return lists.map { list in
                if list.title == "Top Friends on Mammoth" {
                    return List(id: list.id, title: "Top Friends")
                } else {
                    return list
                }
            }
        } else {
            // Filter out TF
            return lists.filter { list in
                list.title != "Top Friends on Mammoth"
            }
        }
    }

    public func addList(_ list: String, completion: @escaping ((_ newList: List?) -> Void)) {
        let request = Lists.create(title: list)
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let error = statuses.error {
                log.error("error trying to create a list: \(list) : \(error)")
            }
            if let stat = statuses.value {
                DispatchQueue.main.async {
                    // request an update
                    completion(stat)
                    self.fetchLists()
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    public func deleteList(_ listID : String, completion: @escaping ((_ success: Bool) -> Void)) {
        let request = Lists.delete(id: listID)
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let error = statuses.error {
                log.error("error trying to delete list: \(listID) : \(error)")
            }
            if statuses.value != nil {
                DispatchQueue.main.async {
                    // request an update
                    completion(true)
                    self.fetchLists()
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    public func addToTopFriends(accountID: String, completion: @escaping ((_ success: Bool) -> Void)) {
        if let topFriendsID = self.topFriendsID() {
            self.addToList(accountID: accountID, listID: topFriendsID, completion: completion)
        } else {
            completion(false)
        }
    }
    
    public func addToList(account: Account, listId: String) async throws {
        try await AccountService.runTaskWithLocalRetry(forAccount: account) { id in
            try await ListService.add(accountID: id, listID: listId)
            self.fetchLists()
        }
    }
    
    @available(*, deprecated)
    public func addToList(accountID: String, listID: String, completion: @escaping ((_ success: Bool) -> Void)) {
        Task {
            do {
                try await ListService.add(accountID: accountID, listID: listID)
                await MainActor.run {
                    // request an update
                    completion(true)
                    self.fetchLists()
                }
            } catch let error {
                switch error as? ClientError {
                case .mastodonError(let message):
                    if message == "Validation failed: Account has already been taken" {
                        await MainActor.run {
                            let alert = UIAlertController(title: "You have already added this account to this list", message: nil, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.ok", comment: ""), style: .default, handler: nil))
                            getTopMostViewController()?.present(alert, animated: true)
                        }
                    } else if message == "Record not found" {
                        await MainActor.run {
                            
                        }
                    } else {
                        fallthrough
                    }
                default:
                    await MainActor.run {
                        let alert = UIAlertController(title: "Unable to add this account to your list", message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.ok", comment: ""), style: .default, handler: nil))
                        getTopMostViewController()?.present(alert, animated: true)
                    }
                }

                completion(false)
            }
        }
    }
    
    @available(*, deprecated)
    public func removeFromAllLists(accountID: String, completion: @escaping ((_ success: Bool) -> Void)) {
        // If at least one succes, count the overall operation as a success
        var overallSuccess = false
        for list in lists {
            self.removeFromList(accountID: accountID, listID: list.id) { success in
                overallSuccess = overallSuccess || success
            }
        }
        DispatchQueue.main.async {
            completion(overallSuccess)
        }
    }
    
    @available(*, deprecated)
    public func removeFromTopFriends(accountID: String, completion: @escaping ((_ success: Bool) -> Void)) {
        if let topFriendsID = self.topFriendsID() {
            self.removeFromList(accountID: accountID, listID: topFriendsID, completion: completion)
        } else {
            completion(false)
        }
    }
    
    public func removeFromList(account: Account, listId: String) async throws {
        try await AccountService.runTaskLocally(forAccount: account) { id in
            try await ListService.remove(accountID: id, listID: listId)
            self.fetchLists()
        }
    }
    
    @available(*, deprecated)
    public func removeFromList(accountID: String, listID: String, completion: @escaping ((_ success: Bool) -> Void)) {
        Task {
            do {
                try await ListService.remove(accountID: accountID, listID: listID)
                await MainActor.run {
                    // request an update
                    completion(true)
                    self.fetchLists()
                }
            } catch {
                switch error as? ClientError {
                case .mastodonError(let message):
                    log.debug("error message: \(message)")
                default:
                    log.error("error removing \(accountID) from list \(listID) - \(error)")
                    break
                }
                
                completion(false)
            }
        }
    }
    
    public func updateListTitle(_ listID: String, title: String, completion: @escaping ((_ success: Bool) -> Void)) {
        let request = Lists.update(id: listID, title: title)
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let error = statuses.error {
                log.error("error renaming list to \(title) - \(error)")
            }
            if statuses.value != nil {
                DispatchQueue.main.async {
                    // request an update
                    completion(true)
                    self.fetchLists()
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    public func updateListExclusivePosts(_ listID: String, exclusive: Bool, completion: @escaping ((_ success: Bool) -> Void)) {
        let request = Lists.update(id: listID, exclusive: exclusive)
        AccountsManager.shared.currentAccountClient.run(request) { [weak self] (statuses) in
            guard let self = self else {return}
            
            if let error = statuses.error {
                log.error("error trying to update list exclusive post setting: \(listID) : \(error)")
            }
            if statuses.value != nil {
                DispatchQueue.main.async {
                    completion(true)
                    self.fetchLists()
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    // Update our list of all followed lists
    public func fetchLists(retryCount: Int = 10) {
        guard retryCount > 0 else { return }
        let request = Lists.all()
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let error = statuses.error {
                log.error("error getting lists; will retry; error: \(error)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.fetchLists(retryCount: retryCount - 1)
                }
            }
            if let stat = statuses.value {
                DispatchQueue.main.async {
                    self.setLists(newLists: stat)
                }
            }
        }
    }
    
    private func setLists(newLists: [List]) {
        self.lists = newLists
        let currentUserFullAcct: String = AccountsManager.shared.currentUser()?.fullAcct ?? ""
        if !currentUserFullAcct.isEmpty {
            do {
                try Disk.save(lists, to: .caches, as: "\(currentUserFullAcct)/lists.json")
            } catch {
                log.error("error saving hashtags to disk: \(error)")
            }
        }
        NotificationCenter.default.post(name: didChangeListsNotification, object: self, userInfo: nil)
    }

}


