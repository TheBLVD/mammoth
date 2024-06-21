//
//  ForYou.swift
//  Mammoth
//
//  Created by Riley Howard on 8/9/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation


enum ForYouAccountType: String, Decodable, Encodable {
    case `personal`  // is enrolled in 2.0 personalization
    case `public`    // original public for you feed (OG)
    case  waitlist   // user was public, but on the waitlist for personal
}

/// Current status of generating user's for you feed
enum ForYouStatus: String, Decodable, Encodable {
    case `idle`     // no changes needed. normal
    case `pending`  // changes to settings. rebuilding
    case overloaded // server is currently overloaded
    case `error`    // failure to generate for you feed
}


public struct ForYouAccount: Decodable, Encodable {
    var forYou: ForYouType
    var subscribedChannels: [Channel]
    private enum CodingKeys: String, CodingKey {
        case forYou = "for_you_settings"
        case subscribedChannels = "subscribed_channels"
    }
}
extension ForYouAccount {
    init() {
        self.forYou = ForYouType()
        self.subscribedChannels = []
    }
}
extension ForYouAccount: Equatable {
   static public func ==(lhs: ForYouAccount, rhs: ForYouAccount) -> Bool {
        return lhs.forYou == rhs.forYou &&
       lhs.subscribedChannels == rhs.subscribedChannels
    }
}

// For you values are 0-3
// 0-off. 1,2,3 translates to low, med, high respectively
public struct ForYouType: Decodable, Encodable {
    var type: ForYouAccountType
    var yourFollows: Int        // 0 off; anything else is on
    var friendsOfFriends: Int
    var fromYourChannels: Int
    var curatedByMammoth: Int
    var status: ForYouStatus
    var enabledChannelIDs: [String]
    private enum CodingKeys: String, CodingKey {
        case type
        case status
        case yourFollows = "your_follows"
        case friendsOfFriends = "friends_of_friends"
        case fromYourChannels = "from_your_channels"
        case curatedByMammoth = "curated_by_mammoth"
        case enabledChannelIDs = "enabled_channels"
    }
}
extension ForYouType {
    init() {
        self.type = .public
        self.status = .idle
        self.yourFollows = 1
        self.friendsOfFriends = 1
        self.fromYourChannels = 1
        self.curatedByMammoth = 1
        self.enabledChannelIDs = []
    }
}
extension ForYouType: Equatable {
   static public func ==(lhs: ForYouType, rhs: ForYouType) -> Bool {
       return lhs.type == rhs.type &&
       lhs.status == rhs.status &&
       lhs.yourFollows == rhs.yourFollows &&
       lhs.friendsOfFriends == rhs.friendsOfFriends &&
       lhs.fromYourChannels == rhs.fromYourChannels &&
       lhs.curatedByMammoth == rhs.curatedByMammoth &&
       lhs.enabledChannelIDs == rhs.enabledChannelIDs
   }
}



extension Timelines {
    
    /// Retrieves the For You curated timeline.
    ///
    /// - Parameters:
    ///   - range: The bounds used when requesting data from Mastodon.
    /// - Returns: Request for `[Status]`.
    public static func forYou(range: RequestRange = .default) -> Request<[Status]> {
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

        let method = HTTPMethod.get(.parameters(rangeParameters))

        return Request<[Status]>(path: "/api/v2/timelines/for_you", method: method)
    }
    
    /// Retrieves the For You curated timeline.
    ///
    /// - Parameters:
    ///   - remoteFullOriginalAcct: full user handle 'jtomchak@infosec.social'  local Moth.social accounts can just be 'jtomchak'
    ///   - range: The bounds used when requesting data from Mastodon.
    /// - Returns: Request for `[Status]`.
     public static func forYouV4(remoteFullOriginalAcct: String, range: RequestRange = .default) -> Request<[Status]> {
         var parameters = [
             Parameter(name: "acct", value: remoteFullOriginalAcct),
             Parameter(name: "beta", value: "true") //adds acct to enrollment list
        ]
         
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

         parameters += rangeParameters
         let method = HTTPMethod.get(.parameters(parameters))

         return Request<[Status]>(path: "/api/v4/timelines/for_you", method: method)
     }
    
    /// Retrieves the For You meta data.
    ///
    /// - Parameters:
    ///   - remoteFullOriginalAcct: full user handle 'jtomchak@infosec.social'
    /// - Returns: Request for `ForYouAccount`.
        public static func forYouMe(remoteFullOriginalAcct: String) -> Request<ForYouAccount> {
            let parameters = [
                Parameter(name: "acct", value: remoteFullOriginalAcct),
           ]
            let method = HTTPMethod.get(.parameters(parameters))

            return Request<ForYouAccount>(path: "/api/v4/timelines/for_you/me", method: method)
        }
    
    /// Sets the For You meta data.
    ///
    /// - Parameters:
    ///   - remoteFullOriginalAcct: full user handle 'jtomchak@infosec.social'
    /// - Returns: Request for `ForYouAccount`.
    public static func updateForYouMe(remoteFullOriginalAcct: String, forYouInfo: ForYouType) -> Request<ForYouAccount> {
        var parameters = [
            Parameter(name: "acct", value: remoteFullOriginalAcct),
            Parameter(name: "friends_of_friends", value: String(forYouInfo.friendsOfFriends)),
            Parameter(name: "from_your_channels", value: String(forYouInfo.fromYourChannels)),
            Parameter(name: "curated_by_mammoth", value: String(forYouInfo.curatedByMammoth)),
            Parameter(name: "your_follows", value: String(forYouInfo.yourFollows)),
            Parameter(name: "ur_follows", value: String(forYouInfo.yourFollows))
            ]
        // Append enabled channels
        if forYouInfo.enabledChannelIDs.count == 0 {
            parameters.append(Parameter(name: "enabled_channels[]", value: "false"))
        } else {
            for channelID in forYouInfo.enabledChannelIDs {
                parameters.append(Parameter(name: "enabled_channels[]", value: channelID))
            }
        }
        let method = HTTPMethod.put(.parameters(parameters))
        return Request<ForYouAccount>(path: "/api/v4/timelines/for_you/me", method: method)
    }
    
    
    /// Retrieves the origin info for the For You statius.
    ///
    /// - Parameters:
    ///   - id: post ID
    /// - Returns: Request for `StatusSource`.
    public static func forYouStatusSource(id: String) -> Request<[StatusSource]> {
        return Request<[StatusSource]>(path: "/api/v4/timelines/for_you/statuses/\(id)")
    }

}
