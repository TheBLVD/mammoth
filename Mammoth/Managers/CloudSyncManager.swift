//
//  CloudSyncManager.swift
//  Mammoth
//
//  Created by Bill Burgess on 6/21/24
//  Copyright © 2024 The BLVD. All rights reserved.
//

struct CloudSyncConstants {
    struct Keys {
        static let kLastFollowingSyncDate = "com.theblvd.mammoth.icloud.following.lastsync"
        static let kLastFollowingSyncID = "com.theblvd.mammoth.icloud.following.syncid"
        static let kLastForYouSyncDate = "com.theblvd.mammoth.icloud.foryou.lastsync"
        static let kLastForYouSyncID = "com.theblvd.mammoth.icloud.foryou.syncid"
        static let kLastFederatedSyncDate = "com.theblvd.mammoth.icloud.federated.lastsync"
        static let kLastFederatedSyncID = "com.theblvd.mammoth.icloud.federated.syncid"
        static let kLastMentionsInSyncDate = "com.theblvd.mammoth.icloud.mentionsIn.lastsync"
        static let kLastMentionsInSyncID = "com.theblvd.mammoth.icloud.mentionsIn.syncid"
        static let kLastMentionsOutSyncDate = "com.theblvd.mammoth.icloud.mentionsOut.lastsync"
        static let kLastMentionsOutSyncID = "com.theblvd.mammoth.icloud.mentionsOut.syncid"
    }
}

class CloudSyncManager {
    static let sharedManager = CloudSyncManager()
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()
    private var syncDebouncer: Timer?
    private var cloudStore = NSUbiquitousKeyValueStore.default
    private var userDefaults = UserDefaults.standard

    init() {

    }

    public func saveSyncStatus(for type: NewsFeedTypes, scrollPosition: NewsFeedScrollPosition) {
        syncDebouncer?.invalidate()
        syncDebouncer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.setSyncStatus(for: type, scrollPosition: scrollPosition)
        }
    }

    public func cloudSavedPosition(for type: NewsFeedTypes) -> NewsFeedScrollPosition? {
        let (itemKey, dateKey) = keys(for: type)
        
        guard !itemKey.isEmpty, !dateKey.isEmpty else { return nil }
        
        if let scrollPositionJSON = cloudStore.data(forKey: itemKey) {
            do {
                let scrollPosition = try jsonDecoder.decode(NewsFeedScrollPosition.self, from: scrollPositionJSON)
                return scrollPosition
            } catch {
                log.error("Failed to decode object: \(error)")
            }
        }
        log.debug("iCloud Sync: No saved conditions satisfied, providing nil sync position")
        return nil
    }

    private func setSyncStatus(for type: NewsFeedTypes, scrollPosition: NewsFeedScrollPosition) {
        let (itemKey, dateKey) = keys(for: type)
        guard !itemKey.isEmpty, !dateKey.isEmpty else { return }
        
        do {
            let scrollPositionJSON = try jsonEncoder.encode(scrollPosition)
            let syncDate = Date()
            cloudStore.set(scrollPositionJSON, forKey: itemKey)
            cloudStore.set(syncDate, forKey: dateKey)
            cloudStore.synchronize()
            log.debug("iCloud Sync: Synced \(type.title()) position at \(syncDate)")
        } catch {
            log.error("Failed to encode object: \(error)")
        }
    }

    private func keys(for type: NewsFeedTypes) -> (itemKey: String, dateKey: String) {
        // NB: We don't want to bake the "." into the sync ID lets because of matching elsewhere
        switch type {
        case .following:
            return (CloudSyncConstants.Keys.kLastFollowingSyncID + "." + (AccountsManager.shared.currentAccount?.fullAcct ?? ""), CloudSyncConstants.Keys.kLastFollowingSyncDate + "." + (AccountsManager.shared.currentAccount?.fullAcct ?? ""))
        case .forYou:
            return (CloudSyncConstants.Keys.kLastForYouSyncID + "." + (AccountsManager.shared.currentAccount?.fullAcct ?? ""), CloudSyncConstants.Keys.kLastForYouSyncDate + "." + (AccountsManager.shared.currentAccount?.fullAcct ?? ""))
        case .federated:
            return (CloudSyncConstants.Keys.kLastFederatedSyncID + "." + (AccountsManager.shared.currentAccount?.fullAcct ?? ""), CloudSyncConstants.Keys.kLastFederatedSyncDate + "." + (AccountsManager.shared.currentAccount?.fullAcct ?? ""))
        case .mentionsIn:
            return (CloudSyncConstants.Keys.kLastMentionsInSyncID + "." + (AccountsManager.shared.currentAccount?.fullAcct ?? ""), CloudSyncConstants.Keys.kLastMentionsInSyncDate + "." + (AccountsManager.shared.currentAccount?.fullAcct ?? ""))
        case .mentionsOut:
            return (CloudSyncConstants.Keys.kLastMentionsOutSyncID + "." + (AccountsManager.shared.currentAccount?.fullAcct ?? ""), CloudSyncConstants.Keys.kLastMentionsOutSyncDate + "." + (AccountsManager.shared.currentAccount?.fullAcct ?? ""))
        default:
            return ("", "")
        }
    }

    private func typeFor(key: String) -> NewsFeedTypes {
        switch key {
        case let string where string.contains(CloudSyncConstants.Keys.kLastFollowingSyncID):
            return .following
        case let string where string.contains(CloudSyncConstants.Keys.kLastForYouSyncID):
            return .forYou
        case let string where string.contains(CloudSyncConstants.Keys.kLastFederatedSyncID):
            return .federated
        case let string where string.contains(CloudSyncConstants.Keys.kLastMentionsInSyncID):
            return .mentionsIn
        case let string where string.contains(CloudSyncConstants.Keys.kLastMentionsOutSyncID):
            return .mentionsOut
        default:
            return .activity(nil) // unsupported type
        }

    }
}
