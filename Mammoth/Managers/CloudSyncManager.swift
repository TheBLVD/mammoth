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
        
        log.debug("SYNC: itemKey: \(itemKey) dateKey \(dateKey)")
        
        guard !itemKey.isEmpty, !dateKey.isEmpty else { return nil }

        /*guard let localDate: Date = userDefaults.object(forKey: dateKey) as? Date else { return nil }
        guard let cloudDate: Date = cloudStore.object(forKey: dateKey) as? Date else { return nil }

        if cloudDate.timeIntervalSince1970 <= localDate.timeIntervalSince1970 {
            // local values are newer than the cloud
            return nil
        }*/
        
        if let scrollPositionJSON = cloudStore.data(forKey: itemKey) {
            do {
                let scrollPosition = try jsonDecoder.decode(NewsFeedScrollPosition.self, from: scrollPositionJSON)
                log.debug("SYNC: decoded NewsFeedScrollPosition offset: \(scrollPosition.offset)")
                return scrollPosition
            } catch {
                log.error("Failed to decode object: \(error)")
            }
        }
        
        /*guard let scrollPosition = cloudStore.object(forKey: itemKey) as? NewsFeedScrollPosition else {
            log.debug("SYNC: scrollPosition decode failed")
            return nil
        }
        log.debug("SYNC: scrollPosition decoded \(scrollPosition)")
        return scrollPosition*/
        
        /*let newsFeedScrollPosition = NewsFeedScrollPosition(model: <#T##NewsFeedListItem?#>, offset: <#T##Double#>)
        if  {
            log.debug("SYNC: get: \(scrollPosition) for \(type)")
            return scrollPosition
        } else {*/
            return nil
        //}
    }

    private func setSyncStatus(for type: NewsFeedTypes, scrollPosition: NewsFeedScrollPosition) {
        let (itemKey, dateKey) = keys(for: type)
        guard !itemKey.isEmpty, !dateKey.isEmpty else { return }
        
        do {
            let scrollPositionJSON = try jsonEncoder.encode(scrollPosition)
            
            let syncDate = Date()
            cloudStore.set(scrollPositionJSON, forKey: itemKey)
            log.debug("SYNC: setScrollPosition: \(itemKey): \(scrollPositionJSON)")
            cloudStore.set(syncDate, forKey: dateKey)
            log.debug("SYNC: setDate: \(dateKey): \(syncDate)")
            cloudStore.synchronize()
        } catch {
            log.error("Failed to encode object: \(error)")
        }

        // testing idea of matching last saved id in user defaults and comparing last saved time
        /*userDefaults.set(uniqueId, forKey: itemKey)
        userDefaults.set(syncDate, forKey: dateKey)
        userDefaults.synchronize()*/
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
