//
//  DetailViewModel.swift
//  Mammoth
//
//  Created by Benoit Nolens on 05/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class DetailViewModel {

    private struct ListData {
        var parents: [PostCardModel]?
        var post: PostCardModel
        var replies: [PostCardModel]?
        
        func indexPath(forPost post: PostCardModel) -> IndexPath? {
            if self.post.uniqueId == post.uniqueId {
                return IndexPath(row: 0, section: Section.post.rawValue)
            }
            if let index = self.parents?.firstIndex(where: {$0.uniqueId == post.uniqueId}) {
                return IndexPath(row: index, section: Section.parents.rawValue)
            }
            if let index = self.replies?.firstIndex(where: {$0.uniqueId == post.uniqueId}) {
                return IndexPath(row: index, section: Section.replies.rawValue)
            }
            
            return nil
        }
        
        mutating func update(post: PostCardModel) {
            if self.post.uniqueId == post.uniqueId {
                self.post = post
            }
            if let index = self.parents?.firstIndex(where: {$0.uniqueId == post.uniqueId}) {
                self.parents![index] = post
            }
            if let index = self.replies?.firstIndex(where: {$0.uniqueId == post.uniqueId}) {
                self.replies![index] = post
            }
        }
        
        mutating func delete(post: PostCardModel) {
            if let index = self.parents?.firstIndex(where: {$0.uniqueId == post.uniqueId}) {
                self.parents!.remove(at: index)
            }
            if let index = self.replies?.firstIndex(where: {$0.uniqueId == post.uniqueId}) {
                self.replies!.remove(at: index)
            }
        }
        
        mutating func updateFollowStatusForPosts(fromAccount fullAcct: String) {
            if let postCardFullAccount = self.post.user?.account?.fullAcct,
               let account = self.post.user?.account, postCardFullAccount == fullAcct {
                
                // Reinstantiating the UserCardModel will use the latest follow status
                self.post.user = UserCardModel(account: account)
            }
            
            self.parents = self.parents?.map({
                if let postCardFullAccount = $0.user?.account?.fullAcct,
                   let account = $0.user?.account, postCardFullAccount == fullAcct {
                    
                    // Reinstantiating the UserCardModel will use the latest follow status
                    $0.user = UserCardModel(account: account)
                    
                    return $0
                }
                
                return $0
            })
            
            self.replies = self.replies?.map({
                if let postCardFullAccount = $0.user?.account?.fullAcct,
                   let account = $0.user?.account, postCardFullAccount == fullAcct {
                    
                    // Reinstantiating the UserCardModel will use the latest follow status
                    $0.user = UserCardModel(account: account)
                    
                    return $0
                }
                
                return $0
            })
        }
    }
    
    enum Section: Int {
        case parents = 0
        case post = 1
        case replies = 2
    }
    
    weak var delegate: RequestDelegate?
    
    private var state: ViewState {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.delegate?.didUpdate(with: self.state)
            }
        }
    }

    private var listData: ListData
    private var isScrollIndicatorDismissed = true
    private var showStatusSource = false
    
    public var post: PostCardModel {
        return listData.post
    }

    init(post: PostCardModel, showStatusSource: Bool) {
        self.state = .idle
        self.listData = ListData(post: post)
        self.showStatusSource = showStatusSource
   
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onPostCardUpdate),
                                               name: PostActions.didUpdatePostCardNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onStatusUpdate),
                                               name: didChangeFollowStatusNotification,
                                               object: nil)
        
        Task { [weak self] in
            guard let self else { return }
            try await self.refreshData(reloadPost: !post.isSyncedWithOriginal)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - DataSource
extension DetailViewModel {
    func numberOfItems(forSection section: Int) -> Int {
        guard let detailSection = Section(rawValue: section) else { return 0 }
        
        switch detailSection {
        case Section.parents:
            return self.listData.parents?.count ?? 0
        case Section.post:
            return 1
        case Section.replies:
            return (self.listData.replies?.count ?? 0) + (self.shouldDisplayLoader() ? 1 : 0) + (self.shouldDisplayError() ? 1 : 0)
        }
    }
    
    var numberOfSections: Int {
        return 3
    }

    func getInfo(forIndexPath indexPath: IndexPath) -> PostCardModel? {
        guard let detailSection = Section(rawValue: indexPath.section) else { return nil }
        
        switch(detailSection) {
        case Section.parents:
            return self.listData.parents?[indexPath.row]
        case Section.post:
            return self.listData.post
        case Section.replies:
            // this might be a loader cell
            guard let replies = self.listData.replies, replies.count > indexPath.row else { return nil }
            return self.listData.replies?[indexPath.row]
        }
    }
    
    func hasChild(indexPath: IndexPath) -> Bool {
        switch Section(rawValue: indexPath.section) {
        case .parents:
            return true
        case .post:
            return !(self.listData.replies?.isEmpty ?? true)
        case .replies:
            return indexPath.row < (self.listData.replies?.count ?? 0) - 1
        default:
            return false
        }
    }
    
    func hasParent(indexPath: IndexPath) -> Bool {
        switch Section(rawValue: indexPath.section) {
        case .parents:
            return indexPath.row > 0
        case .post:
            return !(self.listData.parents?.isEmpty ?? true)
        case .replies:
            return true
        default:
            return false
        }
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
    
    func shouldShowScrollUpIndicator() -> Bool {
        return !(self.listData.parents?.isEmpty ?? true) && !self.isScrollIndicatorDismissed
    }
}

// MARK: - Service
extension DetailViewModel {
    public func refreshData(reloadPost: Bool = true, instanceName: String? = nil) async throws {
        do {
            await MainActor.run { self.state = .loading }
            
            var server = instanceName ?? self.listData.post.originalInstanceName ?? GlobalHostServer()
            var postId = self.listData.post.originalId
            // For Threads posts, load post and context thru user's instance
            if self.listData.post.originalInstanceName == "www.threads.net" {
                server = AccountsManager.shared.currentAccountClient.baseHost
                postId = self.listData.post.id
            }
            
            let instanceName = server
            let id = postId
            // fetch original post
            async let fetchPost = reloadPost ? StatusService.fetchStatus(id: id, instanceName: instanceName) : nil
            // fetch post context (replies and parent post)
            async let fetchContext: (parents: [PostCardModel]?, replies: [PostCardModel]?)? = self.loadContext(post: self.listData.post, instanceName: instanceName)
            // fetch status source
            async let fetchSource = showStatusSource ? TimelineService.forYouStatusSource(id: self.listData.post.id!) : nil
            
            // Wait for all results
            let result = try await [ fetchPost, fetchContext, fetchSource] as [Any?]
            
            await MainActor.run  { [weak self] in
                guard let self else { return }
                // Handle results for `fetchPost`
                // if `reloadPost` is set to false we don't re-fetch the post and result[0] is nil
                if let status = result[0] as? Status {
                    if let account = self.post.user?.account {
                        self.post.user!.followStatus = FollowManager.shared.followStatusForAccount(account, requestUpdate: .force)
                    }
                    
                    self.listData.post = self.listData.post.mergeInOriginalData(status: status)
                    self.listData.post.preloadQuotePost()
                }
                
                // Handle results for `fetchContext`
                if let (parents, replies) = result[1] as? (parents: [PostCardModel]?, replies: [PostCardModel]?) {
                    // workaround for MAM-3683. basically we make sure remote usertags look like local usertags.
                    parents?.forEach { PostCardModel.normalizeUsertag($0) }
                    replies?.forEach { PostCardModel.normalizeUsertag($0) }
                    self.listData = ListData(parents: parents, post: self.listData.post, replies: replies)
                    self.isScrollIndicatorDismissed = false
                    
                    PostCardModel.preload(postCards: (parents ?? []) + (replies ?? []))
                }
                
                // Handle results for `fetchSource`
                if let source = result[2] as? [StatusSource] {
                    self.listData.post.statusSource = source
                }
                
                self.state = .success
            }
        } catch let error {
            if instanceName != AccountsManager.shared.currentAccountClient.baseHost {
                // Retry thru user's instance
                try await self.refreshData(reloadPost: false, instanceName: AccountsManager.shared.currentAccountClient.baseHost)
            } else {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.state = .error(error)
                }
            }
        }
    }
    
    private func loadContext(post: PostCardModel, instanceName: String? = nil) async throws -> (parents: [PostCardModel]?, replies: [PostCardModel]?)? {
        if case .mastodon(let status) = post.data {
            let context = try await StatusService.fetchContext(status: status, instanceName: instanceName ?? post.instanceName, withPolicy: .retryLocally)
            let parents = context?.ancestors.map({ PostCardModel(status: $0, instanceName: instanceName ?? post.instanceName) })
            let replies = context?.descendants.map({ PostCardModel(status: $0, instanceName: instanceName ?? post.instanceName) })
            
            return (parents: parents, replies: replies)
        }
        
        return nil
    }
    
    public func dismissScrollUpIndicator() {
        self.isScrollIndicatorDismissed = true
    }
}

// MARK: - Notification handlers
private extension DetailViewModel {
    @objc func onPostCardUpdate(notification: Notification) {
        if let postCard = notification.userInfo?["postCard"] as? PostCardModel {
            if let cardIndexPath = self.listData.indexPath(forPost: postCard) {
               if let isDeleted = notification.userInfo?["deleted"] as? Bool, isDeleted == true {
                   DispatchQueue.main.async { [weak self] in
                       guard let self else { return }
                       // Replace post card data in list data
                       self.listData.delete(post: postCard)
                       // Request a table view cell refresh
                       self.delegate?.didDeleteCard(at: cardIndexPath)
                   }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        // Replace post card data in list data
                        self.listData.update(post: postCard)
                        // Request a table view cell refresh
                        self.delegate?.didUpdateCard(at: cardIndexPath)
                    }
                }
            }
        }
    }
    
    @objc func onStatusUpdate(notification: Notification) {
        // Only observe the notification if it's tied to the current user.
        if (notification.userInfo!["currentUserFullAcct"] as! String) == AccountsManager.shared.currentUser()?.fullAcct {
            let fullAcct = notification.userInfo!["otherUserFullAcct"] as! String
            let followStatus = FollowManager.FollowStatus(rawValue: notification.userInfo!["followStatus"] as! String)!
            if followStatus != .inProgress {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.listData.updateFollowStatusForPosts(fromAccount: fullAcct)
                    self.delegate?.didUpdate(with: .success)
                }
            }
        }
    }
}
