//
//  AcctHandler.swift
//  Mammoth
//
//  Created by Riley Howard on 6/27/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

protocol AcctHandler {
    static func becomeCurrent(acctData: any AcctDataType, completion: @escaping (_ error: Error?) -> Void)
    static func deleteFromDisk(acctData: any AcctDataType)
    static func setDisplayName(_ displayName: String, for acctData: any AcctDataType) async -> any AcctDataType
    static func setAvatar(_ avatar: UIImage, for acctData: any AcctDataType) async -> any AcctDataType
    static func setHeader(_ header: UIImage, for acctData: any AcctDataType) async -> any AcctDataType
    static func updateAccountFromNetwork(acctData: any AcctDataType) async -> any AcctDataType
    static func updateForYouFromNetwork(acctData: any AcctDataType) async -> any AcctDataType
    static func setForYouType(acctData: any AcctDataType, forYouInfo: ForYouType) async -> any AcctDataType
    static func notifyAboutAccountUpdates(oldAcctData: any AcctDataType, newAcctData: any AcctDataType)
}

extension AcctHandler {
    static func deleteFromDisk(acctData: any AcctDataType) {
        let folderToDelete = acctData.diskFolderName()
        do {
            try Disk.remove(folderToDelete, from: .documents)
        } catch let error {
            log.error("error deleting folder from Documents: \(folderToDelete) - \(error)")
        }
        do {
            try Disk.remove(folderToDelete, from: .caches)
        } catch let error {
            log.error("error deleting folder from Caches: \(folderToDelete) - \(error)")
        }
    }
}

class MastodonAcctHandler: AcctHandler {

    // Do whatever is necessary to sign in to an existing account
    static func addExistingAccount(instanceData: InstanceData, client: Client, completion: @MainActor @escaping (_ error: Error?, _ acct: (any AcctDataType)?) -> Void) {

        // Log in to new instance
        var request = URLRequest(url: URL(string: "https://\(instanceData.returnedText)/oauth/token?grant_type=authorization_code&code=\(instanceData.authCode)&redirect_uri=\(instanceData.redirect)&client_id=\(instanceData.clientID)&client_secret=\(instanceData.clientSecret)&scope=read%20write%20follow%20push")!)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil, let data = data else {
                log.error("Error logging into new instance: \(error!)")
                DispatchQueue.main.async {
                    completion(error, nil)
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    if let accessToken = (json["access_token"] as? String) {
                        instanceData.accessToken = accessToken

                        // Verify credentials
                        client.accessToken = accessToken
                        let request = Accounts.currentUser()
                        client.run(request) { (statuses) in
                            if let account = statuses.value {
                                // Make sure this account isn't already logged into
                                let newFullAcct = account.fullAcct
                                if AccountsManager.shared.allAccounts.contains(where: { $0.fullAcct == newFullAcct} ) {
                                    let error = NSError(domain: "Already logged into this account", code: 401)
                                    log.error("\(error)")
                                    DispatchQueue.main.async {
                                        completion(error, nil)
                                    }
                                } else {
                                    let newAcct = MastodonAcctData(account: account, instanceData: instanceData, client: client, defaultPostVisibility: .public, emoticons: [], forYou: ForYouAccount(), wentThroughOnboarding: false)
                                    DispatchQueue.main.async {
                                        completion(nil, newAcct)
                                    }
                                }
                            } else {
                                let error = NSError(domain: "Unable to log into account", code: 401)
                                log.error("\(error)")
                                DispatchQueue.main.async {
                                    completion(error, nil)
                                }
                            }
                        }
                    } else {
                        let error = NSError(domain: "No access token", code: 401)
                        log.error("\(error)")
                        DispatchQueue.main.async {
                            completion(error, nil)
                        }
                    }
                } else {
                    let error = NSError(domain: "JSONSerialization failed", code: 401)
                    log.error("\(error)")
                    DispatchQueue.main.async {
                        completion(error, nil)
                    }
                }
            } catch let error {
                log.error("catch - error logging into new instance: \(error)")
                DispatchQueue.main.async {
                    completion(error, nil)
                }
            }
        })
        task.resume()
    }
    
    // Do whatever is necessary to create a new account
    static func addNewAccount(instanceData: InstanceData, client: Client, completion: @MainActor @escaping (_ error: Error?, _ acct: (any AcctDataType)?) -> Void) {
        // Verify credentials
        let request = Accounts.currentUser()
        client.run(request) { (statuses) in
            if let error = statuses.error {
                log.error("\(error)")
                DispatchQueue.main.async {
                    completion(error, nil)
                }
            }
            if let account = statuses.value {
                let newAcct = MastodonAcctData(account: account, instanceData: instanceData, client: client, defaultPostVisibility: .public, emoticons: [], forYou: ForYouAccount(), wentThroughOnboarding: false)
                DispatchQueue.main.async {
                    completion(nil, newAcct)
                }
            }
        }
    }
    
    static func becomeCurrent(acctData: any AcctDataType, completion: @escaping (_ error: Error?) -> Void) {
        guard (acctData as? MastodonAcctData) != nil else {
            log.error("expected acctData to be MastodonAcctData")
            let error = NSError(domain: "Internal Error", code: 100)
            completion(error)
            return
        }
        completion(nil)
    }
    
    static func setDisplayName(_ displayName: String, for acctData: any AcctDataType) async -> any AcctDataType {
        do {
            guard let mastodonAcct = acctData as? MastodonAcctData else {
                log.error("wrong acct type")
                return acctData
            }
            let accountWithUpdatedDisplayName = try await AccountService.updateDisplayName(displayName: displayName)
            if acctData.uniqueID == AccountsManager.shared.currentAccount?.uniqueID {
                let updatedAcct = MastodonAcctData(account: accountWithUpdatedDisplayName, instanceData: mastodonAcct.instanceData, client: mastodonAcct.client, defaultPostVisibility: mastodonAcct.defaultPostVisibility, emoticons: mastodonAcct.emoticons, forYou: mastodonAcct.forYou, uniqueID: acctData.uniqueID, wentThroughOnboarding: mastodonAcct.wentThroughOnboarding)
                AccountsManager.shared.updateAccount(updatedAcct)
                return updatedAcct
            } else {
                log.error("account ID changed while setting avatar")
                return acctData
            }
        } catch let error {
            log.error("setAvatar error: \(error)")
            return acctData
        }
    }

    static func setAvatar(_ avatar: UIImage, for acctData: any AcctDataType) async -> any AcctDataType {
        do {
            guard let mastodonAcct = acctData as? MastodonAcctData else {
                log.error("wrong acct type")
                return acctData
            }
            let accountWithUpdatedAvatar = try await AccountService.updateAvatar(image: avatar, compressionQuality: 0.5)
            if acctData.uniqueID == AccountsManager.shared.currentAccount?.uniqueID {
                let updatedAcct = MastodonAcctData(account: accountWithUpdatedAvatar, instanceData: mastodonAcct.instanceData, client: mastodonAcct.client, defaultPostVisibility: mastodonAcct.defaultPostVisibility, emoticons: mastodonAcct.emoticons, forYou: mastodonAcct.forYou, uniqueID: acctData.uniqueID, wentThroughOnboarding: mastodonAcct.wentThroughOnboarding)
                AccountsManager.shared.updateAccount(updatedAcct)
                return updatedAcct
            } else {
                log.error("account ID changed while setting avatar")
                return acctData
            }
        } catch let error {
            log.error("setAvatar error: \(error)")
            return acctData
        }
    }
    
    static func setHeader(_ header: UIImage, for acctData: any AcctDataType) async -> any AcctDataType {
        do {
            guard let mastodonAcct = acctData as? MastodonAcctData else {
                log.error("wrong acct type")
                return acctData
            }
            let accountWithUpdatedHeader = try await AccountService.updateHeader(image: header, compressionQuality: 0.5)
            if acctData.uniqueID == AccountsManager.shared.currentAccount?.uniqueID {
                let updatedAcct = MastodonAcctData(account: accountWithUpdatedHeader, instanceData: mastodonAcct.instanceData, client: mastodonAcct.client, defaultPostVisibility: mastodonAcct.defaultPostVisibility, emoticons: mastodonAcct.emoticons, forYou: mastodonAcct.forYou, uniqueID: acctData.uniqueID, wentThroughOnboarding: mastodonAcct.wentThroughOnboarding)
                AccountsManager.shared.updateAccount(updatedAcct)
                return updatedAcct
            } else {
                log.error("account ID changed while setting header")
                return acctData
            }
        } catch let error {
            log.error("setHeader error: \(error)")
            return acctData
        }
    }

    static func updateAccountFromNetwork(acctData: any AcctDataType) async -> any AcctDataType {
        
        guard let mastodonAcct = acctData as? MastodonAcctData else {
            log.error("wrong acct type")
            return acctData
        }

        async let getCurrentUser = AccountService.currentUser()
        async let getServerConstants = InstanceService.serverConstants()
        async let getCustomEmojis = InstanceService.customEmojis()
        
        // Block on getting all results
        do {
            let results = try await [
                getCurrentUser as Any,
                getServerConstants,
                getCustomEmojis
            ] as [Any]
            
            let updatedUser = results[0] as? Account ?? mastodonAcct.account
            let updatedConstants = results[1] as? serverConstants
            let updatedEmojis = results[2] as? [Emoji] ?? []

            var postVisiblity: Visibility = .public
            if updatedConstants?.defaultVisibility != nil {
                postVisiblity = Visibility(rawValue: updatedConstants!.defaultVisibility!) ?? .public
            }
            
            let updatedMastAcct = MastodonAcctData(account: updatedUser, instanceData: mastodonAcct.instanceData, client: mastodonAcct.client, defaultPostVisibility: postVisiblity, emoticons: updatedEmojis, forYou: mastodonAcct.forYou, uniqueID: mastodonAcct.uniqueID, wentThroughOnboarding: mastodonAcct.wentThroughOnboarding)
            AccountsManager.shared.updateAccount(updatedMastAcct)
            return updatedMastAcct
        } catch {
            log.error("problems updating user/server info: \(error)")
            return mastodonAcct
        }
    }
    
    static func updateForYouFromNetwork(acctData: any AcctDataType) async -> any AcctDataType {
        guard let mastodonAcct = acctData as? MastodonAcctData else {
            log.error("wrong acct type")
            return acctData
        }

        do {
            let getForYou = try await TimelineService.forYouMe(remoteFullOriginalAcct: mastodonAcct.remoteFullOriginalAcct)

            let updatedMastAcct = MastodonAcctData(account: mastodonAcct.account, instanceData: mastodonAcct.instanceData, client: mastodonAcct.client, defaultPostVisibility: mastodonAcct.defaultPostVisibility, emoticons: mastodonAcct.emoticons, forYou: getForYou, uniqueID: mastodonAcct.uniqueID, wentThroughOnboarding: mastodonAcct.wentThroughOnboarding)
            AccountsManager.shared.updateAccount(updatedMastAcct)
            return updatedMastAcct
        } catch {
            log.error("problems updating user/server info: \(error)")
            return mastodonAcct
        }
    }

    
    static func setForYouType(acctData: any AcctDataType, forYouInfo: ForYouType) async -> any AcctDataType {
        guard let mastodonAcct = acctData as? MastodonAcctData else {
            log.error("wrong acct type")
            return acctData
        }

        do {
            let updatedForYou = try await TimelineService.updateForYouMe(remoteFullOriginalAcct: mastodonAcct.remoteFullOriginalAcct, forYouInfo: forYouInfo)

            let updatedMastAcct = MastodonAcctData(account: mastodonAcct.account, instanceData: mastodonAcct.instanceData, client: mastodonAcct.client, defaultPostVisibility: mastodonAcct.defaultPostVisibility, emoticons: mastodonAcct.emoticons, forYou: updatedForYou, uniqueID: mastodonAcct.uniqueID, wentThroughOnboarding: mastodonAcct.wentThroughOnboarding)
            AccountsManager.shared.updateAccount(updatedMastAcct)
            return updatedMastAcct
        } catch {
            log.error("problems updating user/server info: \(error)")
            return mastodonAcct
        }
    }


    static func notifyAboutAccountUpdates(oldAcctData: any AcctDataType, newAcctData: any AcctDataType) {
        guard let oldAcctData = oldAcctData as? MastodonAcctData else {
            log.error("wrong acct type: old")
            return
        }
        guard let newAcctData = newAcctData as? MastodonAcctData else {
            log.error("wrong acct type: new")
            return
        }

        // Check and see what might have changed
        if oldAcctData.avatar != newAcctData.avatar {
            NotificationCenter.default.post(name: didUpdateAccountAvatar, object: self, userInfo: ["account":newAcctData])
        }
        if oldAcctData.account.header != newAcctData.account.header {
            NotificationCenter.default.post(name: didUpdateAccountHeader, object: self, userInfo: ["account":newAcctData])
        }
        if oldAcctData.forYou != newAcctData.forYou {
            NotificationCenter.default.post(name: didUpdateAccountForYou, object: self, userInfo: ["account":newAcctData])
        }
    }

}

class BlueskyAcctHandler: AcctHandler {
        
    static func addExistingAccount(authResponse: BlueskyAPI.AuthResponse) async throws -> BlueskyAcctData {
        let tokenSet = BlueskyAPI.TokenSet(
            accessToken: authResponse.accessJwt,
            refreshToken: authResponse.refreshJwt)
        
        let api = BlueskyAPI(tokenSet: tokenSet)
        
        let userID = authResponse.did
        
        let user = try await api.getUserProfile(id: userID)
        let displayName = user.displayName ?? user.handle
            
        return BlueskyAcctData(
            userID: userID,
            handle: user.handle,
            displayName: displayName,
            avatar: user.avatar ?? "",
            tokenSet: tokenSet)
    }

    static func becomeCurrent(acctData: any AcctDataType, completion: @escaping (_ error: Error?) -> Void) {
        guard acctData is BlueskyAcctData else {
            log.error("expected acctData to be BlueskyAcctData")
            let error = NSError(domain: "Internal Error", code: 100)
            completion(error)
            return
        }
        completion(nil)
    }
    
    static func setDisplayName(_ displayName: String, for acctData: any AcctDataType) async -> any AcctDataType {
        log.error(#function + " missing for Bluesky")
        return acctData
    }
    
    static func setAvatar(_ avatar: UIImage, for acctData: any AcctDataType) async -> any AcctDataType {
        log.error(#function + " missing for Bluesky")
        return acctData
    }
    
    static func setHeader(_ header: UIImage, for acctData: any AcctDataType) async -> any AcctDataType {
        log.error(#function + " missing for Bluesky")
        return acctData
    }
    
    static func updateAccountFromNetwork(acctData: any AcctDataType) async -> any AcctDataType {
        log.error(#function + " missing for Bluesky")
        return acctData
    }
    
    static func updateForYouFromNetwork(acctData: any AcctDataType) async -> any AcctDataType {
        log.error(#function + " missing for Bluesky")
        return acctData
    }
    
    static func setForYouType(acctData: any AcctDataType, forYouInfo: ForYouType) async -> any AcctDataType {
        log.error(#function + " missing for Bluesky")
        return acctData
    }

    static func notifyAboutAccountUpdates(oldAcctData: any AcctDataType, newAcctData: any AcctDataType) {
        guard oldAcctData is BlueskyAcctData else {
            log.error("wrong acct type: old")
            return
        }
        guard newAcctData is BlueskyAcctData else {
            log.error("wrong acct type: new")
            return
        }
    }


}
