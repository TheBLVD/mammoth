//
//  NewsFeedViewModel+Caching.swift
//  Mammoth
//
//  Created by Benoit Nolens on 11/07/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension NewsFeedViewModel {
    
    internal func hydrateCache(forFeedType feedType: NewsFeedTypes,
                               completed: @escaping ([NewsFeedListItem]?, NewsFeedScrollPosition?) -> Void) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let cards = try await self.readItemsFromDisk(feedType)
                let position = try await self.readPositionFromDisk(feedType)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.listData.set(items: cards, forType: feedType)
                    self.setScrollPosition(model: position.model, offset: position.offset, forFeed: feedType)
                    
                    completed(cards, position)
                }
            } catch {
                DispatchQueue.main.async {
                    completed(nil, nil)
                }
            }
        }
    }
    
    private func statusesPath(forFeedType feedType: NewsFeedTypes) -> String? {
        if let user = AccountsManager.shared.currentAccount as? MastodonAcctData {
            switch feedType {
            case .following:
                return "\(user.diskFolderName())/statuses_following.json"
            case .federated:
                return "\(user.diskFolderName())/statuses_federated.json"
            case .community(let instance):
                return "\(user.diskFolderName())/statuses_\(instance.sanitizedFileName).json"
            case .forYou:
                return "\(user.diskFolderName())/statuses_forYou.json"
            case .list(let list):
                return "\(user.diskFolderName())/list_\(list.id.sanitizedFileName).json"
            case .hashtag(let hashtag):
                return "\(user.diskFolderName())/hashtag_\(hashtag.name.sanitizedFileName).json"
            case .trending(let instance):
                return "\(user.diskFolderName())/trending_\(instance.sanitizedFileName).json"
            case .likes:
                return "\(user.diskFolderName())/statuses_likes.json"
            case .bookmarks:
                return "\(user.diskFolderName())/statuses_bookmarks.json"
            case .mentionsIn:
                return "\(user.diskFolderName())/mentions_in.json"
            case .mentionsOut:
                return "\(user.diskFolderName())/mentions_out.json"
            case .activity(let type):
                return "\(user.diskFolderName())/activity_\(type?.rawValue ?? "all").json"
            case .channel(let channel):
                return "\(user.diskFolderName())/channel_\(channel.id.sanitizedFileName).json"
            }
        }
        return nil
    }
    
    private func positionPath(forFeedType feedType: NewsFeedTypes) -> String? {
        if let user = AccountsManager.shared.currentAccount as? MastodonAcctData {
            switch feedType {
            case .following:
                return "\(user.diskFolderName())/position_following.json"
            case .federated:
                return "\(user.diskFolderName())/position_federated.json"
            case .community(let instance):
                return "\(user.diskFolderName())/position_\(instance.sanitizedFileName).json"
            case .forYou:
                return "\(user.diskFolderName())/position_forYou.json"
            case .list(let list):
                return "\(user.diskFolderName())/position_\(list.id.sanitizedFileName).json"
            case .hashtag(let hashtag):
                return "\(user.diskFolderName())/position_\(hashtag.name.sanitizedFileName).json"
            case .trending(let instance):
                return "\(user.diskFolderName())/position_\(instance.sanitizedFileName).json"
            case .likes:
                return "\(user.diskFolderName())/position_likes.json"
            case .bookmarks:
                return "\(user.diskFolderName())/position_bookmarks.json"
            case .mentionsIn:
                return "\(user.diskFolderName())/position_mentions_in.json"
            case .mentionsOut:
                return "\(user.diskFolderName())/position_mentions_out.json"
            case .activity(let type):
                return "\(user.diskFolderName())/position_activity_\(type?.rawValue ?? "all").json"
            case .channel(let channel):
                return "\(user.diskFolderName())/position_\(channel.id.sanitizedFileName).json"
            }
        }
        return nil
    }
    
    enum SaveMode {
        case position
        case cards
        case cardsAndPosition
    }
    
    internal func saveToDisk(items: [NewsFeedListItem]?,
                             position: NewsFeedScrollPosition,
                             feedType: NewsFeedTypes,
                             mode: SaveMode = .cardsAndPosition) {
        
        let statusesPath = self.statusesPath(forFeedType: feedType)
        let positionPath = self.positionPath(forFeedType: feedType)
        // Put this on the queue and return immediately (async),
        // but note that this is a synchronous queue.
        savingQueue.async {
            let scrollPositionCardIndex = items?.firstIndex(where: { $0 == position.model })

            if let scrollPositionCardIndex {
                // Keep the bookmarked card, 4 younger cards, and 10 older cards
                var cardsSubset = items?[max(scrollPositionCardIndex - 2, 0)...min(scrollPositionCardIndex + 10, (items?.count ?? 1) - 1)]

                // If the 'load more' button is inside the subset of cards saved to disk
                // only keep the chunk of the subset before or after the 'load more' button
                // This prevents newer and older posts to be saved together leading to a jump in timestamps
                // FIXME: save the 'load more' button to disk as well
                if let loadMoreIndex = cardsSubset?.firstIndex(where: {
                    if case .loadMore = $0 { return true }
                    return false
                }) {
                    let cardsSubsetArray = Array(cardsSubset ?? [])
                    if loadMoreIndex <= 5 {
                        // keep what's after the 'load more' button
                        if  loadMoreIndex+1 <= cardsSubsetArray.count-1 {
                            cardsSubset = cardsSubsetArray[loadMoreIndex+1...cardsSubsetArray.count-1]
                        }
                    } else {
                        // keep what's before the 'load more' button
                        cardsSubset = cardsSubsetArray[0...min(max(loadMoreIndex-1, 1), cardsSubsetArray.count-1)]
                    }
                }

                self.saveToDisk(items: Array(cardsSubset ?? []), path: statusesPath)
            } else {
                self.saveToDisk(items: items, path: statusesPath)
            }

            switch mode {
            case .position, .cardsAndPosition:
                self.saveToDisk(position: position, path: positionPath)
            default:
                break
            }
        }
    }
    
    internal func saveToDisk(items: [NewsFeedListItem]?, path: String?) {
        if let path, let items {
            do {
                if let data = extractListData(items), let first = data.first {
                    if Swift.type(of: (first as AnyObject)) == Status.self {
                        try Disk.save(data as! [Status], to: .caches, as: path)
                    }
                    
                    if Swift.type(of: (first as AnyObject)) == Notificationt.self {
                        try Disk.save(data as! [Notificationt], to: .caches, as: path)
                    }
                }
            } catch {
                log.error("unable to write posts to \(path) - \(error)")
            }
        }
    }
    
    internal func saveToDisk(position: NewsFeedScrollPosition, path: String?) {
        if let path {
            do {
                try Disk.save(position, to: .caches, as: path)
            } catch {
                log.error("unable to write position to \(path) - \(error)")
            }
        }
    }
        
    internal func readItemsFromDisk(_ feedType: NewsFeedTypes) async throws -> [NewsFeedListItem] {
        return try await withCheckedThrowingContinuation { continuation in
            if let path = self.statusesPath(forFeedType: feedType) {
                do {
                    if case .activity = feedType {
                        let notifications = try Disk.retrieve(path, from: .caches, as: [Notificationt].self)
                        let batchName = "hydrated_batch_\(Int.random(in: 0 ... 10000))"
                        let items = notifications.enumerated().map({ NewsFeedListItem.activity(ActivityCardModel(notification: $1, batchId: batchName, batchItemIndex: $0)) })
                        
                        continuation.resume(returning: items)
                    } else {
                        let statuses = try Disk.retrieve(path, from: .caches, as: [Status].self)
                        let hasStaticMetrics = feedType == .forYou
                        
                        let batchName = "hydrated_batch_\(Int.random(in: 0 ... 10000))"
                        
                        var instanceName: String? = nil
                        var shouldUseOriginalServer = false
                        switch feedType {
                        case .forYou, .list(_), .channel(_), .hashtag(_):
                            shouldUseOriginalServer = true
                        case .community(let name):
                            shouldUseOriginalServer = false
                            instanceName = name
                        case .trending(let name):
                            shouldUseOriginalServer = false
                            instanceName = name
                        default:
                            shouldUseOriginalServer = false
                        }
                        
                        let items = statuses.enumerated().map({ NewsFeedListItem.postCard(PostCardModel(status: $1, withStaticMetrics: hasStaticMetrics, instanceName: shouldUseOriginalServer ? $1.serverName : instanceName, batchId: batchName, batchItemIndex: $0)) })
                        
                        continuation.resume(returning: items)
                    }
                } catch {
                    // unable to read posts from disk
                    continuation.resume(throwing: error)
                }
            } else {
                continuation.resume(throwing: NSError(domain: "Can't find path", code: 0))
            }
        }
    }
    
    internal func readPositionFromDisk(_ feedType: NewsFeedTypes) async throws -> NewsFeedScrollPosition {
        return try await withCheckedThrowingContinuation { continuation in
            if let path = self.positionPath(forFeedType: feedType) {
                do {
                    let position = try Disk.retrieve(path, from: .caches, as: NewsFeedScrollPosition.self)
                    continuation.resume(returning: position)
                } catch {
                    // unable to read position from disk
                    continuation.resume(throwing: error)
                }
            } else {
                continuation.resume(throwing: NSError(domain: "Can't find path", code: 0))
            }
        }
    }
}
