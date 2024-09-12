//
//  FeedsManager.swift
//  Mammoth
//
//  Created by Benoit Nolens on 12/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

public let didChangeFeedTypeItemsNotification = Notification.Name("didChangeFeedTypeItemsNotification")

class FeedsManager {
    
    static let shared = FeedsManager()
    
    private var initialized: Bool = false
    private var didSwitchAccountTask: Task<Void, Error>?

    public var feeds: [FeedTypeItem] = [] {
        didSet {
            if self.feeds != oldValue {
                NotificationCenter.default.post(name: didChangeFeedTypeItemsNotification, object: nil)
            }
        }
    }
    
    public init() {
        self.feeds = self.initialFeedItems()
        self.consolidate()
        self.initialized = true
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didSwitchAccount),
                                               name: didSwitchCurrentAccountNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.willSwitchAccount),
                                               name: willSwitchCurrentAccountNotification,
                                               object: nil)
        
        self.addChangeObservers()
    }
    
    deinit {
        self.removeChangeObservers()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func addChangeObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.checkCommunitiesChanges),
                                               name: didChangePinnedInstancesNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.checkHashtagsChanges),
                                               name: didChangeHashtagsNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.checkListsChanges),
                                               name: didChangeListsNotification,
                                               object: nil)
    }
    
    private func removeChangeObservers() {
        NotificationCenter.default.removeObserver(self, name: didChangePinnedInstancesNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: didChangeHashtagsNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: didChangeListsNotification, object: nil)
    }
    
    private func initialFeedItems() -> [FeedTypeItem] {
        do {
            let cachedFeeds = try self.readFeedsFromDisk()
            if !cachedFeeds.isEmpty {
                let filteredFeeds = cachedFeeds.filter { item in
                    if case .channel = item.type {
                        return false
                    }
                    return true
                }
                return filteredFeeds
            }
        } catch {}
        
        let general = [
            FeedTypeItem(type: NewsFeedTypes.following, isDraggable: false),
            FeedTypeItem(type: NewsFeedTypes.forYou, isDraggable: false),
            FeedTypeItem(type: NewsFeedTypes.federated, isEnabled: false),
            FeedTypeItem(type: NewsFeedTypes.community(AccountsManager.shared.currentUser()?.server ?? "Instance"), isEnabled: false)
        ]
        
        let communities = InstanceManager.shared.pinnedInstances.map({ FeedTypeItem(type: NewsFeedTypes.community($0)) })
        let lists = ListManager.shared.allLists().map({ FeedTypeItem(type: NewsFeedTypes.list($0)) })
        let hashtags = HashtagManager.shared.allHashtags().map({ FeedTypeItem(type: NewsFeedTypes.hashtag($0)) })
        
        return general + communities + lists + hashtags
    }
    
    // consolidate cached feed type items with new lists, hashtags and instances
    public func consolidate() {
        self.checkListsChanges()
        self.checkHashtagsChanges()
        self.checkCommunitiesChanges()
    }
    
    public func clearCache() {
        if let path = Self.diskPath {
            do {
                try Disk.remove(path, from: .caches)
            } catch {
                log.error("error clearing feeds cache: \(error)")
            }
        }
        
        self.feeds = self.initialFeedItems()
    }
    
    @objc func willSwitchAccount() {
        self.removeChangeObservers()
        self.initialized = false
        
        if self.didSwitchAccountTask != nil {
            self.didSwitchAccountTask!.cancel()
        }
        
        self.feeds = [
            FeedTypeItem(type: NewsFeedTypes.following, isDraggable: false),
            FeedTypeItem(type: NewsFeedTypes.forYou, isDraggable: false)
        ]
    }
    
    @objc func didSwitchAccount() {
        self.initialized = true
        self.feeds = self.initialFeedItems()
        
        if self.didSwitchAccountTask != nil {
            self.didSwitchAccountTask!.cancel()
        }
        
        self.didSwitchAccountTask = Task {
            try await Task.sleep(seconds: 3)
            await MainActor.run {
                self.consolidate()
                self.addChangeObservers()
            }
        }
    }
    
    @objc func checkCommunitiesChanges() {
        guard self.initialized else { return }
        DispatchQueue.main.async {
            let allInstances = InstanceManager.shared.pinnedInstances.map({ FeedTypeItem(type:NewsFeedTypes.community($0)) }) + [FeedTypeItem(type: NewsFeedTypes.community(AccountsManager.shared.currentUser()?.server ?? "Instance"), isEnabled: false)]
            
            let diff = allInstances.difference(from: self.feeds.filter({
                if case .community = $0.type { return true}
                return false
            }))
            
            if self.applyDiff(diff: diff) {
                self.saveFeedsToDisk(feeds: self.feeds)
            }
        }
    }
    
    @objc func checkHashtagsChanges() {
        guard self.initialized else { return }
            let allHashtags = HashtagManager.shared.allHashtags().map({ FeedTypeItem(type: NewsFeedTypes.hashtag($0)) })
        
        let diff = allHashtags.difference(from: self.feeds.filter({
            if case .hashtag = $0.type { return true}
            return false
        }))
        
        if self.applyDiff(diff: diff) {
            self.saveFeedsToDisk(feeds: self.feeds)
        }
    }
    
    @objc func checkListsChanges() {
        guard self.initialized else { return }
        let allLists = ListManager.shared.allLists().map({ FeedTypeItem(type: NewsFeedTypes.list($0)) })
        
        let diff = allLists.difference(from: self.feeds.filter({
            if case .list = $0.type { return true}
            return false
        }))
        
        self.applyDiff(diff: diff)
        
        // Update list names
        self.feeds = self.feeds.map({ feedTypeItem in
            if let item = allLists.first(where: { listItem in
                listItem == feedTypeItem
            }) {
                // create a new item and copy over the current isEnabled and isDraggable state
                return FeedTypeItem(type: item.type, isDraggable: feedTypeItem.isDraggable, isEnabled: feedTypeItem.isEnabled)
            }
            
            return feedTypeItem
        })
        
        self.saveFeedsToDisk(feeds: self.feeds)
    }
    
    @discardableResult
    private func applyDiff(diff: CollectionDifference<FeedTypeItem>) -> Bool {
        var didApplyDiff = false
        var insertions: [FeedTypeItem] = []
        var deletions: [FeedTypeItem] = []
        for change in diff {
            switch change {
            case .insert(_, let element, _):
                insertions.append(element)
                break
            case .remove(_, let element, _):
                deletions.append(element)
                break
            }
        }
        
        // ignore position diffs (the same element is both deleted and inserted at a different offset)
        let filteredInsertions = insertions.filter({ !deletions.contains($0) })
        deletions = deletions.filter({ !insertions.contains($0) })
        insertions = filteredInsertions
        
        if !insertions.isEmpty {
            self.feeds.append(contentsOf: insertions)
            didApplyDiff = true
        }

        deletions.forEach({
            if let index = self.feeds.firstIndex(of: $0) {
                self.feeds.remove(at: index)
                didApplyDiff = true
            }
        })
        
        return didApplyDiff
    }
    
    public func moveItem(_ item: FeedTypeItem, fromIndex sourceIndex: Int, toIndex destinationIndex: Int) {
        self.feeds.remove(at: sourceIndex)
        self.feeds.insert(item, at: destinationIndex)
        self.saveFeedsToDisk(feeds: self.feeds)
    }
    
    public func enable(_ item: FeedTypeItem) {
        if let index = self.feeds.firstIndex(of: item) {
            self.feeds[index].isEnabled = true
            self.moveItem(self.feeds[index], fromIndex: index, toIndex: self.feeds.count - 1)
        }
    }
    
    public func disable(_ item: FeedTypeItem) {
        if let index = self.feeds.firstIndex(of: item) {
            self.feeds[index].isEnabled = false
            self.moveItem(self.feeds[index], fromIndex: index, toIndex: 0)
        }
    }
}

// MARK: - Disk IO
extension FeedsManager {
    
    static var diskPath: String? {
        if let user = AccountsManager.shared.currentAccount as? MastodonAcctData {
            return "\(user.diskFolderName())/feeds.json"
        }
        
        return nil
    }
    
    internal func saveFeedsToDisk(feeds: [FeedTypeItem]) {
        if let path = Self.diskPath {
            do {
                try Disk.save(feeds, to: .caches, as: path)
            } catch {
                log.error("unable to write feedTypeItems to \(path) - \(error)")
            }
        }
    }
    
    internal func readFeedsFromDisk() throws -> [FeedTypeItem] {
        if let path = Self.diskPath {
            do {
                let feeds = try Disk.retrieve(path, from: .caches, as: [FeedTypeItem].self)
                return feeds
            } catch {
                // unable to read feedTypeItems from disk
                throw error
            }
        }
        
        return []
    }
}

class FeedTypeItem: Codable, Equatable {
    let type: NewsFeedTypes
    let isDraggable: Bool
    var isEnabled: Bool
    
    init(type: NewsFeedTypes, isDraggable: Bool = true, isEnabled: Bool = true) {
        self.type = type
        self.isDraggable = isDraggable
        self.isEnabled = isEnabled
    }
    
    static func == (lhs: FeedTypeItem, rhs: FeedTypeItem) -> Bool {
        return lhs.type == rhs.type
    }
}
