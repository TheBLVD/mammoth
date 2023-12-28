//
//  InstanceManager.swift
//  Mammoth
//
//  Created by Riley Howard on 9/14/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

public let didChangePinnedInstancesNotification = Notification.Name("didChangePinnedInstancesNotification") // list of un/subscribed Instances changed
public let didChangeAllInstancesNotification = Notification.Name("didChangeAllInstancesNotification") // list of possible Instances changed

class InstanceManager {
    
    static let shared = InstanceManager()
    
    enum InstanceStatus: String {
        case notPinned           // default (not subscribed)
        case pinned              // am subscribed
    }
    
    var allInstances: [tagInstance] = []
    var pinnedInstances: [String] = [] { // subscribed to
        didSet {
            NotificationCenter.default.post(name: didChangePinnedInstancesNotification, object: self, userInfo: nil)
        }
    }
    
    public init() {
        // Listen to account switch, and update the list of channels accordingly
        NotificationCenter.default.addObserver(self, selector: #selector(self.didSwitchAccount), name: didSwitchCurrentAccountNotification, object: nil)
                
        // Get all possible instances
        Task {
            let allInstances = await InstanceService.allInstances()
            DispatchQueue.main.async {
                self.allInstances = allInstances
                NotificationCenter.default.post(name: didChangeAllInstancesNotification, object: self, userInfo: nil)
            }
        }
        // Get channels for current user
        self.updateUserInstances()
    }
    
    public func prepareForUse() {}
    

    @objc func didSwitchAccount() {
        self.updateUserInstances()
    }
    
    @objc func onForYouDidChange() {
        updateUserInstances()
    }

    private func updateUserInstances() {
        pinnedInstances = []
        let currentAccount = AccountsManager.shared.currentAccount
        do {
            pinnedInstances = try Disk.retrieve("\(currentAccount?.diskFolderName() ?? "")/instances.json", from: .documents, as: [String].self)
        } catch {
            // unable to find subscribed instances file on disk
        }
    }
    
    public func setPinnedInstances(instances: [String], forAccount account: any AcctDataType) {
        if let acctData = account as? MastodonAcctData {
            do {
                try Disk.save(instances, to: .documents, as: "\(acctData.diskFolderName())/instances.json")
            } catch {
                log.error("unable to migrate instances: \(error)")
            }
        }
        if AccountsManager.shared.currentAccount?.uniqueID == account.uniqueID {
            log.debug("reloading users instances")
            updateUserInstances()
        }
    }
    
}


// Public APIs
extension InstanceManager {
        
    public func pinnedStatusForInstance(_ instanceName: String) -> InstanceStatus {
        if pinnedInstances.contains(instanceName) {
            return .pinned
        } else {
            return .notPinned
        }
    }

    public func pinInstance(_ instanceName: String) {
        pinnedInstances.append(instanceName)
        do {
            if let currentAccount = AccountsManager.shared.currentAccount {
                try Disk.save(pinnedInstances, to: .documents, as: "\(currentAccount.diskFolderName())/instances.json")
            }
        } catch {
            log.error("unable to pin instance \(instanceName): \(error)")
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: didChangePinnedInstancesNotification, object: self, userInfo: ["InstanceName" : instanceName])
        }
    }

    public func unpinInstance(_ instanceName: String) {
        pinnedInstances.removeAll { anInstance in
            anInstance == instanceName
        }
        do {
            if let currentAccount = AccountsManager.shared.currentAccount {
                try Disk.save(pinnedInstances, to: .documents, as: "\(currentAccount.diskFolderName())/instances.json")
            }
        } catch {
            log.error("unable to unpin instance \(instanceName): \(error)")
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: didChangePinnedInstancesNotification, object: self, userInfo: ["InstanceName" : instanceName])
        }
    }

    public func clearCache() {
        let currentAccount = AccountsManager.shared.currentAccount
        do {
            try Disk.remove("\(currentAccount?.diskFolderName() ?? "")/instances.json", from: .documents)
        } catch {
            log.error("error clearing instances cache: \(error)")
        }
        updateUserInstances()
    }

}


