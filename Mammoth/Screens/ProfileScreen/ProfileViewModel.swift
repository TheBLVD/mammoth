//
//  ProfileViewModel.swift
//  Mammoth
//
//  Created by Benoit Nolens on 12/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

final class ProfileViewModel {
    
    enum ViewTypes: Int, CaseIterable {
        case posts = 0
        case postsAndReplies
        
        func labelText() -> String {
            switch self {
            case .posts:
                return NSLocalizedString("profile.posts", comment: "")
            case .postsAndReplies:
                return NSLocalizedString("profile.postsAndReplies", comment: "")
            }
        }
        
        func key() -> String {
            switch self {
            case .posts:
                return "posts"
            case .postsAndReplies:
                return "postsAndReplies"
            }
        }
    }
    
    enum ProfileScreenType {
        case own
        case others
    }
    
    private struct ListData {
        var posts: [PostCardModel]?
        var postsAndReplies: [PostCardModel]?
        var postsCursorId: String?
        var postsAndRepliesCursorId: String?
        
        func listForType(type: ViewTypes) -> [PostCardModel]? {
            switch type {
            case .posts:
                return self.posts
            case .postsAndReplies:
                return self.postsAndReplies
            }
        }
    }

    enum ListDataReturn {
        case postsData(PostCardModel?)
        case postsAndReplies(PostCardModel?)
    }
    
    enum NetworkError: Error {
        case userNotFound
    }
    
    weak var delegate: RequestDelegate?
        
    private var type: ViewTypes
    private var state: ViewState {
        didSet {
            if oldValue != state {
                delegate?.didUpdate(with: state)
            }
        }
    }
    public var screenType: ProfileScreenType
    public var isLoadingOriginals: Bool = true
    
    private var listData: ListData = ListData()
    private var isLoadMoreEnabled: Bool = true
    
    var user: UserCardModel?
    
    init(_ type: ViewTypes = .posts, fullAcct: String, serverName: String) {
        self.state = .loading
        self.type = type
        self.screenType = .others
        
        self.addObservers()
        
        // When initialized with a fullAcct string and serverName (eg when tapping an account tag)
        // we lookup the account based on the account tag
        Task { [weak self] in
            guard let self else { return }
            
            // If server is Threads.net, use the user's local instance
            let serverName = (serverName == "www.threads.net")
                ? AccountsManager.shared.currentAccountClient.baseHost
                : serverName
            
            if let account = await AccountService.lookup(fullAcct, serverName: serverName) {
                // Lookup on account's instance
                let user = UserCardModel(account: account, instanceName: serverName, requestFollowStatusUpdate: .force)
                await MainActor.run {
                    self.user = user
                }
                
                await self.loadListData(type: self.type)
                
            } else if let account = await AccountService.lookup(fullAcct, serverName: AccountsManager.shared.currentAccountClient.baseHost) {
                // Lookup on signed in user's local instance.
                // This is a fallback for non-mastodon instances
                let user = UserCardModel(account: account, instanceName: AccountsManager.shared.currentAccountClient.baseHost, requestFollowStatusUpdate: .force)
                await MainActor.run {
                    self.user = user
                }
                
                await self.loadListData(type: self.type)
            } else {
                await MainActor.run {
                    self.state = .error(NetworkError.userNotFound)
                    self.delegate?.didUpdate(with: self.state)
                }
            }
        }
    }

    init(_ type: ViewTypes = .posts, user: UserCardModel?, screenType: ProfileScreenType = .own) {
        self.type = type
        self.user = user
        self.screenType = (user?.isSelf ?? false) ? .own : screenType
        self.state = .success
        
        self.addObservers()
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            if screenType == .others {
                Task { [weak self] in
                    guard let self else { return }
                    await self.reloadUser()
                    await self.loadListData(type: self.type)
                }
                
                if let account = user?.account {
                    let newStatus = FollowManager.shared.followStatusForAccount(account, requestUpdate: .force)
                    if newStatus != self.user?.followStatus {
                        if newStatus != .inProgress {
                            self.user?.followStatus = newStatus
                            self.delegate?.didUpdate(with: .success)
                        }
                    }
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.appDidBecomeActive),
                                               name: appDidBecomeActiveNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onPostCardUpdate),
                                               name: PostActions.didUpdatePostCardNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onUserCardUpdate),
                                               name: UserActions.didUpdateUserCardNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didSwitchAccount),
                                               name: didSwitchCurrentAccountNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onReloadPinned),
                                               name: NSNotification.Name(rawValue: "reloadPinned"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onNewPostSent),
                                               name: NSNotification.Name(rawValue: "updateFeed"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onAvatarDidChange),
                                               name: didUpdateAccountAvatar,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onHeaderDidChange),
                                               name: didUpdateAccountHeader,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onFollowStatusUpdate),
                                               name: didChangeFollowStatusNotification,
                                               object: nil)
    }
}

// MARK: - DataSource
extension ProfileViewModel {
    func numberOfItems(forSection section: Int) -> Int {
        switch(self.type) {
        case .posts:
            return max((self.listData.posts?.count ?? 0) + (self.shouldDisplayLoader() ? 1 : 0), 1)
        case .postsAndReplies:
            return max((self.listData.postsAndReplies?.count ?? 0) + (self.shouldDisplayLoader() ? 1 : 0), 1)
        }
    }
    
    var numberOfSections: Int {
        return 1
    }
    
    func shouldDisplayLoader() -> Bool {
        if self.state == .loading {
            return true
        }
        return false
    }
    
    func isListEmpty() -> Bool {
        if self.state == .loading {
            return false
        }
        switch(self.type) {
        case .posts:
            return self.listData.posts?.isEmpty ?? true
        case .postsAndReplies:
            return self.listData.postsAndReplies?.isEmpty ?? true
        }
    }
    
    func hasHeader(forSection sectionIndex: Int) -> Bool {
        if sectionIndex == 0 {
            return true
        }
        return false
    }

    func getInfo(forIndexPath indexPath: IndexPath) -> PostCardModel? {
        switch(self.type) {
        case .posts:
            return self.listData.posts?.count ?? 0 > indexPath.row ? self.listData.posts?[indexPath.row] : nil
        case .postsAndReplies:
            return self.listData.postsAndReplies?.count ?? 0 > indexPath.row ? self.listData.postsAndReplies?[indexPath.row] : nil
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
}

// MARK: - Service
extension ProfileViewModel {
    private func createRequest(forType: ViewTypes, user: UserCardModel, range: RequestRange = .default) async throws -> (pinned: [Status], statuses: [Status], cursorId: String?) {
        do {
            switch(type) {
            case .posts:
                return try await AccountService.profilePosts(user: user, range: range, serverName: user.instanceName)
            case .postsAndReplies:
                return try await AccountService.profilePostsAndReplies(user: user, range: range, serverName: user.instanceName)
            }
        } catch {
            // Fallback to the user's instance to fetch the profile posts.
            // When fetching profiles on AP we cannot query the original instance.
            // We need to query the content through the user's mastodon instance
            let currentServer = AccountsManager.shared.currentAccountClient.baseHost
            
            var localUser = user
            if user.instanceName != nil && user.instanceName != currentServer {
                localUser = await self.reloadUser(forceLocal: true) ?? user
                await MainActor.run { self.state = .loading }
            }
            
            switch(type) {
            case .posts:
                let result = try await AccountService.profilePosts(user: localUser, range: range, serverName: currentServer)
                await MainActor.run {
                    self.user?.instanceName = currentServer
                    self.isLoadingOriginals = false
                }
                return result
            case .postsAndReplies:
                let result = try await AccountService.profilePostsAndReplies(user: localUser, range: range, serverName: currentServer)
                await MainActor.run {
                    self.user?.instanceName = currentServer
                    self.isLoadingOriginals = false
                }
                return result
            }
        }
    }
    
    private func getCursor(forType type: ViewTypes) -> String? {
        switch type {
        case .posts:
            return self.listData.postsCursorId ?? self.listData.posts?.last?.id
        case .postsAndReplies:
            return self.listData.postsAndRepliesCursorId ?? self.listData.postsAndReplies?.last?.id
        }
    }
    
    private func setCursor(_ cursorId: String?, forType type: ViewTypes) {
        switch type {
        case .posts:
            self.listData.postsCursorId = cursorId
        case .postsAndReplies:
            self.listData.postsAndRepliesCursorId = cursorId
        }
    }
    
    // Replace the local user used on this profile screen with the currentUser in AccountManager
    func syncCurrentUser() {
        if self.screenType == .own {
            if let currentUser = AccountsManager.shared.currentAccount as? MastodonAcctData {
                let currentAccount = currentUser.account
                self.user = UserCardModel(account: currentAccount)
            }
        }
    }
    
    @discardableResult
    func reloadUser(forceLocal: Bool = false) async -> UserCardModel? {
        do {
            if self.screenType == .own {
                await MainActor.run {self.state = .loading }
                if let account = try await AccountService.currentUser() {
                    return await MainActor.run { [weak self] in
                        guard let self else { return nil }
                        self.user = UserCardModel(account: account)
                        self.state = .success
                        return self.user
                    }
                }
            } else {
                let user = await MainActor.run { [weak self] in
                    return self?.user
                }
                    
                guard var user = user else { return nil }
                await MainActor.run {self.state = .loading }
                
                // Fetch the profile on its original instance
                let instanceName = user.instanceName ?? user.account?.server ?? AccountsManager.shared.currentAccountClient.baseHost
                if let account = await AccountService.lookup(user.uniqueId, serverName: instanceName), !forceLocal {
                    return await MainActor.run { [weak self] in
                        guard let self else { return nil }
                        let followStatus = self.user?.followStatus
                        let cachedProfilePic = self.user?.decodedProfilePic
                        let preSyncAccount = self.user?.account
                        
                        self.user = UserCardModel(account: account, instanceName: instanceName)
                        self.user?.followStatus = followStatus
                        self.user?.decodedProfilePic = cachedProfilePic
                        self.user?.preSyncAccount = preSyncAccount
                        self.state = .success
                        return self.user
                    }
                } else {
                    // If the instance returns an error, search for the user on the user's instance
                    if  let accountId = user.account?.fullAcct {
                        if let account = await AccountService.lookup(accountId, serverName: AccountsManager.shared.currentAccountClient.baseHost) ?? user.account {
                            
                            user = UserCardModel(account: account, instanceName: AccountsManager.shared.currentAccountClient.baseHost)
                            
                            let user = user
                            return await MainActor.run { [weak self] in
                                guard let self else { return nil }
                                let followStatus = self.user?.followStatus
                                let cachedProfilePic = self.user?.decodedProfilePic
                                let preSyncAccount = self.user?.account
                                
                                self.user = user
                                self.user?.followStatus = followStatus
                                user.decodedProfilePic = cachedProfilePic
                                user.preSyncAccount = preSyncAccount
                                self.state = .success
                                return self.user
                            }
                        }
                    }
                }
            }
        } catch let error {
            self.state = .error(error)
        }
        
        return nil
    }
    
    func loadListData(type: ViewTypes? = nil, loadNextPage: Bool = false) async {
        let user = await MainActor.run { self.user }
        guard let user else { return }
        await MainActor.run {self.state = .loading }
        let currentType = type ?? self.type
        
        do  {
            if loadNextPage {
                if let lastId = await MainActor.run(body: { [weak self] in self?.getCursor(forType: currentType) }) {
                    let (pinned, newStatuses, cursorId) = try await self.createRequest(forType: currentType,
                                                                   user: user,
                                                                   range: RequestRange.max(id: lastId, limit: 40))
                    
                    let cursorHasChanged = await MainActor.run { [weak self] () -> Bool in
                        guard let self else { return false }
                        let previousCursor = self.getCursor(forType: currentType)
                        self.setCursor(cursorId, forType: currentType)
                        return cursorId != nil && previousCursor != cursorId
                    }
                    
                    guard !(cursorHasChanged && newStatuses.isEmpty) else {
                        // Load the next page if no statuses are returned but the cursor changed.
                        // This probably means the page only included direct posts. We filter those out
                        // in the client.
                        await self.loadListData(type: currentType, loadNextPage: true)
                        return
                    }
                    
                    // Fetch the latest version of user from the main thread
                    let user = await MainActor.run { [weak self] in
                        guard let self else { return nil }
                        return self.user
                    } ?? user
                    
                    let pinnedPostCards = pinned.map({ PostCardModel(status: $0, withStaticMetrics: false, instanceName: user.instanceName ?? user.account?.server) })
                        .removeFiltered()  // Remove pinned statuses flags as hidden by one of the filters
                    let pinnedIds = pinnedPostCards.map({ $0.id })
                    
                    let newPostCards = newStatuses.map({
                        PostCardModel(status: $0, withStaticMetrics: false, instanceName: user.instanceName ?? user.account?.server)
                    })
                        .filter({ !pinnedIds.contains($0.id) }) // Remove pinned items from main list
                        .removeFiltered() // Remove statuses flags as hidden by one of the filters
                    
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        var postsToPreload: [PostCardModel] = []
                        switch currentType {
                        case .posts:
                            if let current = self.listData.posts {
                                let currentIds = current.map({ $0.id })
                                let newPosts = newPostCards.filter({ !currentIds.contains($0.id) })
                                if cursorId == nil {
                                    self.isLoadMoreEnabled = false
                                }
                                
                                postsToPreload.append(contentsOf: newPosts)
                                
                                // append new posts to current posts and remove dups
                                self.listData.posts?.append(contentsOf: newPosts)
                            } else {
                                postsToPreload.append(contentsOf: pinnedPostCards)
                                postsToPreload.append(contentsOf: newPostCards)
                                self.listData.posts = pinnedPostCards + newPostCards
                            }
                                                        
                        case .postsAndReplies:
                            if let current = self.listData.postsAndReplies {
                                let currentIds = current.map({ $0.id })
                                let newPosts = newPostCards.filter({ !currentIds.contains($0.id) })
                                if cursorId == nil {
                                    self.isLoadMoreEnabled = false
                                }
                                
                                postsToPreload.append(contentsOf: newPosts)
                                
                                // append new posts to current posts and remove dups
                                self.listData.postsAndReplies = current + newPosts
                            } else {
                                postsToPreload.append(contentsOf: pinnedPostCards)
                                postsToPreload.append(contentsOf: newPostCards)
                                self.listData.postsAndReplies = pinnedPostCards + newPostCards
                            }
                        }

                        self.state = .success
                        
                        // Preload quote posts and images
                        PostCardModel.preload(postCards: postsToPreload)
                    }
                } else {
                    await MainActor.run {
                        self.state = .success
                    }
                }
            } else {
                self.isLoadMoreEnabled = true
                let (pinned, statuses, cursorId) = try await self.createRequest(forType: currentType, user: user)
                
                let cursorHasChanged = await MainActor.run { [weak self] () -> Bool in
                    guard let self else { return false }
                    let previousCursor = self.getCursor(forType: currentType)
                    self.setCursor(cursorId, forType: currentType)
                    return cursorId != nil && previousCursor != cursorId
                }
                
                guard !(cursorHasChanged && statuses.isEmpty) else {
                    // Load the next page if no statuses are returned but the cursor changed.
                    // This probably means the page only included direct posts. We filter those out
                    // in the client.
                    await self.loadListData(type: currentType, loadNextPage: true)
                    return
                }
                
                // Fetch the latest version of user from the main thread
                let user = await MainActor.run { [weak self] in
                    guard let self else { return nil }
                    return self.user
                } ?? user
                
                let pinnedPostCards = pinned.map({ PostCardModel(status: $0, withStaticMetrics: false, instanceName: user.instanceName ?? user.account?.server) })
                    .removeFiltered()  // Remove pinned statuses flags as hidden by one of the filters
                let pinnedIds = pinnedPostCards.map({ $0.id })
                
                let mainPostCards = statuses.map({
                    PostCardModel(status: $0, withStaticMetrics: false, instanceName: user.instanceName ?? user.account?.server)
                })
                    .filter({ !pinnedIds.contains($0.id) }) // Remove pinned items from main list
                    .removeFiltered()  // Remove statuses flags as hidden by one of the filters
                
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    if cursorId == nil {
                        self.isLoadMoreEnabled = false
                    }
                
                    switch currentType {
                    case .posts:
                        self.listData.posts = pinnedPostCards + mainPostCards
                    case .postsAndReplies:
                        self.listData.postsAndReplies = pinnedPostCards + mainPostCards
                    }
                    
                    self.state = .success
                    
                    // Preload quote posts and images
                    PostCardModel.preload(postCards: pinnedPostCards + mainPostCards)
                }
            }
            
        } catch let error {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.state = .error(error)
            }
        }
    }
    
    func preloadCards(atIndexPaths indexPaths: [IndexPath]) {
        indexPaths.forEach({
            switch(self.type) {
            case .posts:
                if let list = self.listData.posts, list.count > $0.row {
                    let card = list[$0.row]
                    
                    if card.quotePostStatus == .loading {
                        card.preloadQuotePost()
                    }
                    
                    PostCardModel.imageDecodeQueue.async {
                        card.preloadImages()
                    }
                    
                    if card.mediaDisplayType == .singleVideo || card.mediaDisplayType == .singleGIF {
                        card.preloadVideo()
                    }
                }
            case .postsAndReplies:
                if let list = self.listData.postsAndReplies, list.count > $0.row {
                    let card = list[$0.row]
                    
                    if card.quotePostStatus == .loading {
                        card.preloadQuotePost()
                    }
                    
                    PostCardModel.imageDecodeQueue.async {
                        card.preloadImages()
                    }
                    
                    if card.mediaDisplayType == .singleVideo || card.mediaDisplayType == .singleGIF {
                        card.preloadVideo()
                    }
                }
            }
        })
    }
    
    func cancelPreloadCards(atIndexPaths indexPaths: [IndexPath]) {
        indexPaths.forEach({
            switch(self.type) {
            case .posts:
                if let list = self.listData.posts, list.count > $0.row {
                    let card = list[$0.row]
                    card.cancelAllPreloadTasks()
                }
            case .postsAndReplies:
                if let list = self.listData.postsAndReplies, list.count > $0.row {
                    let card = list[$0.row]
                    card.cancelAllPreloadTasks()
                }
            }
        })
    }
    
    func stopAllVideos() {
        if let list = self.listData.posts {
            list.forEach({
                $0.videoPlayer?.pause()
            })
        }
        
        if let list = self.listData.postsAndReplies {
            list.forEach({
                $0.videoPlayer?.pause()
            })
        }
    }
}

// MARK: - Notification handlers
private extension ProfileViewModel {
    @objc func appDidBecomeActive() {
        if self.user == nil,
            self.screenType == .own {
            self.syncCurrentUser()
        }
        
        if self.user != nil {
            Task { [weak self] in
                guard let self else { return }
                // Load posts when app is active
                await self.reloadUser()
                await self.loadListData(type: self.type)
            }
        }
    }
    
    @objc func onPostCardUpdate(notification: Notification) {
        if let postCard = notification.userInfo?["postCard"] as? PostCardModel {
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let postCardIndex = self.listData.posts?.firstIndex(where: {$0.uniqueId == postCard.uniqueId})
                let replyCardIndex = self.listData.postsAndReplies?.firstIndex(where: {$0.uniqueId == postCard.uniqueId})
                
                if let isDeleted = notification.userInfo?["deleted"] as? Bool, isDeleted == true {
                    if let postCardIndex {
                        // Delete post card data in posts list data
                        self.listData.posts?.remove(at: postCardIndex)
                    }
                    
                    if let replyCardIndex {
                        // Delete post card data in posts & replies list data
                        self.listData.postsAndReplies?.remove(at: replyCardIndex)
                    }
                    
                    switch self.type {
                    case .posts:
                        // Request a table view cell refresh
                        if let postCardIndex {
                            // If we are deleting the very last post, we don't actually
                            // delete it, but simply reload it to show the Sparkle graphic.
                            if self.listData.posts?.count == 0 {
                                self.delegate?.didUpdateCard(at: IndexPath(row: postCardIndex, section: 0))
                            } else {
                                self.delegate?.didDeleteCard(at: IndexPath(row: postCardIndex, section: 0))
                            }
                        }
                    case .postsAndReplies:
                        // Request a table view cell refresh
                        if let replyCardIndex {
                            // If we are deleting the very last post, we don't actually
                            // delete it, but simply reload it to show the Sparkle graphic.
                            if self.listData.postsAndReplies?.count == 0 {
                                self.delegate?.didUpdateCard(at: IndexPath(row: replyCardIndex, section: 0))
                            } else {
                                self.delegate?.didDeleteCard(at: IndexPath(row: replyCardIndex, section: 0))
                            }
                        }
                    }
                } else {
                    if let postCardIndex {
                        // Replace post card data in posts list data
                        self.listData.posts?[postCardIndex] = postCard
                    }
                    
                    if let replyCardIndex {
                        // Replace post card data in posts & replies list data
                        self.listData.postsAndReplies?[replyCardIndex] = postCard
                    }
                    
                    switch self.type {
                    case .posts:
                        // Request a table view cell refresh
                        if let postCardIndex {
                            self.delegate?.didUpdateCard(at: IndexPath(row: postCardIndex, section: 0))
                        }
                    case .postsAndReplies:
                        // Request a table view cell refresh
                        if let replyCardIndex {
                            self.delegate?.didUpdateCard(at: IndexPath(row: replyCardIndex, section: 0))
                        }
                    }
                }
            }
        }
    }
    
    @objc func onUserCardUpdate(notification: Notification) {
        if let userCard = notification.userInfo?["userCard"] as? UserCardModel,
            userCard.account?.fullAcct == self.user?.account?.fullAcct {
            // Override user with updated user
            self.user = userCard
            // Override user in each post card
            self.listData.posts = self.listData.posts?.map({ postCard in postCard.withNewUser(user: userCard) })
            self.listData.postsAndReplies = self.listData.postsAndReplies?.map({ postCard in postCard.withNewUser(user: userCard) })
            // Update profile header
            self.delegate?.didUpdate(with: .success)
        }
    }
    
    @objc func didSwitchAccount(notification: Notification) {
        if let userCard = notification.userInfo?["userCard"] as? UserCardModel,
           self.screenType == .own {
            // Override user with updated user
            self.user = userCard
           
            Task { [weak self] in
                guard let self else { return }
                await self.loadListData(type: self.type)
            }
        }
    }
    
    @objc func onReloadPinned(notification: Notification) {
        Task { [weak self] in
            guard let self else { return }
            if self.screenType == .own && self.user == nil {
                self.syncCurrentUser()
            }
            
            await self.reloadUser()
            await self.loadListData(type: self.type)
        }
    }
    
    @objc func onAvatarDidChange(notification: Notification) {
        let acctData = notification.userInfo?["account"] as? any AcctDataType
        if let account = (acctData as? MastodonAcctData)?.account,
           account.fullAcct == self.user?.account?.fullAcct {
            // Override user with updated user account
            let userCard = UserCardModel(account: account, instanceName: self.user?.instanceName)
            let preSyncAccount = self.user?.preSyncAccount
            let cachedProfilePic = self.user?.decodedProfilePic
            
            self.user = userCard
            self.user?.decodedProfilePic = cachedProfilePic
            self.user?.preSyncAccount = preSyncAccount
            // Override user in each post card
            self.listData.posts = self.listData.posts?.map({ postCard in postCard.withNewUser(user: userCard) })
            self.listData.postsAndReplies = self.listData.postsAndReplies?.map({ postCard in postCard.withNewUser(user: userCard) })
            // Update profile header
            self.delegate?.didUpdate(with: .success)
        }
    }
    
    @objc func onHeaderDidChange(notification: Notification) {
        let acctData = notification.userInfo?["account"] as? any AcctDataType
        if let account = (acctData as? MastodonAcctData)?.account,
           account.fullAcct == self.user?.account?.fullAcct {
            // Override user with updated user account
            let userCard = UserCardModel(account: account, instanceName: self.user?.instanceName)
            let preSyncAccount = self.user?.preSyncAccount
            let cachedProfilePic = self.user?.decodedProfilePic
            
            self.user = userCard
            self.user?.decodedProfilePic = cachedProfilePic
            self.user?.preSyncAccount = preSyncAccount
            // Update profile header
            self.delegate?.didUpdate(with: .success)
        }
    }
    
    @objc func onFollowStatusUpdate(notification: Notification) {
        if let updatedfullAcct = notification.userInfo!["otherUserFullAcct"] as? String, let currentAccount = user?.account, updatedfullAcct == currentAccount.fullAcct {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let userCard = UserCardModel(account: currentAccount, instanceName: self.user?.instanceName)
                if userCard.followStatus != .inProgress {
                    let preSyncAccount = self.user?.preSyncAccount
                    let cachedProfilePic = self.user?.decodedProfilePic
                    
                    self.user = userCard
                    self.user?.decodedProfilePic = cachedProfilePic
                    self.user?.preSyncAccount = preSyncAccount
                    // Update profile header
                    self.delegate?.didUpdate(with: .success)
                }
            }
        }
    }
    
    @objc func onNewPostSent() {
        if self.screenType == .own {
            Task { [weak self] in
                await self?.loadListData()
            }
        }
    }
}

extension ProfileViewModel: ProfileSectionHeaderDelegate {
    func didChangeSegment(with selectedSegment: ViewTypes) {
        self.type = selectedSegment
        
        // Force a reload
        self.delegate?.didUpdate(with: .success)
        
        Task { [weak self] in
            guard let self else { return }
            await self.loadListData(type: selectedSegment)
        }
    }
}
