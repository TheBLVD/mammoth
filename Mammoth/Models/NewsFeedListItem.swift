//
//  NewsFeedListItem.swift
//  Mammoth
//
//  Created by Benoit Nolens on 05/07/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

enum NewsFeedListItem: Hashable {
    case postCard(PostCardModel)
    case activity(ActivityCardModel)
    case empty
    case loadMore
    case serverUpdating
    case serverUpdated
    case serverOverload
    case error

    func uniqueId() -> String {
        switch self {
        case .postCard(let postCard):
            return postCard.uniqueId ?? "postCard"
        case .activity(let activityCard):
            return activityCard.uniqueId
        case .empty:
            return "empty"
        case .loadMore:
            return "loadMore"
        case .serverUpdating:
            return "serverUpdating"
        case .serverUpdated:
            return "serverUpdated"
        case .serverOverload:
            return "serverOverload"
        case .error:
            return "error"
        }
    }
}

extension NewsFeedListItem {
    func extractPostCard() -> PostCardModel? {
        if case .postCard(let postCard) = self { return postCard }
        if case .activity(let activity) = self { return activity.postCard }
        return nil
    }
    
    func extractData() -> Any? {
        if case .postCard(let postCard) = self {
            let data = postCard.data
            if case .mastodon(let status) = data  {
                return status
            }
        }
        if case .activity(let activityCard) = self { return activityCard.notification }
        return nil
    }
    
    func extractUniqueId() -> String? {
        if case .postCard(let postCard) = self { return postCard.uniqueId }
        if case .activity(let activity) = self { return activity.uniqueId }
        return nil
    }
}

extension NewsFeedListItem {
    func deepEqual(with item: NewsFeedListItem) -> Bool {
        if case .postCard(let lhs) = self, case .postCard(let rhs) = item {
            return lhs.uniqueId == rhs.uniqueId &&
            lhs.username == rhs.username &&
            lhs.containsPoll == rhs.containsPoll &&
            lhs.hasLink == rhs.hasLink &&
            lhs.hasMediaAttachment == rhs.hasMediaAttachment &&
            lhs.mediaAttachments.count == rhs.mediaAttachments.count &&
            lhs.hasQuotePost == rhs.hasQuotePost &&
            lhs.isAReply == rhs.isAReply &&
            lhs.postText == rhs.postText &&
            lhs.profileURL == rhs.profileURL &&
            lhs.userTag == rhs.userTag &&
            lhs.user?.followStatus == rhs.user?.followStatus &&
            lhs.likeCount == rhs.likeCount &&
            lhs.replyCount == rhs.replyCount &&
            lhs.repostCount == rhs.repostCount
        }
        if case .activity(let lhs) = self, case .activity(let rhs) = item {
            return lhs.uniqueId == rhs.uniqueId
        }
        return true
    }
}

func toListCardItems(_ cards: [PostCardModel]?) -> [NewsFeedListItem] {
    return cards?.map({.postCard($0)}) ?? []
}

func extractListData(_ items: [NewsFeedListItem]?) -> [Any]? {
    guard let items, items.count > 0 else { return nil }
    return items.compactMap({ $0.extractData()})
}

func toPostCards(_ items: [NewsFeedListItem]?) -> [PostCardModel]? {
    return items?.compactMap({ $0.extractPostCard() })
}

extension Array where Element == NewsFeedListItem {
    func removeMutesAndBlocks() -> [Element] {
        let blockedIds = ModerationManager.shared.blockedUsers.map { $0.remoteFullOriginalAcct }
        let mutedIds = ModerationManager.shared.mutedUsers.map { $0.remoteFullOriginalAcct }
        return self.filter {
            if case .postCard(let postCard) = $0 {
                let isBlocked = blockedIds.contains(where: {
                    postCard.user?.uniqueId as? String == $0})
                
                let isMuted = mutedIds.contains(where: {
                    postCard.user?.uniqueId as? String == $0
                })
                return !isBlocked && !isMuted
            }
            
            else if case .activity(let activity) = $0 {
                let isBlocked = blockedIds.contains(where: {
                    activity.user.uniqueId == $0})
                
                let isMuted = mutedIds.contains(where: {
                    activity.user.uniqueId == $0
                })
                return !isBlocked && !isMuted
            }
            
            return false
        }
    }
    
    func removeFiltered() -> [Element] {
        return self.filter {
            if case .postCard(let postCard) = $0 {
                if case .hide(_) = postCard.filterType {
                    return false
                }
            }
            
            return true
        }
    }
}

extension Array where Element == PostCardModel {
    func removeFiltered() -> [Element] {
        return self.filter {
            if case .hide(_) = $0.filterType {
                return false
            }
            
            return true
        }
    }
}
