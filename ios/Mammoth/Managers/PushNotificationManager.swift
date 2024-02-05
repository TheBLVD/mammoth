//
//  PushNotificationManager.swift
//  Mammoth
//
//  Created by Benoit Nolens on 31/10/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import ArkanaKeys

class PushNotificationManager {
    
    enum PushNotificationServiceError: Error {
        case receiverSetupFailed
    }
    
    deinit {}
    
    // If the user has allowed notifications, tell the account's server
    // about our device so it can subscribe to the Apple Push Notifications
    // server.
    @discardableResult
    static func subscribe(deviceToken: Data, account: MastodonAcctData) async throws -> URLResponse? {
        log.debug("subscribing to pushes for account: \(account.fullAcct)")
        let pushNotificationURL = ArkanaKeys.Production().pushNotificationURL
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        var urH = "\(pushNotificationURL)\(token)"
#if DEBUG
        // Set to staging environment
        let pushNotificationURLDevelopment = ArkanaKeys.Staging().pushNotificationURL
        urH = "\(pushNotificationURLDevelopment)\(token)"
#endif
        
        guard let receiver = try? PushNotificationReceiver(forDeviceToken: token) else {
            throw PushNotificationServiceError.receiverSetupFailed
        }
        let alerts = PushNotificationAlerts.init(
            favourite: GlobalStruct.pnLikes,
            follow: GlobalStruct.pnFollows,
            mention: GlobalStruct.pnMentions,
            reblog: GlobalStruct.pnReposts,
            poll: GlobalStruct.pnPolls,
            status: GlobalStruct.pnStatuses,
            followRequest: GlobalStruct.pnFollowRequests)
        
        let requestParams = PushNotificationSubscriptionRequest(endpoint: "\(urH)", receiver: receiver, alerts: alerts)
        
        do {
            let server = account.instanceData.returnedText
            let url = URL(string: "https://\(server)/api/v1/push/subscription")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(requestParams)
            request.httpBody = jsonData
            
            request.setValue("Bearer \(account.instanceData.accessToken)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            let subscription = PushNotificationSubscription(endpoint: URL(string:"\(urH)")!, alerts: alerts)
            let deviceTokenObj = PushNotificationDeviceToken(deviceToken: deviceToken)
            let state = PushNotificationState(receiver: receiver, subscription: subscription, deviceToken: deviceTokenObj)
            PushNotificationReceiver.setState(state: state, for: account.uniqueID)
            
            log.debug("success subscribing to push notifications for - \(account.fullAcct)")
            return response
            
        } catch let error {
            log.error("error subscribing push notifications - \(error)")
            throw error
        }
    }
    
    @MainActor static func unsubscribe(account: MastodonAcctData, retryCount: Int = 0) async throws {
        log.debug("unsubscribing to pushes for account: \(account.fullAcct)")
        do {
            let mastodonInstance = account.instanceData
            if let url = URL(string: "https://\(mastodonInstance.returnedText)/api/v1/push/subscription") {
                var request = URLRequest(url: url)
                request.httpMethod = "DELETE"
                
                request.setValue("Bearer \(mastodonInstance.accessToken)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                let (data, _) = try await URLSession.shared.data(for: request as URLRequest)

                if let json = try? JSONSerialization.jsonObject(with: data, options: [.mutableContainers]) as? [String: Any] {
                    // Retry if data in the json && we haven't tried too many times
                    if !json.isEmpty && retryCount < 10 {
                        log.error("error unsubscribing; has json data; tried \(retryCount+1) times; trying again")
                        try await Task.sleep(seconds: 0.5)
                        try await self.unsubscribe(account: account, retryCount: retryCount + 1)
                    } else {
                        // Success!
                        log.debug("success unsubscribing from push notification: \(account.fullAcct)")
                    }
                   
                    // Clear out the state used for decrypting push notifications
                    PushNotificationReceiver.setState(state: nil, for: account.uniqueID)
                }
            }
        } catch let error {
            if retryCount < 10 {
                log.error("error - unsubscribing from push notification - trying again in 1 second - \(error)")
                try await Task.sleep(seconds: 0.5)
                try await self.unsubscribe(account: account, retryCount: retryCount + 1)
            } else {
                log.error("error - unsubscribing from push notification (final try) - \(error)")

            }
        }
    }
    
    // Migration work required for old (corrupted) keys
    // Unsubscribe from previous subscriptions that are possibly corrupt and clear cached keys from disk
    // Added in version 2.0
    static func migrate() async {
        do {
            for account in AccountsManager.shared.allAccounts {
                if let account = account as? MastodonAcctData, PushNotificationReceiver.hasDeprecatedState(for: account.uniqueID) {
                    try await Self.unsubscribe(account: account)
                }
            }
            
            // After we unsubscribe from previous subscriptions we clear old states from disk
            PushNotificationReceiver.clearAllDeprecatedStates()
        } catch {}
    }
}
