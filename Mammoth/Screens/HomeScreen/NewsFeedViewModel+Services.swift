//
//  NewsFeedViewModel+Services.swift
//  Mammoth
//
//  Created by Benoit Nolens on 28/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import SDWebImage

public enum NewsFeedFetchType {
    case nextPage       // append older posts (bottom)
    case previousPage   // insert newer posts (top)
    case refresh        // refresh list with newest
}

// MARK: - Services
extension NewsFeedViewModel {

    @discardableResult
    func loadListData(type: NewsFeedTypes? = nil, fetchType: NewsFeedFetchType = .refresh) async throws -> [NewsFeedListItem] {
        return try await loadListDataMastodon(type: type, fetchType: fetchType)
    }
        
    @discardableResult
    func loadListDataMastodon(type: NewsFeedTypes? = nil, fetchType: NewsFeedFetchType = .refresh) async throws -> [NewsFeedListItem] {
        let currentType = type ?? self.type
        let requestingUser = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID
        
        if case .error(_) = self.state { return [] }
        
        do  {
            switch fetchType {
            // Fetch older posts
            case .nextPage:
                self.state = .loading
                self.displayLoader(forType: currentType)

                if let lastId = self.oldestItemId(forType: currentType) {
                    let items: [NewsFeedListItem]
                    
                    if (self.makePaginatedRequest) {
                        let (requestItems, pagination, requestCursorId) = try await currentType.fetchAllPaginated(range: self.nextPageRange ?? .default, batchName: "next-page_batch")
                        items = requestItems

                        self.cursorId = requestCursorId
                        updateCurrentRange(newPagination: pagination)
                        if (self.nextPageRange == nil) {
                            // If a 'nextPage' call results in a nil nextpageRange, we've hit the end
                            self.isLoadMoreEnabled = false
                        }
                        
                    } else {
                        let (requestItems, requestCursorId) = try await currentType.fetchAll(range: RequestRange.max(id: lastId, limit: 20), batchName: "next-page_batch")
                        items = requestItems
                        
                        self.cursorId = requestCursorId
                        if self.cursorId == nil {
                            self.isLoadMoreEnabled = false
                        }
                    }
                    
                    // only remove mutes and blocks in remote feeds.
                    let newItems: [NewsFeedListItem]
                    if case .community = type {
                        newItems = items.removeMutesAndBlocks().removeFiltered()
                    } else if case .forYou = currentType {
                        newItems = items.removeMutesAndBlocks().removeFiltered()
                    } else if case .channel = currentType {
                        newItems = items.removeMutesAndBlocks().removeFiltered()
                    } else {
                        newItems = items
                    }
                    
                    return await MainActor.run { [weak self] in
                        guard let self else { return [] }

                        // Abort if user changed in the meantime
                        guard requestingUser == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID else { return [] }
                        
                        if let current = self.listData.forType(type: currentType) {
                            let currentIds = current.compactMap({ $0.extractUniqueId() })
                            let uniqueNewItems = newItems.filter({ !currentIds.contains($0.extractUniqueId() ?? "") }).removingDuplicates()
                            if !uniqueNewItems.isEmpty {
                                self.append(items: uniqueNewItems, forType: currentType)
                                
                                if self.snapshot.indexOfSection(.empty) != nil {
                                    self.hideEmpty(forType: currentType)
                                }
                            }
                            
                            self.state = .success
                            self.hideLoader(forType: currentType)
                            
                            // Clear cached video players of items higher up
                            if self.snapshot.itemIdentifiers.count > 60 {
                                let firstSection = Array(self.snapshot.itemIdentifiers[0...self.snapshot.itemIdentifiers.count-40])
                                firstSection.forEach({
                                    if case .postCard(let postCard) = $0 {
                                        postCard.clearCache()
                                    }
                                })
                            }
                            
                            return uniqueNewItems
                        } else {
                            self.set(withItems: newItems, forType: currentType)
                            self.state = .success
                            self.hideLoader(forType: currentType)
                            
                            return newItems
                        }
                    }
                } else {
                    self.state = .success
                    self.hideLoader(forType: currentType)
                    return []
                }
                
            // Fetch newer posts
            case .previousPage:
                if let firstId = self.newestItemId(forType: currentType) {
                    
                    let items: [NewsFeedListItem]

                    if (self.makePaginatedRequest) {
                        let (requestItems, pagination, requestCursorId) = try await currentType.fetchAllPaginated(range: self.previousPageRange ?? .default, batchName: "previous-page_batch")
                        items = requestItems
                        self.cursorId = requestCursorId
                        updateCurrentRange(newPagination: pagination)
                    } else {
                        let (requestItems, requestCursorId) = try await currentType.fetchAll(range: RequestRange.min(id: firstId, limit: 40), batchName: "previous-page_batch")
                        items = requestItems
                        self.cursorId = requestCursorId
                    }
                    
                    // only remove mutes and blocks in remote feeds.
                    let newItems: [NewsFeedListItem]
                    if case .community = type {
                        newItems = items.removeMutesAndBlocks().removeFiltered()
                    } else if case .forYou = currentType {
                        newItems = items.removeMutesAndBlocks().removeFiltered()
                    } else if case .channel = currentType {
                        newItems = items.removeMutesAndBlocks().removeFiltered()
                    } else {
                        newItems = items
                    }

                    return await MainActor.run { [weak self] in
                        guard let self else { return [] }

                        // Abort if user changed in the meantime
                        guard requestingUser == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID else { return [] }
                        
                        if let current = self.listData.forType(type: currentType) {
                            let currentIds = current.compactMap({ $0.extractUniqueId() })
                            let newUniqueItems = newItems.filter({ !currentIds.contains($0.extractUniqueId() ?? "") }).removingDuplicates()
                            if !newUniqueItems.isEmpty {
                                self.insert(items: newUniqueItems, forType: currentType)
                                
                                if self.snapshot.indexOfSection(.empty) != nil {
                                    self.hideEmpty(forType: currentType)
                                }
                            }
                            
                            return newUniqueItems
                                                        
                        } else {
                            self.set(withItems: newItems, forType: currentType)
                            return newItems
                        }
                    }
                } else {
                    // No content yet
                    return try await self.loadListData(type: type, fetchType: .refresh)
                }
                
            // Refresh list
            case .refresh:
                self.state = .loading
                self.isLoadMoreEnabled = true
                
                let items: [NewsFeedListItem]

                if (self.makePaginatedRequest) {
                    let (requestItems, pagination, requestCursorId) = try await currentType.fetchAllPaginated(batchName: "refresh_batch")
                    items = requestItems
                    self.cursorId = requestCursorId
                    updateCurrentRange(newPagination: pagination)
                } else {
                    let (requestItems, requestCursorId) = try await currentType.fetchAll(batchName: "refresh_batch")
                    items = requestItems
                    self.cursorId = requestCursorId
                }
                
                // This should be true of paginated and unpaginated requests
                if (self.cursorId == nil) {
                    self.isLoadMoreEnabled = false
                    self.showEmpty(forType: currentType)
                } else {
                    self.hideEmpty(forType: currentType)
                }
                
                // only remove mutes and blocks in remote feeds.
                let newItems: [NewsFeedListItem]
                if case .community = type {
                    newItems = items.removeMutesAndBlocks().removeFiltered()
                } else if case .forYou = currentType {
                    newItems = items.removeMutesAndBlocks().removeFiltered()
                } else if case .channel = currentType {
                    newItems = items.removeMutesAndBlocks().removeFiltered()
                } else {
                    newItems = items
                }
                
                await MainActor.run { [weak self] in
                    guard let self else { return }

                    // Abort if user changed in the meantime
                    guard requestingUser == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID else { return }
                    
                    self.set(withItems: newItems, forType: currentType)
                    self.state = .success
                    self.hideLoader(forType: currentType)
                }
                
                return newItems
            }
            
        } catch let error {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.state = .error(error)
                self.displayError(feedType: self.type)
                if case .refresh = fetchType  {
                    self.isLoadMoreEnabled = true
                    self.hideLoader(forType: currentType)
                } else if case .nextPage = fetchType  {
                    self.isLoadMoreEnabled = true
                    self.hideLoader(forType: currentType)
                }
            }
            
            throw error
        }
    }
    
    func loadListDataBluesky(account: BlueskyAcctData, type: NewsFeedTypes? = nil, fetchType: NewsFeedFetchType = .refresh) async throws {
        let currentType = type ?? self.type
        
        do {
            switch fetchType {
            // Fetch older posts
            case .nextPage:
                break
                
            // Fetch newer posts
            case .previousPage:
                break // Not possible in Bluesky
                
            // Refresh list
            case .refresh:
                self.state = .loading
                self.displayLoader(forType: currentType)
                self.isLoadMoreEnabled = true
                
                let response = try await account.api.getTimeline(cursor: nil)
                
                DispatchQueue.main.async { [weak self]  in
                    guard let self else { return }
//                    self.blueskyCursor = response.cursor
                    let postCards = Self.postCardModels(fromBlueskyResponse: response, myUserID: account.userID)
                    
                    if postCards.isEmpty {
                        self.isLoadMoreEnabled = false
                    }
                    self.set(withCards: postCards, forType: currentType)
                    self.state = .success
                    self.hideLoader(forType: currentType)
                }
            }
            
        } catch let error {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.state = .error(error)
                self.displayError(feedType: self.type)
                if case .refresh = fetchType  {
                    self.isLoadMoreEnabled = true
                    self.hideLoader(forType: currentType)
                } else if case .nextPage = fetchType  {
                    self.isLoadMoreEnabled = true
                    self.hideLoader(forType: currentType)
                }
            }
            
            throw error
        }
    }
    
    func startCheckingFYStatus(completion: @escaping(() -> Void)) {
        self.forYouStatus = .pending
        Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            self.hideServerUpdated(feedType: self.type)
            self.hideServerOverload(feedType: self.type)
            let updateType = self.displayServerUpdating(feedType: self.type) // Will move it up if needed
            DispatchQueue.main.sync {
                self.delegate?.didUpdateSnapshot(self.snapshot,
                                                 feedType: self.type,
                                                 updateType: updateType, onCompleted: nil)
                completion()
            }
        }
    }
    
    // Return true if there is a server updating/server updated/server overload case happening
    func loadForYouStatus(feedType: NewsFeedTypes, forceFYCheck: Bool) async throws -> Bool {
        if case .error(_) = self.state { return false }
        if feedType != .forYou { return false }
        if !forceFYCheck && forYouStatus == .idle { return false } // Only bother if unknown or in progress
        
        // Check the ForYou status from the server
        guard let remoteFullOriginalAcct = AccountsManager.shared.currentAccount?.remoteFullOriginalAcct else { return false }
        let updatedFYStatus = try await TimelineService.forYouMe(remoteFullOriginalAcct: remoteFullOriginalAcct).forYou.status
        log.debug("For You idle check result.forYou.status: \(updatedFYStatus)")

        var updateType: NewsFeedSnapshotUpdateType? = nil
        // Check for server overload
        if updatedFYStatus == .overloaded {
            self.hideServerUpdated(feedType: feedType)
            self.hideServerUpdating(feedType: feedType)
            updateType = self.displayServerOverload(feedType: feedType) // Will move it up if needed
        }
        // Check if still Updating...
        else if updatedFYStatus == .pending {
            self.hideServerUpdated(feedType: feedType)
            self.hideServerOverload(feedType: feedType)
            updateType = self.displayServerUpdating(feedType: feedType) // Will move it up if needed
        }
        // Check if it just switched from Updating to Updated
        else if self.forYouStatus == .pending, updatedFYStatus == .idle {
            self.hideServerUpdating(feedType: feedType)
            self.hideServerOverload(feedType: feedType)
            updateType = self.displayServerUpdated(feedType: feedType)
        }
        // Check if it just switched from Overloaded to Updated
        else if self.forYouStatus == .overloaded, updatedFYStatus == .idle {
            self.hideServerUpdating(feedType: feedType)
            self.hideServerOverload(feedType: feedType)
            updateType = self.displayServerUpdated(feedType: feedType)
        }

        if let updateType {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.delegate?.didUpdateSnapshot(self.snapshot,
                                                 feedType: feedType,
                                                 updateType: updateType) {
                }
            }
        }
                
        self.forYouStatus = updatedFYStatus
        let showingUpdateRow = updateType != nil
        log.debug("loadForYouStatus showingUpdateRow:\(showingUpdateRow)")
        return showingUpdateRow
    }

    func loadLatest(feedType: NewsFeedTypes, threshold: Int? = nil) async throws {
        do {
            if case .error(_) = self.state { return }
            
            // Abord if the load-more button is in the viewport.
            // When appending the latest posts we might also clean older posts and remove the load-more button.
            // We don't want this to happen when the load-more button is visible. So we don't load any new posts 
            // in that case, but will try again a few seconds later.
            guard !(await self.isLoadMoreButtonInView(forType: feedType)) else { return }
            
            let requestingUser = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID
            
            let items: [NewsFeedListItem]
            if (self.makePaginatedRequest) {
                let (requestItems, pagination, requestCursorId) = try await feedType.fetchAllPaginated(batchName: "latest_batch")
                items = requestItems
                self.cursorId = requestCursorId
                updateCurrentRange(newPagination: pagination)
            } else {
                let (requestItems, requestCursorId) = try await feedType.fetchAll(range: .limit(60), batchName: "latest_batch")
                items = requestItems
                self.cursorId = requestCursorId
            }

            // only remove mutes and blocks in remote feeds.
            let newItems: [NewsFeedListItem]
            if case .community = type {
                newItems = items.removeMutesAndBlocks().removeFiltered()
            } else if case .forYou = feedType {
                newItems = items.removeMutesAndBlocks().removeFiltered()
            } else if case .channel = feedType {
                newItems = items.removeMutesAndBlocks().removeFiltered()
            } else {
                newItems = items
            }
            
            // Abort if user changed in the meantime
            guard requestingUser == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID else { return }
            guard !Task.isCancelled else { return }
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                                
                if let current = self.listData.forType(type: feedType) {
                    
                    // only keep newer posts - trim away what's already in the feed
                    var newItemsSlice = newItems
                    if self.isReadingNewest(forType: feedType) == nil || self.isReadingNewest(forType: feedType) == true {
                        // if reading newest, take the top item of the feed as the reference
                        let currentFirstUniqueId = current.first?.extractUniqueId()
                        if let currentFirstIndex = newItems.firstIndex(where: {$0.extractUniqueId() == currentFirstUniqueId}) {
                            newItemsSlice = Array(newItems[0...max(currentFirstIndex-1, 0)])
                            // if only one item new item is available and it's the same as the currentFirst
                            if newItems.count == 1 && currentFirstUniqueId == newItems[0].extractUniqueId() {
                                newItemsSlice = []
                            }
                        }
                    } else {
                        // if not yet reading the newest, take the one after the "read more" button as reference
                        if let currentFirstItem = self.firstOfTheOlderItems(forType: feedType),
                           let currentFirstUniqueId = currentFirstItem.extractUniqueId(),
                           let currentFirstIndex = newItems.firstIndex(where: {$0.extractUniqueId() == currentFirstUniqueId}) {
                            newItemsSlice = Array(newItems[0...max(currentFirstIndex-1, 0)])
                        
                            // if only one item new item is available and it's the same as the currentFirst
                            if newItems.count == 1 && currentFirstUniqueId == newItems[0].extractUniqueId() {
                                newItemsSlice = []
                            }
                        }
                    }
                    
                    
                    let currentIds = current.compactMap({ $0.extractUniqueId() })
                    let newUniqueItems = newItemsSlice.filter({
                        !currentIds.contains($0.extractUniqueId() ?? "")
                    }).removingDuplicates()
                    
                    if !newUniqueItems.isEmpty {
                        self.hideEmpty(forType: feedType)
                    }
                    
                    // Abort if user changed in the meantime
                    guard requestingUser == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID else { return }
                    guard !Task.isCancelled else { return }
                    
                    if newUniqueItems.count >= (threshold ?? self.newItemsThreshold) {
                        if feedType != .mentionsIn && feedType != .mentionsOut && NewsFeedTypes.allActivityTypes.contains(feedType) {
                            self.stopPollingListData()
                        }
                        
                        let picUrls = newUniqueItems
                            .compactMap({ $0.extractPostCard()?.account })
                            .removingDuplicates()
                            .sorted { $0.followersCount > $1.followersCount }
                            .compactMap({ URL(string: $0.avatar) })
                        
                        if !picUrls.isEmpty {
                            self.setUnreadPics(urls: Array(picUrls[0...min(3, picUrls.count-1)]), forFeed: feedType)
                            SDWebImagePrefetcher.shared.prefetchURLs(picUrls, context: [.imageTransformer: LatestPill.transformer], progress: nil)
                        }
                        
                        if newUniqueItems.count >= self.newestSectionLength {
                            let items = Array(newUniqueItems[0...self.newestSectionLength-1])
                            self.insertNewest(items: items,
                                              includeLoadMore: true,
                                              forType: feedType)
                        } else if newUniqueItems.count > 15 {
                            // The server might return less posts than requested, even if there are more posts available.
                            // To cover this case we optimistically display the "load more" button if > 15 posts are returned
                            self.insertNewest(items: newUniqueItems, includeLoadMore: true, forType: feedType)
                        } else {
                            self.insertNewest(items: newUniqueItems, includeLoadMore: false, forType: feedType)
                        }
                        
                        // Preload quote posts
                        newUniqueItems.forEach({
                            $0.extractPostCard()?.preloadQuotePost()
                        })
                        
                        // display a tab bar badge when new items are fetched
                        if feedType == .mentionsIn {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "showIndActivity2"), object: nil)
                        } else if feedType == .activity(nil) {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "showIndActivity"), object: nil)
                        }
                    }
                } else {
                    guard requestingUser == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID else { return }
                    guard !Task.isCancelled else { return }
                    
                    if newItems.isEmpty {
                        self.hideLoader(forType: feedType)
                        self.showEmpty(forType: feedType)
                    } else {
                        self.set(withItems: newItems, forType: feedType)
                    }
                }
            }
        } catch {
            guard !Task.isCancelled else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.state = .error(error)
                self.displayError(feedType: self.type)
                log.error("error fetching newest posts: \(error)")
            }
            
            throw error
        }
    }
    
    func loadOlderPosts(feedType: NewsFeedTypes) async throws {
        do {
            let loadMoreLimit = 20
            let requestingUser = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID
            
            if let lastId = self.firstOfTheOlderItemsId(forType: feedType) {
                let (newItems, _) = try await feedType.fetchAll(range: RequestRange.min(id: lastId, limit: loadMoreLimit), batchName: "load-more_batch")
                
                // only remove mutes and blocks in remote feeds.
                var newItemsSlice: [NewsFeedListItem]
                if case .community = type {
                    newItemsSlice = newItems.removeMutesAndBlocks().removeFiltered()
                } else if case .forYou = feedType {
                    newItemsSlice = newItems.removeMutesAndBlocks().removeFiltered()
                } else if case .channel = feedType {
                    newItemsSlice = newItems.removeMutesAndBlocks().removeFiltered()
                } else {
                    newItemsSlice = newItems
                }
                
                // only keep older posts - trim away what's already in the feed
                if let currentFirstItem = self.lastItemOfTheNewestItems(forType: feedType),
                    let currentFirstId = currentFirstItem.extractUniqueId(),
                    let currentFirstIndex = newItems.firstIndex(where: {$0.extractUniqueId() == currentFirstId}) {
                    
                    if currentFirstIndex <= newItems.count-1 {
                        newItemsSlice = Array(newItems[(currentFirstIndex+1)...])
                    }
                    
                    // if only one new item is available and it's the same as the currentFirst
                    if newItems.count == 1 && currentFirstId == newItems[0].extractUniqueId() {
                        newItemsSlice = []
                    }
                }

                let newUniqueItems = newItemsSlice
                
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }

                    // Abort if user changed in the meantime
                    guard requestingUser == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID else { return }
                    
                    if !newUniqueItems.isEmpty {
                        self.hideEmpty(forType: feedType)
                    }
                                        
                    // Abort if user changed in the meantime
                    guard requestingUser == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.uniqueID else { return }
                    
                    self.append(items: newUniqueItems, forType: feedType, after: .loadMore)
                    
                    if newUniqueItems.count == 0 {
                        self.hideLoadMore(feedType: feedType)
                        self.hideLoader(forType: feedType)
                        self.delegate?.didUpdateSnapshot(self.snapshot,
                                                         feedType: feedType,
                                                         updateType: .remove,
                                                         onCompleted: nil)
                    }
                }
            }
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.state = .error(error)
                self.displayError(feedType: self.type)
            }
        }
    }
    
    func preloadCards(atIndexPaths indexPaths: [IndexPath]) {
        indexPaths.forEach({
            if case .postCard(let postCard) = self.dataSource?.itemIdentifier(for: $0) {
                if postCard.quotePostStatus == .loading {
                    postCard.preloadQuotePost()
                }
                
                if postCard.mediaDisplayType == .singleVideo || postCard.mediaDisplayType == .singleGIF {
                    postCard.preloadVideo()
                }
                
                PostCardModel.imageDecodeQueue.async {
                    postCard.preloadImages()
                }
            }
            
            if case .activity(let activity) = self.dataSource?.itemIdentifier(for: $0) {
                if activity.postCard?.quotePostStatus == .loading {
                    activity.postCard?.preloadQuotePost()
                }
                
                if activity.postCard?.mediaDisplayType == .singleVideo || activity.postCard?.mediaDisplayType == .singleGIF {
                    activity.postCard?.preloadVideo()
                }
                
                PostCardModel.imageDecodeQueue.async {
                    activity.postCard?.preloadImages()
                }
            }
        })
    }
    
    func cancelPreloadCards(atIndexPaths indexPaths: [IndexPath]) {
        indexPaths.forEach({
            if case .postCard(let postCard) = self.dataSource?.itemIdentifier(for: $0) {
                postCard.cancelAllPreloadTasks()
            }
        })
    }
    
    func syncFollowStatusIfNeeded(item: NewsFeedListItem) {
        if let postCard = item.extractPostCard(), let account = postCard.account {
            if self.type.postCardCellType().shouldSyncFollowStatus(postCard: postCard) {
                DispatchQueue.main.async {
                    postCard.user!.followStatus = FollowManager.shared.followStatusForAccount(account, requestUpdate: .whenUncertain)
                    if !item.deepEqual(with: .postCard(postCard)) {
                        NotificationCenter.default.post(name: PostActions.didUpdatePostCardNotification, object: nil, userInfo: ["postCard": postCard])
                    }
                }
            }
        }
    }
    
    public var isPollingEnabled: Bool {
        return self.pollingTask != nil && !self.pollingTask!.isCancelled
    }
    
    func startPollingListData(forFeed type: NewsFeedTypes, delay: Double = 0) {
        // In the For You case, we want to force a check of the ForYou status
        // the first time through this loop.
        let forceFYCheck: Bool = type == .forYou
        
        if self.pollingTask == nil || self.pollingTask!.isCancelled {
            self.pollingTask = Task(priority: .medium) { [weak self] in
                guard let self else { return }
                var fetchingNewItems = false

                try await self.recursiveTask(retryCount: 5, frequency: self.pollingFrequency, delay: delay) { [weak self] in
                    guard let self else { return }
                                        
                    guard !fetchingNewItems else {
                        log.warning("Skipping polling task for \(type) because previous task is still fetching")
                        return
                    }
                    
                    guard !NetworkMonitor.shared.isNearRateLimit else {
                        log.warning("Skipping polling task for \(type) due to rate limit")
                        return
                    }
                    // Only load the latest content if we are not showing
                    // the Updating or Updated rows.
                    //
                    // It's OK to load newer content if overloaded though (since it's likely
                    // showing Mammoth picks at that point).
                    let showingUpdateRow = try await self.loadForYouStatus(feedType:type, forceFYCheck: forceFYCheck)
                    if !showingUpdateRow || (showingUpdateRow && self.forYouStatus == .overloaded) {

                        if GlobalStruct.feedReadDirection == .topDown {
                            fetchingNewItems = true
                            log.debug("Calling loadLatest for feedType: \(type)")
                            try await self.loadLatest(feedType: type)
                            fetchingNewItems = false
                        } else {
                            var pageToFetchLimit = 10
                            fetchingNewItems = true
                                                        
                            log.debug("Calling loadListData(previousPage) for feedType: \(type)")
                            let fetchedItems = try await self.loadListData(type: type, fetchType: .previousPage)
                            pageToFetchLimit -= 1
                            
                            if !fetchedItems.isEmpty {
                                
                                // Show the JumpToNow pill if the feed is old
                                if fetchedItems.count >= 40 {
                                    await MainActor.run { [weak self] in
                                        self?.setShowJumpToNow(enabled: true, forFeed: type)
                                    }
                                }
                                
                                while fetchingNewItems && pageToFetchLimit > 0 {
                                    log.debug("Calling loadListData(previousPage) for feedType: \(type)")
                                    let fetchedItems = try await self.loadListData(type: type, fetchType: .previousPage)
                                    if fetchedItems.isEmpty {
                                        break
                                    } else {
                                        pageToFetchLimit -= 1
                                    }
                                }
                            }
                            
                            if pageToFetchLimit == 0 {
                                await MainActor.run { [weak self] in
                                    guard let self else { return }
                                    self.stopPollingListData()
                                    if !self.isJumpToNowButtonDisabled {
                                        self.setShowJumpToNow(enabled: true, forFeed: type)
                                        self.delegate?.didUpdateUnreadState(type: type)
                                    }
                                }
                            } else if pageToFetchLimit >= 9 {
                                await MainActor.run { [weak self] in
                                    self?.setShowJumpToNow(enabled: false, forFeed: type)
                                    self?.delegate?.didUpdateUnreadState(type: type)
                                }
                            }

                            fetchingNewItems = false
                        }
                    }
                }
            }
        }
    }
    
    func stopPollingListData() {
        self.pollingTask?.cancel()
    }
    
    func requestItemSync(forIndexPath indexPath: IndexPath, afterSeconds delay: CGFloat) {
        if let item = self.getItemForIndexPath(indexPath) {
            self.postSyncingTasks[indexPath] = Task(priority: .medium) { [weak self] in
                guard let self else { return }
                try await Task.sleep(seconds: delay)
                guard !NetworkMonitor.shared.isNearRateLimit else {
                    log.warning("Skipping syncing item due to rate limit")
                    return
                }
                
                guard !Task.isCancelled else { return }
                self.syncFollowStatusIfNeeded(item: item)
                try await self.syncItem(item: item)
            }
        }
    }
    
    func cancelItemSync(forIndexPath indexPath: IndexPath) {
        if let task = self.postSyncingTasks[indexPath], !task.isCancelled {
            task.cancel()
            self.postSyncingTasks[indexPath] = nil
        }
    }
    
    func cancelAllItemSyncs() {
        self.postSyncingTasks.forEach({ $1.cancel() })
        self.postSyncingTasks = [:]
    }
    
    func syncItem(item: NewsFeedListItem) async throws {
        guard !Task.isCancelled else { return }
        
        switch item {
        case .postCard(let postCard):
            guard !postCard.isSyncedWithOriginal else { return }
            do {
                if let status = try await StatusService.fetchStatus(id: postCard.originalId, instanceName: postCard.originalInstanceName ?? AccountsManager.shared.currentAccountClient.baseHost) {
                    guard !Task.isCancelled else { return }

                    let newPostCard = postCard.mergeInOriginalData(status: status)
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        self.update(with: .postCard(newPostCard), forType: self.type, silently: false)
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                
                postCard.isSyncedWithOriginal = true
                
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    postCard.isSyncedWithOriginal = true
                    self.update(with: .postCard(postCard), forType: self.type, silently: true)
                }
                
                switch error as? ClientError {
                case .mastodonError(let message):
                    if message == "Record not found" {
                        if let postCard = item.extractPostCard(), 
                            let user = postCard.user,
                            let instanceName = user.instanceName {
                            // Do a webfinger lookup and only delete post if the account is federated
                            let webfinger = await AccountService.webfinger(user: user, serverName: instanceName)
                            // Webfinger returns nil if account is deleted and returns a non-empty string if account is federated.
                            // In both cases, mark the post as deleted.
                            // Webfinger returns an empty string when account is not federated. In that case, don't mark the post as deleted.
                            if webfinger == nil || !webfinger!.isEmpty {
                                let deletedPostCard = postCard
                                deletedPostCard.isDeleted = true
                                await MainActor.run { [weak self] in
                                    guard let self else { return }
                                    self.update(with: .postCard(deletedPostCard), forType: self.type, silently: false)
                                }
                            }
                        }
                    }
                default:
                    break
                }
            }
            
            break
        default:
            break
        }
    }
}

// MARK: - Helpers
private extension NewsFeedViewModel {
    ///
    /// - Parameter retryCount: The amount of times the task should fail until it stops
    /// - Parameter frequency: The time in seconds waited **after** the task succeeded
    /// - Parameter delay: The time in seconds waited **before** the task is executed
    /// - Parameter task: The closure (task) called on each recursion
    func recursiveTask(retryCount: Int, frequency: Double, delay: Double = 0, task: () async throws -> Void) async throws -> Void {
        do {
            if Task.isCancelled { return }
            
            if retryCount <= 0  {
                self.pollingTask?.cancel()
                log.error("NewsFeed: recursive fetching stopped due to too many errors")
                return
            }
            
            try await Task.sleep(seconds: delay)
            if Task.isCancelled { return }
            try await task()
            try await Task.sleep(seconds: frequency)
            try await recursiveTask(retryCount: retryCount, frequency: frequency, task: task)
        } catch let error {
            if case is CancellationError = error {
                return
            }
            
            log.error("Recursive task error in \(#function): \(error)")
            try await Task.sleep(seconds: frequency / 2)
            try await recursiveTask(retryCount: retryCount-1, frequency: frequency, task: task)
        }
    }
    
    static func postCardModels(
        fromBlueskyResponse response: BlueskyAPI.FeedResponse,
        myUserID: String
    ) -> [PostCardModel] {
        let feedPosts = response.feed.compactMap { $0.value }
        
        let viewModels = feedPosts.map { feedPost in
            BlueskyPostViewModel(
                post: feedPost.post,
                myUserID: myUserID)
        }
        
        return viewModels.map {
            PostCardModel(blueskyPostVM: $0)
        }
    }
    
}
