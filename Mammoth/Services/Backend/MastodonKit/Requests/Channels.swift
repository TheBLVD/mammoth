//
//  Channels.swift
//  Mammoth
//
//  Created by Riley Howard on 8/29/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation


public struct Channels {
   
    /// Retrieves all available channels.
    ///
    /// - Returns: Request for `[Channel]`.
    public static func allChannels() -> Request<[Channel]> {
        return Request<[Channel]>(path: "/api/v3/channels")
    }

    /// Subscribes to the given channels.
    ///
    /// - Returns: The updated ForYouAccount
    public static func subscribeToChannel(remoteFullOriginalAcct: String, channelID: String) -> Request<ForYouAccount> {
        let parameters = [
            Parameter(name: "acct", value: remoteFullOriginalAcct),
        ]
        let method = HTTPMethod.post(.parameters(parameters))
        return Request<ForYouAccount>(path: "/api/v3/channels/\(channelID)/subscribe", method: method)
    }

    /// Unsubscribes to the given channels.
    ///
    /// - Returns: The updated ForYouAccount
    public static func unsubscribeFromChannel(remoteFullOriginalAcct: String, channelID: String) -> Request<ForYouAccount> {
        let parameters = [
            Parameter(name: "acct", value: remoteFullOriginalAcct),
        ]
        let method = HTTPMethod.post(.parameters(parameters))
        return Request<ForYouAccount>(path: "/api/v3/channels/\(channelID)/unsubscribe", method: method)
    }

}
