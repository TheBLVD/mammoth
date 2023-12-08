//
//  InstancesViewModel.swift
//  Mammoth
//
//  Created by Riley Howard on 9/13/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class InstancesViewModel {
            
    weak var delegate: RequestDelegate?

    private var state: ViewState {
        didSet {
            self.delegate?.didUpdate(with: state)
        }
    }
    
    private var listData: [InstanceCardModel] = []
    
    init() {
        self.state = .idle
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.allInstancesDidChange),
                                               name: didChangeAllInstancesNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.pinnedInstancesDidChange),
                                               name: didChangePinnedInstancesNotification,
                                               object: nil)
        Task {
            await self.loadRecommendations()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - DataSource
extension InstancesViewModel {
    func numberOfItems(forSection section: Int) -> Int {
        return self.listData.count
    }
    
    var numberOfSections: Int {
        return 1
    }
    
    func hasHeader(forSection sectionIndex: Int) -> Bool {
        return false
    }

    func getInfo(forIndexPath indexPath: IndexPath) -> InstanceCardModel? {
        guard listData.count != 0 else {
            return nil
        }
        return self.listData[indexPath.row]
    }
    
}

// MARK: - Service
extension InstancesViewModel {
    func loadRecommendations() async {
        self.listData = []
        self.state = .loading
    }
    
    func search(query: String, fullSearch: Bool = false) {
        if fullSearch {
            self.searchAll(query: query)
        }
    }
    
    // Actually do the searching/filtering here
    func searchAll(query: String) {
        self.listData = []
        self.state = .loading
        Task {
            let searchResults = await InstanceService.searchForInstances(query: query).map({ InstanceCardModel(instance:$0) })
            DispatchQueue.main.async {
                self.listData = searchResults
                self.state = .success
            }
        }
    }

    
    func cancelSearch() {
    }

}

// MARK: - Notification handlers
private extension InstancesViewModel {
        
    @objc func allInstancesDidChange(notification: Notification) {
        Task {
            await self.loadRecommendations()
        }
    }
    
    @objc func pinnedInstancesDidChange(notification: Notification) {
        if let instanceName = notification.userInfo?["InstanceName"] as? String, let index = updatePinnedInstanceNamed(instanceName) {
            self.delegate?.didUpdateCard(at: IndexPath(row: index, section: 0))
        }
    }
    
    func updatePinnedInstanceNamed(_ instanceName: String) -> Int? {
        // Update both allInstances and listData
        var updatedInstance: InstanceCardModel
        if let allInstancesIndex = self.listData.firstIndex(where: { tagInstance in
            tagInstance.name == instanceName
        }) {
            updatedInstance = self.listData[allInstancesIndex]
            updatedInstance.isPinned = InstanceManager.shared.pinnedStatusForInstance(instanceName) == .pinned
            self.listData[allInstancesIndex] = updatedInstance
        }
        
        let listDataIndex = listData.firstIndex(where: { tagInstance in
            tagInstance.name == instanceName
        })
        if listDataIndex != nil {
            updatedInstance = listData[listDataIndex!]
            updatedInstance.isPinned = InstanceManager.shared.pinnedStatusForInstance(instanceName) == .pinned
            listData[listDataIndex!] = updatedInstance
        }

        // Return index of listData
        return listDataIndex
    }
    
}
