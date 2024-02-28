//
//  DiscoverSuggestionsViewModel.swift
//  Mammoth
//
//  Created by Riley Howard on 9/25/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation


protocol DiscoverySuggestionsDelegate: AnyObject {
    func didUpdateAll()
    func didUpdateSection(section: DiscoverSuggestionsViewModel.DiscoverySuggestionSection, with state: ViewState)
    func didUpdateCard(at indexPath: IndexPath)
    func didDeleteCard(at indexPath: IndexPath)
}


class DiscoverSuggestionsViewModel {
    
    enum DiscoverySuggestionSection: Int {
        case channel
        case hashtag
        case account
    }
    
    private struct ListData {
        var channels: [Channel]?
        var hashtags: [Tag]?
        var accounts: [UserCardModel]?
    }

    enum ListDataReturn {
        case channel(Channel?)
        case hashtag(Tag?)
        case account(UserCardModel?)
    }

    let DefaultNumberOfChannels = 3
    let DefaultNumberOfHashtags = 2
    
    // Data displayed to the user (may be filtered)
    private var listData: ListData = ListData()
    // Full list of underlying data
    private var allChannels: [Channel] = []
    private(set) var allTrendingHashtags: [Tag] = []
    private var allSuggestedAccounts: [UserCardModel] = []
    
    private var searchAccountsTask: Task<Void, Never>?
    private var postSyncingTasks: [IndexPath: Task<Void, Error>] = [:]
    
    private var states: [ViewState] = [ .loading, .loading, .loading] {
        didSet {
            let changedSections = zip(states, oldValue).map{$0 != $1}.enumerated().filter{$1}.map{$0.0}
            let changedSectionIndex = changedSections[0]
            let changedSection = DiscoverSuggestionsViewModel.DiscoverySuggestionSection(rawValue: changedSectionIndex)!
            let viewState = states[changedSectionIndex]
            self.delegate?.didUpdateSection(section: changedSection, with: viewState)
        }
    }
    
    weak var delegate: DiscoverySuggestionsDelegate?
    var showSummaryCells = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.delegate?.didUpdateAll()
            }
        }
    }
    
    private var searchQuery: String? = nil {
        didSet {
            updateContentFromSearchQuery()
        }
    }

    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didSwitchAccount),
                                               name: didSwitchCurrentAccountNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.allChannelsDidChange), name: didChangeChannelsNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.channelStatusDidChange), name: didChangeChannelStatusNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.hashtagStatusDidChange), name: didChangeHashtagsNotification, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onStatusUpdate),
                                               name: didChangeFollowStatusNotification,
                                               object: nil)

        Task { [weak self] in
            guard let self else { return }
            await self.loadRecommendations()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

extension DiscoverSuggestionsViewModel {
    func numberOfItems(forSection section: Int) -> Int {
        switch(section) {
        case 0:
            return self.listData.channels?.count ?? 0
        case 1:
            return self.listData.hashtags?.count ?? 0
        case 2:
            return self.listData.accounts?.count ?? 0
        default:
            return 0
        }
    }
    
    var numberOfSections: Int {
        return 3
    }
    
    func hasHeader(forSection sectionIndex: Int) -> Bool {
        return numberOfItems(forSection: sectionIndex) > 0
    }
    
    func getInfo(forIndexPath indexPath: IndexPath) -> ListDataReturn {
        switch(indexPath.section) {
        case 0:
            return .channel(self.listData.channels?[indexPath.row])
        case 1:
            return .hashtag(self.listData.hashtags?[indexPath.row])
        case 2:
            var userCardModel = self.listData.accounts?[indexPath.row]
            if !(searchQuery?.isEmpty ?? true) {
                userCardModel = userCardModel?.simple()
            }
            return .account(userCardModel)
        default:
            log.error("unexpected index for getInfo")
            return .channel(self.listData.channels?[indexPath.row])
        }
    }
    
    func getSectionTitle(for sectionIndex: Int) -> String {
        switch(sectionIndex) {
        case 0:
            return NSLocalizedString("discover.smartLists", comment: "")
        case 1:
            return NSLocalizedString("discover.trendingHashtags", comment: "")
        case 2:
            if searchQuery?.isEmpty ?? true {
                return NSLocalizedString("discover.recommendedFollows", comment: "")
            } else {
                return NSLocalizedString("discover.users", comment: "")
            }
        default:
            return ""
        }
    }
    
//    func updateFollowStatus(atIndexPath indexPath: IndexPath, forceUpdate: Bool = false) {
//        // Only update follow state on search results
//        if self.type != .regular || forceUpdate {
//            // Update the raw data for this account
//            if indexPath.section == 0 {
//                if let accounts = self.listData.accounts,
//                   indexPath.row < accounts.count,
//                   var card = self.listData.accounts?[indexPath.row] {
//                    card.syncFollowStatus()
//                    self.listData.accounts?[indexPath.row] = card
//                } else {
//                    log.error("Unexpected index \(indexPath.row) beyond card count (\(self.listData.accounts?.count ?? 0))")
//                }
//            }
//        }
//    }
//
    func updateFollowStatusForAccountName(_ accountName: String!, followStatus: FollowManager.FollowStatus) -> Int? {
        let accounts = self.listData.accounts

        // Find the index of this account
        let cardIndex = accounts?.firstIndex(where: { card in
            card.account?.fullAcct == accountName
        })
        if let cardIndex {
            // Force the new status upon the card
            let card = self.listData.accounts![cardIndex]
            card.setFollowStatus(followStatus)
            self.listData.accounts![cardIndex] = card
            // Return the index to be updated
            return cardIndex
        } else {
            return nil
        }
    }

}


// MARK: - Service
extension DiscoverSuggestionsViewModel {
    func loadRecommendations(section: DiscoverySuggestionSection? = nil) async {

        if let fullAcct = AccountsManager.shared.currentUser()?.fullAcct {
            // Make requests for…
            //      - smart lists
            //      - trending hashtags
            //      - suggested follows
            
            // Smart Lists
            if section == nil || section == .channel {
                Task { [weak self] in
                    guard let self else { return }
                    // Get all available channels, then prioritize ones
                    // the user is not subscribed to yet.
                    let allChannels = ChannelManager.shared.allChannels()
                    let unsubscribedChannels = allChannels.filter { ChannelManager.shared.subscriptionStatusForChannel($0) != .subscribed
                    }
                    let subscribedChannels = allChannels.filter { ChannelManager.shared.subscriptionStatusForChannel($0) == .subscribed
                    }
                    self.allChannels = unsubscribedChannels + subscribedChannels
                    let suggestedChannels = (self.allChannels).prefix(DefaultNumberOfChannels)
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        self.listData.channels = Array(suggestedChannels)
                        self.delegate?.didUpdateSection(section: .channel, with: .success)
                    }
                }
            }
            
            // Trending Hashtags
            if section == nil || section == .hashtag {
                Task { [weak self] in
                    guard let self else { return }
                    // Get the trending hashtags, and remove the ones the user
                    // already subscribes to.
                    let allTrendingHashtags = try await InstanceService.trendingTags()
                    let subscribedHashtags = HashtagManager.shared.allHashtags()
                    let unsubscribedTrending = allTrendingHashtags.filter { !subscribedHashtags.contains($0) }
                    // Limit to the top two
                    let suggestedHashtags = Array(unsubscribedTrending.prefix(DefaultNumberOfHashtags))
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        self.allTrendingHashtags = allTrendingHashtags
                        self.listData.hashtags = suggestedHashtags
                        self.delegate?.didUpdateSection(section: .hashtag, with: .success)
                    }
                }
            }
            
            // Accounts
            if section == nil || section == .account {
                Task { [weak self] in
                    guard let self else { return }
                    do {
                        let accounts = try await AccountService.getFollowRecommentations(fullAcct: fullAcct)
                        // Filter out accounts that the user is already following,
                        // and randomize the results
                        let unfollowedAccounts = accounts.filter { account in
                            return FollowManager.shared.followStatusForAccount(account, requestUpdate: .none) != .following
                        }.shuffled()
                        
                        let userCards = unfollowedAccounts.map({ account in
                            UserCardModel.fromAccount(account: account, instanceName: GlobalHostServer())
                        })
                        
                        UserCardModel.preload(userCards: userCards)
                        
                        // Prefetch follow status for the first 20 items
                        if userCards.count > 0 {
                            let firstPage = Array(userCards[0...min(20, userCards.count-1)])
                            DispatchQueue.main.async {
                                firstPage.forEach({
                                    $0.syncFollowStatus(.whenUncertain)
                                })
                            }
                        }
                        
                        DispatchQueue.main.async { [weak self] in
                            guard let self else { return }
                            self.allSuggestedAccounts = userCards
                            self.listData.accounts = userCards
                            self.delegate?.didUpdateSection(section: .account, with: .success)
                        }
                    } catch {
                        log.error("error getting accounts: \(error)")
                    }
                }
            }
        }
    }
    
    func requestItemSync(forIndexPath indexPath: IndexPath, afterSeconds delay: CGFloat) {
        let item = self.getInfo(forIndexPath: indexPath)
        self.postSyncingTasks[indexPath] = Task {
            try await Task.sleep(seconds: delay)
            guard !Task.isCancelled else { return }
            
            guard !NetworkMonitor.shared.isNearRateLimit else {
                log.warning("Skipping syncing status due to rate limit")
                return
            }
            
            switch item {
            case .account(let userCard):
                await MainActor.run {
                    userCard?.syncFollowStatus(.whenUncertain)
                }
            default:
                break
            }
        }
    }
    
    func cancelItemSync(forIndexPath indexPath: IndexPath) {
        if let task = self.postSyncingTasks[indexPath], !task.isCancelled {
            task.cancel()
            self.postSyncingTasks[indexPath] = nil
        }
    }
    
    func cancelAllItemSyncs() {
        self.postSyncingTasks.forEach({ $1.cancel() })
        self.postSyncingTasks = [:]
    }
    
}


// MARK: - Notification handlers
private extension DiscoverSuggestionsViewModel {
    @objc func didSwitchAccount() {
        Task { [weak self] in
            guard let self else { return }
            // Reload recommentations when a user is set/changed
            await self.loadRecommendations()
        }
    }
    
    @objc func allChannelsDidChange() {
        Task { [weak self] in
            guard let self else { return }
            // Reload recommentations when the list of all channels changes
            await self.loadRecommendations(section: .channel)
        }
    }

    @objc func channelStatusDidChange(notification: Notification) {
        let acctData = notification.userInfo?["account"] as? any AcctDataType
        if acctData == nil || acctData?.uniqueID == AccountsManager.shared.currentAccount?.uniqueID {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.delegate?.didUpdateSection(section: .channel, with: .success)
            }
        }
    }
    
    @objc func hashtagStatusDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.didUpdateSection(section: .hashtag, with: .success)
        }
    }
    
    @objc func onStatusUpdate(notification: Notification) {
        // Only observe the notification if it's tied to the current user.
        if (notification.userInfo!["currentUserFullAcct"] as! String) == AccountsManager.shared.currentUser()?.fullAcct {
            let fullAcct = notification.userInfo!["otherUserFullAcct"] as! String
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let followStatus = FollowManager.FollowStatus(rawValue: notification.userInfo!["followStatus"] as! String)!
                if followStatus != .inProgress {
                    if let index = self.updateFollowStatusForAccountName(fullAcct, followStatus: followStatus) {
                        self.delegate?.didUpdateCard(at: IndexPath(row: index, section: 2))
                    }
                }
            }
        }
    }
}

// MARK: - Service
extension DiscoverSuggestionsViewModel {
    
    func search(query: String, fullSearch: Bool = false) {
        self.searchQuery = query
    }
 
    // Actually do the searching/filtering here
    func searchAll(query: String) async {
    }

    func cancelSearch() {
        self.searchQuery = nil
    }
    
    func updateContentFromSearchQuery() {
        self.showSummaryCells = (self.searchQuery != nil)
        
        // Filter list content based on the search query
        if self.searchQuery?.isEmpty ?? true  {
            self.listData.channels = Array(self.allChannels.prefix(self.DefaultNumberOfChannels))
            self.listData.hashtags = Array(self.allTrendingHashtags.prefix(self.DefaultNumberOfHashtags))
            self.listData.accounts = self.allSuggestedAccounts
            self.delegate?.didUpdateAll()
        } else if let searchQuery = self.searchQuery {
            // Filter channels
            let filteredChannels = self.allChannels.filter { channel in
                return channel.title.localizedCaseInsensitiveContains(searchQuery) ||
                channel.description.localizedCaseInsensitiveContains(searchQuery)
            }
            self.listData.channels = filteredChannels
            self.delegate?.didUpdateSection(section: .channel, with: .success)

            // Show one hashtag that is an exact match for the query
            var exactMatchQuery = searchQuery.lowercased()
            if exactMatchQuery.hasPrefix("#") {
                exactMatchQuery = String(exactMatchQuery.dropFirst())
            }
            let exactMatch = Tag(name: exactMatchQuery, url: "")
            self.listData.hashtags = [exactMatch]
            self.delegate?.didUpdateSection(section: .hashtag, with: .success)

            // Make a new query for accounts
            if let task = self.searchAccountsTask, !task.isCancelled {
                task.cancel()
            }
            self.searchAccountsTask = Task { [weak self] in
                guard let self else { return }
                do {
                    try await Task.sleep(seconds: 0.4)
                    guard !Task.isCancelled else { return }
                    let result = try await SearchService.searchAccounts(query: searchQuery)
                    guard !Task.isCancelled else { return }
                    let userCards = result.map({ account in
                        UserCardModel.fromAccount(account: account)
                    })
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        self.listData.accounts = userCards
                        self.delegate?.didUpdateSection(section: .account, with: .success)
                    }
                } catch {
                    log.warning("unexpected error, or interrupted searching accounts: \(error)")
                }
            }
        }
    }
    
}


