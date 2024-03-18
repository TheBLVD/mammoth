//
//  NewsFeedViewModel+DataSource.swift
//  Mammoth
//
//  Created by Benoit Nolens on 30/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

internal enum NewsFeedSections {
    case main
    case loader
    case empty
}

internal struct NewsFeedListData {
    var forYou: [NewsFeedListItem]?
    var following: [NewsFeedListItem]?
    var federated: [NewsFeedListItem]?
    var community: [String: [NewsFeedListItem]] = [:]
    var trending: [String: [NewsFeedListItem]] = [:]
    var hashtag: [String: [NewsFeedListItem]] = [:]
    var list: [String: [NewsFeedListItem]] = [:]
    var likes: [NewsFeedListItem]?
    var bookmarks: [NewsFeedListItem]?
    var mentionsIn: [NewsFeedListItem]?
    var mentionsOut: [NewsFeedListItem]?
    var activity: [String: [NewsFeedListItem]] = [:]
    var channel: [String: [NewsFeedListItem]] = [:]

    let empty = NewsFeedListItem.empty
    let loadMore = NewsFeedListItem.loadMore
    let serverUpdating = NewsFeedListItem.serverUpdating
    let serverUpdated = NewsFeedListItem.serverUpdated
    let error = NewsFeedListItem.error
    
    func forType(type: NewsFeedTypes) -> [NewsFeedListItem]? {
        switch type {
        case .forYou:
            return self.forYou
        case .following:
            return self.following
        case .federated:
            return self.federated
        case .community(let name):
            return self.community[name]
        case .trending(let name):
            return self.trending[name]
        case .hashtag(let tag):
            return self.hashtag[tag.name]
        case .list(let list):
            return self.list[list.id]
        case .likes:
            return self.likes
        case .bookmarks:
            return self.bookmarks
        case .mentionsIn:
            return self.mentionsIn
        case .mentionsOut:
            return self.mentionsOut
        case .activity(let type):
            return self.activity[type?.rawValue ?? "all"]
        case .channel(let channel):
            return self.channel[channel.id]
        }
    }
    
    mutating func set(items: [NewsFeedListItem], forType type: NewsFeedTypes) {
        switch type {
        case .forYou:
            self.forYou = items
        case .following:
            self.following = items
        case .federated:
            self.federated = items
        case .community(let name):
            self.community[name] = items
        case .trending(let name):
            self.trending[name] = items
        case .hashtag(let tag):
            self.hashtag[tag.name] = items
        case .list(let list):
            self.list[list.id] = items
        case .likes:
            self.likes = items
        case .bookmarks:
            self.bookmarks = items
        case .mentionsIn:
            self.mentionsIn = items
        case .mentionsOut:
            self.mentionsOut = items
        case .activity(let type):
            self.activity[type?.rawValue ?? "all"] = items
        case .channel(let channel):
            self.channel[channel.id] = items
        }
    }
    
    mutating func clear(forType type: NewsFeedTypes) {
        switch type {
        case .forYou:
            self.forYou = []
        case .following:
            self.following = []
        case .federated:
            self.federated = []
        case .community(let name):
            self.community[name] = []
        case .trending(let name):
            self.trending[name] = []
        case .hashtag(let tag):
            self.hashtag[tag.name] = []
        case .list(let list):
            self.list[list.id] = []
        case .likes:
            self.likes = []
        case .bookmarks:
            self.bookmarks = []
        case .mentionsIn:
            self.mentionsIn = []
        case .mentionsOut:
            self.mentionsOut = []
        case .activity(let type):
            self.activity[type?.rawValue ?? "all"]  = []
        case .channel(let channel):
            self.channel[channel.id] = []
        }
    }

    mutating func insert(items: [NewsFeedListItem], forType type: NewsFeedTypes, after: NewsFeedListItem) {
        switch type {
        case .forYou:
            let index = self.forYou?.firstIndex(where: {$0 == after})
            var copy = self.forYou
            copy?.insert(contentsOf: items, at: index ?? self.forYou?.count ?? 0)
            self.forYou = copy
            
        case .following:
            let index = self.following?.firstIndex(where: {$0 == after})
            var copy = self.following
            copy?.insert(contentsOf: items, at: index ?? self.following?.count ?? 0)
            self.following = copy
            
        case .federated:
            let index = self.federated?.firstIndex(where: {$0 == after})
            var copy = self.federated
            copy?.insert(contentsOf: items, at: index ?? self.federated?.count ?? 0)
            self.federated = copy
            
        case .community(let name):
            let index = self.community[name]?.firstIndex(where: {$0 == after})
            var copy = self.community[name]
            copy?.insert(contentsOf: items, at: index ?? self.community[name]?.count ?? 0)
            self.community[name] = copy
            
        case .trending(let name):
            let index = self.trending[name]?.firstIndex(where: {$0 == after})
            var copy = self.trending[name]
            copy?.insert(contentsOf: items, at: index ?? self.trending[name]?.count ?? 0)
            self.trending[name] = copy
            
        case .hashtag(let tag):
            let index = self.hashtag[tag.name]?.firstIndex(where: {$0 == after})
            var copy = self.hashtag[tag.name]
            copy?.insert(contentsOf: items, at: index ?? self.hashtag[tag.name]?.count ?? 0)
            self.hashtag[tag.name] = copy
            
        case .list(let list):
            let index = self.list[list.id]?.firstIndex(where: {$0 == after})
            var copy = self.list[list.id]
            copy?.insert(contentsOf: items, at: index ?? self.list[list.id]?.count ?? 0)
            self.list[list.id] = copy
        
        case .likes:
            let index = self.likes?.firstIndex(where: {$0 == after})
            var copy = self.likes
            copy?.insert(contentsOf: items, at: index ?? self.likes?.count ?? 0)
            self.likes = copy
            
        case .bookmarks:
            let index = self.bookmarks?.firstIndex(where: {$0 == after})
            var copy = self.bookmarks
            copy?.insert(contentsOf: items, at: index ?? self.bookmarks?.count ?? 0)
            self.bookmarks = copy
            
        case .mentionsIn:
            let index = self.mentionsIn?.firstIndex(where: {$0 == after})
            var copy = self.mentionsIn
            copy?.insert(contentsOf: items, at: index ?? self.mentionsIn?.count ?? 0)
            self.mentionsIn = copy
            
        case .mentionsOut:
            let index = self.mentionsOut?.firstIndex(where: {$0 == after})
            var copy = self.mentionsOut
            copy?.insert(contentsOf: items, at: index ?? self.mentionsOut?.count ?? 0)
            self.mentionsOut = copy
            
        case .activity(let type):
            let key = type?.rawValue ?? "all"
            let index = self.activity[key]?.firstIndex(where: {$0 == after})
            var copy = self.activity[key]
            copy?.insert(contentsOf: items, at: index ?? self.activity[key]?.count ?? 0)
            self.activity[key] = copy

        case .channel(let channel):
            let index = self.channel[channel.id]?.firstIndex(where: {$0 == after})
            var copy = self.channel[channel.id]
            copy?.insert(contentsOf: items, at: index ?? self.channel[channel.id]?.count ?? 0)
            self.channel[channel.id] = copy
        }
    }
    
    mutating func update(item: NewsFeedListItem) {
        NewsFeedTypes.allCases.forEach { feedType in
            switch(feedType) {
            case .forYou:
                if let index = self.forYou?.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                    self.update(item: item, atIndex: index, forType: feedType)
                }
            case .following:
                if let index = self.following?.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                    self.update(item: item, atIndex: index, forType: feedType)
                }
            case .federated:
                if let index = self.federated?.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                    self.update(item: item, atIndex: index, forType: feedType)
                }
            case .community:
                self.community.forEach { (key, community) in
                    if let index = community.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                        self.update(item: item, atIndex: index, forType: .community(key))
                    }
                }
            case .trending:
                self.trending.forEach { (key, trending) in
                    if let index = trending.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                        self.update(item: item, atIndex: index, forType: .trending(key))
                    }
                }
            case .hashtag:
                self.hashtag.forEach { (key, hashtag) in
                    if let index = hashtag.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                        self.update(item: item, atIndex: index, forType: .hashtag(Tag(name: key, url: "")))
                    }
                }
            case .list:
                self.list.forEach { (key, list) in
                    if let index = list.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                        self.update(item: item, atIndex: index, forType: .list(List(id: key, title: "")))
                    }
                }
                
            case .likes:
                if let index = self.likes?.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                    self.update(item: item, atIndex: index, forType: feedType)
                }
                
            case .bookmarks:
                if let index = self.bookmarks?.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                    self.update(item: item, atIndex: index, forType: feedType)
                }
                
            case .mentionsIn:
                if let index = self.mentionsIn?.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                    self.update(item: item, atIndex: index, forType: feedType)
                }
                
            case .mentionsOut:
                if let index = self.mentionsOut?.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                    self.update(item: item, atIndex: index, forType: feedType)
                }
                
            case .activity(_):
                self.activity.forEach { (key, activities) in
                    let activityType: NotificationType? = key == "all" ? nil : NotificationType(rawValue: key)
                    if let index = activities.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                        self.update(item: item, atIndex: index, forType: .activity(activityType))
                    } else if let index = activities.firstIndex(where: {$0.extractPostCard()?.uniqueId == item.uniqueId()}){
                        // update the postcard in the activity
                        if case .activity(let activity) = activities[index] {
                            activity.postCard = item.extractPostCard()
                            self.update(item: .activity(activity), atIndex: index, forType: .activity(activityType))
                        }
                    }
                }

            case .channel:
                self.channel.forEach { (key, channel) in
                    if let index = channel.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                        self.update(item: item, atIndex: index, forType: .channel(Channel(id: key, title: "", owner: ChannelOwner())))
                    }
                }
            }
        }
    }
    
    mutating func update(item: NewsFeedListItem, atIndex index: Int, forType type: NewsFeedTypes) {
        switch type {
        case .forYou:
            self.forYou?[index] = item
        case .following:
            self.following?[index] = item
        case .federated:
            self.federated?[index] = item
        case .community(let name):
            self.community[name]?[index] = item
        case .trending(let name):
            self.trending[name]?[index] = item
        case .hashtag(let tag):
            self.hashtag[tag.name]?[index] = item
        case .list(let list):
            self.list[list.id]?[index] = item
        case .likes:
            self.likes?[index] = item
        case .bookmarks:
            self.bookmarks?[index] = item
        case .mentionsIn:
            self.mentionsIn?[index] = item
        case .mentionsOut:
            self.mentionsOut?[index] = item
        case .activity(let type):
            self.activity[type?.rawValue ?? "all"]?[index] = item
        case .channel(let channel):
            self.channel[channel.id]?[index] = item
        }
    }
    
    @discardableResult
    mutating func remove(atIndex index: Int, forType type: NewsFeedTypes) -> NewsFeedListItem? {
        switch type {
        case .forYou:
            return self.forYou?.remove(at: index)
        case .following:
            return self.following?.remove(at: index)
        case .federated:
            return self.federated?.remove(at: index)
        case .community(let name):
            return self.community[name]?.remove(at: index)
        case .trending(let name):
            return self.trending[name]?.remove(at: index)
        case .hashtag(let tag):
            return self.hashtag[tag.name]?.remove(at: index)
        case .list(let list):
            return self.list[list.id]?.remove(at: index)
        case .likes:
            return self.likes?.remove(at: index)
        case .bookmarks:
            return self.bookmarks?.remove(at: index)
        case .mentionsIn:
            return self.mentionsIn?.remove(at: index)
        case .mentionsOut:
            return self.mentionsOut?.remove(at: index)
        case .activity(let type):
            return self.activity[type?.rawValue ?? "all"]?.remove(at: index)
        case .channel(let channel):
            return self.channel[channel.id]?.remove(at: index)
        }
    }
    
    mutating func remove(item: NewsFeedListItem) {
        NewsFeedTypes.allCases.forEach { feedType in
            switch(feedType) {
            case .forYou:
                if let index = self.forYou?.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                    self.remove(atIndex: index, forType: feedType)
                }
            case .following:
                if let index = self.following?.firstIndex(where: {$0.uniqueId() == item.uniqueId()}) {
                    self.remove(atIndex: index, forType: feedType)
                }
            case .federated:
                if let index = self.federated?.firstIndex(where: {$0.uniqueId() == item.uniqueId()}) {
                    self.remove(atIndex: index, forType: feedType)
                }
            case .community:
                self.community.forEach { (key, community) in
                    if let index = community.firstIndex(where: {$0.uniqueId() == item.uniqueId()}) {
                        self.remove(atIndex: index, forType: .community(key))
                    }
                }
            case .trending:
                self.trending.forEach { (key, trending) in
                    if let index = trending.firstIndex(where: {$0.uniqueId() == item.uniqueId()}) {
                        self.remove(atIndex: index, forType: .trending(key))
                    }
                }
            case .hashtag:
                self.hashtag.forEach { (key, hashtag) in
                    if let index = hashtag.firstIndex(where: {$0.uniqueId() == item.uniqueId()}) {
                        self.remove(atIndex: index, forType: .hashtag(Tag(name: key, url: "")))
                    }
                }
            case .list:
                self.list.forEach { (key, list) in
                    if let index = list.firstIndex(where: {$0.uniqueId() == item.uniqueId()}) {
                        self.remove(atIndex: index, forType: .list(List(id: key, title: "")))
                    }
                }
            case .likes:
                if let index = self.likes?.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                    self.remove(atIndex: index, forType: feedType)
                }
            case .bookmarks:
                if let index = self.bookmarks?.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                    self.remove(atIndex: index, forType: feedType)
                }
            case .mentionsIn:
                if let index = self.mentionsIn?.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                    self.remove(atIndex: index, forType: feedType)
                }
                
            case .mentionsOut:
                if let index = self.mentionsOut?.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                    self.remove(atIndex: index, forType: feedType)
                }
                
            case .activity(_):
                self.activity.forEach { (key, activities) in
                    if let index = activities.firstIndex(where: {$0.uniqueId() == item.uniqueId()}){
                        let activityType: NotificationType? = key == "all" ? nil : NotificationType(rawValue: key)
                        self.remove(atIndex: index, forType: .activity(activityType))
                    }
                }
                
            case .channel:
                self.channel.forEach { (key, channel) in
                    if let index = channel.firstIndex(where: {$0.uniqueId() == item.uniqueId()}) {
                        self.remove(atIndex: index, forType: .channel(Channel(id: key, title: "", owner: ChannelOwner())))
                    }
                }
            }
        }
    }
}

// MARK: - Data source accessors & mutators
extension NewsFeedViewModel {
    
    // MARK: - Set
    
    func syncDataSource(type: NewsFeedTypes? = nil, completed: (() -> Void)? = nil) {
        let feedType = type ?? self.type
        let cards = self.listData.forType(type: feedType)?.removingDuplicates().removeMutesAndBlocks().removeFiltered() ?? []
        
        if cards.isEmpty {
            // Retrieve cards and scroll position from disk
            self.clearSnapshot()
            self.state = .loading
            self.delegate?.showLoader(enabled: true)
            self.hydrateCache(forFeedType: feedType) { [weak self] retrievedItems, retrievedPosition in
                guard let self else { return }
                
                self.snapshot.deleteSections([.main])
                self.snapshot = self.appendMainSectionToSnapshot(snapshot: self.snapshot)
                
                // Until we refactor persistence to store nextPageRange / previousPageRange
                // we cannot accurately restore the state of any feedType that makes paginated requests
                guard retrievedItems != nil && !makePaginatedRequest else {
                    self.state = .success
                    completed?()
                    return
                }

                self.snapshot.appendItems(retrievedItems?.removingDuplicates().removeMutesAndBlocks() ?? [], toSection: .main)
                self.snapshot.deleteSections([.empty])
                self.isLoadMoreEnabled = true
                self.state = .success
                self.delegate?.didUpdateSnapshot(self.snapshot,
                                                 feedType: feedType,
                                                 updateType: .hydrate,
                                                 onCompleted: completed)
            }
        } else {
            // Retrieve cards and scroll position from memory
            self.state = .loading
            self.snapshot.deleteSections([.main])
            self.snapshot.appendSections([.main])
            
            self.snapshot.appendItems(cards, toSection: .main)
            if !cards.isEmpty {
                self.snapshot.deleteSections([.main])
            }
            self.isLoadMoreEnabled = true
            self.state = .success

            self.delegate?.didUpdateSnapshot(self.snapshot,
                                             feedType: feedType,
                                             updateType: .hydrate,
                                             onCompleted: completed)
        }
    }
    
    func set(withCards cards: [PostCardModel], forType type: NewsFeedTypes) {
        self.set(withItems: toListCardItems(cards), forType: type)
    }
    
    func set(withItems items: [NewsFeedListItem], forType type: NewsFeedTypes, silently: Bool = false) {
        self.listData.set(items: items.removingDuplicates(), forType: type)

        // Don't update data source if this feed is not currently viewed
        guard type == self.type else { return }
        
        // Save cards to disk
//        let scrollPosition = self.getScrollPosition(forFeed: type)
//        self.saveToDisk(items: self.listData.forType(type: type), position: scrollPosition, feedType: type, mode: .cards)
        
        self.snapshot.deleteSections([.main])
        self.snapshot.appendSections([.main])
        
        self.snapshot.appendItems(items.removingDuplicates(), toSection: .main)
        
        if !silently {
            self.delegate?.didUpdateSnapshot(self.snapshot,
                                             feedType: type,
                                             updateType: .replaceAll,
                                             onCompleted: nil)
        }
    }
    
    // MARK: - Update
    
    func update(with item: NewsFeedListItem, forType type: NewsFeedTypes, silently: Bool = false) {
        self.listData.update(item: item)
        
        // Don't update data source if this feed is not currently viewed
        guard type == self.type else { return }
        guard let _ = self.listData.forType(type: type)?.first(where: { $0.uniqueId() == item.uniqueId() }) else { return }
        
        // Save cards to disk
        let scrollPosition = self.getScrollPosition(forFeed: type)
        self.saveToDisk(items: self.listData.forType(type: type), position: scrollPosition, feedType: type, mode: .cards)

        if self.snapshot.indexOfItem(item) != nil {
            if #available(iOS 15.0, *) {
                self.snapshot.reconfigureItems([item])
            } else {
                self.snapshot.reloadItems([item])
            }
            
            if !silently {
                self.delegate?.didUpdateSnapshot(self.snapshot,
                                                 feedType: type,
                                                 updateType: .update,
                                                 onCompleted: nil)
            }
        } else {
            // This might happen when the view is not in the view hierarchy
            log.debug("updating 1 item but can not find it (replaceAll instead)")
            let allItems = self.listData.forType(type: type)?.removingDuplicates()
            self.set(withItems: allItems ?? [], forType: type, silently: silently)
        }
    }
    
    func updateFollowStatusForPosts(fromAccount fullAcct: String) {
        var didUpdateSnapshot = false
        self.snapshot.itemIdentifiers.forEach({
            if let postCard = $0.extractPostCard(),
                let postCardFullAccount = postCard.user?.account?.fullAcct,
                postCardFullAccount == fullAcct {
                postCard.user?.syncFollowStatus(.none)
                let item = NewsFeedListItem.postCard(postCard)
                
                if self.snapshot.indexOfItem(item) != nil {
                    if #available(iOS 15.0, *) {
                        self.snapshot.reconfigureItems([item])
                    } else {
                        self.snapshot.reloadItems([item])
                    }
                    
                    didUpdateSnapshot = true
                }
            }
        })
        
        if didUpdateSnapshot {
            self.delegate?.didUpdateSnapshot(self.snapshot,
                                             feedType: type,
                                             updateType: .update,
                                             onCompleted: nil)
        }
    }
    
    // MARK: - Insert
    
    func append(items: [NewsFeedListItem], forType type: NewsFeedTypes, after: NewsFeedListItem? = nil) {
        guard let _ = self.snapshot.indexOfSection(.main) else { return }
                    
        let current = self.snapshot.itemIdentifiers(inSection: .main)
        
        if let after {
            self.listData.insert(items: items, forType: type, after: after)
        } else {
            self.listData.set(items: current + items, forType: type)
        }
        
        // Don't update data source if this feed is not currently viewed
        guard type == self.type else { return }

        self.snapshot = self.appendMainSectionToSnapshot(snapshot: self.snapshot)
        
        let uniques = items.filter({ !self.snapshot.itemIdentifiers(inSection: .main).contains($0)})
        if !uniques.isEmpty {
            if let after, self.snapshot.itemIdentifiers.contains(after) {
                self.snapshot.insertItems(uniques, afterItem: after)
                self.delegate?.didUpdateSnapshot(self.snapshot,
                                                    feedType: type,
                                                    updateType: .inject,
                                                    onCompleted: nil)
            } else {
                self.snapshot.appendItems(uniques, toSection: .main)
                self.delegate?.didUpdateSnapshot(self.snapshot,
                                                    feedType: type,
                                                    updateType: .append,
                                                    onCompleted: nil)
            }
        } else {
            // Trying to append 0 items after another element means we need to remove the "load more" button
            if let _ = after {
                self.hideLoadMore(feedType: type)
                self.delegate?.didUpdateSnapshot(self.snapshot,
                                                    feedType: type,
                                                    updateType: .remove,
                                                    onCompleted: nil)
            }
        }
    }
    
    func insert(items: [NewsFeedListItem], forType type: NewsFeedTypes) {
        let current = self.listData.forType(type: type) ?? []
        self.listData.set(items: items + current, forType: type)

        // Don't update data source if this feed is not currently viewed
        guard type == self.type else { return }

        if !self.snapshot.sectionIdentifiers.contains(.main) {
            self.snapshot.appendSections([.main])
        }
        
        if let firstItem = self.snapshot.itemIdentifiers(inSection: .main).first {
            self.snapshot.insertItems(items, beforeItem: firstItem)
        } else {
            self.snapshot.appendItems(items, toSection: .main)
        }

        self.delegate?.didUpdateSnapshot(self.snapshot,
                                            feedType: type,
                                            updateType: .insert) { [weak self] in
            guard let self else { return }
            self.insertUnreadIds(ids: items.map({$0.uniqueId()}), forFeed: type)
            self.delegate?.didUpdateUnreadState(type: type)
        }
    }
    
    func appendMainSectionToSnapshot(snapshot: NewsFeedSnapshot) -> NewsFeedSnapshot {
        var snapshot = snapshot
        if !snapshot.sectionIdentifiers.contains(.main) {
            snapshot.appendSections([.main])
        }
        
        return snapshot
    }
    
    func insertNewest(items: [NewsFeedListItem], includeLoadMore: Bool, forType type: NewsFeedTypes) {
        // don't update data source if this feed is not currently viewed
        guard type == self.type else { return }
        
        // append main section if needed
        self.snapshot = self.appendMainSectionToSnapshot(snapshot: self.snapshot)
        let numberOfItemsPreUpdate = self.snapshot.numberOfItems(inSection: .main)
        
        if let isReadingNewest = self.isReadingNewest(forType: type) {
            if isReadingNewest {
                // if the user is reading the newest posts remove old items at the bottom
                self.removeOldFromSnapshot(forType: type)
            } else {
                // if the user is NOT reading the newest posts remove newest items at the top
                self.removeNewestFromSnapshot(forType: type)
            }
        }
        
        // insert new cards at the top
        if let firstItem = self.snapshot.itemIdentifiers(inSection: .main).first {
            self.snapshot.insertItems(items.removingDuplicates(), beforeItem: firstItem)
        } else {
            self.snapshot.appendItems(items.removingDuplicates(), toSection: .main)
        }
        
        // optionally add a "read more" button
        if includeLoadMore, let lastItem = items.last {
            self.displayLoadMore(after: lastItem, feedType: type)
        }

        // update in-memory cache
        self.listData.set(items: self.snapshot.itemIdentifiers(inSection: .main), forType: type)

        if numberOfItemsPreUpdate == 0 {
            self.setUnreadEnabled(enabled: false, forFeed: type)
            self.hideLoader(forType: type)
        }
        
        if self.snapshot.numberOfItems(inSection: .main) == 0 {
            self.showEmpty(forType: type)
        } else {
            self.delegate?.didUpdateSnapshot(self.snapshot,
                                             feedType: type,
                                             updateType: .insert) {
                
                // Set the unread state after updating the data source.
                // This will show the unread pill/indicator
                if GlobalStruct.feedReadDirection == .topDown {
                    if NewsFeedTypes.allActivityTypes.contains(type) || [.mentionsIn, .mentionsOut].contains(type) {
                        self.insertUnreadIds(ids: items.map({$0.uniqueId()}), forFeed: type)
                        self.setUnreadEnabled(enabled: true, forFeed: type)
                    } else {
                        if items.count >= 5 && numberOfItemsPreUpdate > 0 {
                            self.insertUnreadIds(ids: items.map({$0.uniqueId()}), forFeed: type)
                            self.setUnreadEnabled(enabled: true, forFeed: type)
                        } else {
                            self.insertUnreadIds(ids: items.map({$0.uniqueId()}), forFeed: type)
                            self.setUnreadEnabled(enabled: false, forFeed: type)
                        }
                    }
                } else {
                    self.insertUnreadIds(ids: items.map({$0.uniqueId()}), forFeed: type)
                    self.setUnreadEnabled(enabled: true, forFeed: type)
                    self.delegate?.didUpdateUnreadState(type: type)
                }
            }
        }
    }
    
    // MARK: - Remove
    
    // When scrolled to the top we slice the feed to only keep the items above the "load more" button
    func removeOldItems(forType type: NewsFeedTypes) {
        DispatchQueue.main.async {
            // Don't update data source if this feed is not currently viewed
            guard type == self.type else { return }
            
            let didRemove = self.removeOldFromSnapshot(forType: self.type)
            if didRemove {
                self.delegate?.didUpdateSnapshot(self.snapshot,
                                                 feedType: type,
                                                 updateType: .remove,
                                                 onCompleted: nil)
            }
        }
    }
    
    func removeNewestFromSnapshot(forType type: NewsFeedTypes) {
        guard let _ = self.snapshot.indexOfSection(.main) else { return }
        let current = self.snapshot.itemIdentifiers(inSection: .main)
        if let lastNewItem = self.lastItemOfTheNewestItems(forType: type),
           let index = current.firstIndex(of: lastNewItem) {
            let newest = Array(current[0...index])
            log.debug("deleting \(newest.count) new items to be replaced")
            self.snapshot.deleteItems(newest)
        }
    }
    
    @discardableResult
    func removeOldFromSnapshot(forType type: NewsFeedTypes) -> Bool {
        guard let _ = self.snapshot.indexOfSection(.main) else  { return false }
        let current = self.snapshot.itemIdentifiers(inSection: .main)
        if let lastNewItem = self.lastItemOfTheNewestItems(forType: type),
           let index = current.firstIndex(of: lastNewItem) {
            let old = Array(current[min((index+1), current.count-1)...])
            self.snapshot.deleteItems(old)
            self.snapshot.deleteItems([.loadMore])
            log.debug("deleting \(old.count) old items + the LoadMore btn")
            return true
        }
        
        return false
    }
    
    func remove(card: PostCardModel, forType type: NewsFeedTypes) {
        DispatchQueue.main.async {
            self.listData.remove(item: .loadMore)
            
            // Save cards to disk
            let scrollPosition = self.getScrollPosition(forFeed: type)
            self.saveToDisk(items: self.listData.forType(type: type), position: scrollPosition, feedType: type, mode: .cards)
            
            // Don't update data source if this feed is not currently viewed
            guard type == self.type else { return }
            let item = NewsFeedListItem.postCard(card)
            if self.snapshot.indexOfItem(item) != nil {
                self.snapshot.deleteItems([item])
                self.delegate?.didUpdateSnapshot(self.snapshot,
                                                 feedType: type,
                                                 updateType: .remove,
                                                 onCompleted: nil)
            }
        }
    }
    
    func removePostsFromUsers(userIDs: [String]) {
        DispatchQueue.main.async {
            let itemsToDelete = self.snapshot.itemIdentifiers.filter { item in
                switch item {
                case .postCard(let postCardModel):
                    let isByUser = userIDs.contains(postCardModel.user?.id ?? "")
                    let isRebloggedByUser = userIDs.contains(postCardModel.rebloggerID ?? "")
                    return isByUser || isRebloggedByUser
                    
                default:
                    return false
                }
            }
            
            guard !itemsToDelete.isEmpty else { return }
            
            self.snapshot.deleteItems(itemsToDelete)
            
            self.delegate?.didUpdateSnapshot(
                self.snapshot,
                feedType: self.type,
                updateType: .remove,
                onCompleted: nil)
        }
    }
    
    func refreshSnapshot() {
        log.debug("[NewsFeedViewModel] Refresh snapshot")
        let feedType = self.type
        let cards = self.listData.forType(type: feedType)?
            .removingDuplicates()
            .removeMutesAndBlocks()
            .removeFiltered() ?? []
        
        if !self.snapshot.itemIdentifiers.isEmpty && !self.snapshot.sectionIdentifiers.isEmpty {
            self.snapshot.deleteAllItems()
        }
        self.snapshot = self.appendMainSectionToSnapshot(snapshot: self.snapshot)
        self.snapshot.appendItems(cards, toSection: .main)
        self.isLoadMoreEnabled = true
        self.state = .success

        self.delegate?.didUpdateSnapshot(self.snapshot,
                                         feedType: feedType,
                                         updateType: .replaceAll,
                                         onCompleted: nil)
    }
    
    func clearSnapshot() {
        log.debug("[NewsFeedViewModel] Clear snapshot")
        guard !self.snapshot.sectionIdentifiers.isEmpty else { return }
        self.snapshot.deleteAllItems()
        self.delegate?.didUpdateSnapshot(
            self.snapshot,
            feedType: type,
            updateType: .removeAll,
            onCompleted: nil)
    }
    
    func removeAll(type: NewsFeedTypes, clearScrollPosition: Bool = true) {
        guard type == self.type else { return }
        
        log.debug("[NewsFeedViewModel] Remove All")
        
        self.listData.clear(forType: type)
        self.clearAllUnreadIds(forFeed: type)
        if clearScrollPosition {
            self.setScrollPosition(model: nil, offset: 0, forFeed: type)
        }
        
        guard !self.snapshot.sectionIdentifiers.isEmpty else { return }
        self.snapshot.deleteAllItems()
        
        self.delegate?.didUpdateSnapshot(
            self.snapshot,
            feedType: type,
            updateType: .removeAll,
            onCompleted: nil)
    }
    
    func clearAllHeights(forType type: NewsFeedTypes) {
        if let current = self.listData.forType(type: type) {
            let updated = current.compactMap({
                if case .postCard(let postCard) = $0 {
                    postCard.cellHeight = 0
                    return NewsFeedListItem.postCard(postCard)
                }

                return nil
            })
            self.listData.set(items: updated, forType: type)
        }
    }
    
    // MARK: - Loader
    
    func displayLoader(forType type: NewsFeedTypes) {
        // Don't show loader if this feed is not currently viewed
        guard type == self.type else { return }
        self.delegate?.showLoader(enabled: true)
    }
    
    func hideLoader(forType type: NewsFeedTypes) {
        // Don't hide loader if this feed is not currently viewed
        guard type == self.type else { return }
        self.delegate?.showLoader(enabled: false)
    }
    
    // MARK: - Load more
    
    func displayLoadMore(after item: NewsFeedListItem, feedType: NewsFeedTypes) {
        // Don't update data source if this feed is not currently viewed
        guard feedType == self.type else { return }
        
        if self.snapshot.indexOfItem(.loadMore) == nil {
            self.snapshot.appendItems([.loadMore], toSection: .main)
            self.snapshot.moveItem(.loadMore, afterItem: item)
        } else {
            self.snapshot.moveItem(.loadMore, afterItem: item)
        }
    }
    
    func hideLoadMore(feedType: NewsFeedTypes) {
        // Don't update data source if this feed is not currently viewed
        guard type == self.type else { return }
        guard let _ = self.snapshot.indexOfItem(.loadMore) else { return }
        self.snapshot.deleteItems([.loadMore])
    }
    
    // MARK: - ServerUpdating item

    func displayServerUpdating(feedType: NewsFeedTypes) -> NewsFeedSnapshotUpdateType {
        // Don't update data source if this feed is not currently viewed
        var updateType: NewsFeedSnapshotUpdateType = .update
        guard feedType == self.type else { return updateType }
        // Add if needed
        if self.snapshot.indexOfItem(.serverUpdating) == nil {
            if self.snapshot.indexOfSection(.main) == nil {
                self.snapshot.appendSections([.main])
            }
            self.snapshot.appendItems([.serverUpdating])
            updateType = .replaceAll
        }
        // Move to beginning
        if self.snapshot.numberOfItems > 1 {
            let firstItem = self.snapshot.itemIdentifiers[0]
            if firstItem != .serverUpdating {
                self.snapshot.moveItem(.serverUpdating, beforeItem: firstItem)
            }
        }
        return updateType
    }
    
    func hideServerUpdating(feedType: NewsFeedTypes) {
        // Don't update data source if this feed is not currently viewed
        guard type == self.type else { return }
        guard let _ = self.snapshot.indexOfItem(.serverUpdating) else { return }
        self.snapshot.deleteItems([.serverUpdating])
    }

    
    // MARK: - ServerUpdated item

    func displayServerUpdated(feedType: NewsFeedTypes) -> NewsFeedSnapshotUpdateType {
        // Don't update data source if this feed is not currently viewed
        var updateType: NewsFeedSnapshotUpdateType = .update
        guard feedType == self.type else { return updateType }
        // Add if needed
        if self.snapshot.indexOfItem(.serverUpdated) == nil {
            if self.snapshot.indexOfSection(.main) == nil {
                self.snapshot.appendSections([.main])
            }
            self.snapshot.appendItems([.serverUpdated])
            updateType = .replaceAll
        }
        // Move to beginning
        if self.snapshot.numberOfItems > 1 {
            let firstItem = self.snapshot.itemIdentifiers[0]
            if firstItem != .serverUpdated {
                self.snapshot.moveItem(.serverUpdated, beforeItem: firstItem)
            }
        }
        return updateType
    }
    
    func hideServerUpdated(feedType: NewsFeedTypes) {
        // Don't update data source if this feed is not currently viewed
        guard type == self.type else { return }
        guard let _ = self.snapshot.indexOfItem(.serverUpdated) else { return }
        self.snapshot.deleteItems([.serverUpdated])
    }

    
    // MARK: - ServerOverload item

    func displayServerOverload(feedType: NewsFeedTypes) -> NewsFeedSnapshotUpdateType {
        // Don't update data source if this feed is not currently viewed
        var updateType: NewsFeedSnapshotUpdateType = .update
        guard feedType == self.type else { return updateType }
        // Add if needed
        if self.snapshot.indexOfItem(.serverOverload) == nil {
            if self.snapshot.indexOfSection(.main) == nil {
                self.snapshot.appendSections([.main])
            }
            self.snapshot.appendItems([.serverOverload])
            updateType = .replaceAll
        }
        // Move to beginning
        if self.snapshot.numberOfItems > 1 {
            let firstItem = self.snapshot.itemIdentifiers[0]
            if firstItem != .serverOverload {
                self.snapshot.moveItem(.serverOverload, beforeItem: firstItem)
            }
        }
        return updateType
    }
    
    func hideServerOverload(feedType: NewsFeedTypes) {
        // Don't update data source if this feed is not currently viewed
        guard type == self.type else { return }
        guard let _ = self.snapshot.indexOfItem(.serverOverload) else { return }
        self.snapshot.deleteItems([.serverOverload])
    }


    // MARK: - Error item
    
    func displayError(feedType: NewsFeedTypes) {
        // Don't update data source if this feed is not currently viewed
        guard feedType == self.type else { return }
        if self.snapshot.indexOfSection(.main) == nil {
            self.snapshot = self.appendMainSectionToSnapshot(snapshot: self.snapshot)
        }
        
        if self.snapshot.indexOfItem(.error) == nil {
            self.snapshot.appendItems([.error], toSection: .main)
            
            self.delegate?.didUpdateSnapshot(self.snapshot,
                                             feedType: type,
                                             updateType: .append,
                                             onCompleted: nil)
        }
    }
    
    func hideError(feedType: NewsFeedTypes) {
        // Don't update data source if this feed is not currently viewed
        guard type == self.type else { return }
        
        if self.snapshot.indexOfSection(.main) == nil {
            self.snapshot = self.appendMainSectionToSnapshot(snapshot: self.snapshot)
        }
        
        guard let _ = self.snapshot.indexOfItem(.error) else { return }
        self.snapshot.deleteItems([.error])
        
        self.delegate?.didUpdateSnapshot(self.snapshot,
                                         feedType: type,
                                         updateType: .append,
                                         onCompleted: nil)
    }
    
    // MARK: - Empty
    
    func showEmpty(forType type: NewsFeedTypes) {
        guard type == self.type else { return }
        
        DispatchQueue.main.async {
            guard self.snapshot.indexOfSection(.empty) == nil else { return }
        
            self.snapshot.appendSections([.empty])
            if self.snapshot.indexOfItem(self.listData.empty) == nil {
                self.snapshot.appendItems([self.listData.empty], toSection: .empty)
            }
            self.delegate?.didUpdateSnapshot(self.snapshot,
                                             feedType: type,
                                             updateType: .append,
                                             onCompleted: nil)
        }
    }
    
    func hideEmpty(forType type: NewsFeedTypes) {
        guard type == self.type else { return }
        DispatchQueue.main.async {
            guard let _ = self.snapshot.indexOfSection(.empty) else { return }
            self.snapshot.deleteSections([.empty])
            self.delegate?.didUpdateSnapshot(self.snapshot,
                                             feedType: type,
                                             updateType: .append,
                                             onCompleted: nil)
        }
    }
    
    // MARK: - Index paths
    
    func getIndexPathForItem(item: NewsFeedListItem) -> IndexPath? {
        return self.getIndexPathForItem(snapshot: self.snapshot, item: item)
    }
    
    func getIndexPathForItem(snapshot: NewsFeedSnapshot, item: NewsFeedListItem) -> IndexPath? {
        // For postcards find item based on uniqueId
        if case .postCard(let postCard) = item {
            guard let _ = snapshot.indexOfSection(.main) else { return nil }
            let index = snapshot.itemIdentifiers(inSection: .main).firstIndex(where: {
                if case .postCard(let currentPostCard) = $0, currentPostCard.uniqueId == postCard.uniqueId {
                    return true
                }
                return false
            })
            
            if let index, let sectionIndex = self.snapshot.indexOfSection(.main) {
                return IndexPath(row: index, section: sectionIndex)
            }
            
            return nil
        
        // Find item based on `indexOfItem`
        } else {
            if let index = snapshot.indexOfItem(item),
               let section = snapshot.sectionIdentifier(containingItem: item),
               let sectionIndex = snapshot.indexOfSection(section) {
                return IndexPath(row: index, section: sectionIndex)
            }
        }
        
        return nil
    }
    
    func getItemForIndexPath(_ indexPath: IndexPath) -> NewsFeedListItem? {
        return self.dataSource?.itemIdentifier(for: indexPath)
    }
    
    // MARK: - Helpers
    
    func isItemInSnapshot(_ item: NewsFeedListItem) -> Bool {
        return self.getIndexPathForItem(item: item) != nil
    }
    
    // First item id in the feed
    func newestItemId(forType type: NewsFeedTypes) -> String? {
        guard let _ = self.snapshot.indexOfSection(.main) else { return nil }
        if case .postCard(let postCard) = self.snapshot.itemIdentifiers(inSection: .main).filter({ $0.extractPostCard() != nil }).first {
            return postCard.cursorId
        }
        
        if case .activity(let activity) = self.snapshot.itemIdentifiers(inSection: .main).first {
            return activity.cursorId
        }
        return nil
    }
    
    // Last item id in the feed
    func oldestItemId(forType type: NewsFeedTypes) -> String? {
        guard let _ = self.snapshot.indexOfSection(.main) else { return nil }
        
        if self.cursorId != nil {
            return self.cursorId
        }
        
        if case .postCard(let postCard) = self.snapshot.itemIdentifiers(inSection: .main).last {
            return postCard.cursorId
        }
        
        if case .activity(let activity) = self.snapshot.itemIdentifiers(inSection: .main).last {
            return activity.cursorId
        }
        return nil
    }
    
    // Last item id before the "load more" button
    func lastOfTheNewestItemsId(forType type: NewsFeedTypes) -> String? {
        if let item = self.lastItemOfTheNewestItems(forType: type) {
            if case .postCard(let postCard) = item {
                return postCard.cursorId
            }
            
            if case .activity(let activity) = item {
                return activity.cursorId
            }
        }
        
        return nil
    }
    
    // Last item before the "load more" button
    func lastItemOfTheNewestItems(forType type: NewsFeedTypes) -> NewsFeedListItem? {
        if let loadMoreIndexPath = self.getIndexPathForItem(item: .loadMore) {
            let lastItemIndexPath = IndexPath(row: loadMoreIndexPath.row-1, section: loadMoreIndexPath.section)
            let item = self.getItemForIndexPath(lastItemIndexPath)
            return item
        }
        
        return nil
    }
    
    // First item id after the "load more" button
    func firstOfTheOlderItemsId(forType type: NewsFeedTypes) -> String? {
        if let item = self.firstOfTheOlderItems(forType: type) {
            if case .postCard(let postCard) = item {
                return postCard.cursorId
            }
            
            if case .activity(let activity) = item {
                return activity.cursorId
            }
        }
        
        return nil
    }
    
    // First item after the "load more" button
    func firstOfTheOlderItems(forType type: NewsFeedTypes) -> NewsFeedListItem? {
        // if there's no "load more" return the top item in the feed
        guard let _ = self.snapshot.indexOfItem(.loadMore),
              let _ = self.snapshot.indexOfSection(.main) else {
            return self.snapshot.itemIdentifiers(inSection: .main).first
        }
        
        if let loadMoreIndexPath = self.getIndexPathForItem(item: .loadMore) {
            let firstItemIndexPath = IndexPath(row: loadMoreIndexPath.row+1, section: loadMoreIndexPath.section)
            let item = self.getItemForIndexPath(firstItemIndexPath)
            return item
        }
        
        return nil
    }
    
    // Is the cached scroll position higher than the "load more" button
    func isReadingNewest(forType type: NewsFeedTypes) -> Bool? {
        let scrollPosition = self.getScrollPosition(forFeed: type)
        
        // if there's no "load more" button we don't know
        guard let _ = self.snapshot.indexOfItem(.loadMore) else {
            return nil
        }
        
        if let visibleItem = scrollPosition.model,
            let scrollPositionIndexPath = self.getIndexPathForItem(item: visibleItem),
            let lastNewItem = self.lastItemOfTheNewestItems(forType: type),
            let lastNewItemIndexPath = self.getIndexPathForItem(item: lastNewItem) {
            if lastNewItemIndexPath.row >= scrollPositionIndexPath.row {
                return true
            }
        }
        
        return false
    }
    
    func isLoadMoreButtonInView(forType type: NewsFeedTypes) async -> Bool {
        // if there's no "load more" button we don't know
        guard let _ = self.snapshot.indexOfItem(.loadMore) else {
            return false
        }
        
        if let visibleIndexPaths = await self.delegate?.getVisibleIndexPaths() {
            for indexPath in visibleIndexPaths {
                if let item = self.getItemForIndexPath(indexPath) {
                    if case .loadMore = item {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    func numberOfItems(forSection section: NewsFeedSections) -> Int {
        if self.snapshot.indexOfSection(.main) != nil {
            return self.snapshot.itemIdentifiers(inSection: section).count
        }
        return 0
    }
    
    func isNewestItemOlderThen(targetDate: Date) -> Bool? {
        if self.snapshot.indexOfSection(.main) != nil {
            if let firstItem = self.snapshot.itemIdentifiers(inSection: .main).first {
                switch firstItem {
                case .postCard(let postCard):
                    let postDate = postCard.createdAt
                    return targetDate > postDate
                default:
                    return nil
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Prefetching
    
    func shouldFetchNext(prefetchRowsAt indexPaths: [IndexPath]) -> Bool {
        if !self.isLoadMoreEnabled {
            return false
        }
        
        switch(self.state) {
        case .loading:
            return false // Dont fetch next items if already loading
        case .error(_):
            fallthrough
        case .success:
            let highest = indexPaths.reduce(0) {
                if $0 > $1.row {
                    return $0
                } else {
                    return $1.row
                }
            }
            
            let total = self.numberOfItems(forSection: .main)
            
            if highest > total - 13 {
                return true
            } else {
                return false
            }
            
        default:
            return false
        }
    }
}
