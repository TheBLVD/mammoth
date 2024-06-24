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
        static let kLastFollowingSyncId = "com.theblvd.mammoth.icloud.following.syncid"
        static let kLastForYouSyncDate = "com.theblvd.mammoth.icloud.foryou.lastsync"
        static let kLastForYouSyncId = "com.theblvd.mammoth.icloud.foryou.syncid"
        static let kLastFederatedSyncDate = "com.theblvd.mammoth.icloud.federated.lastsync"
        static let kLastFederatedSyncId = "com.theblvd.mammoth.icloud.federated.syncid"
        static let kLastMentionsInSyncDate = "com.theblvd.mammoth.icloud.mentionsIn.lastsync"
        static let kLastMentionsInSyncId = "com.theblvd.mammoth.icloud.mentionsIn.syncid"
        static let kLastMentionsOutSyncDate = "com.theblvd.mammoth.icloud.mentionsOut.lastsync"
        static let kLastMentionsOutSyncId = "com.theblvd.mammoth.icloud.mentionsOut.syncid"
    }
}

class CloudSyncManager {
    static let sharedManager = CloudSyncManager()
    private var syncDebouncer: Timer?
    private var cloudStore = NSUbiquitousKeyValueStore.default

    init() {
        // monitor for changes to cloud sync data
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangeExternally), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
    }

    @objc func didChangeExternally(notification: Notification) {
        if let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] {
            print("keys changed: \(keys)")
        }
    }

    public func saveSyncStatus(for type: NewsFeedTypes, uniqueId: String) {
        syncDebouncer?.invalidate()
        syncDebouncer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
            self?.setSyncStatus(for: type, uniqueId: uniqueId)
        }
    }

    private func setSyncStatus(for type: NewsFeedTypes, uniqueId: String) {
        let (itemKey, dateKey) = keys(for: type)
        guard !itemKey.isEmpty, !dateKey.isEmpty else { return }

        cloudStore.set(uniqueId, forKey: itemKey)
        cloudStore.set(Date(), forKey: dateKey)
        cloudStore.synchronize()
    }

    private func keys(for type: NewsFeedTypes) -> (itemKey: String, dateKey: String) {
        switch type {
        case .following:
            return (CloudSyncConstants.Keys.kLastFollowingSyncId, CloudSyncConstants.Keys.kLastFollowingSyncDate)
        case .forYou:
            return (CloudSyncConstants.Keys.kLastForYouSyncId, CloudSyncConstants.Keys.kLastForYouSyncDate)
        case .federated:
            return (CloudSyncConstants.Keys.kLastFederatedSyncId, CloudSyncConstants.Keys.kLastFederatedSyncDate)
        case .mentionsIn:
            return (CloudSyncConstants.Keys.kLastMentionsInSyncId, CloudSyncConstants.Keys.kLastMentionsInSyncDate)
        case .mentionsOut:
            return (CloudSyncConstants.Keys.kLastMentionsOutSyncId, CloudSyncConstants.Keys.kLastMentionsOutSyncDate)
        default:
            return ("", "")
        }
    }
}
