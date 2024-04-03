//
//  Timelines.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation


public struct Timelines {
    /// Retrieves the home timeline.
    ///
    /// - Parameter range: The bounds used when requesting data from Mastodon.
    /// - Returns: Request for `[Status]`.
    public static func home(range: RequestRange = .default) -> Request<[Status]> {
        var parameters: [Parameter]
        if case .limit(let limit) = range {
            parameters = range.parameters(limit: between(1, and: limit, default: limit)) ?? []
        } else if case .min(_, let limit) = range, let limit {
            parameters = range.parameters(limit: between(1, and: limit, default: 20)) ?? []
        } else if case .max(_, let limit) = range, let limit {
            parameters = range.parameters(limit: between(1, and: limit, default: 20)) ?? []
        } else {
            parameters = range.parameters(limit: between(1, and: 40, default: 20)) ?? []
        }
        
        let method = HTTPMethod.get(.parameters(parameters))

        return Request<[Status]>(path: "/api/v1/timelines/home", method: method)
    }
    
    public static func lists(listId: String, range: RequestRange = .default) -> Request<[Status]> {
        var parameters: [Parameter]
        if case .limit(let limit) = range {
            parameters = range.parameters(limit: between(1, and: limit, default: limit)) ?? []
        } else if case .min(_, let limit) = range, let limit {
            parameters = range.parameters(limit: between(1, and: limit, default: 20)) ?? []
        } else if case .max(_, let limit) = range, let limit {
            parameters = range.parameters(limit: between(1, and: limit, default: 20)) ?? []
        } else {
            parameters = range.parameters(limit: between(1, and: 40, default: 20)) ?? []
        }

        let method = HTTPMethod.get(.parameters(parameters))

        return Request<[Status]>(path: "/api/v1/timelines/list/\(listId)", method: method)
    }

    public static func channel(channelId: String, range: RequestRange = .default) -> Request<[Status]> {
        var parameters: [Parameter]
        if case .limit(let limit) = range {
            parameters = range.parameters(limit: between(1, and: limit, default: limit)) ?? []
        } else if case .min(_, let limit) = range, let limit {
            parameters = range.parameters(limit: between(1, and: limit, default: 20)) ?? []
        } else if case .max(_, let limit) = range, let limit {
            parameters = range.parameters(limit: between(1, and: limit, default: 20)) ?? []
        } else {
            parameters = range.parameters(limit: between(1, and: 40, default: 20)) ?? []
        }

        let method = HTTPMethod.get(.parameters(parameters))

        return Request<[Status]>(path: "/api/v3/timelines/channels/\(channelId)", method: method)
    }

    /// Retrieves the public timeline.
    ///
    /// - Parameters:
    ///   - local: Only return statuses originating from this instance.
    ///   - range: The bounds used when requesting data from Mastodon.
    /// - Returns: Request for `[Status]`.
    public static func `public`(local: Bool? = nil, range: RequestRange = .default, mediaOnly: Bool? = nil) -> Request<[Status]> {
        var rangeParameters: [Parameter]
        if case .limit(let limit) = range {
            rangeParameters = range.parameters(limit: between(1, and: limit, default: limit)) ?? []
        } else if case .min(_, let limit) = range, let limit {
            rangeParameters = range.parameters(limit: between(1, and: limit, default: 20)) ?? []
        } else if case .max(_, let limit) = range, let limit {
            rangeParameters = range.parameters(limit: between(1, and: limit, default: 20)) ?? []
        } else {
            rangeParameters = range.parameters(limit: between(1, and: 40, default: 20)) ?? []
        }
        
        let localParameter = [
            Parameter(name: "only_media", value: mediaOnly.flatMap(trueOrNil)),
            Parameter(name: "local", value: local.flatMap(trueOrNil))
        ]
        let method = HTTPMethod.get(.parameters(localParameter + rangeParameters))

        return Request<[Status]>(path: "/api/v1/timelines/public", method: method)
    }

    /// Retrieves a tag timeline.
    ///
    /// - Parameters:
    ///   - hashtag: The hashtag.
    ///   - local: Only return statuses originating from this instance.
    ///   - range: The bounds used when requesting data from Mastodon.
    /// - Returns: Request for `[Status]`.
    public static func tag(_ hashtag: String, local: Bool? = nil, range: RequestRange = .default) -> Request<[Status]> {
        var rangeParameters: [Parameter]
        if case .limit(let limit) = range {
            rangeParameters = range.parameters(limit: between(1, and: limit, default: limit)) ?? []
        } else if case .min(_, let limit) = range, let limit {
            rangeParameters = range.parameters(limit: between(1, and: limit, default: 20)) ?? []
        } else if case .max(_, let limit) = range, let limit {
            rangeParameters = range.parameters(limit: between(1, and: limit, default: 20)) ?? []
        } else {
            rangeParameters = range.parameters(limit: between(1, and: 40, default: 20)) ?? []
        }

        let localParameter = [Parameter(name: "local", value: local.flatMap(trueOrNil))]
        let method = HTTPMethod.get(.parameters(localParameter + rangeParameters))

        return Request<[Status]>(path: "/api/v1/timelines/tag/\(hashtag)", method: method)
    }
    
    /// Retrieves a conversation timeline.
    ///
    /// - Parameter range: The bounds used when requesting data from Mastodon.
    /// - Returns: Request for `[Conversation]`.
    public static func conversations(range: RequestRange = .default) -> Request<[Conversation]> {
        let parameters = range.parameters(limit: between(1, and: 40, default: 20))
        let method = HTTPMethod.get(.parameters(parameters))
        
        return Request<[Conversation]>(path: "/api/v1/conversations", method: method)
    }
    
    /// Updates the conversation read status.
    ///
    /// - Parameter id: The conversation id.
    /// - Returns: Request for `Status`.
    public static func markRead(id: String) -> Request<Conversation> {
        return Request<Conversation>(path: "/api/v1/conversations/\(id)/read", method: .post(.empty))
    }
    
    public static func deleteConversation(id: String) -> Request<Empty> {
        return Request<Empty>(path: "/api/v1/conversations/\(id)", method: .delete(.empty))
    }
    

}
