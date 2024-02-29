//
//  NewsFeedViewModel+UnreadCount.swift
//  Mammoth
//
//  Created by Benoit Nolens on 30/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

internal struct NewsFeedUnreadState {
    var count: Int {
        return unreadIDs.count
    }
    var unreadIDs = Set<String>()
    var enabled: Bool = true
    var unreadPics: [URL] = []
    var showJumpToNow: Bool = false
}

internal struct NewsFeedUnreadStates {
    var forYou = NewsFeedUnreadState()
    var following = NewsFeedUnreadState()
    var federated = NewsFeedUnreadState()
    var community: [String: NewsFeedUnreadState] = [:]
    var trending: [String: NewsFeedUnreadState] = [:]
    var hashtag: [String: NewsFeedUnreadState] = [:]
    var list: [String: NewsFeedUnreadState] = [:]
    var likes = NewsFeedUnreadState()
    var bookmarks = NewsFeedUnreadState()
    var mentionsIn = NewsFeedUnreadState()
    var mentionsOut = NewsFeedUnreadState()
    var activity: [String: NewsFeedUnreadState] = [:]
    var channel: [String: NewsFeedUnreadState] = [:]
    
    mutating func setEnabled(enabled: Bool, forFeed type: NewsFeedTypes) {
        switch type {
        case .forYou:
            forYou.enabled = enabled
        case .following:
            following.enabled = enabled
        case .federated:
            federated.enabled = enabled
        case .community(let name):
            var model = community[name] ?? NewsFeedUnreadState()
            model.enabled = enabled
            community[name] = model
        case .trending(let name):
            var model = trending[name] ?? NewsFeedUnreadState()
            model.enabled = enabled
            trending[name] = model
        case .hashtag(let data):
            var model = hashtag[data.name] ?? NewsFeedUnreadState()
            model.enabled = enabled
            hashtag[data.name] = model
        case .list(let data):
            var model = list[data.id] ?? NewsFeedUnreadState()
            model.enabled = enabled
            list[data.id] = model
        case .likes:
            likes.enabled = enabled
        case .bookmarks:
            bookmarks.enabled = enabled
        case .mentionsIn:
            mentionsIn.enabled = enabled
        case .mentionsOut:
            mentionsOut.enabled = enabled
        case .activity(let type):
            var model = activity[type?.rawValue ?? "all"] ?? NewsFeedUnreadState()
            model.enabled = enabled
            activity[type?.rawValue ?? "all"] = model
        case .channel(let data):
            var model = channel[data.id] ?? NewsFeedUnreadState()
            model.enabled = enabled
            channel[data.id] = model
        }
    }
    
    mutating func setUnreadPics(urls: [URL], forFeed type: NewsFeedTypes) {
        switch type {
        case .forYou:
            forYou.unreadPics = urls
        case .following:
            following.unreadPics = urls
        case .federated:
            federated.unreadPics = urls
        case .community(let name):
            var model = community[name] ?? NewsFeedUnreadState()
            model.unreadPics = urls
            community[name] = model
        case .trending(let name):
            var model = trending[name] ?? NewsFeedUnreadState()
            model.unreadPics = urls
            trending[name] = model
        case .hashtag(let data):
            var model = hashtag[data.name] ?? NewsFeedUnreadState()
            model.unreadPics = urls
            hashtag[data.name] = model
        case .list(let data):
            var model = list[data.id] ?? NewsFeedUnreadState()
            model.unreadPics = urls
            list[data.id] = model
        case .likes:
            likes.unreadPics = urls
        case .bookmarks:
            bookmarks.unreadPics = urls
        case .mentionsIn:
            mentionsIn.unreadPics = urls
        case .mentionsOut:
            mentionsOut.unreadPics = urls
        case .activity(let type):
            var model = activity[type?.rawValue ?? "all"] ?? NewsFeedUnreadState()
            model.unreadPics = urls
            activity[type?.rawValue ?? "all"] = model
        case .channel(let data):
            var model = channel[data.id] ?? NewsFeedUnreadState()
            model.unreadPics = urls
            channel[data.id] = model
        }
    }
    
    mutating func setShowJumpToNow(enabled: Bool, forFeed type: NewsFeedTypes) {
        switch type {
        case .forYou:
            forYou.showJumpToNow = enabled
        case .following:
            following.showJumpToNow = enabled
        case .federated:
            federated.showJumpToNow = enabled
        case .community(let name):
            var model = community[name] ?? NewsFeedUnreadState()
            model.showJumpToNow = enabled
            community[name] = model
        case .trending(let name):
            var model = trending[name] ?? NewsFeedUnreadState()
            model.showJumpToNow = enabled
            trending[name] = model
        case .hashtag(let data):
            var model = hashtag[data.name] ?? NewsFeedUnreadState()
            model.showJumpToNow = enabled
            hashtag[data.name] = model
        case .list(let data):
            var model = list[data.id] ?? NewsFeedUnreadState()
            model.showJumpToNow = enabled
            list[data.id] = model
        case .likes:
            likes.showJumpToNow = enabled
        case .bookmarks:
            bookmarks.showJumpToNow = enabled
        case .mentionsIn:
            mentionsIn.showJumpToNow = enabled
        case .mentionsOut:
            mentionsOut.showJumpToNow = enabled
        case .activity(let type):
            var model = activity[type?.rawValue ?? "all"] ?? NewsFeedUnreadState()
            model.showJumpToNow = enabled
            activity[type?.rawValue ?? "all"] = model
        case .channel(let data):
            var model = channel[data.id] ?? NewsFeedUnreadState()
            model.showJumpToNow = enabled
            channel[data.id] = model
        }
    }
    
    mutating func addUnreadIds(ids: [String], forFeed type: NewsFeedTypes) {
        switch type {
        case .forYou:
            forYou.unreadIDs.formUnion(ids)
        case .following:
            following.unreadIDs.formUnion(ids)
        case .federated:
            federated.unreadIDs.formUnion(ids)
        case .community(let name):
            var model = community[name] ?? NewsFeedUnreadState()
            model.unreadIDs.formUnion(ids)
            community[name] = model
        case .trending(let name):
            var model = trending[name] ?? NewsFeedUnreadState()
            model.unreadIDs.formUnion(ids)
            trending[name] = model
        case .hashtag(let data):
            var model = hashtag[data.name] ?? NewsFeedUnreadState()
            model.unreadIDs.formUnion(ids)
            hashtag[data.name] = model
        case .list(let data):
            var model = list[data.id] ?? NewsFeedUnreadState()
            model.unreadIDs.formUnion(ids)
            list[data.id] = model
        case .likes:
            likes.unreadIDs.formUnion(ids)
        case .bookmarks:
            bookmarks.unreadIDs.formUnion(ids)
        case .mentionsIn:
            mentionsIn.unreadIDs.formUnion(ids)
        case .mentionsOut:
            mentionsOut.unreadIDs.formUnion(ids)
        case .activity(let type):
            var model = activity[type?.rawValue ?? "all"] ?? NewsFeedUnreadState()
            model.unreadIDs.formUnion(ids)
            activity[type?.rawValue ?? "all"] = model
        case .channel(let data):
            var model = channel[data.id] ?? NewsFeedUnreadState()
            model.unreadIDs.formUnion(ids)
            channel[data.id] = model
        }
    }
    
    mutating func removeUnreadId(id: String, forFeed type: NewsFeedTypes) {
        switch type {
        case .forYou:
            forYou.unreadIDs.remove(id)
        case .following:
            following.unreadIDs.remove(id)
        case .federated:
            federated.unreadIDs.remove(id)
        case .community(let name):
            var model = community[name] ?? NewsFeedUnreadState()
            model.unreadIDs.remove(id)
            community[name] = model
        case .trending(let name):
            var model = trending[name] ?? NewsFeedUnreadState()
            model.unreadIDs.remove(id)
            trending[name] = model
        case .hashtag(let data):
            var model = hashtag[data.name] ?? NewsFeedUnreadState()
            model.unreadIDs.remove(id)
            hashtag[data.name] = model
        case .list(let data):
            var model = list[data.id] ?? NewsFeedUnreadState()
            model.unreadIDs.remove(id)
            list[data.id] = model
        case .likes:
            likes.unreadIDs.remove(id)
        case .bookmarks:
            bookmarks.unreadIDs.remove(id)
        case .mentionsIn:
            mentionsIn.unreadIDs.remove(id)
        case .mentionsOut:
            mentionsOut.unreadIDs.remove(id)
        case .activity(let type):
            var model = activity[type?.rawValue ?? "all"] ?? NewsFeedUnreadState()
            model.unreadIDs.remove(id)
            activity[type?.rawValue ?? "all"] = model
        case .channel(let data):
            var model = channel[data.id] ?? NewsFeedUnreadState()
            model.unreadIDs.remove(id)
            channel[data.id] = model
        }
    }
    
    mutating func clearAllUnreadIds(forFeed type: NewsFeedTypes) {
        switch type {
        case .forYou:
            forYou.unreadIDs.removeAll()
        case .following:
            following.unreadIDs.removeAll()
        case .federated:
            federated.unreadIDs.removeAll()
        case .community(let name):
            var model = community[name] ?? NewsFeedUnreadState()
            model.unreadIDs.removeAll()
            community[name] = model
        case .trending(let name):
            var model = trending[name] ?? NewsFeedUnreadState()
            model.unreadIDs.removeAll()
            trending[name] = model
        case .hashtag(let data):
            var model = hashtag[data.name] ?? NewsFeedUnreadState()
            model.unreadIDs.removeAll()
            hashtag[data.name] = model
        case .list(let data):
            var model = list[data.id] ?? NewsFeedUnreadState()
            model.unreadIDs.removeAll()
            list[data.id] = model
        case .likes:
            likes.unreadIDs.removeAll()
        case .bookmarks:
            bookmarks.unreadIDs.removeAll()
        case .mentionsIn:
            mentionsIn.unreadIDs.removeAll()
        case .mentionsOut:
            mentionsOut.unreadIDs.removeAll()
        case .activity(let type):
            var model = activity[type?.rawValue ?? "all"] ?? NewsFeedUnreadState()
            model.unreadIDs.removeAll()
            activity[type?.rawValue ?? "all"] = model
        case .channel(let data):
            var model = channel[data.id] ?? NewsFeedUnreadState()
            model.unreadIDs.removeAll()
            channel[data.id] = model
        }
    }
    
    func getState(forType type: NewsFeedTypes) -> NewsFeedUnreadState {
        switch type {
        case .forYou:
            return forYou
        case .following:
            return following
        case .federated:
            return federated
        case .community(let name):
            return community[name] ?? NewsFeedUnreadState()
        case .trending(let name):
            return trending[name] ?? NewsFeedUnreadState()
        case .hashtag(let data):
            return hashtag[data.name] ?? NewsFeedUnreadState()
        case .list(let data):
            return list[data.id] ?? NewsFeedUnreadState()
        case .likes:
            return likes
        case .bookmarks:
            return bookmarks
        case .mentionsIn:
            return mentionsIn
        case .mentionsOut:
            return mentionsOut
        case .activity(let type):
            return activity[type?.rawValue ?? "all"] ?? NewsFeedUnreadState()
        case .channel(let data):
            return channel[data.id] ?? NewsFeedUnreadState()
        }
    }
}

// MARK: - Unread count accessors
extension NewsFeedViewModel {
    func setUnreadEnabled(enabled: Bool, forFeed type: NewsFeedTypes) {
        self.unreadCounts.setEnabled(enabled: enabled, forFeed: type)
    }
    
    func setUnreadPics(urls: [URL], forFeed type: NewsFeedTypes) {
        self.unreadCounts.setUnreadPics(urls: urls, forFeed: type)
    }
    
    func addUnreadIds(ids: [String], forFeed type: NewsFeedTypes) {
        self.unreadCounts.addUnreadIds(ids: ids, forFeed: type)
    }
    
    func removeUnreadId(id: String, forFeed type: NewsFeedTypes) {
        self.unreadCounts.removeUnreadId(id: id, forFeed: type)
    }
    
    func clearAllUnreadIds(forFeed type: NewsFeedTypes) {
        self.unreadCounts.clearAllUnreadIds(forFeed: type)
    }
    
    func getUnreadCount(forFeed type: NewsFeedTypes) -> Int {
        return self.unreadCounts.getState(forType: type).unreadIDs.count
    }
    
    func getUnreadEnabled(forFeed type: NewsFeedTypes) -> Bool {
        return self.unreadCounts.getState(forType: type).enabled
    }
    
    func getUnreadPics(forFeed type: NewsFeedTypes) -> [URL] {
        return self.unreadCounts.getState(forType: type).unreadPics
    }
    
    func getUnreadState(forFeed type: NewsFeedTypes) -> NewsFeedUnreadState {
        return self.unreadCounts.getState(forType: type)
    }
    
    func setShowJumpToNow(enabled: Bool, forFeed type: NewsFeedTypes) {
        self.unreadCounts.setShowJumpToNow(enabled: enabled, forFeed: type)
    }
    
    func getShowJumpToNow(forFeed type: NewsFeedTypes) -> Bool {
        return self.unreadCounts.getState(forType: type).showJumpToNow
    }
}
