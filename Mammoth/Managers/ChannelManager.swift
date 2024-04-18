//
//  ChannelManager.swift
//  Mammoth
//
//  Created by Riley Howard on 9/8/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

public let didChangeChannelsNotification = Notification.Name("didChangeChannelsNotification") // List of possible channels changed
public let didChangeChannelStatusNotification = Notification.Name("didChangeChannelStatusNotification") // Un/subscribe status of a channel changed
//  "account" in userInfo is the acctInfo
//  "channel" in userInfo is the channel


class ChannelManager {
    
    static let shared = ChannelManager()
    
    enum ChannelStatus: String {
        case unknown
        case notSubscribed           // default (not subscribed)
        case subscribeRequested      // asked to subscribe
        case subscribed              // am subscribed
        case unsubscribeRequested    // asked to unsubscribe
    }
    
    enum NetworkUpdateType: String {
        case none                   // no need to make a network request
        case force                  // request a network update
        case whenUncertain          // will request if not .following and not .notFollowing
    }
    
    private var channels: [Channel] = [] {
        didSet {
            NotificationCenter.default.post(name: didChangeChannelsNotification, object: self, userInfo: nil)
        }
    }
    private var subscriptionsRequested: [Channel] = []
    private var unsubscriptionsRequested: [Channel] = []
    private var forYouAccount: ForYouAccount? = nil // For the current user
    
    private var lastChannelSync: Date? = nil
    
    public init() {
        // Listen to account switch, and update the list of channels accordingly
        NotificationCenter.default.addObserver(self, selector: #selector(self.didSwitchAccount), name: didSwitchCurrentAccountNotification, object: nil)
        
        // Listen to ForYou settings changing for the current account
        NotificationCenter.default.addObserver(self, selector: #selector(self.onForYouDidChange), name: didUpdateAccountForYou, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.appDidBecomeActive), name: appDidBecomeActiveNotification, object: nil)
        
        // Get all channels
        self.updateAllChannels()

        // Get channels for current user
        self.updateUserChannels()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func didSwitchAccount() {
        // Reload recommentations when a user is set/changed
        forYouAccount = nil
        self.updateUserChannels()
    }
    
    @objc func onForYouDidChange() {
        updateUserChannels()
    }
    
    @objc func appDidBecomeActive() {
        // Refresh channels from server if needed
        if self.lastChannelSync == nil || Date().since(self.lastChannelSync!, in: DateComponentType.hour) >= 4 {
            updateAllChannels()
        }
    }
    
    private func updateAllChannels() {
        Task { [weak self] in
            guard let self else { return }
            let channels = try await ChannelService.allChannels()
            DispatchQueue.main.async {
                self.lastChannelSync = Date()
                self.channels = channels
                self.validateUserChannels()
            }
        }
    }

    // Get the account's local list of subscribed channels,
    // and compare it to the previous list. This...
    //      - updates the list of un/subscriptions requested
    //      - posts a notification that channel statuses have changed
    private func updateUserChannels() {
        let previousChannels = self.forYouAccount?.subscribedChannels
        self.forYouAccount = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.forYou
        let currentChannels = self.forYouAccount?.subscribedChannels
        
        // Update the subscriptionsRequested and unsubscriptionsRequests lists
        let newlySubscribed = currentChannels?.filter { !(previousChannels?.contains($0) ?? false) }
        let newlyUnsubscribed = previousChannels?.filter { !(currentChannels?.contains($0) ?? false) }

        subscriptionsRequested = subscriptionsRequested.filter { !(newlySubscribed?.contains($0) ?? false) }
        unsubscriptionsRequested = unsubscriptionsRequested.filter { !(newlyUnsubscribed?.contains($0) ?? false) }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: didChangeChannelStatusNotification, object: self, userInfo: nil)
        }
        
        self.validateUserChannels()
    }

    // Unsubscribe the user from any channels that no longer exist
    private func validateUserChannels() {
        let serverChannels = self.channels
        let currentlySubscribedChannels = self.subscribedChannels()
        guard serverChannels.count > 0,
              currentlySubscribedChannels.count > 0 else {
            return
        }
        
        for channel in currentlySubscribedChannels {
            if !serverChannels.contains(channel) {
                log.debug("Channel no longer exists; unsubscribing: \(channel.title)")
                self.unsubscribeFromChannel(channel, silent: true)
            }
        }
    }

}


// Public APIs
extension ChannelManager {
    
    // Returns all possible channels
    public func allChannels() -> [Channel] {
        return channels
    }
    
    // Returns currently subscribed channels
    public func subscribedChannels() -> [Channel] {
        return self.forYouAccount?.subscribedChannels ?? []
    }
    
    public func subscriptionStatusForChannel(_ channel: Channel) -> ChannelStatus {
        if subscriptionsRequested.contains(channel) {
            return .subscribeRequested
        }
        if unsubscriptionsRequested.contains(channel) {
            return .unsubscribeRequested
        }
        if forYouAccount?.subscribedChannels.contains(channel) ?? false {
            return .subscribed
        }
        if forYouAccount == nil {
            return .unknown
        }
        return .notSubscribed
    }

    public func subscribeToChannel(_ channel: Channel, silent: Bool = false) {
        // Update pending actions, and notify of the status change
        unsubscriptionsRequested.removeAll { aChannel in
            aChannel.id == channel.id
        }
        log.debug("adding \(channel.title) to subscriptionsRequested")
        subscriptionsRequested.append(channel)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: didChangeChannelStatusNotification, object: self, userInfo: nil)
        }
        
        // Make the network request
        Task {
            if let currentUser = AccountsManager.shared.currentAccount?.remoteFullOriginalAcct {
                do {
                    let forYouInfo = try await ChannelService.subscribeToChannel(remoteFullOriginalAcct: currentUser, channel: channel)
                    if !silent {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: ToastNotificationManager.toast.subscribed, object: nil)
                        }
                        
                        AnalyticsManager.track(event: .channelSubscribed)
                    }
                    AccountsManager.shared.updateCurrentAccountForYou(forYouInfo, writeToServer: false)
                } catch {
                    log.error("\(error)")
                }
            }
        }
    }

    public func unsubscribeFromChannel(_ channel: Channel, silent: Bool = false) {
        // Update pending actions, and notify of the status change
        subscriptionsRequested.removeAll { aChannel in
            aChannel.id == channel.id
        }
        log.debug("adding \(channel.title) to unsubscriptionsRequested")
        unsubscriptionsRequested.append(channel)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: didChangeChannelStatusNotification, object: self, userInfo: nil)
        }
        
        // Make the network request
        Task {
            if let currentUser = AccountsManager.shared.currentAccount?.remoteFullOriginalAcct {
                let result = try await ChannelService.unsubscribeFromChannel(remoteFullOriginalAcct: currentUser, channel: channel)
                if !silent {
                    DispatchQueue.main.async {
                        self.forYouAccount?.subscribedChannels = result.subscribedChannels
                        NotificationCenter.default.post(name: didChangeChannelStatusNotification, object: self, userInfo: nil)
                        NotificationCenter.default.post(name: ToastNotificationManager.toast.unsubscribed, object: nil)
                    }
                    
                    AnalyticsManager.track(event: .channelUnsubscribed)
                }
                AccountsManager.shared.updateCurrentAccountForYou(result, writeToServer: false)
            }
        }
    }

    
}


