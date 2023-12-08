//
//  ChannelService.swift
//  Mammoth
//
//  Created by Riley Howard on 8/29/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

struct ChannelService {
    
    /// Fetches the list of channels  from Moth.social
    static func allChannels() async throws -> [Channel] {
        let request = Channels.allChannels()
        let result = try await ClientService.runMothRequest(request: request)
        return result
    }

    /// Request to subscribe to a channel
    /// Returns the updated ForYouAccount settings, including the updated list of followed channels
    static func subscribeToChannel(remoteFullOriginalAcct: String, channel: Channel) async throws -> ForYouAccount {
        let request = Channels.subscribeToChannel(remoteFullOriginalAcct: remoteFullOriginalAcct, channelID: channel.id)
        let result = try await ClientService.runMothRequest(request: request)
        return result
    }

    /// Request to unsubscribe from a channel
    /// Returns the updated ForYouAccount settings, including the updated list of followed channels
    static func unsubscribeFromChannel(remoteFullOriginalAcct: String, channel: Channel) async throws -> ForYouAccount {
        let request = Channels.unsubscribeFromChannel(remoteFullOriginalAcct: remoteFullOriginalAcct, channelID: channel.id)
        let result = try await ClientService.runMothRequest(request: request)
        return result
    }

}
