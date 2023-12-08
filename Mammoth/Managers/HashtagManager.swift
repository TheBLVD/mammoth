//
//  HashtagManager.swift
//  Mammoth
//
//  Created by Riley Howard on 5/12/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

public let didChangeHashtagsNotification = Notification.Name("didChangeHashtagsNotification")

class HashtagManager {
    
    static let shared = HashtagManager()
    
    enum HashtagStatus: String {
        case notFollowing           // default (not following)
        case followRequested        // asked to follow
        case following              // am following
        case unfollowRequested      // asked to unfollow
    }

    private var hashtags: [Tag] = []
    private var requestedFollow: [String] = []
    private var requestedUnfollow: [String] = []

    
    public init() {
        // Listen to accout switch, and update the list of hashtags accordingly
        NotificationCenter.default.addObserver(self, selector: #selector(self.didSwitchAccount), name: didSwitchCurrentAccountNotification, object: nil)
        
        self.initializeList(forceNetworkUpdate: true)
    }
    
    
    // This will either load from storage, or kick off a network
    // reqeust as approprate.
    private func initializeList(forceNetworkUpdate: Bool = false) {
        // Restore from disk
        let currentUserFullAcct: String = AccountsManager.shared.currentUser()?.fullAcct ?? ""
        if !currentUserFullAcct.isEmpty {
            do {
                hashtags = try Disk.retrieve("\(currentUserFullAcct)/followedHashtags.json", from: .caches, as: type(of: hashtags))
            } catch {
                // none from disk
            }
        }

        // If the list was empty from disk, or a new account, or at launch, make a network request
        if hashtags.isEmpty || forceNetworkUpdate {
            self.fetchFollowingTags()
        }
    }
    
    
    public func clearCache() {
        let currentUserFullAcct: String = AccountsManager.shared.currentUser()?.fullAcct ?? ""
        if !currentUserFullAcct.isEmpty {
            do {
                try Disk.remove("\(currentUserFullAcct)/followedHashtags.json", from: .documents)
            } catch {
                log.error("error clearing hashtags cache: \(error)")
            }
        }
        initializeList()
    }

    
    @objc func didSwitchAccount() {
        self.setHashtags(newHashtags: [])
        self.requestedFollow = []
        self.requestedUnfollow = []
        self.initializeList()
    }

    public func statusForHashtag(_ hashtag: Tag) -> HashtagStatus {
        if requestedFollow.contains(hashtag.name) {
            return .followRequested
        }
        if requestedUnfollow.contains(hashtag.name) {
            return .unfollowRequested
        }
        if hashtags.contains(hashtag) {
            return .following
        }
        return .notFollowing
    }
    
    public func allHashtags() -> [Tag] {
        return hashtags
    }

    
    // hashtag - without the preceeding #
    public func followHashtag(_ hashtag: String, completion: @escaping ((_ success: Bool) -> Void)) {
        requestedFollow.append(hashtag)
        NotificationCenter.default.post(name: didChangeHashtagsNotification, object: self, userInfo: nil)
        let request = TrendingTags.follow(id: "\(hashtag.lowercased())")
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let indexOfRequestedUpdate = self.requestedFollow.firstIndex(of: hashtag) {
                self.requestedFollow.remove(at: indexOfRequestedUpdate)
            }
            if let error = statuses.error {
                log.error("error trying to follow #\(hashtag) : \(error)")
            }
            if let _ = (statuses.value) {
                DispatchQueue.main.async {
                    // request an update
                    completion(true)
                    self.fetchFollowingTags()
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }

    
    // hashtag - without the preceeding #
    public func unfollowHashtag(_ hashtag: String, completion: @escaping ((_ success: Bool) -> Void)) {
        requestedUnfollow.append(hashtag)
        NotificationCenter.default.post(name: didChangeHashtagsNotification, object: self, userInfo: nil)
        let request = TrendingTags.unfollow(id: "\(hashtag.lowercased())")
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let indexOfRequestedUpdate = self.requestedUnfollow.firstIndex(of: hashtag) {
                self.requestedUnfollow.remove(at: indexOfRequestedUpdate)
            }
            if let error = statuses.error {
                log.error("error trying to unfollow #\(hashtag) : \(error)")
            }
            if let _ = (statuses.value) {
                DispatchQueue.main.async {
                    // request an update
                    completion(true)
                    self.fetchFollowingTags()
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }

    
    // Update our list of all followed hashtags
    public func fetchFollowingTags() {
        guard AccountsManager.shared.currentAccount != nil else {
            return
        }
        let request = TrendingTags.followedTags()
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let error = statuses.error {
                log.error("error getting hashtags; will retry; error: \(error)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.fetchFollowingTags()
                }
            }
            if let stat = statuses.value {
                DispatchQueue.main.async {
                    self.setHashtags(newHashtags: stat)
                }
            }
        }
    }
    
    
    private func setHashtags(newHashtags: [Tag]) {
        self.hashtags = newHashtags
        let currentUserFullAcct: String = AccountsManager.shared.currentUser()?.fullAcct ?? ""
        if !currentUserFullAcct.isEmpty {
            do {
                try Disk.save(hashtags, to: .caches, as: "\(currentUserFullAcct)/followedHashtags.json")
            } catch {
                log.error("error saving hashtags to disk: \(error)")
            }
        }
        NotificationCenter.default.post(name: didChangeHashtagsNotification, object: self, userInfo: nil)
    }

}
