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
    private var userDefaults = UserDefaults.standard

    init() {

    }

    public func saveSyncStatus(for type: NewsFeedTypes, uniqueId: String) {
        syncDebouncer?.invalidate()
        syncDebouncer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.setSyncStatus(for: type, uniqueId: uniqueId)
        }
    }

    public func cloudSavedPostId(for type: NewsFeedTypes) -> String? {
        let (itemKey, dateKey) = keys(for: type)
        guard !itemKey.isEmpty, !dateKey.isEmpty else { return nil }

        guard let localDate: Date = userDefaults.object(forKey: dateKey) as? Date else { return nil }
        guard let cloudDate: Date = cloudStore.object(forKey: dateKey) as? Date else { return nil }

        if cloudDate.timeIntervalSince1970 <= localDate.timeIntervalSince1970 {
            // local values are newer than the cloud
            return nil
        }

        if let postId = cloudStore.string(forKey: itemKey) {
            return postId
        } else {
            return nil
        }
    }

    private func setSyncStatus(for type: NewsFeedTypes, uniqueId: String) {
        let (itemKey, dateKey) = keys(for: type)
        guard !itemKey.isEmpty, !dateKey.isEmpty else { return }

        let syncDate = Date()
        cloudStore.set(uniqueId, forKey: itemKey)
        cloudStore.set(syncDate, forKey: dateKey)
        cloudStore.synchronize()

        // testing idea of matching last saved id in user defaults and comparing last saved time
        userDefaults.set(uniqueId, forKey: itemKey)
        userDefaults.set(syncDate, forKey: dateKey)
        userDefaults.synchronize()
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

    private func typeFor(key: String) -> NewsFeedTypes {
        switch key {
        case CloudSyncConstants.Keys.kLastFollowingSyncId:
            return .following
        case CloudSyncConstants.Keys.kLastForYouSyncId:
            return .forYou
        case CloudSyncConstants.Keys.kLastFederatedSyncId:
            return .federated
        case CloudSyncConstants.Keys.kLastMentionsInSyncId:
            return .mentionsIn
        case CloudSyncConstants.Keys.kLastMentionsOutSyncId:
            return .mentionsOut
        default:
            return .activity(nil) // unsupported type
        }

    }
}
