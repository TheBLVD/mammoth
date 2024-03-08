//
//  ChannelsViewModel.swift
//  Mammoth
//
//  Created by Riley Howard on 8/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

protocol ChannelsViewModelDelegate: AnyObject {
    func didUpdate(with state: ViewState)
}


class ChannelsViewModel {
            
    weak var delegate: ChannelsViewModelDelegate?
    
    private var state: ViewState {
        didSet {
            self.delegate?.didUpdate(with: state)
        }
    }
    private struct ListData {
        var matchingChannels: [Channel]?
        var moreChannels: [Channel]?
    }

    private var singleSection = false // Force all channels into a single section
    private var allChannels: [Channel] = []
    private var listData = ListData()
    private var searchQuery: String = "" {
        didSet {
            if searchQuery.isEmpty {
                // TODO: make class vars thread-safe instead
                DispatchQueue.main.async {
                    self.listData.matchingChannels = []
                    self.listData.moreChannels = self.allChannels
                    self.state = .success
                }
            } else {
                Task {
                    await self.searchAll(query: self.searchQuery)
                }
            }
        }
    }

    init(singleSection: Bool = false) {
        self.singleSection = singleSection
        self.state = .idle
                
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didSwitchAccount),
                                               name: didSwitchCurrentAccountNotification,
                                               object: nil)
                                
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.appDidBecomeActive),
                                               name: appDidBecomeActiveNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.allChannelsDidChange), name: didChangeChannelsNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.channelStatusDidChange), name: didChangeChannelStatusNotification, object: nil)

        Task {
            await self.loadRecommendations()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - DataSource
extension ChannelsViewModel {
    
    func listDataForSection(_ section: Int) -> [Channel] {
        var listDataForSection: [Channel] = []
        if singleSection {
            listDataForSection = allChannels
        } else if section == 0 {
            listDataForSection = listData.matchingChannels ?? []
        } else if section == 1 {
            listDataForSection = listData.moreChannels ?? []
        }
        return listDataForSection
    }
    
    func numberOfItems(forSection section: Int) -> Int {
        return listDataForSection(section).count
    }
    
    var numberOfSections: Int {
        if singleSection {
            return 1
        } else {
            return 2
        }
    }
    
    func hasHeader(forSection sectionIndex: Int) -> Bool {
        return !singleSection
    }

    func getInfo(forIndexPath indexPath: IndexPath) -> (Channel?, Bool)? {
        let listDataForSection = listDataForSection(indexPath.section)

        var channel: Channel? = nil
        var showAsSubscribed = false
        if listDataForSection.count > indexPath.row {
            channel = listDataForSection[indexPath.row]
        }
        if let channel {
            let channelStatus = ChannelManager.shared.subscriptionStatusForChannel(channel)
            showAsSubscribed = (channelStatus == .subscribeRequested || channelStatus == .subscribed)
        }
        return (channel, showAsSubscribed)
    }
    
    func getSectionTitle(for sectionIndex: Int) -> String {
        switch(sectionIndex) {
        case 0:
            return NSLocalizedString("discover.matchingSL", comment: "")
        case 1:
            return NSLocalizedString("discover.moreSL", comment: "")
        default:
            return ""
        }
    }

    
}

// MARK: - Service
extension ChannelsViewModel {
    func loadRecommendations() async {
        self.state = .loading
        let channels = ChannelManager.shared.allChannels()
        DispatchQueue.main.async {
            self.allChannels = channels
            self.listData.matchingChannels = []
            self.listData.moreChannels = self.allChannels
            self.state = .success
        }
    }
    
    func search(query: String, fullSearch: Bool = false) {
        // Filter out channels based on the query
        self.searchQuery = query
    }
    
    // Actually do the searching/filtering here
    func searchAll(query: String) async {
        self.state = .loading
        let filteredResults = self.allChannels.filter { channel in
            return channel.title.localizedCaseInsensitiveContains(query) ||
                   channel.description.localizedCaseInsensitiveContains(query)
        }
                    
        // TODO: make class vars thread-safe instead
        DispatchQueue.main.async {
            self.listData.matchingChannels = filteredResults
            self.listData.moreChannels = self.allChannels.filter({ !(self.listData.matchingChannels?.contains($0) ?? false)})
            self.state = .success
        }
    }

    
    func cancelSearch() {
        self.searchQuery = ""
    }

}

// MARK: - Notification handlers
private extension ChannelsViewModel {
    
    @objc func channelStatusDidChange(notification: Notification) {
        let acctData = notification.userInfo?["account"] as? any AcctDataType
        if acctData == nil || acctData?.uniqueID == AccountsManager.shared.currentAccount?.uniqueID {
            DispatchQueue.main.async {
                self.delegate?.didUpdate(with: self.state)
            }
        }
    }
    
    @objc func allChannelsDidChange() {
        Task {
            // Reload recommentations when all channels change
            await self.loadRecommendations()
        }
    }
    
    
    @objc func didSwitchAccount() {
        Task {
            // Reload recommentations when a user is set/changed
            await self.loadRecommendations()
        }
    }
    
    @objc func appDidBecomeActive() {
        Task {
            // Load recommentations when app is active
            await self.loadRecommendations()
        }
     }
        
}
