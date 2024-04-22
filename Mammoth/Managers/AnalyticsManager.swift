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
    case newPostFailed
    case newReplyFailed
    case upgradedToGold
    case restoredToGold
    case failedToUpgrade
    case postBookmarked
    case channelSubscribed
    case channelUnsubscribed
    case navigateToChannel
    
    case follow
    case unfollow
    
    case like
    case unlike
    case repost
    case unrepost
}

class AnalyticsManager {
    private var analytics: Analytics?
    static let shared = AnalyticsManager()
    
    init() {
        if GlobalStruct.shareAnalytics {
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
    }
    
    func prepareForUse() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.didSwitchAccount), name: didSwitchCurrentAccountNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didUpdatePurchase), name: didUpdatePurchaseStatus, object: nil)
        
        if let analytics = self.analytics {
            analytics.add(plugin: DeviceToken())
            analytics.add(plugin: UIKitScreenTracking())
        }
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
        if GlobalStruct.shareAnalytics {
            if let currentFullAccount = AccountsManager.shared.currentAccount?.remoteFullOriginalAcct {
                FeaturesService.activities(fullAccountName: currentFullAccount)
            } else {
                log.warning("no account to check in with")
            }
        }
    }
    
    static public func initClient() {
        #if DEBUG
        let key = ArkanaKeys.Staging().analyticsKey
        let config = Configuration(writeKey: key)
            .trackApplicationLifecycleEvents(true)
            .flushAt(3)
            .flushInterval(10)
        
        self.shared.analytics = Analytics(configuration: config)
        
        #else
        let key = ArkanaKeys.Production().analyticsKey
        let config = Configuration(writeKey: key)
            .trackApplicationLifecycleEvents(true)
            .flushAt(3)
            .flushInterval(10)
        
        self.shared.analytics = Analytics(configuration: config)
        #endif
    }
    
    static public func track(event: Events, props: [String:Any]? = [:]) {
        if GlobalStruct.shareAnalytics {
            self.shared.analytics?.track(name: event.rawValue, properties: props)
        }
    }
    
    static public func reportError(_ error: Error) {
        if GlobalStruct.shareAnalytics {
            self.shared.analytics?.reportInternalError(error)
        }
    }
    
    static public func identity(userId: String, identity: IdentityData) {
        if GlobalStruct.shareAnalytics {
            self.shared.analytics?.identify(userId: userId, traits: identity)
        }
    }
    
    static public func openURL(url: URL) {
        if GlobalStruct.shareAnalytics {
            self.shared.analytics?.openURL(url)
        }
    }
    
    static public func setDeviceToken(token: Data) {
        if GlobalStruct.shareAnalytics {
            self.shared.analytics?.registeredForRemoteNotifications(deviceToken: token)
        }
    }
    
    static public func failedToRegisterForPushNotifications(error: Error?) {
        if GlobalStruct.shareAnalytics {
            self.shared.analytics?.failedToRegisterForRemoteNotification(error: error)
        }
    }
    
    static public func subscribe() {
        self.shared.analytics?.identify(traits: ["unsubscribed": false, "shareAnalytics": true])
        self.shared.analytics?.flush()
    }
    
    static public func unsubscribe() {
        self.shared.analytics?.identify(traits: ["unsubscribed": true, "shareAnalytics": false])
        self.shared.analytics?.flush()
        self.shared.analytics?.reset()
        self.shared.analytics = nil
    }
    
}
