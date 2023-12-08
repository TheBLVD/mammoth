//
//  ProfileCacher.swift
//  Mammoth
//
//  Created by Riley Howard on 2/2/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit


public class ProfileCacher {

    public static let shared = ProfileCacher()

    var prefetchImages: Set<UIImageView> = []
    var preloadedIDs: Set<String> = []

    func performActionForVisibleCells(table: UITableView, dataArray: [AnyObject]) {
        guard !dataArray.isEmpty else {
            return
        }
        let datum = dataArray[0]
        if datum is Status {
            preloadProfiles(table: table, statuses: dataArray as! [Status])
        } else if datum is Notificationt {
            preloadProfiles(table: table, notifications: dataArray as! [Notificationt])
        } else if datum is Account {
            preloadProfiles(table: table, accounts: dataArray as! [Account])
        } else {
            log.error("unexpected data type for " + #function)
        }
    }

    func preloadProfiles(table: UITableView, accounts: [Account]) {
        var visibleIDs: Set<String> = []
        let visibleIndexPaths = table.indexPathsForVisibleRows
        if !visibleIndexPaths!.isEmpty {
            for indexPath in visibleIndexPaths! {
                if indexPath.row < accounts.count {
                    let account = accounts[indexPath.row]
                    visibleIDs.insert(account.id)
                }
            }
        }
        preloadProfilesForIDs(Array(visibleIDs))
    }

    func preloadProfiles(table: UITableView, notifications: [Notificationt]) {
        var visibleIDs: Set<String> = []
        let visibleIndexPaths = table.indexPathsForVisibleRows
        if !visibleIndexPaths!.isEmpty {
            for indexPath in visibleIndexPaths! {
                if indexPath.row < notifications.count {
                    let notification = notifications[indexPath.row]
                    visibleIDs.insert(notification.account.id)
                }
            }
        }
        preloadProfilesForIDs(Array(visibleIDs))
    }

    
    public func preloadProfiles(table: UITableView, statuses: [Status]) {
        var visibleStatuses: [Status] = []
        let visibleIndexPaths = table.indexPathsForVisibleRows
        if !visibleIndexPaths!.isEmpty {
            for indexPath in visibleIndexPaths! {
                if indexPath.row < statuses.count {
                    let stat = statuses[indexPath.row]
                    visibleStatuses.append(stat)
                }
            }
            preloadProfilesForStatuses(visibleStatuses)
        }
    }
    
    private func preloadProfilesForStatuses(_ statuses: [Status]) {
        // These are a set of posts that would like to have the account info
        // prefetched.
        //
        // However, for posts that are being reblogged, their post.account.id
        // may not be valid (for our user's server). In that case, do a search
        // on the user's server for a valid ID, and go from there.
        
        for status in statuses {
            if status.reblog != nil {
                self.preloadProfile(id: status.reblog?.account?.id ?? "")
            } else {
                self.preloadProfile(id: status.account?.id ?? "")
            }
        }
    }
    
    public func preloadProfilesForIDs(_ ids: [String]) {
        for id in ids {
            self.preloadProfile(id: id)
        }
    }

    private func preloadProfile(id: String) {
        // Exit if we already processed this request
        if preloadedIDs.contains(id) {
            return
        }

        guard let userAccount = AccountsManager.shared.currentUser() else { return }

        // Add this id since it's either already been cached, or will
        // shortly be cached.
        preloadedIDs.insert(id)

        log.debug("M_PROFILE_CACHE", "Request to preload profile for \(id)")

        DispatchQueue.global(qos: .utility).async {
            // See if we already have this account info.
            // If not, then prefetch it.

            // Exit if we already have the info on disk
            var accountOnDisk: Account? = nil
            do {
                let path = "profiles/" + id + "/otherUserPro.json"
                // print(#function + "searching path: " + path)
                accountOnDisk = try Disk.retrieve(path, from: .documents, as: Account.self)
                if accountOnDisk != nil {
                    log.debug("M_PROFILE_CACHE", "Found \(id) : \(accountOnDisk!.displayName) on disk!")
                }
            } catch {
                // log.debug("error trying to check cached info - \(error)")
            }

            if accountOnDisk == nil {
                // Kick off a cache request
                self.prefetchOtherUserData(id: id, userAccount: userAccount)
            }
        }
    }
    
    
    private func prefetchOtherUserData(id: String, userAccount: Account) {
        log.debug("M_PROFILE_CACHE", "Kicking off a network request for \(id)")
        let request = Accounts.account(id: id)
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let stat = (statuses.value) {
                DispatchQueue.main.async {
                    self.savePrefetchedOtherUserDataToDisk(id: id, account: stat)
                    self.prefetchRelation(id: id, userAccount: userAccount, profileAccount: stat)
                }
            } else {
                log.error(#function + " no account info from network request for id:\(id)")
            }
        }
    }
    
    // This is generally private, but… used by the SuggestionsViewController
    func savePrefetchedOtherUserDataToDisk(id: String, account: Account) {
        log.debug("M_PROFILE_CACHE", "Saving otherUserData to disk: \(id) \(account.username)")
        do {
            let path = "profiles/" + id + "/otherUserPro.json"
            try Disk.save(account, to: .documents, as: path)
        } catch {
            log.error("error saving prefetched account to Disk")
        }
    }

    private func prefetchRelation(id: String, userAccount: Account, profileAccount: Account) {
        let request0 = Accounts.relationships(ids: [id])
        AccountsManager.shared.currentAccountClient.run(request0) { (statuses) in
            if let stat = (statuses.value) {
                if stat.count > 0 {
                    DispatchQueue.main.async {
                        self.savePrefetchedRelationToDisk(userAccount: userAccount, profileAccount: profileAccount, relationship: stat[0])
                        self.prefetchAvatarAndHeader(id: id)
                    }
                }
            }
        }
    }

    private func savePrefetchedRelationToDisk(userAccount: Account, profileAccount: Account, relationship: Relationship) {
        log.debug("M_PROFILE_CACHE", "Saving relation to disk: \(profileAccount.username)")
        do {
            try Disk.save(relationship, to: .caches, as: "\(userAccount.fullAcct)/profiles/\(profileAccount.fullAcct)/relationshipPro.json")
        } catch {
            log.error("error saving prefetched account to Disk")
        }
    }
    
    private func prefetchAvatarAndHeader(id: String) {
        do {
            let account = try Disk.retrieve("profiles/\(id)/otherUserPro.json", from: .documents, as: Account.self)
            
            let avatar = account.avatar
            if avatar != "" {
                log.debug("M_PROFILE_CACHE", "Setting avatar URL for: \(id)")
                let imageView = UIImageView()
                prefetchImages.insert(imageView)
                imageView.sd_setImage(with: URL(string: avatar), completed: { image, error, cacheType, url in
                    // We can release the imageView now
                    self.prefetchImages.remove(imageView)
                    // Note - this is the last piece of loading the account, relation, and avatar.
                    // It's a good place to verify that the info all came through.
                    log.debug("M_PROFILE_CACHE", "Got account + relation + avatar for: \(account.username) - id: \(id)  account.id: \(account.id) !!!!")
                })
            }
            
            let header = account.header
            if header != "" {
                let imageView = UIImageView()
                prefetchImages.insert(imageView)
                imageView.sd_setImage(with: URL(string: header), completed: { image, error, cacheType, url in
                    self.prefetchImages.remove(imageView)
                })
            }
        } catch {
            log.error("error trying to load an account")
        }
    }
}
