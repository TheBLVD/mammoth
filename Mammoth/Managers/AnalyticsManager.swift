//
//  AnalyticsManager.swift
//  Mammoth
//
//  Created by Terence on 10/3/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class AnalyticsManager {
    
    static let shared = AnalyticsManager()
    
    func prepareForUse() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.didSwitchAccount), name: didSwitchCurrentAccountNotification, object: nil)
    }
    
    @objc func didSwitchAccount(_ notification: NSNotification) {
        if let currentFullAccount = AccountsManager.shared.currentAccount?.remoteFullOriginalAcct {
            FeaturesService.activities(fullAccountName: currentFullAccount)
        } else {
            log.warning("no account to check in with")
        }
    }
}
