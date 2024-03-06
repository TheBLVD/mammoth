//
//  DiscoveryViewModel.swift
//  Mammoth
//
//  Created by Benoit Nolens on 11/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class DiscoveryViewModel {
    
    enum ScreenPosition {
        case main
        case aux
    }
    
    private enum ViewTypes: Int, CaseIterable {
        case regular
        case typing
        case searchResult
    }
    
    weak var delegate: RequestDelegate?
    let position: ScreenPosition
    
    private var type: ViewTypes = .regular
    private var state: ViewState {
        didSet {
            delegate?.didUpdate(with: state)
        }
    }
    
    private var searchDebouncer: Timer?
    private var searchTask: Task<Void, Never>?
    private var searchQuery: String = "" {
        didSet {
            if !searchQuery.isEmpty {
                if let task = searchTask, !task.isCancelled {
                    task.cancel()
                }
                self.searchTask = Task { [weak self] in
                    guard let self else { return }
                    await self.searchAll(query: self.searchQuery)
                }
            }
        }
    }

    private var listData: [UserCardModel] = []
    private var suggested: [UserCardModel] = []

    init(screenPosition: ScreenPosition = .main) {
        self.state = .idle
        self.position = screenPosition
                
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didSwitchAccount),
                                               name: didSwitchCurrentAccountNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onUpdateClient),
                                               name: NSNotification.Name(rawValue: "updateClient"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onStatusUpdate),
                                               name: didChangeFollowStatusNotification,
                                               object: nil)
                
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.appDidBecomeActive),
                                               name: appDidBecomeActiveNotification,
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

// MARK: - DataSource
extension DiscoveryViewModel {
    func numberOfItems(forSection section: Int) -> Int {
        return self.listData.count
    }
    
    var numberOfSections: Int {
        return 1
    }
    
    func hasHeader(forSection sectionIndex: Int) -> Bool {
        switch(self.type) {
        case .regular:
            return true
        case .typing:
            return false
        case .searchResult:
            return false
        }
    }
    
    func shouldSyncFollowStatus() -> Bool {
        switch self.type {
        case .typing:
            return false
        default:
            return false
        }
    }

    func getInfo(forIndexPath indexPath: IndexPath) -> UserCardModel {
        switch(self.type) {
        case .regular:
            return self.listData[indexPath.row]
        case .typing:
            return self.listData[indexPath.row]
        case .searchResult:
            return self.listData[indexPath.row]
        }
    }
    
    func getSectionTitle(for sectionIndex: Int) -> String {
        switch(self.type) {
        case .regular:
            return NSLocalizedString("discover.recommendedFollows", comment: "")
        case .typing:
            return ""
        case .searchResult:
            return ""
        }
    }
    
    func updateFollowStatus(atIndexPath indexPath: IndexPath, forceUpdate: Bool = false) {
        // Only update follow state on search results
        if self.type != .regular || forceUpdate {
            // Update the raw data for this account
            if indexPath.section == 0 {
                if indexPath.row < self.listData.count {
                    let card = self.listData[indexPath.row]
                    card.syncFollowStatus()
                    self.listData[indexPath.row] = card
                } else {
                    log.error("Unexpected index \(indexPath.row) beyond card count (\(self.listData.count ))")
                }
            }
        }
    }

    func updateFollowStatusForAccountName(_ accountName: String!, followStatus: FollowManager.FollowStatus) -> Int? {
        let accounts = self.listData

        // Find the index of this account
        let cardIndex = accounts.firstIndex(where: { card in
            card.account?.fullAcct == accountName
        })
        if let cardIndex {
            // Force the new status upon the card
            let card = self.listData[cardIndex]
            card.setFollowStatus(followStatus)
            self.listData[cardIndex] = card
            // Return the index to be updated
            return cardIndex
        } else {
            return nil
        }
    }
}

// MARK: - Service
extension DiscoveryViewModel {
    func loadRecommendations() async {
        self.state = .loading
        
        // No need to load default content on the iPhone
        guard self.position == .aux else { return }
        
        if let fullAcct = AccountsManager.shared.currentUser()?.fullAcct {
            do {
                let accounts = try await AccountService.getFollowRecommentations(fullAcct: fullAcct)

                let userCards = accounts.map({ account in
                    UserCardModel.fromAccount(account: account, instanceName: GlobalHostServer())
                })
                
                UserCardModel.preload(userCards: userCards)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.suggested = userCards
                    self.listData = userCards
                    self.state = .success
                }
                
            } catch let error {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.state = .error(error)
                }
            }
        }

    }
    
    func search(query: String, fullSearch: Bool = false) {
        //Debounce search
        self.searchDebouncer?.invalidate()
        
        if fullSearch {
            self.type = .searchResult
            self.state = .success // force a table reload
        } else {
            self.type = .typing
            self.state = .success // force a table reload
        }
        
        if query.isEmpty {
            self.searchQuery = query
        } else {
            searchDebouncer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false, block: { [weak self] (timer) in
                guard let self else { return }
                self.searchQuery = query
            })
        }
    }
    
    func searchAll(query: String) async {
        self.state = .loading
        do {
            let result = try await SearchService.searchAccounts(query: query)
 
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let userCards = result.map({ account in
                    UserCardModel.fromAccount(account: account)
                })
                self.listData = userCards
                self.state = .success
            }
        } catch let error {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.state = .error(error)
            }
        }
    }
    
    func cancelSearch() {
        self.type = .regular
        self.listData = self.suggested
        self.searchQuery = ""
    }
    
    func syncFollowStatus(forIndexPaths indexPaths: [IndexPath]) {
        indexPaths.forEach({ [weak self] indexPath in
            guard let self else { return }
            let userCard = self.getInfo(forIndexPath: indexPath)
            if let account = userCard.account {
                let newStatus = FollowManager.shared.followStatusForAccount(account, requestUpdate: .whenUncertain)
                if newStatus !=  self.listData[indexPath.row].followStatus {
                    self.listData[indexPath.row].followStatus = newStatus
                    self.delegate?.didUpdateCard(at: indexPath)
                }
            }
        })
    }
}

// MARK: - Notification handlers
private extension DiscoveryViewModel {
    @objc func didSwitchAccount() {
        Task { [weak self] in
            guard let self else { return }
            // Reload recommentations when a user is set/changed
            await self.loadRecommendations()
        }
    }
    
    @objc func onUpdateClient() {
        Task { [weak self] in
            guard let self else { return }
            // Reload recommentations when a user is set/changed
            await self.loadRecommendations()
        }
    }
    
    @objc func appDidBecomeActive() {
        Task { [weak self] in
            guard let self else { return }
            // Load recommentations when app is active
            await self.loadRecommendations()
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
                        self.delegate?.didUpdateCard(at: IndexPath(row: index, section: 0))
                    }
                }
            }
        }
    }
    
}
