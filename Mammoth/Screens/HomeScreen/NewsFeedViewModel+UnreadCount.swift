//
//  NewsFeedViewModel+UnreadCount.swift
//  Mammoth
//
//  Created by Benoit Nolens on 30/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

internal struct NewsFeedUnreadState {
    var count: Int = 0
    var enabled: Bool = true
    var unreadPics: [URL] = []
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
    var activity = NewsFeedUnreadState()
    var channel: [String: NewsFeedUnreadState] = [:]

    mutating func setCount(count: Int, forFeed type: NewsFeedTypes) {
        switch type {
        case .forYou:
            forYou.count = count
        case .following:
            following.count = count
        case .federated:
            federated.count = count
        case .community(let name):
            var model = community[name] ?? NewsFeedUnreadState()
            model.count = count
            community[name] = model
        case .trending(let name):
            var model = trending[name] ?? NewsFeedUnreadState()
            model.count = count
            trending[name] = model
        case .hashtag(let tag):
            var model = hashtag[tag.name] ?? NewsFeedUnreadState()
            model.count = count
            hashtag[tag.name] = model
        case .list(let data):
            var model = list[data.id] ?? NewsFeedUnreadState()
            model.count = count
            list[data.id] = model
        case .likes:
            likes.count = count
        case .bookmarks:
            bookmarks.count = count
        case .mentionsIn:
            mentionsIn.count = count
        case .mentionsOut:
            mentionsOut.count = count
        case .activity:
            activity.count = count
        case .channel(let data):
            var model = channel[data.id] ?? NewsFeedUnreadState()
            model.count = count
            channel[data.id] = model
        }
    }
    
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
        case .activity:
            activity.enabled = enabled
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
        case .activity:
            activity.unreadPics = urls
        case .channel(let data):
            var model = channel[data.id] ?? NewsFeedUnreadState()
            model.unreadPics = urls
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
        case .activity:
            return activity
        case .channel(let data):
            return channel[data.id] ?? NewsFeedUnreadState()
        }
    }
}

// MARK: - Unread count accessors
extension NewsFeedViewModel {
    func setUnreadState(count: Int, enabled: Bool, forFeed type: NewsFeedTypes) {
        self.unreadCounts.setCount(count: count, forFeed: type)
        self.unreadCounts.setEnabled(enabled: enabled, forFeed: type)
    }
    
    func setUnreadCount(count: Int, forFeed type: NewsFeedTypes) {
        self.unreadCounts.setCount(count: count, forFeed: type)
    }
    
    func setUnreadEnabled(enabled: Bool, forFeed type: NewsFeedTypes) {
        self.unreadCounts.setEnabled(enabled: enabled, forFeed: type)
    }
    
    func setUnreadPics(urls: [URL], forFeed type: NewsFeedTypes) {
        self.unreadCounts.setUnreadPics(urls: urls, forFeed: type)
    }
    
    func getUnreadCount(forFeed type: NewsFeedTypes) -> Int {
        return self.unreadCounts.getState(forType: type).count
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
}
