//
//  StatusCache.swift
//  Mammoth
//
//  Created by Riley Howard on 4/21/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class StatusCache {
    
    static let shared = StatusCache()
    static var cachedStatusesLock = NSLock()
    static var cachedStatuses: [URL:Status] = [:]
    static var nilValuesURLsLock = NSLock()
    static var nilValueURLs: [URL] = []
    
    enum MetricType {
        case like
        case repost
        case bookmark
    }
    
    typealias AccountId = String
    typealias StatusId = String

    // Used to serialze the storage
    let storageQueue = DispatchQueue(label: "Store StatusCache", qos: .utility)

    var localLikes: [AccountId: [StatusId: Bool]] = [:] {
        didSet {
            let localLikesToStore = self.localLikes
            self.storageQueue.async {
                UserDefaults.standard.set(localLikesToStore, forKey: "localLikes")
            }
        }
    }
    var localReposts: [AccountId: [StatusId: Bool]] = [:] {
        didSet {
            let localRepostsToStore = self.localReposts
            self.storageQueue.async {
                UserDefaults.standard.set(localRepostsToStore, forKey: "localReposts")
            }
        }
    }
    
    var localBookmarks: [AccountId: [StatusId: Bool]] = [:] {
        didSet {
            let localBookmarksToStore = self.localBookmarks
            self.storageQueue.async {
                UserDefaults.standard.set(localBookmarksToStore, forKey: "localBookmarks")
            }
        }
    }
    
    init() {
        self.localLikes = UserDefaults.standard.value(forKey: "localLikes") as? [AccountId: [StatusId: Bool]] ?? [:]
        self.localReposts = UserDefaults.standard.value(forKey: "localReposts") as? [AccountId: [StatusId: Bool]] ?? [:]
        self.localBookmarks = UserDefaults.standard.value(forKey: "localBookmarks") as? [AccountId: [StatusId: Bool]] ?? [:]
        
        if let userId = AccountsManager.shared.currentUser()?.fullAcct {
            GlobalStruct.allLikes = self.localLikes[userId]?.keys as? [String] ?? []
            GlobalStruct.allReposts = self.localReposts[userId]?.keys as? [String] ?? []
            GlobalStruct.allBookmarks = self.localBookmarks[userId]?.keys as? [String] ?? []
        }
    }
    
    public func clearCache() {
        StatusCache.cachedStatusesLock.lock()
        StatusCache.cachedStatuses.removeAll()
        StatusCache.cachedStatusesLock.unlock()
        
        StatusCache.nilValuesURLsLock.lock()
        StatusCache.nilValueURLs.removeAll()
        StatusCache.nilValuesURLsLock.unlock()
        
        self.localLikes = [:]
        self.localReposts = [:]
        self.localBookmarks = [:]
        
        GlobalStruct.allLikes = []
        GlobalStruct.allReposts = []
        GlobalStruct.allBookmarks = []
    }
    
    public func cachedStatusForURL(url: URL) -> Status? {
        // Return immedidately if we've cached this
        StatusCache.cachedStatusesLock.lock()
        let cachedStatus = StatusCache.cachedStatuses[url]
        StatusCache.cachedStatusesLock.unlock()
        if cachedStatus != nil {
            return cachedStatus
        } else {
            StatusCache.nilValuesURLsLock.lock()
            let isNil = StatusCache.nilValueURLs.contains(url)
            StatusCache.nilValuesURLsLock.unlock()
            if isNil {
                return nil
            }
        }
        
        return nil
    }

    // May return immediately, or send a network request
    public func cacheStatusForURL(url: URL, completion: @escaping (_ url: URL, _ stat: Status?) -> Void) {
        // Return immedidately if we've cached this
        StatusCache.cachedStatusesLock.lock()
        let cachedStatus = StatusCache.cachedStatuses[url]
        StatusCache.cachedStatusesLock.unlock()

        if cachedStatus != nil {
            // log.debug("+++ cache hit for \(url)")
            completion(url, cachedStatus)
            return
        }
        
        StatusCache.nilValuesURLsLock.lock()
        let isNil = StatusCache.nilValueURLs.contains(url)
        StatusCache.nilValuesURLsLock.unlock()
        if isNil {
            // this URL previously returned nil; do it again
            completion(url, nil)
            return
        } else {
            // Make the network request, then the callback
            let request = Search.searchOne(query: url.absoluteString, resolve: true)
            Task {
                do {
                    let result = try await ClientService.runRequest(request: request)
                    if let stat = result.statuses.first {
                        await MainActor.run {
                            StatusCache.cachedStatusesLock.lock()
                            StatusCache.cachedStatuses[url] = stat
                            StatusCache.cachedStatusesLock.unlock()
                        }
                        completion(url, stat)
                    } else {
                        log.error("couldn't find quote post.")
                        completion(url, nil)
                    }
                } catch {
                    log.error("couldn't find quote post.")
                    completion(url, nil)
                }
            }
        }
    }
    
    public func addLocalMetric(metricType: MetricType, statusId: String?) {
        if let userId = AccountsManager.shared.currentUser()?.fullAcct, let statusId = statusId {
            switch(metricType) {
            case .like:
                if self.localLikes[userId] == nil {
                    self.localLikes[userId] = [:]
                }
                
                self.localLikes[userId]?[statusId] = true
                GlobalStruct.allLikes.append(statusId)
                GlobalStruct.idsToUnlike = GlobalStruct.idsToUnlike.filter({ $0 != statusId })
            case .repost:
                if self.localReposts[userId] == nil {
                    self.localReposts[userId] = [:]
                }
                
                self.localReposts[userId]?[statusId] = true
                GlobalStruct.allReposts.append(statusId)
            case .bookmark:
                if self.localBookmarks[userId] == nil {
                    self.localBookmarks[userId] = [:]
                }
                
                self.localBookmarks[userId]?[statusId] = true
                GlobalStruct.allBookmarks.append(statusId)
            }
        }
    }
    
    public func removeLocalMetric(metricType: MetricType, statusId: String?) {
        if let userId = AccountsManager.shared.currentUser()?.fullAcct, let statusId = statusId {
            switch(metricType) {
            case .like:
                self.localLikes[userId]?[statusId] = false
                GlobalStruct.allLikes = GlobalStruct.allLikes.filter({ $0 != statusId })
                GlobalStruct.idsToUnlike.append(statusId)
                UserDefaults.standard.set(GlobalStruct.idsToUnlike, forKey: "idsToUnlike")
                NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadUnlike"), object: nil)
            case .repost:
                self.localReposts[userId]?[statusId] = false
                GlobalStruct.allReposts = GlobalStruct.allReposts.filter({ $0 != statusId })
            case .bookmark:
                self.localBookmarks[userId]?[statusId] = false
                GlobalStruct.allBookmarks = GlobalStruct.allBookmarks.filter({ $0 != statusId })
                GlobalStruct.idsToUnbookmark.append(statusId)
            }
        }
    }
    
    public func removeLocalMetrics(metricType: MetricType, statusIds: [String]) {
        statusIds.forEach { id in
            self.removeLocalMetric(metricType: metricType, statusId: id)
        }
    }
    
    public func hasLocalMetric(metricType: MetricType, forStatusId statusId: String?) -> Bool? {
        guard let statusId = statusId, !statusId.isEmpty else { return false }
        
        if let userId = AccountsManager.shared.currentUser()?.fullAcct {
            switch(metricType) {
            case .like:
                return self.localLikes[userId]?[statusId]
            case .repost:
                return self.localReposts[userId]?[statusId]
            case .bookmark:
                return self.localBookmarks[userId]?[statusId]
            }
        }
        
        return false
    }
}
