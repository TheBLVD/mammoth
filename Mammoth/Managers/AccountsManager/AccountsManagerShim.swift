//
//  AccountsManagerShim.swift
//  Mammoth
//
//  Created by Riley Howard on 6/27/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation


// Listens to notifications, and does things for the app

class AccountsManagerShim {
    
    static let shared = AccountsManagerShim()
    
    init() {
    }
    
    func willSwitchCurentAccount() {
    }
    
    func didSwitchCurrentAccount(forceUIRefresh: Bool) {
        DispatchQueue.main.async {
            
            let currentAccount = AccountsManager.shared.currentAccount
            
            GlobalStruct.hasSetupNewsDots = false
            GlobalStruct.timer1.invalidate()
            GlobalStruct.topAccounts = []
            GlobalStruct.allLikes = []
            GlobalStruct.allReposts = []
            GlobalStruct.allBookmarks = []
            do {
                GlobalStruct.drafts = try Disk.retrieve("\(currentAccount?.diskFolderName() ?? "")/drafts.json", from: .documents, as: [Draft].self)
            } catch {
                // unable to create drafts; perhaps there were none
            }

            // Delete any app-related storage if there is no current acccount
            if currentAccount == nil {
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
            }
            
            // Recreate the window root view controller if a regular switch;
            // otherwise, let the user continue with setting up their profile,
            // picking accounts to follow, etc.
            if forceUIRefresh {
                NotificationCenter.default.post(name: shouldChangeRootViewController, object: nil)
            }
            
            var userInfo: [AnyHashable: Any]? = nil
            if let mastodonAccount = (currentAccount as? MastodonAcctData)?.account {
                userInfo = ["userCard": UserCardModel(account: mastodonAccount)]
            }
            
            NotificationCenter.default.post(name: didSwitchCurrentAccountNotification, object: self, userInfo: userInfo)
            
            AccountsManager.shared.updateCurrentAccountFromNetwork()
        }
    }
}


// Globals Helper
extension AccountsManager {
    func currentUser() -> Account? {
        var currentUser: Account? = nil
        if let mastodonAcctData = AccountsManager.shared.currentAccount as? MastodonAcctData {
            currentUser = mastodonAcctData.account
        }
        return currentUser
    }
}
