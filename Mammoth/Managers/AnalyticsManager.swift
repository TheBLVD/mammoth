//
//  AnalyticsManager.swift
//  Mammoth
//
//  Created by Terence on 10/3/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import Segment
import ArkanaKeys

enum Events: String {
    case newPost
    case newReply
    case newPostFailed
    case newReplyFailed
    case upgradedToGold
    case restoredToGold
    case failedToUpgrade
    case postBookmarked
    case channelSubscribed
    case channelUnsubscribed
    case navigateToChannel
}

class AnalyticsManager {
    private let analytics: Analytics
    static let shared = AnalyticsManager()
    
    init() {
            #if DEBUG
            let key = ArkanaKeys.Staging().analyticsKey
            let config = Configuration(writeKey: key)
                .trackApplicationLifecycleEvents(true)
                .flushAt(3)
                .flushInterval(10)
            
            analytics = Analytics(configuration: config)
            
            #else
            let key = ArkanaKeys.Production().analyticsKey
            let config = Configuration(writeKey: key)
                .trackApplicationLifecycleEvents(true)
                .flushAt(3)
                .flushInterval(10)
            
            analytics = Analytics(configuration: config)
            #endif
    }
    
    func prepareForUse() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.didSwitchAccount), name: didSwitchCurrentAccountNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didUpdatePurchase), name: didUpdatePurchaseStatus, object: nil)
        
        let analytics = self.analytics
        analytics.add(plugin: DeviceToken())
    }
    
    @objc func didSwitchAccount(_ notification: NSNotification) {
        callActivities()
    }
    
    @objc func didUpdatePurchase(_ notification: NSNotification) {
        if IAPManager.isGoldMember {
            callActivities()
        }
    }
    
    private func callActivities() {
        if let currentFullAccount = AccountsManager.shared.currentAccount?.remoteFullOriginalAcct {
            FeaturesService.activities(fullAccountName: currentFullAccount)
        } else {
            log.warning("no account to check in with")
        }
    }
    
    static public func track(event: Events, props: [String:Any]? = [:]) {
        self.shared.analytics.track(name: event.rawValue, properties: props)
    }
    
    static public func reportError(_ error: Error) {
        self.shared.analytics.reportInternalError(error)
    }
    
    static public func identity(userId: String, identity: IdentityData) {
        self.shared.analytics.identify(userId: userId, traits: identity)
    }
    
    static public func openURL(url: URL) {
        self.shared.analytics.openURL(url)
    }
    
    static public func setDeviceToken(token: Data) {
        self.shared.analytics.registeredForRemoteNotifications(deviceToken: token)
    }
    
    static public func failedToRegisterForPushNotifications(error: Error?) {
        self.shared.analytics.failedToRegisterForRemoteNotification(error: error)
    }
    
    static public func logout() {
        self.shared.analytics.reset()
    }
    
}
