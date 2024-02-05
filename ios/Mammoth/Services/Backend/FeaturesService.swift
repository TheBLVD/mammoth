//
//  FeaturesService.swift
//  Mammoth
//
//  Created by Terence on 10/3/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

/// API calls to feature.moth.soical for post/put http 
struct FeaturesService {
    
    static var baseURL = "https://feature.moth.social/"
    
    // A basic "I'm here" checkin with the server
    static func activities(fullAccountName: String) {
        let parameters: [String: Any] = ["acct": fullAccountName]
        let requestData = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        
        let urlStr = FeaturesService.baseURL + "api/v1/activity"
        let accessToken = AccountsManager.shared.currentAccountMothClient.accessToken
        let url: URL = URL(string: urlStr)!
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer missing", forHTTPHeaderField: "Authorization")
            log.error("feature missing access token")
        }

        request.httpMethod = "POST"
        request.httpBody = requestData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard data != nil, error == nil else {
                log.debug("error registering: \(String(describing: error))")
                return
            }
        }
        task.resume()
    }
    
    static func personalize(fullAccountName: String) {
        let parameters: [String: Any] = ["acct": fullAccountName]
        let requestData = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        
        let urlStr = FeaturesService.baseURL + "api/v1/personalize"
        let accessToken = AccountsManager.shared.currentAccountMothClient.accessToken
        let url: URL = URL(string: urlStr)!
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer missing", forHTTPHeaderField: "Authorization")
            log.error("feature missing access token")
        }
        request.httpMethod = "POST"
        request.httpBody = requestData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard data != nil, error == nil else {
                log.debug("error registering: \(String(describing: error))")
                return
            }
        }
        task.resume()
    }

}
