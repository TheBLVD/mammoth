//
//  UserListViewModel.swift
//  Mammoth
//
//  Created by Benoit Nolens on 08/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class UserListViewModel {

    public enum UserListType: Int, CaseIterable {
        case likes
        case reposts
        case followers
        case following
        case mutes
        case blocks
        case listMembers
        
        func title(_ user: UserCardModel? = nil) -> String {
            switch self {
            case .likes:
                return NSLocalizedString("title.likes", comment: "")
            case .reposts:
                return NSLocalizedString("activity.reposts", comment: "")
            case .followers:
                return NSLocalizedString("title.followers", comment: "") + " (\(user?.followersCount ?? "0"))"
            case .following:
                return NSLocalizedString("title.following", comment: "") + " (\(user?.followingCount ?? "0"))"
            case .mutes:
                return NSLocalizedString("profile.muted", comment: "")
            case .blocks:
                return NSLocalizedString("profile.blocked", comment: "")
            case .listMembers:
                return NSLocalizedString("list.members", comment: "")
            }
        }
        
        func fetchAll(_ post: PostCardModel, range: RequestRange = .default) async throws -> ([UserCardModel], Pagination?) {
            switch self {
            case .likes:
                let (accounts, pagination) = try await StatusService.likes(id: post.originalId, instanceName: post.originalInstanceName, range: range)
                let users = accounts.map({ UserCardModel(account: $0, requestFollowStatusUpdate: .none) })
                return (users, pagination)
            case .reposts:
                let (accounts, pagination) = try await StatusService.reposts(id: post.originalId, instanceName: post.originalInstanceName, range: range)
                let users = accounts.map({ UserCardModel(account: $0, requestFollowStatusUpdate: .none) })
                return (users, pagination)
            default:
                fatalError("pass a user instead to fetch all \(self.rawValue)")
            }
        }
        
        func fetchAll(_ user: UserCardModel, range: RequestRange = .default) async throws -> ([UserCardModel], Pagination?) {
            switch self {
            case .followers:
                let (accounts, pagination) = try await AccountService.followers(userId: user.id, instanceName: user.instanceName, range: range)
                let users = accounts.map({ UserCardModel(account: $0, requestFollowStatusUpdate: .none) })
                return (users, pagination)
            case .following:
                let (accounts, pagination) = try await AccountService.following(userId: user.id, instanceName: user.instanceName, range: range)
                let users = accounts.map({ UserCardModel(account: $0, requestFollowStatusUpdate: .none, isFollowing: true) })
                return (users, pagination)
            case .mutes:
//                let (accounts, pagination) = try await AccountService.mutes(range: range)
                let cachedMutes = ModerationManager.shared.mutedUsers.map({ UserCardModel(account: $0, requestFollowStatusUpdate: .none) })
//                let users = accounts.map({ UserCardModel(account: $0, requestFollowStatusUpdate: .none) })
                return (cachedMutes, nil)
            case .blocks:
//                let (accounts, pagination) = try await AccountService.blocks(range: range)
                let cachedBlocks = ModerationManager.shared.blockedUsers.map({ UserCardModel(account: $0, requestFollowStatusUpdate: .none) })
//                let users = accounts.map({ UserCardModel(account: $0, requestFollowStatusUpdate: .none) })
                return (cachedBlocks, nil)
            default:
                fatalError("pass a post instead to fetch all \(self.rawValue)")
            }
        }
        
        func fetchAll(_ listID: String, range: RequestRange = .default) async throws -> ([UserCardModel], Pagination?) {
            switch self {
            case .listMembers:
                let (accounts, pagination) = try await ListService.accounts(listID: listID, range: range)
                let users = accounts.map({ UserCardModel(account: $0, requestFollowStatusUpdate: .none) })
                return (users, pagination)
            default:
                fatalError("pass a user instead to fetch all \(self.rawValue)")
            }
        }
    }
    
    weak var delegate: RequestDelegate?
    private var isLoadMoreEnabled: Bool = true
    private var nextPageRange: RequestRange?
    
    private var state: ViewState {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.didUpdate(with: self.state)
            }
        }
    }

    private var listData: [UserCardModel] = []
    private(set) var type: UserListType
    private var post: PostCardModel?
    private(set) var user: UserCardModel?
    private(set) var listID: String?
    
    public var ongoingTask: Task<Void, Error>?

    init(type: UserListType, user: UserCardModel) {
        self.state = .idle
        self.type = type
        self.user = user
        self.listData = []
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onStatusUpdate),
                                               name: didChangeFollowStatusNotification,
                                               object: nil)
        
        self.state = .loading
        self.ongoingTask = Task {
            do {
                if let acct = user.account, let account = await AccountService.lookup(acct.fullAcct, serverName: acct.server) {
                    let lookedUpUser = UserCardModel(account: account, instanceName: account.server)
                    await MainActor.run {
                        self.user = lookedUpUser
                    }
                    try await self.loadList(lookedUpUser, loadNextPage: false)
                    
                    if self.type == .blocks || self.type == .mutes {
                        self.state = .loading
                        try await ModerationManager.shared.fetchLists()
                        try await self.loadList(lookedUpUser, loadNextPage: false)
                    }
                } else {
                    if let acct = user.account {
                        let user = UserCardModel(account: acct, instanceName: user.instanceName ?? acct.server)
                        try await self.loadList(user, loadNextPage: false)
                        await MainActor.run  {
                            self.user = user
                        }
                    }
                }
            } catch { }
        }
        
    }
    
    init(type: UserListType, post: PostCardModel) {
        self.state = .idle
        self.type = type
        self.post = post
        self.listData = []
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onStatusUpdate),
                                               name: didChangeFollowStatusNotification,
                                               object: nil)
        
        self.ongoingTask = Task { try await self.loadList() }
    }
    
    init(listID: String) {
        self.state = .idle
        self.type = .listMembers
        self.listID = listID
        self.listData = []
        
        self.ongoingTask = Task { try await self.loadList() }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func title() -> String {
        switch self.type {
        case .likes, .reposts, .blocks, .mutes, .listMembers:
            return self.type.title()
        default:
            return ""
        }
    }
    
    public func carouselItems() -> [UserListType] {
        switch self.type {
        case .followers, .following:
            return [.followers, .following]
        default:
            return []
        }
    }
    
    public func changeType(type: UserListType) {
        self.type = type
        self.listData = []
        self.isLoadMoreEnabled = true
        if let user = self.user {
            self.ongoingTask?.cancel()
            self.ongoingTask = Task {
                try await self.loadList(user, loadNextPage: false)
            }
        }
    }
}

// MARK: - DataSource
extension UserListViewModel {
    func numberOfItems(forSection section: Int) -> Int {
        return max(self.listData.count + (self.shouldDisplayLoader() ? 1 : 0) + (self.shouldDisplayError() ? 1 : 0), 1)
    }
    
    var numberOfSections: Int {
        return 1
    }

    func getInfo(forIndexPath indexPath: IndexPath) -> UserCardModel? {
        guard self.listData.count > indexPath.row else { return nil}
        return self.listData[indexPath.row]
    }
    
    func shouldDisplayLoader() -> Bool {
        if case .loading = self.state {
            return true
        }
        return false
    }
    
    func shouldDisplayError() -> Bool {
        if case .error = self.state {
            return true
        }
        return false
    }
    
    func isListEmpty() -> Bool {
        if self.state == .loading {
            return false
        }
        
        return self.listData.isEmpty
    }
    
    func shouldShowFollowButton() -> Bool {
        if let user = self.user, user.isSelf {
            if self.type == .following {
                return false
            }
        }
        
        return true
    }
    
    func actionButtonType() -> UserCardCell.ActionButtonType {
        switch self.type {
        case .followers, .following, .likes, .reposts:
            if self.shouldShowFollowButton() {
                return .follow
            } else {
                return .none
            }
        case .blocks:
            return .unblock
        case .mutes:
            return .unmute
        case .listMembers:
            return .removeFromList
        }
    }
    
    func shouldFetchNext(prefetchRowsAt indexPaths: [IndexPath]) -> Bool {
        if !self.isLoadMoreEnabled {
            return false
        }
        
        switch(self.state) {
        case .loading:
            return false // Dont preload new items if already loading
        case .error(_):
            fallthrough
        case .success:
            let highest = indexPaths.reduce(0) {
                if $0 > $1.row {
                    return $0
                } else {
                    return $1.row
                }
            }
            
            let total = self.numberOfItems(forSection: 0)
            
            if highest > total - 6 {
                return true
            } else {
                return false
            }
            
        default:
            return false
        }
    }
    
    func updateFollowStatusForAccountName(_ accountName: String!, followStatus: FollowManager.FollowStatus) -> Int? {
        // Find the index of this account
        let cardIndex = self.listData.firstIndex(where: { card in
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
extension UserListViewModel {
    public func refreshData() async throws {
        self.isLoadMoreEnabled = true
        
        if self.type == .blocks || self.type == .mutes {
            try await ModerationManager.shared.fetchLists()
        }
        
        try await self.loadList()
    }
    
    public func loadList(loadNextPage: Bool = false) async throws {
        switch self.type {
        case .likes, .reposts:
            if let post = self.post {
                try await self.loadList(post, loadNextPage: loadNextPage)
            }
        case .followers, .following, .mutes, .blocks:
            if let user = self.user {
                try await self.loadList(user, loadNextPage: loadNextPage)
            }
        case .listMembers:
            if let listID = self.listID {
                try await self.loadList(listID, loadNextPage: loadNextPage)
            }
        }
    }
    
    private func loadList(_ post: PostCardModel, loadNextPage: Bool = false) async throws -> Void {
        self.state = .loading
        do {
            var range: RequestRange = .default
            if loadNextPage, let nextPageRange = self.nextPageRange {
                range = nextPageRange
            }
            
            let (results, pagination) = try await self.type.fetchAll(post, range: range)
            if Task.isCancelled { return }
            
            self.nextPageRange = pagination?.next
            
            await MainActor.run {
                if loadNextPage {
                    let newList = (self.listData + results).removingDuplicates()
                    if newList == self.listData {
                        self.isLoadMoreEnabled = false
                    }
                    
                    self.listData = newList
                } else {
                    if results.isEmpty {
                        self.isLoadMoreEnabled = false
                    }
                    self.listData = results
                }
                
                self.state = .success
            }
        } catch let error {
            self.state = .error(error)
        }
    }
    
    private func loadList(_ user: UserCardModel, loadNextPage: Bool = false) async throws -> Void {
        self.state = .loading
        do {
            var range: RequestRange = .default
            if loadNextPage, let nextPageRange = self.nextPageRange {
                range = nextPageRange
            }
            
            let (results, pagination) = try await self.type.fetchAll(user, range: range)
            if Task.isCancelled { return }
            
            self.nextPageRange = pagination?.next
            
            await MainActor.run {
                if loadNextPage {
                    if results.isEmpty {
                        self.isLoadMoreEnabled = false
                    } else {
                        let newList = (self.listData + results).removingDuplicates()
                        if newList == self.listData {
                            self.isLoadMoreEnabled = false
                        }
                        
                        self.listData = newList
                    }
                } else {
                    self.listData = results
                }
                
                self.state = .success
            }
        } catch let error {
            self.state = .error(error)
        }
    }
    
    private func loadList(_ listID: String, loadNextPage: Bool = false) async throws -> Void {
        self.state = .loading
        do {
            var range: RequestRange = .default
            if loadNextPage, let nextPageRange = self.nextPageRange {
                range = nextPageRange
            }
            
            let (results, pagination) = try await self.type.fetchAll(listID, range: range)
            if Task.isCancelled { return }
            
            self.nextPageRange = pagination?.next
            
            await MainActor.run {
                if loadNextPage {
                    if results.isEmpty {
                        self.isLoadMoreEnabled = false
                    } else {
                        let newList = (self.listData + results).removingDuplicates()
                        if newList == self.listData {
                            self.isLoadMoreEnabled = false
                        }
                        
                        self.listData = newList
                    }
                } else {
                    self.listData = results
                }
                
                self.state = .success
            }
        } catch let error {
            self.state = .error(error)
        }
    }
    
    func syncFollowStatus(forIndexPaths indexPaths: [IndexPath]) {
        indexPaths.forEach({
            if let userCard = self.getInfo(forIndexPath: $0), let account = userCard.account {
                let newStatus = FollowManager.shared.followStatusForAccount(account, requestUpdate: .whenUncertain)
                if newStatus != self.listData[$0.row].followStatus {
                    self.listData[$0.row].followStatus = newStatus
                    self.delegate?.didUpdateCard(at: $0)
                }
            }
        })
    }
}

extension UserListViewModel {
    @objc func onStatusUpdate(notification: Notification) {
        // Only observe the notification if it's tied to the current user.
        if (notification.userInfo!["currentUserFullAcct"] as! String) == AccountsManager.shared.currentUser()?.fullAcct {
            let fullAcct = notification.userInfo!["otherUserFullAcct"] as! String
            DispatchQueue.main.async {
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
