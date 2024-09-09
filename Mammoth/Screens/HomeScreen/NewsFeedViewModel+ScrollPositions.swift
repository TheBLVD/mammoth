//
//  NewFeedViewModel+ScrollPosition.swift
//  Mammoth
//
//  Created by Benoit Nolens on 29/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

struct NewsFeedScrollPosition {
    var model: NewsFeedListItem? = nil
    var offset: Double = 0

    init() {}
    init(model: NewsFeedListItem?, offset: Double) {
        self.model = model
        self.offset = offset
    }
}

// Positions are cached on disk
extension NewsFeedScrollPosition: Codable {
    
    enum CodingKeys: String, CodingKey { case model, offset }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        do {
            let data = try values.decode(Status.self, forKey: .model)
            let postCard = PostCardModel(status: data)
            model = .postCard(postCard)
        } catch {
            do {
                let data = try values.decode(Notificationt.self, forKey: .model)
                let activity = ActivityCardModel(notification: data)
                model = .activity(activity)
            } catch {}
        }
        offset = try values.decode(Double.self, forKey: .offset)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if case .postCard(let postCard) = model {
            if case .mastodon(let status) = postCard.data {
                try container.encode(status, forKey: .model)
            }
        }
        if case .activity(let activity) = model {
            try container.encode(activity.notification, forKey: .model)
        }
        try container.encode(offset, forKey: .offset)
    }
}

internal struct NewsFeedScrollPositions {
    var forYou: NewsFeedScrollPosition = NewsFeedScrollPosition()
    var following: NewsFeedScrollPosition = NewsFeedScrollPosition()
    var federated: NewsFeedScrollPosition = NewsFeedScrollPosition()
    var community: [String: NewsFeedScrollPosition] = [:]
    var trending: [String: NewsFeedScrollPosition] = [:]
    var hashtag: [String: NewsFeedScrollPosition] = [:]
    var list: [String: NewsFeedScrollPosition] = [:]
    var likes: NewsFeedScrollPosition = NewsFeedScrollPosition()
    var bookmarks: NewsFeedScrollPosition = NewsFeedScrollPosition()
    var mentionsIn: NewsFeedScrollPosition = NewsFeedScrollPosition()
    var mentionsOut: NewsFeedScrollPosition = NewsFeedScrollPosition()
    var activity: [String: NewsFeedScrollPosition] = [:]
    var channel: [String: NewsFeedScrollPosition] = [:]

    @discardableResult
    fileprivate mutating func setPosition(model: NewsFeedListItem?, offset: Double, forFeed type: NewsFeedTypes) -> NewsFeedScrollPosition {
        let position = NewsFeedScrollPosition(model: model, offset: offset)
        switch type {
        case .forYou:
            forYou = position
        case .following:
            following = position
        case .federated:
            federated = position
        case .community(let name):
            community[name] = position
        case .trending(let name):
            trending[name] = position
        case .hashtag(let tag):
            hashtag[tag.name] = position
        case .list(let data):
            list[data.id] = position
        case .likes:
            likes = NewsFeedScrollPosition()
        case .bookmarks:
            bookmarks = NewsFeedScrollPosition()
        case .mentionsIn:
            mentionsIn = position
        case .mentionsOut:
            mentionsOut = position
        case .activity(let type):
            activity[type?.rawValue ?? "all"] = position
        case .channel(let data):
            channel[data.id] = position
        }
        
        return position
    }
    
    fileprivate func getPosition(forType type: NewsFeedTypes) -> NewsFeedScrollPosition {
        switch type {
        case .forYou:
            return forYou
        case .following:
            return following
        case .federated:
            return federated
        case .community(let name):
            return community[name] ?? NewsFeedScrollPosition()
        case .trending(let name):
            return trending[name] ?? NewsFeedScrollPosition()
        case .hashtag(let tag):
            return hashtag[tag.name] ?? NewsFeedScrollPosition()
        case .list(let data):
            return list[data.id] ?? NewsFeedScrollPosition()
        case .likes:
            return likes
        case .bookmarks:
            return bookmarks
        case .mentionsIn:
            return mentionsIn
        case .mentionsOut:
            return mentionsOut
        case .activity(let type):
            return activity[type?.rawValue ?? "all"] ?? NewsFeedScrollPosition()
        case .channel(let data):
            return channel[data.id] ?? NewsFeedScrollPosition()
        }
    }
}

// MARK: - Scroll position accessors
extension NewsFeedViewModel {
    @discardableResult
    func setScrollPosition(model: NewsFeedListItem?, offset: Double, forFeed type: NewsFeedTypes) -> NewsFeedScrollPosition {
        let position = self.scrollPositions.setPosition(model: model, offset: offset, forFeed: type)
        
        let items = self.listData.forType(type: type)
        self.saveToDisk(items: items, position: position, feedType: type)
        
        return position
    }
    
    func getScrollPosition(forFeed type: NewsFeedTypes) -> NewsFeedScrollPosition {
        return self.scrollPositions.getPosition(forType: type)
    }
}
