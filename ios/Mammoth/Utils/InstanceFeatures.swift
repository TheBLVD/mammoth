//
//  InstanceFeatures.swift
//  Mammoth
//
//  Created by Riley Howard on 3/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation



class InstanceFeatures {

    static var cachedInstanceInfo: [String : Instance] = [:]
    
    enum FeatureType: String {
        case VIP            // Supports VIP
        case editingAltText // Supports editing ALT text
        case networkLookup  // Supports network lookup of accounts
    }
    
    static let featureTable = [
        FeatureType.VIP             : "4.0",
        FeatureType.editingAltText  : "4.1",
        FeatureType.networkLookup   : "4.1"
    ]

    
    
    /// Check if an instance supports a certain feature.
    ///
    /// - Parameters:
    ///   - feature: a feature from the above list
    ///   - server: The server to use if not the default/current user's server.
    ///   - completion: Completion to call with the result
    class func supportsFeature(_ feature: FeatureType, server: String? = nil, completion: @escaping ((_ supported: Bool, _ instanceInfo: Instance?) -> Void)) {

        // Do we already have info for the current instance?
        var serverAsKey: String? = nil
        let serverURL: String = (server?.count ?? 0 > 0) ? "https://" + (server ?? "") : AccountsManager.shared.currentAccountClient.baseURL
        if let url = URL(string: serverURL) {
            serverAsKey = url.host
        }
        
        if serverAsKey == nil {
            log.error("expected server key to be valid for server \(server ?? "<nil>")")
            completion(false, nil)
            return
        }
        
        let key = serverAsKey!
        let instanceInfo = cachedInstanceInfo[key]
        if instanceInfo != nil {
            self.callCompletionForFeature(feature, completion: completion, instanceInfo: instanceInfo!)
        } else {
            // Make the network call first
            let request = Instances.current()
            let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken
            let client = Client(
                    baseURL: "https://\(key)",
                    accessToken: accessToken)
            client.run(request) { (statuses) in
                if let error = statuses.error {
                    log.error("Unable to get instance information: \(client.baseURL) : \(error)")
                }
                if let status = statuses.value {
                    self.cachedInstanceInfo[key] = status
                }
                self.callCompletionForFeature(feature, completion: completion, instanceInfo: self.cachedInstanceInfo[key])
            }
        }
    }
        
    
    private class func callCompletionForFeature(_ feature: FeatureType, completion: ((_ supported: Bool, _ instanceInfo: Instance?) -> Void), instanceInfo: Instance?) {
        var supported = false
        if let instanceInfo {
            let minRequiredVersion = self.featureTable[feature]!
            let instanceVersion: String = instanceInfo.version ?? "0"
            supported = instanceVersion.compare(minRequiredVersion, options: .numeric) != .orderedAscending
        }
        completion(supported, instanceInfo)
    }
    
    
}

