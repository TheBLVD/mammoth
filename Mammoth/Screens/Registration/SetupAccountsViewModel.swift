//
//  SetupAccountsViewModel.swift
//  Mammoth
//
//  Created by Riley Howard on 10/9/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class SetupAccountsViewModel {
    
    private enum ViewTypes: Int, CaseIterable {
        case regular
        case typing
        case searchResult
    }
    
    static let shared = SetupAccountsViewModel()
    static func preload() {
        _ = self.shared
    }

    weak var delegate: RequestDelegate? {
        didSet {
            self.delegate?.didUpdate(with: state)
        }
    }
    
    private var type: ViewTypes = .regular
    private var state: ViewState {
        didSet {
            self.delegate?.didUpdate(with: state)
        }
    }
    
    private var listDataHeaders: [String] = []
    private var listData: [[UserCardModel]] = []
    private var postSyncingTasks: [IndexPath: Task<Void, Error>] = [:]

    init() {
        self.state = .idle
                
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onStatusUpdate),
                                               name: didChangeFollowStatusNotification,
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
extension SetupAccountsViewModel {
    func numberOfItems(forSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return self.listData[section-1].count
        }
    }
    
    var numberOfSections: Int {
        return 1+self.listData.count
    }
    
    func hasHeader(forSection sectionIndex: Int) -> Bool {
        return (sectionIndex != 0)
    }
    
    func shouldSyncFollowStatus() -> Bool {
        return true
    }

    func getInfo(forIndexPath indexPath: IndexPath) -> UserCardModel? {
        guard indexPath.section > 0 else { return nil } // The first section is the header / no data
        return self.listData[indexPath.section-1][indexPath.row]
    }
    
    func getSectionTitle(for sectionIndex: Int) -> String {
        if sectionIndex > 0 {
            return self.listDataHeaders[sectionIndex-1]
        } else {
            return ""
        }
    }

    func updateFollowStatusForAccountName(_ accountName: String!, followStatus: FollowManager.FollowStatus) -> IndexPath? {
        for (index, listData) in self.listData.enumerated() {
            let accounts = listData
            
            // Find the index of this account
            let cardIndex = accounts.firstIndex(where: { card in
                card.account?.fullAcct == accountName
            })
            if let cardIndex {
                // Force the new status upon the card
                let card = self.listData[index][cardIndex]
                card.setFollowStatus(followStatus)
                self.listData[index][cardIndex] = card
                // Return the index to be updated
                return IndexPath(row: cardIndex, section: index+1)
            }
        }
        
        return nil
    }
}

// MARK: - Service
extension SetupAccountsViewModel {
    func loadRecommendations() async {
        self.state = .loading
        do {
            var mammothAccount: Account? = nil
            var newListHeaders: [String] = []
            var newListData: [[UserCardModel]] = []
            
            let request = Accounts.onboardingFollowRecommendations()
            let result = try await ClientService.runMothRequest(request: request)
            let categoriesFromServer: [Category] = result
            
            // Convert categories to our listData (skipping hashtags)
            for categoryFromServer in categoriesFromServer {
                let accounts = categoryFromServer.items.compactMap {
                    switch $0 {
                    case .account(let account):
                        if mammothAccount == nil && account.remoteFullOriginalAcct == "mammoth@moth.social" {
                            mammothAccount = account
                        }
                        return account
                    case .hashtag:
                        return nil
                    }
                }
                
                // We used to include mammoth@moth.social in the list, but not anymore.
                // If it's in this category, and it's the only one, go ahead
                // and just skip this category altogether.
                if accounts.count == 1, accounts[0] == mammothAccount {
                    log.debug("skipping category with just the mammoth@moth.social account")
                    continue
                }
                
                let userCards = accounts.map({ account in
                    UserCardModel.fromAccount(account: account, instanceName: GlobalHostServer())
                })
                userCards.forEach({
                    $0.preloadImages()
                })
                
                // Prefetch follow status for the first 20 items
                if userCards.count > 0 {
                    let firstPage = Array(userCards[0...min(20, userCards.count-1)])
                    DispatchQueue.main.async {
                        firstPage.forEach({
                            $0.syncFollowStatus(.whenUncertain)
                        })
                    }
                }
                
                newListHeaders.append(categoryFromServer.name)
                newListData.append(userCards)
            }
                        
            let newHeaders = newListHeaders
            let newData = newListData
            await MainActor.run {
                self.listDataHeaders = newHeaders
                self.listData = newData
                self.state = .success
            }
            
        } catch let error {
            // TODO: make class vars thread-safe instead
            DispatchQueue.main.async {
                self.state = .error(error)
            }
        }
    }
    
    func requestItemSync(forIndexPath indexPath: IndexPath, afterSeconds delay: CGFloat) {
        if let item = self.getInfo(forIndexPath: indexPath) {
            self.postSyncingTasks[indexPath] = Task {
                try await Task.sleep(seconds: delay)
                guard !Task.isCancelled else { return }
                
                guard !NetworkMonitor.shared.isNearRateLimit else {
                    log.warning("Skipping syncing status due to rate limit")
                    return
                }
                
                await MainActor.run {
                    item.syncFollowStatus(.whenUncertain)
                }
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
private extension SetupAccountsViewModel {
        
    @objc func onStatusUpdate(notification: Notification) {
        // Only observe the notification if it's tied to the current user.
        if (notification.userInfo!["currentUserFullAcct"] as! String) == AccountsManager.shared.currentUser()?.fullAcct {
            let fullAcct = notification.userInfo!["otherUserFullAcct"] as! String
            DispatchQueue.main.async {
                let followStatus = FollowManager.FollowStatus(rawValue: notification.userInfo!["followStatus"] as! String)!
                if followStatus != .inProgress {
                    if let indexPath = self.updateFollowStatusForAccountName(fullAcct, followStatus: followStatus) {
                        self.delegate?.didUpdateCard(at: indexPath)
                    }
                }
            }
        }
    }
    
}
