//
//  AccountsManager.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 28/02/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage


// AccountsManager
//
// Singleton class. Used to login and logout, and delete accounts.
// Maintains list of all accounts, as well as the current account.
//
//      currentAccount -> ___AccountData
//      allAccounts -> [AcctDataType]
//      switchToAccount(___AccountData)


// MastodonAccountData, BlueskyAccountData
//
// Data structures that encapsulate the info needed to login to accounts.
//      For Mastodon: account type, Account, InstanceData
//      For Bluesky: account type, ____TBD
//
// NetworkAcctData is the generic type that is represented by any
// of the above *AcctData types. Used mainly for reading/writing to disk.


// AcctHandler
//
// Protocol for creating, signing in, deleting, and becoming
// the current account. This is most closely tied to whatever
// low level calls are needed to interface with the given network.
//
//      addExistingAccount()    // sign in to an existing account
//      addNewAccount()         // create a new account and sign in
//      deleteFromDisk()
//      becomeCurrent()
//
// MastodonAcctHandler - conforms to AcctLogin; can login/out with MastodonAccountData
// BlueskyAcctHandler - conforms to AcctLogin; can login/out with BlueskyAccountData





public let willSwitchCurrentAccountNotification = Notification.Name("willSwitchCurrentAccountNotification")
public let didSwitchCurrentAccountNotification = Notification.Name("didSwitchCurrentAccountNotification")
public let didUpdateAccountDisplayName = Notification.Name("didUpdateAccountDisplayName")
public let didUpdateAccountAvatar = Notification.Name("didUpdateAccountAvatar")
public let didUpdateAccountHeader = Notification.Name("didUpdateAccountHeader")
public let didUpdateAccountForYou = Notification.Name("didUpdateAccountForYou")

class AccountsManager {
 
    static let shared = AccountsManager()
    var currentAccount: (any AcctDataType)?
    var allAccounts: [any AcctDataType] = []

    var accountsManagerShim = AccountsManagerShim.shared
    
    init() {
    }
    
    @MainActor func prepareForUse() async throws {
        // Restore accounts from disk; will migrate if needed
        try await restoreAccountsFromDisk()
        
        // Select the current account
        if let previousAcctIdentifier = UserDefaults.standard.object(forKey: "currentAccountIdentifier") as? String {
            let previousAcctData = allAccounts.first { acctData in
                acctData.uniqueID == previousAcctIdentifier
            }
            
            log.debug("switching to saved account: \(String(describing: previousAcctData?.fullAcct))")
            switchToAccount(previousAcctData, forceUIRefresh: false)
            
            if currentAccount == nil && allAccounts.count > 0 {
                log.error("Unable to switch to saved account; switching to first account")
                switchToAccount(allAccounts.first, forceUIRefresh: false)
            }
        }
    }
        
    // Which handler can deal with this acctData? Mastodon, or Bluesky?
    private func acctHandlerForAcctData(_ acctData: (any AcctDataType)?) -> AcctHandler.Type? {
        let acctHandler: AcctHandler.Type?
        switch acctData?.acctType {
        case .Mastodon: acctHandler = MastodonAcctHandler.self
        case .Bluesky: acctHandler = BlueskyAcctHandler.self
        default: acctHandler = nil
        }
        return acctHandler
    }
    
    @MainActor public func switchToAccount(_ acctData: (any AcctDataType)?, forceUIRefresh: Bool = true) {
        log.debug("account: switching account")
        NotificationCenter.default.post(name: willSwitchCurrentAccountNotification, object: self, userInfo: nil)
        AccountsManagerShim.shared.willSwitchCurentAccount()
        
        if UserDefaults.standard.value(forKey: "notifs1") as? Bool == true {
            if let previousAccount = AccountsManager.shared.currentAccount as? MastodonAcctData {
                Task {
                    // stop listening for push notifications for the previous account
                    try await PushNotificationManager.unsubscribe(account: previousAccount)
                }
            }
        }
        
        RealtimeManager.shared.disconnect()
        RealtimeManager.shared.clearAllListeners()
        
        currentAccount = acctData
        if currentAccount != nil {
            if let acctHandler = acctHandlerForAcctData(acctData) {
                acctHandler.becomeCurrent(acctData: acctData!) { error in
                    if let error {
                        log.error("error switching accounts: \(error)")
                    } else {
                        // Store current account to disk
                        UserDefaults.standard.set(acctData?.uniqueID, forKey: "currentAccountIdentifier")
                        
                        self.syncIdentityData()

                        // Let the rest of the app know
                        AccountsManagerShim.shared.didSwitchCurrentAccount(forceUIRefresh: forceUIRefresh)
                        
                        // Sign in for push notifications
                        if UserDefaults.standard.value(forKey: "notifs1") as? Bool == true {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                        
                        do {
                            try RealtimeManager.shared.connect()
                        } catch {
                            log.error("[realtime] unable to connect to websockets")
                        }
                    }
                }
            } else {
                log.error("unable to switch accounts - missing acctHandler")
            }
        } else {
            // no account; notify the rest of the app
            AccountsManagerShim.shared.didSwitchCurrentAccount(forceUIRefresh: true)
        }
    }
    
    @MainActor public func syncIdentityData() {
        if let identity = self.sanitizedCurrentIdentityData {
            AnalyticsManager.identity(userId: identity.id, identity: identity)
            
            if let token = GlobalStruct.deviceToken {
                AnalyticsManager.setDeviceToken(token: token)
            }
        }
    }
    
    public func updateAccount(_ acctData: (any AcctDataType)) {
        let existingAcctIndex = allAccounts.firstIndex(where: {$0.uniqueID == acctData.uniqueID})
        if existingAcctIndex != nil {
            allAccounts[existingAcctIndex!] = acctData
            self.storeAccountsToDisk()
        } else {
            log.error("no index found when trying to update with \(acctData.fullAcct)")
        }
        if acctData.uniqueID == currentAccount?.uniqueID {
            currentAccount = acctData
            
            DispatchQueue.main.async { [weak self] in
                self?.syncIdentityData()
            }
        }
    }
    
    // Signs in to an existing account, and adds it to the list of accounts
    public func addExistingMastodonAccount(instanceData: InstanceData, client: Client, completion: @escaping (_ error: Error?, _ acctData: (any AcctDataType)?) -> Void) {
        log.debug("account: adding existing account")
        MastodonAcctHandler.addExistingAccount(instanceData: instanceData, client: client) { [weak self] error, acctData in
            guard let self else { return }
            if let error {
                log.error("error creating Mastodon account: \(error)")
                completion(error, acctData)
            } else {
                if let acctData {
                    // Add to our list of accounts
                    self.allAccounts.append(acctData)

                    // Save account info
                    self.storeAccountsToDisk()
                    
                    // Make this the current account
                    self.switchToAccount(acctData, forceUIRefresh: false)

                    completion(nil, acctData)
                } else {
                    log.error("acctData was nil")
                    let error = NSError(domain: "acctData was nil", code: 100)
                    completion(error, acctData)
                }
            }
        }
    }
    
    // Creates a new Mastodon account, and adds it to the list of accounts
    public func addNewMastodonAccount(instanceData: InstanceData, client: Client, completion: @escaping (_ error: Error?) -> Void) {
        log.debug("account: adding new account")
        MastodonAcctHandler.addNewAccount(instanceData: instanceData, client: client) { [weak self] error, acctData in
            guard let self else { return }
            if let error {
                log.error("error creating new Mastodon account: \(error)")
                completion(error)
            } else {
                if let acctData {
                    // Add to our list of accounts
                    self.allAccounts.append(acctData)

                    // Save account info
                    self.storeAccountsToDisk()
                    
                    // Make this the current account
                    self.switchToAccount(acctData, forceUIRefresh: false)

                    completion(nil)
                } else {
                    log.error("acctData was nil")
                    let error = NSError(domain: "acctData was nil", code: 100)
                    completion(error)
                }
            }
        }
    }
    
    
    // Signs in to an existing account, and adds it to the list of accounts
    public func addExistingBlueskyAccount(authResponse: BlueskyAPI.AuthResponse) async throws {
        log.debug("account: adding existing account")
        
        let acctData = try await BlueskyAcctHandler
            .addExistingAccount(authResponse: authResponse)
        
        await MainActor.run {
            // Add to our list of accounts
            self.allAccounts.append(acctData)
            
            // Save account info
            self.storeAccountsToDisk()
            
            // Make this the current account
            self.switchToAccount(acctData, forceUIRefresh: false)
        }
    }
    
    
    // Creates a new Bluesky account, and adds it to the list of accounts
    public func addNewBlueskyAccount(instanceData: InstanceData, client: Client, completion: @escaping (_ error: Error?) -> Void) {
        // Bluesky HERE
        // (not needed/useful until we have a 'create bluesky account' button)
    }

    
    // Several steps here:
    //      • stop listening for push notifications
    //      • delete the account
    //      • remove from data structures
    //      • store updated accounts list to disk
    //      • swtich to another account if available
    @MainActor public func logoutAndDeleteAccount(_ acctData: any AcctDataType) {
        log.debug("account: logging out and deleting account")
        guard let acctHandler = acctHandlerForAcctData(acctData) else {
            log.error("missing acctHandler for \(acctData)")
            return
        }

        Task {
            // • stop listening for push notifications
            if let account = acctData as? MastodonAcctData {
                try await PushNotificationManager.unsubscribe(account: account)
            }
        }

        // • delete the account
        acctHandler.deleteFromDisk(acctData: acctData)
        if let mastodonAcctData = acctData as? MastodonAcctData {
            AccountCacher.clearCache(forAccount: mastodonAcctData.account)
        }
        
        AnalyticsManager.unsubscribe()

        // • remove from data structures
        let isCurrentAccount = self.currentAccount?.isEqualTo(other: acctData) ?? false
        if isCurrentAccount {
            self.currentAccount = nil
        }
        self.allAccounts = self.allAccounts.filter({ acct in
            return !acct.isEqualTo(other: acctData)
        })
        
        // • store updated accounts list to disk
        self.storeAccountsToDisk()

        // • Switch to anther account (could be nil)
        self.switchToAccount(self.allAccounts.first)
        
        // • additional cleanup if this was the last account
        if self.allAccounts.count == 0 {
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
        }
    }

    
    private func storeAccountsToDisk() {
        log.debug("storing allAccounts (\(allAccounts.count))")
        do {
            // Convert accounts to a codeable array
            var codableArray: [NetworkAcctData] = []
            allAccounts.forEach { acctData in
                if acctData.acctType == .Mastodon {
                    let mastodonAcctData = NetworkAcctData.mastodonAcctData(acctData as! MastodonAcctData)
                    codableArray.append(mastodonAcctData)
                } else if acctData.acctType == .Bluesky {
                    let blueskyAcctData = NetworkAcctData.blueskyAcctData(acctData as! BlueskyAcctData)
                    codableArray.append(blueskyAcctData)
                }
            }
            try Disk.save(codableArray, to: .documents, as: "allAccounts.json")
        } catch {
            log.error("error storing allAccounts: \(error)")
        }
    }

    
    @MainActor private func restoreAccountsFromDisk() async throws {
        try await migrateOldAccountsIfNeeded()
        do {
            allAccounts = []
            let codedArray = try Disk.retrieve("allAccounts.json", from: .documents, as: [NetworkAcctData].self)
            codedArray.forEach { networkAcctData in
                let acctData = networkAcctData.asAcctDataType()
                allAccounts.append(acctData)
            }
        } catch {
            // error decoding accounts from Disk (Could not find an existing file or folder?)
        }
        migrateDraftsIfNeeded()
        migrateInstancesIfNeeded()
        migrateOnboardingStatus()
    }
    
    // Will migrate & delete old accounts as needed
    @MainActor private func migrateOldAccountsIfNeeded() async throws {
        let oldAccounts = Account.getAccounts()
        let oldInstances = InstanceData.getAllInstances()
        guard oldAccounts.count > 0 else {
            log.debug("no accounts to migrate")
            return
        }
        guard oldAccounts.count == oldInstances.count else {
            log.error("number of accounts and instances don't match")
            return
        }
        var selectedAcctData: (any AcctDataType)? = nil
        for index in 0..<oldAccounts.count {
            // Iterate over old accounts and migrate them
            let account = oldAccounts[index]
            let instance = oldInstances[index]
            log.debug("migrating account: \(account.remoteFullOriginalAcct)")
            // Select this account?
            let client = Client(baseURL: "https://\(instance.returnedText)", accessToken: instance.accessToken)
            let acctData = MastodonAcctData(account: account, instanceData: instance, client: client, defaultPostVisibility: .public, defaultPostingLanguage: nil, emoticons: [], forYou: ForYouAccount(forYou: ForYouType(), subscribedChannels: []))
            if instance == InstanceData.getCurrentInstance() {
                selectedAcctData = acctData
            }
            
            // Add the account to our list of accounts
            self.allAccounts.append(acctData)
        }
        
        // Store the ID of the previously selected account
        UserDefaults.standard.set(selectedAcctData?.uniqueID, forKey: "currentAccountIdentifier")
        
        // Write migrated accounts to disk
        storeAccountsToDisk()
        
        // Remove old account/instance data
        Account.clearAccounts()
        InstanceData.clearInstances()
        
        // Unsubscribe from all push notifications if applicable
        // (the selected account will be re-subscribed in the
        // new way when it's selected)
        if UserDefaults.standard.value(forKey: "notifs1") as? Bool == true {
            for account in AccountsManager.shared.allAccounts {
                if let account = account as? MastodonAcctData {
                    try await PushNotificationManager.unsubscribe(account: account)
                }
            }
        }
    }
    
    // Move any 'wentThroughOnboarding' from AccountInfo to disk if needed
    @MainActor private func migrateOnboardingStatus() {
        if !UserDefaults.standard.bool(forKey: "didMigrateOnboardingStatus") {
            for account in AccountsManager.shared.allAccounts {
                if let mastodonAcct = account as? MastodonAcctData {
                    if mastodonAcct.wentThroughOnboarding {
                        self.didShowOnboardingForAccount(mastodonAcct)
                    }
                }
            }
            UserDefaults.standard.set(true, forKey: "didMigrateOnboardingStatus")
        }
    }
    
    // Pre Mammoth 2.0, drafts were stored in /drafts/accountID/drafts.json
    // Now, they are in /acct.diskFolderName()/drafts.json
    private func migrateDraftsIfNeeded() {
        for account in allAccounts {
            if let acctData = account as? MastodonAcctData {
                do {
                    let drafts = try Disk.retrieve("drafts/\(acctData.account.id)/drafts.json", from: .documents, as: [Draft].self)
                    if !drafts.isEmpty {
                        try Disk.save(drafts, to: .documents, as: "\(acctData.diskFolderName())/drafts.json")
                        try Disk.remove("drafts/\(acctData.account.id)/drafts.json", from: .documents)
                    }
                } catch {
                    // unable to migrate drafts
                }
            }
        }
    }
    
    // Pre Mammoth 2.0, all the tracked instances were stored in a global.
    // Now, they are stored per-account
    private func migrateInstancesIfNeeded() {
        // If the old pinned timelines exists, copy it to every Mastodon
        // account, then delete it.
        
        if let pinnedTimelines = UserDefaults.standard.value(forKey: "pinnedTimelines") as? [String] {
            log.warning("going to migrate pinned timelines: \(pinnedTimelines)")
            for account in allAccounts {
                log.debug("setting pinned timelines for account: \(account.remoteFullOriginalAcct)")
                InstanceManager.shared.setPinnedInstances(instances: pinnedTimelines, forAccount: account)
            }
            // Done with these forever
            log.debug("deleting old pinned timelines")
            UserDefaults.standard.setValue(nil, forKey: "pinnedTimelines")
        }
    }
    
}


// Helper function
extension AccountsManager {
    
    var currentAccountClient: Client {
        if let currentAccount = self.currentAccount as? MastodonAcctData {
            return currentAccount.client
        } else {
            log.error("currentAccountClient called with no active account")
            // Not really a valid client
            return Client(baseURL: "https://useless")
        }
    }
    
    var currentAccountMothClient: Client {
        if let currentAccount = self.currentAccount as? MastodonAcctData {
            return currentAccount.mothClient
        } else {
            log.error("currentAccountMothClient called with no active account")
            // Not really a valid client
            return Client(baseURL: "https://moth.social")
        }
    }

    var currentAccountFeatureClient: Client {
        if let currentAccount = self.currentAccount as? MastodonAcctData {
            return currentAccount.featureClient
        } else {
            log.error("currentAccountFeatureClient called with no active account")
            // Not really a valid client
            return Client(baseURL: "https://feature.moth.social")
        }
    }

    var currentAccountBlueskyAPI: BlueskyAPI? {
        let account = currentAccount as? BlueskyAcctData
        return account?.api
    }
    
    // Used for analytics
    var sanitizedCurrentIdentityData: IdentityData? {
        if let mastodonAccount = (self.currentAccount as? MastodonAcctData) {
            return IdentityData(from: mastodonAccount, allAccounts: self.allAccounts)
        }
        
        return nil
    }

}


extension AccountsManager {
    
    public func updateCurrentAccountFromNetwork() {
        if let account = self.currentAccount,
           let acctHandler = acctHandlerForAcctData(account) {
            Task {
                let updatedAccount = await acctHandler.updateAccountFromNetwork(acctData: account)
                acctHandler.notifyAboutAccountUpdates(oldAcctData: account, newAcctData: updatedAccount)
            }
        }
    }
    
    
    public func updateCurrentAccountForYouFromNetwork() {
        if let account = self.currentAccount,
           let acctHandler = acctHandlerForAcctData(account) {
            Task {
                let updatedAccount = await acctHandler.updateForYouFromNetwork(acctData: account)
                acctHandler.notifyAboutAccountUpdates(oldAcctData: account, newAcctData: updatedAccount)
            }
        }
    }
    
    public func updateCurrentAccountForYou(_ forYouAccount: ForYouAccount, writeToServer: Bool = true) {
        if let account = self.currentAccount,
           let acctHandler = acctHandlerForAcctData(account) {
            Task {
                // Compute the new updatedAccount with updated forYouInfo
                var updatedAccount: any AcctDataType = account
                if writeToServer {
                    if let updatedAccountFromNetwork = await acctHandler.setForYouType(acctData: account, forYouInfo: forYouAccount.forYou) {
                        updatedAccount = updatedAccountFromNetwork
                    }
                } else {
                    if var modifiedAcct = updatedAccount as? MastodonAcctData {
                        modifiedAcct.forYou = forYouAccount
                        updatedAccount = modifiedAcct
                    }
                }
                // The currentAccount may have changed while the network call was ongoing
                // (seen in the onboarding case). For that reason, re-create an
                // updated version of the current account now.
                let currentAccount = self.currentAccount as! MastodonAcctData
                let updatedCurrentAccount = MastodonAcctData(account: currentAccount.account, instanceData: currentAccount.instanceData, client: currentAccount.client, defaultPostVisibility: currentAccount.defaultPostVisibility, defaultPostingLanguage: currentAccount.defaultPostingLanguage, emoticons: currentAccount.emoticons, forYou: (updatedAccount as! MastodonAcctData).forYou, uniqueID: currentAccount.uniqueID)

                // Store the updated settings to the account on disk
                if var updatedAcctData = account as? MastodonAcctData {
                    log.debug("writing back forYou data for \(updatedAcctData.remoteFullOriginalAcct)")
                    updatedAcctData.forYou = (updatedAccount as? MastodonAcctData)!.forYou
                    updateAccount(updatedAcctData)
                }
                
                acctHandler.notifyAboutAccountUpdates(oldAcctData: account, newAcctData: updatedCurrentAccount)
            }
        }
    }

    
    public func updateCurrentAccountForYou(_ forYouInfo: ForYouType, writeToServer: Bool = true) {
        if let account = self.currentAccount,
           let acctHandler = acctHandlerForAcctData(account) {
            Task {
                // Compute the new updatedAccount with updated forYouInfo
                var updatedAccount: any AcctDataType = account
                if writeToServer {
                    if let updatedAccountFromNetwork = await acctHandler.setForYouType(acctData: account, forYouInfo: forYouInfo) {
                        updatedAccount = updatedAccountFromNetwork
                    }
                } else {
                    if var modifiedAcct = updatedAccount as? MastodonAcctData {
                        modifiedAcct.forYou.forYou = forYouInfo
                        updatedAccount = modifiedAcct
                    }
                }
                // The currentAccount may have changed while the network call was ongoing
                // (seen in the onboarding case). For that reason, re-create an
                // updated version of the current account now.
                let currentAccount = self.currentAccount as! MastodonAcctData
                let updatedCurrentAccount = MastodonAcctData(account: currentAccount.account, instanceData: currentAccount.instanceData, client: currentAccount.client, defaultPostVisibility: currentAccount.defaultPostVisibility, defaultPostingLanguage: currentAccount.defaultPostingLanguage, emoticons: currentAccount.emoticons, forYou: (updatedAccount as! MastodonAcctData).forYou, uniqueID: currentAccount.uniqueID)

                // Store the updated settings to the account on disk
                if var updatedAcctData = account as? MastodonAcctData {
                    log.debug("writing back forYou data for \(updatedAcctData.remoteFullOriginalAcct)")
                    updatedAcctData.forYou = (updatedAccount as? MastodonAcctData)!.forYou
                    updateAccount(updatedAcctData)
                }
                
                acctHandler.notifyAboutAccountUpdates(oldAcctData: account, newAcctData: updatedCurrentAccount)
            }
        }
    }

    
    public func updateCurrentAccountDisplayName(_ displayName: String) {
        if let account = self.currentAccount,
           let acctHandler = acctHandlerForAcctData(account) {
            Task {
                let updatedAccount = await acctHandler.setDisplayName(displayName, for: account)
                NotificationCenter.default.post(name: didUpdateAccountDisplayName, object: self, userInfo: ["account":updatedAccount])
            }
        }
    }

    
    public func updateCurrentAccountAvatar(_ avatar: UIImage) {
        if let account = self.currentAccount,
           let acctHandler = acctHandlerForAcctData(account) {
            Task {
                // Optimistically notify with the new image (but not the updated account)
                NotificationCenter.default.post(name: didUpdateAccountAvatar, object: self, userInfo: ["image":avatar])
                let previousURL = account.avatar
                let updatedAccount = await acctHandler.setAvatar(avatar, for: account)
                // Inform sd_image about the new avatar
                if previousURL != updatedAccount.avatar {
                    await SDImageCache.shared.store(avatar, forKey: updatedAccount.avatar)
                }
                NotificationCenter.default.post(name: didUpdateAccountAvatar, object: self, userInfo: ["account":updatedAccount, "image":avatar])
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: ToastNotificationManager.toast.imageSaved, object: nil)
                }
            }
        }
    }
    
    public func updateCurrentAccountHeader(_ header: UIImage) {
        if let account = self.currentAccount,
           let acctHandler = acctHandlerForAcctData(account) {
            Task {
                // Optimistically notify with the new image (but not the updated account)
                NotificationCenter.default.post(name: didUpdateAccountHeader, object: self, userInfo: ["header":header])
                let updatedAccount = await acctHandler.setHeader(header, for: account)
                NotificationCenter.default.post(name: didUpdateAccountHeader, object: self, userInfo: ["account":updatedAccount, "header":header])
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: ToastNotificationManager.toast.imageSaved, object: nil)
                }
            }
        }
    }

}

// Onboarding
extension AccountsManager {
    
    public func shouldShowOnboardingForCurrentAccount() -> Bool {
        var shouldShowOnboarding = true
        if let mastodonAcctData = self.currentAccount as? MastodonAcctData {
            let onboardedAccounts: [String] = UserDefaults.standard.object(forKey: "onboardedAccounts") as? [String] ?? []
            shouldShowOnboarding = !onboardedAccounts.contains(mastodonAcctData.remoteFullOriginalAcct)
        }
        return shouldShowOnboarding
    }
    
    public func didShowOnboardingForCurrentAccount() {
        if let updatedAcctData = self.currentAccount as? MastodonAcctData {
            self.didShowOnboardingForAccount(updatedAcctData)
        }
    }
    
    public func didShowOnboardingForAccount(_ mastodonAcctData: MastodonAcctData) {
        log.debug("setting wentThroughOnboarding to true for \(mastodonAcctData.remoteFullOriginalAcct)")
        var onboardedAccounts: [String] = UserDefaults.standard.object(forKey: "onboardedAccounts") as? [String] ?? []
        if !onboardedAccounts.contains(mastodonAcctData.remoteFullOriginalAcct) {
            onboardedAccounts.append(mastodonAcctData.remoteFullOriginalAcct)
        }
        UserDefaults.standard.set(onboardedAccounts, forKey: "onboardedAccounts")
    }
}
