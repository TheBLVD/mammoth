//
//  SetupChannelsViewModel.swift
//  Mammoth
//
//  Created by Riley Howard on 10/9/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

protocol SetupChannelsViewModelDelegate: AnyObject {
    func didUpdate(with state: ViewState)
}


class SetupChannelsViewModel {

    static let shared = SetupChannelsViewModel()
    static func preload() {
        _ = self.shared
    }
    
    weak var delegate: SetupChannelsViewModelDelegate? {
        didSet {
            self.delegate?.didUpdate(with: state)
        }
    }
    
    private var state: ViewState {
        didSet {
            self.delegate?.didUpdate(with: state)
        }
    }

    // Keep the News channel separate;
    // we will auto-subscribe the user  to that
    // one, and not show it in the list.
    var newsChannel: Channel? = nil
    private var visibleChannels: [Channel] = []

    init(singleSection: Bool = false) {
        self.state = .loading
                        
        NotificationCenter.default.addObserver(self, selector: #selector(self.allChannelsDidChange), name: didChangeChannelsNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.channelStatusDidChange), name: didChangeChannelStatusNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didUpdateAccountFY), name: didUpdateAccountForYou, object: nil)

        Task {
            await self.loadAllChannels()
            await self.loadSubscribedChannels()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - DataSource
extension SetupChannelsViewModel {
        
    func numberOfItems(forSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return visibleChannels.count
        }
    }
    
    var numberOfSections: Int {
        return 2
    }
    
    func hasHeader(forSection sectionIndex: Int) -> Bool {
        return false
    }

    func getInfo(forIndexPath indexPath: IndexPath) -> (Channel?, Bool)? {
        var channel: Channel? = nil
        var showAsSubscribed = false
        if visibleChannels.count > indexPath.row {
            channel = visibleChannels[indexPath.row]
        }
        if let channel {
            let channelStatus = ChannelManager.shared.subscriptionStatusForChannel(channel)
            showAsSubscribed = (channelStatus == .subscribeRequested || channelStatus == .subscribed)
        }
        return (channel, showAsSubscribed)
    }
    
    func getSectionTitle(for sectionIndex: Int) -> String {
        if sectionIndex == 1 {
            return NSLocalizedString("discover.smartLists", comment: "")
        } else {
            return ""
        }
    }

    
}

// MARK: - Service
extension SetupChannelsViewModel {
    func loadAllChannels() async {
        self.state = .loading
        let allChannels = ChannelManager.shared.allChannels()
        let newsChannel = allChannels.first(where: { channel in
            channel.id == "f222deba-7fcb-49b9-be23-c32da1982d2b" // News channel ID
        })
        let allButNewsChannel = allChannels.filter({ $0 != newsChannel } )
        DispatchQueue.main.async {
            self.newsChannel = newsChannel
            self.visibleChannels = allButNewsChannel
            self.state = .success
        }
    }
    
    func loadSubscribedChannels() async {
        // Make sure we know what channels the user is subscribed to
        AccountsManager.shared.updateCurrentAccountForYouFromNetwork()
    }
}

// MARK: - Notification handlers
private extension SetupChannelsViewModel {
    
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
            await self.loadAllChannels()
        }
    }
    
    @objc func didUpdateAccountFY() {
        // Force delegate to reload
        self.delegate?.didUpdate(with: state)
    }
      
}
