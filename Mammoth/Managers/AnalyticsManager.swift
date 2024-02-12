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
        NotificationCenter.default.addObserver(self, selector: #selector(self.didUpdatePurchase), name: didUpdatePurchaseStatus, object: nil)
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
    
}
