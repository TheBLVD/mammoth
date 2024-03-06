//
//  ForYouCustomizationViewModel.swift
//  Mammoth
//
//  Created by Riley Howard on 10/2/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

struct ForYouRowInfo {
    let title: String
    let description: String
    let isOn: Bool
    let isEnabled: Bool
}

protocol ForYouCustomizationDelegate: AnyObject {
    func didUpdate(with state: ViewState)
    func didUpdateForYouAccountType(_ forYouAccountType: ForYouAccountType?)
    func shouldJoinWaitlist(completion: @escaping (_ join: Bool) -> Void)
}

class ForYouCustomizationViewModel {
            
    enum BetaStatus {
        case unknown
        case notSignedUp
        case onWaitlist
        case active
    }
    
    enum Section: Int {
        case mammothPicks
        case smartLists
        case beta
    }
    
    enum BetaItem: Int {
        case signUpForBeta
        case friendsOfFriends
        case trending
    }
    
    weak var delegate: ForYouCustomizationDelegate?

    private var state: ViewState {
        didSet {
            self.delegate?.didUpdate(with: state)
        }
    }
    
    private var serverForYouInfo: ForYouType? // Latest from the server
    private var updatedForYouInfo: ForYouType? { // Includes in-progress changes by the user
        didSet {
            self.delegate?.didUpdateForYouAccountType(updatedForYouInfo?.type)
        }
    }
    
    private var subscribedChannels: [Channel] = []
    
    private var showBetaSignUpRow: Bool {
        return self.betaStatus == .unknown || self.betaStatus == .notSignedUp
    }
    var betaStatus: BetaStatus {
        var betaStatus: BetaStatus = .unknown
        let aBetaSettingIsOn = self.updatedForYouInfo?.yourFollows == 1 || self.updatedForYouInfo?.friendsOfFriends == 1
        if self.updatedForYouInfo?.type == .personal {
            betaStatus = .active
        } else if self.updatedForYouInfo?.type == .waitlist ||
                 (self.updatedForYouInfo?.type == .public && aBetaSettingIsOn) {
            betaStatus = .onWaitlist
        } else if self.updatedForYouInfo?.type != nil {
            betaStatus = .notSignedUp
        } else {
            log.debug("unknown")
        }
        return betaStatus
    }
    
    init() {
        self.state = .idle
        self.subscribedChannels = ChannelManager.shared.subscribedChannels()
        self.serverForYouInfo = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.forYou.forYou
        self.updatedForYouInfo = self.serverForYouInfo
        NotificationCenter.default.addObserver(self, selector: #selector(self.onSubscribedChannelsDidChange), name: didChangeChannelsNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onForYouDidChange), name: didUpdateAccountForYou, object: nil)
        Task {
            await self.loadRecommendations()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - DataSource
extension ForYouCustomizationViewModel {
    func numberOfItems(forSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .mammothPicks:
            return 1
        case .smartLists:
            if updatedForYouInfo?.fromYourChannels == 0 {
                return 1
            } else {
                return self.subscribedChannels.count + 1
            }
        case .beta:
            var numRows = 2
            if self.showBetaSignUpRow {
                numRows = numRows+1
            }
            return numRows
        case .none:
            return 0
        }
    }
    
    var numberOfSections: Int {
        // Sections:
        //      - Mammoth Picks
        //      - Smart Lists
        //      - Beta
        return 2 // Was 3; we no longer show the beta features
    }
    
    func hasHeader(forSection sectionIndex: Int) -> Bool {
        switch Section(rawValue: sectionIndex) {
        case .mammothPicks:
            return true
        case .smartLists:
            return false
        case .beta:
            return true
        case .none:
            log.error("unexpected")
            return false
        }
    }

    func getSectionTitle(for sectionIndex: Int) -> String {
        switch Section(rawValue: sectionIndex) {
        case .mammothPicks:
            return NSLocalizedString("customize.title", comment: "")
        case .smartLists:
            return ""
        case .beta:
            if showBetaSignUpRow {
                return "Beta features - Toggle this on to join the waitlist"
            } else if betaStatus == .active {
                return "Beta features"
            } else {
                return "You're on the waitlist - We'll notify you when we have space"
            }
        case .none:
            log.error("unexpected")
            return ""
        }
    }

    func getInfo(forIndexPath indexPath: IndexPath) -> ForYouRowInfo? {
        var forYouRowInfo: ForYouRowInfo
        switch Section(rawValue: indexPath.section) {
        case .mammothPicks:
            let isOn = self.updatedForYouInfo?.curatedByMammoth == 1
            forYouRowInfo = ForYouRowInfo(title: NSLocalizedString("customize.mammothPicks.title", comment: ""), description: NSLocalizedString("customize.mammothPicks", comment: ""), isOn: isOn, isEnabled: true)
        case .smartLists:
            if indexPath.item == 0 {
                let isOn = self.updatedForYouInfo?.fromYourChannels == 1
                forYouRowInfo = ForYouRowInfo(title: NSLocalizedString("customize.smartLists.title", comment: ""), description: NSLocalizedString("customize.smartLists", comment: ""), isOn: isOn, isEnabled: true)
            } else {
                let subscribedChannel = self.subscribedChannels[indexPath.item-1]
                let isOn = self.updatedForYouInfo?.enabledChannelIDs.contains(subscribedChannel.id) ?? false
                forYouRowInfo = ForYouRowInfo(title: subscribedChannel.title, description: "", isOn: isOn, isEnabled: true)
            }
        case .beta:
            // three possible rows: sign up (0) / trending (1) / friends of friends (2)
            var index = indexPath.item
            if !showBetaSignUpRow {
               index = index + 1
            }
            switch BetaItem(rawValue: index) {
            case .signUpForBeta:
                forYouRowInfo = ForYouRowInfo(title: "Sign up for Beta features", description: "Get added to the waitlist for beta features", isOn: false, isEnabled: true)
            case .friendsOfFriends:
                forYouRowInfo = ForYouRowInfo(title: "Friends of friends", description: "People who follow similar accounts to you", isOn: self.updatedForYouInfo?.friendsOfFriends == 1, isEnabled: betaStatus == .active)
            case .trending:
                forYouRowInfo = ForYouRowInfo(title: "Trending among follows", description: "Trending posts from your Following feed", isOn: self.updatedForYouInfo?.yourFollows == 1, isEnabled: betaStatus == .active)
            case .none:
                log.error("unexpected")
                forYouRowInfo = ForYouRowInfo(title: "", description: "", isOn: false, isEnabled: false)
            }
        case .none:
            log.error("unexpected")
            forYouRowInfo = ForYouRowInfo(title: "", description: "", isOn: false, isEnabled: false)
        }
        return forYouRowInfo
    }
    
    func setForYouRowInfoOn(indexPath: IndexPath, value: Bool) {
        switch Section(rawValue: indexPath.section) {
        case .mammothPicks:
            updatedForYouInfo?.curatedByMammoth = value ? 1 : 0
            self.updateStatusFromForYouData(forYouInfo: updatedForYouInfo!)
        case .smartLists:
            if indexPath.item == 0 {
                updatedForYouInfo?.fromYourChannels = value ? 1 : 0
                self.updateStatusFromForYouData(forYouInfo: updatedForYouInfo!)
            } else {
                // Toggle a channel off/on
                let channel = subscribedChannels[indexPath.row-1]
                if value {
                    // add to enabled channels
                    var updatedChannelIDs = updatedForYouInfo?.enabledChannelIDs ?? []
                    updatedChannelIDs.append(channel.id)
                    updatedForYouInfo?.enabledChannelIDs = updatedChannelIDs
                } else {
                    // remove from enabled channels
                    var updatedChannelIDs = updatedForYouInfo?.enabledChannelIDs ?? []
                    updatedChannelIDs = updatedChannelIDs.filter({$0 != channel.id})
                    updatedForYouInfo?.enabledChannelIDs = updatedChannelIDs
                }
            }
        case .beta:
            var index = indexPath.item
            if !showBetaSignUpRow {
                index = index + 1
            }
            switch BetaItem(rawValue: index) {
            case .signUpForBeta:
                // User is wanting to join the waitlist
                delegate?.shouldJoinWaitlist(completion: { [weak self] shouldJoin in
                    guard let self else { return }
                    if shouldJoin {
                        // Enable Trending and FOAF
                        self.updatedForYouInfo?.yourFollows = 1
                        self.updatedForYouInfo?.friendsOfFriends = 1
                        log.debug("Adding to For You personalization waitlist")
                        if let currentUser = AccountsManager.shared.currentAccount?.remoteFullOriginalAcct {
                            FeaturesService.personalize(fullAccountName: currentUser)
                        }
                    } else {
                        self.updatedForYouInfo?.yourFollows = 0
                        self.updatedForYouInfo?.friendsOfFriends = 0
                    }
                })
            case .trending:
                updatedForYouInfo?.yourFollows = value ? 1 : 0
            case .friendsOfFriends:
                updatedForYouInfo?.friendsOfFriends = value ? 1 : 0
            case .none:
                log.error("unexpected")
            }
        case .none:
            log.error("unexpected")
        }
    }
}

// MARK: - Service
extension ForYouCustomizationViewModel {
    func loadRecommendations() async {
        DispatchQueue.main.async {
            self.state = .loading
        }
        
        // Get the ForYou settings for this account (this may trigger an update)
        guard let mastodonAcctData = AccountsManager.shared.currentAccount as? MastodonAcctData else {
            log.error("unexpected account type")
            return
        }
        
        updateStatusFromAccountData(mastodonAcctData)
    }
    
    func updateStatusFromAccountData(_ mastodonAcctData: MastodonAcctData) {
        self.serverForYouInfo = mastodonAcctData.forYou.forYou
        updateStatusFromForYouData(forYouInfo: mastodonAcctData.forYou.forYou)
    }
        
    func updateStatusFromForYouData(forYouInfo: ForYouType) {
        // Convert the For You data to a ForYouRowInfo array
        log.debug("For You - yourFollows:\(forYouInfo.yourFollows) friendsOfFriends:\(forYouInfo.friendsOfFriends) fromYourChannels:\(forYouInfo.fromYourChannels) curatedByMammoth:\(forYouInfo.curatedByMammoth)")

        // Update the UI
        DispatchQueue.main.async {
            self.updatedForYouInfo = forYouInfo
            self.state = .success
        }
    }
    
    func canSendSettingsToServer() -> Bool {
        let curatedOn = self.updatedForYouInfo?.curatedByMammoth != 0
        let channelOn = self.updatedForYouInfo?.fromYourChannels != 0
        let friendsOn = self.updatedForYouInfo?.yourFollows != 0
        let foafOn = self.updatedForYouInfo?.friendsOfFriends != 0
        let betaActive = betaStatus == .active
        // Validate that at least one switch is on and valid
        return curatedOn ||
               channelOn ||
               (betaActive && (friendsOn || foafOn))
    }
    
    func sendSettingsToServer() {
        // Since we write out the settings, it will trigger an update notification.
        // No need to observer it any longer.
//        NotificationCenter.default.removeObserver(self, name: didUpdateAccountForYou, object: nil)
        
        // If the values have changed, notify instance of new settings
        let somethingChanged = (serverForYouInfo != updatedForYouInfo)
        if somethingChanged, let updatedForYouInfo {
            AccountsManager.shared.updateCurrentAccountForYou(updatedForYouInfo)
        }
    }
}

// MARK: - Notification handlers
private extension ForYouCustomizationViewModel {
    @objc func onSubscribedChannelsDidChange(notification: Notification) {
        DispatchQueue.main.async {
            self.subscribedChannels = ChannelManager.shared.subscribedChannels()
            self.delegate?.didUpdate(with: self.state)
        }
    }
    
    @objc func onForYouDidChange(notification: Notification) {
        // Get the updated account info
        let mastodonAcctData = notification.userInfo!["account"] as! MastodonAcctData
        DispatchQueue.main.async {
            self.state = .loading
            self.updateStatusFromAccountData(mastodonAcctData)
        }
    }
}

