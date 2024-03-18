//
//  NewsFeedViewModel.swift
//  Mammoth
//
//  Created by Benoit Nolens on 26/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

enum NewsFeedViewModelError: Error {
    case invalidFeedType
}

enum NewsFeedSnapshotUpdateType {
    case hydrate        // loading items from cache
    case replaceAll     // replacing all items
    case insert         // insert at the top
    case append         // insert at the bottom
    case inject         // insert in-between (load-more)
    case update         // update an item
    case remove         // remove an item
    case removeAll      // remove all items
}

enum NewsFeedReadDirection: String {
    case bottomUp
    case topDown
}

protocol NewsFeedViewModelDelegate: AnyObject {
    func didUpdateSnapshot(_ snapshot: NewsFeedSnapshot,
                           feedType: NewsFeedTypes,
                           updateType: NewsFeedSnapshotUpdateType,
                           onCompleted: (() -> Void)?)
    func willChangeFeed(fromType: NewsFeedTypes, toType: NewsFeedTypes)
    func didChangeFeed(type: NewsFeedTypes)
    func showLoader(enabled: Bool)
    func didUpdateUnreadState(type: NewsFeedTypes)
    func getVisibleIndexPaths() async -> [IndexPath]?
}

typealias NewsFeedSnapshot =  NSDiffableDataSourceSnapshot<NewsFeedSections, NewsFeedListItem>

/// Feed types (e.g. For You, Following, Federated, etc.)
enum NewsFeedTypes: CaseIterable, Equatable, Codable, Hashable {
    static var allCases: [NewsFeedTypes] = [.forYou, .following, .federated, .community("instance"), .trending("instance"), .hashtag(Tag()), .list(List()), .likes, .bookmarks, .mentionsIn, .mentionsOut, .activity(nil), .channel(Channel())]
    
    static var allActivityTypes: [NewsFeedTypes] = [.activity(nil), .activity(.favourite), .activity(.reblog), .activity(.follow), .activity(.update)]

    case forYou
    case following
    case federated
    case community(String)
    case trending(String)
    case hashtag(Tag)
    case list(List)
    case likes
    case bookmarks
    case mentionsIn
    case mentionsOut
    case activity(NotificationType?)
    case channel(Channel)
    
    func title() -> String {
        switch self {
        case .forYou:
            return NSLocalizedString("title.forYou", comment: "Home carousel's personalized For You page title.")
        case .following:
            return NSLocalizedString("title.following", comment: "Home carousel's home timeline title.")
        case .federated:
            return NSLocalizedString("title.federated", comment: "Home carousel's federated timeline title.")
        case .community(let name):
            return name
        case .trending:
            return NSLocalizedString("title.trending", comment: "")
        case .hashtag(let hashtag):
            return "#\(hashtag.name)"
        case .list(let list):
            return list.title
        case .likes:
            return NSLocalizedString("title.likes", comment: "User's liked posts.")
        case .bookmarks:
            return NSLocalizedString("title.bookmarks", comment: "User's bookmarked posts.")
        case .mentionsIn:
            return NSLocalizedString("title.mentionsIn", comment: "")
        case .mentionsOut:
            return NSLocalizedString("title.mentionsOut", comment: "")
        case .activity:
            return NSLocalizedString("title.activity", comment: "Activity tab title.")
        case .channel(let channel):
            return channel.title
        }
    }
    
    func plainTitle() -> String {
        switch self {
        case .channel(let channel):
            return "/\(channel.title)"
        default:
            return self.title()
        }
    }
        
    func fetchAll(range: RequestRange = .default, batchName: String, retryCount: Int = 0) async throws -> ([NewsFeedListItem], cursorId: String?) {
        let batchName = "\(batchName)_\(Int.random(in: 0 ... 10000))"
        
        do {
            switch(self) {
            case .forYou:
                guard let remoteFullOriginalAcct = AccountsManager.shared.currentAccount?.remoteFullOriginalAcct else {return ([], cursorId: nil)}
                let (result, cursorId) = try await TimelineService.forYou(remoteFullOriginalAcct: remoteFullOriginalAcct, range: range)
                return (result.enumerated().map({ .postCard(PostCardModel(status: $1, withStaticMetrics: true, instanceName: $1.serverName, batchId: batchName, batchItemIndex: $0)) }), cursorId: cursorId)
                
            case .following:
                let (result, cursorId) = try await TimelineService.home(range: range)
                return (result.enumerated().map({ .postCard(PostCardModel(status: $1, withStaticMetrics: false, batchId: batchName, batchItemIndex: $0)) }), cursorId: cursorId)
                
            case .federated:
                let (result, cursorId) = try await TimelineService.federated(range: range)
                return (result.enumerated().map({ .postCard(PostCardModel(status: $1, withStaticMetrics: false, batchId: batchName, batchItemIndex: $0)) }), cursorId: cursorId)
                
            case .community(let name):
                let (result, cursorId) = try await TimelineService.community(instanceName: name, type: .public, range: range)
                return (result.enumerated().map({ .postCard(PostCardModel(status: $1, withStaticMetrics: false, instanceName: name, batchId: batchName, batchItemIndex: $0)) }), cursorId: cursorId)
                
            case .trending(let name):
                let (result, cursorId) = try await TimelineService.community(instanceName: name, type: .trending, range: range)
                return (result.enumerated().map({ .postCard(PostCardModel(status: $1, withStaticMetrics: false, instanceName: name, batchId: batchName, batchItemIndex: $0)) }), cursorId: cursorId)
                
            case .hashtag(let hashtag):
                let (result, cursorId) = try await TimelineService.tag(hashtag: hashtag.name, range: range)
                return (result.enumerated().map({ .postCard(PostCardModel(status: $1, withStaticMetrics: false, instanceName: $1.serverName, batchId: batchName, batchItemIndex: $0)) }), cursorId: cursorId)
                
            case .list(let list):
                let (result, cursorId) = try await TimelineService.list(listId: list.id, range: range)
                return (result.enumerated().map({ .postCard(PostCardModel(status: $1, withStaticMetrics: false, instanceName: $1.serverName, batchId: batchName, batchItemIndex: $0)) }), cursorId: cursorId)
                
            case .likes:
                throw NewsFeedViewModelError.invalidFeedType

            case .bookmarks:
                throw NewsFeedViewModelError.invalidFeedType
                
            case .mentionsIn:
                let (result, cursorId) = try await TimelineService.mentions(range: range)
                return (result.enumerated().map({ .postCard(PostCardModel(status: $1, withStaticMetrics: false, batchId: batchName, batchItemIndex: $0)) }), cursorId: cursorId)
                
            case .mentionsOut:
                let (result, cursorId) = try await AccountService.mentionsSent(range: range)
                return (result.enumerated().map({ .postCard(PostCardModel(status: $1, withStaticMetrics: false, batchId: batchName, batchItemIndex: $0)) }), cursorId: cursorId)
                
            case .activity(let type):
                let (result, cursorId) = try await TimelineService.activity(range: range, type: type)
                return (result.enumerated().compactMap({
                    // Hide 'New Post' notifications of deleted posts
                    guard !($1.type == .status && $1.status == nil) else { return nil }
                    return .activity(ActivityCardModel(notification: $1, batchId: batchName, batchItemIndex: $0)) }), cursorId: cursorId)
                
            case .channel(let channel):
                let (result, cursorId) = try await TimelineService.channel(channelId: channel.id, range: range)
                return (result.enumerated().map({ .postCard(PostCardModel(status: $1, withStaticMetrics: false, instanceName: $1.serverName, batchId: batchName, batchItemIndex: $0)) }), cursorId: cursorId)
            }
        } catch {
            // Mastodon might return a 206 error when the feed is being regenerated.
            // If so, wait 3 seconds and retry (max 4 times)
            // https://docs.joinmastodon.org/methods/timelines/#206-partial-content
            if let clientError = error as? ClientError {
                switch clientError {
                case .networkError(let statusCode):
                    if (statusCode == 206 || statusCode == 500) && retryCount < 5 {
                        log.error("error status code \(statusCode); going to retry in 3 seconds")
                        try await Task.sleep(seconds: 3)
                        return try await self.fetchAll(range: range, batchName: batchName, retryCount: retryCount + 1)
                    }
                    fallthrough
                default:
                    throw error
                }
            } else {
                throw error
            }
        }
    }
    
    func fetchAllPaginated(range: RequestRange = .default, batchName: String, retryCount: Int = 0) async throws -> ([NewsFeedListItem], Pagination?, String?) {
        let batchName = "\(batchName)_\(Int.random(in: 0 ... 10000))"

        switch(self) {
        case .bookmarks:
            let (result, pagination, cursorId) = try await TimelineService.bookmarks(range: range)
            return (result.enumerated().map({ .postCard(PostCardModel(status: $1, withStaticMetrics: false, batchId: batchName, batchItemIndex: $0)) }), pagination, cursorId)
        case .likes:
            let (result, pagination, cursorId) = try await TimelineService.likes(range: range)
            return (result.enumerated().map({ .postCard(PostCardModel(status: $1, withStaticMetrics: false, batchId: batchName, batchItemIndex: $0)) }), pagination, cursorId)
        default:
            // fetchAllPaginated() only applies to bookmarks
            throw NewsFeedViewModelError.invalidFeedType
        }

        // There is no catch block here as bookmarks should not rate limit like news feeds might
    }
        
    // Map cell types to view types
    func postCardCellType() -> PostCardCell.PostCardCellType {
        switch self {
        case .forYou:
            return PostCardCell.PostCardCellType.forYou
        case .channel(_):
            return PostCardCell.PostCardCellType.channel
        case .mentionsIn:
            return PostCardCell.PostCardCellType.mentions
        case .mentionsOut:
            return PostCardCell.PostCardCellType.mentions
        case .following:
            return PostCardCell.PostCardCellType.following
        case .list(_):
            return PostCardCell.PostCardCellType.list
        default:
            return PostCardCell.PostCardCellType.regular
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch(self) {
        case .forYou:
            return hasher.combine("forYou")
        case .following:
            return hasher.combine("following")
        case .federated:
            return hasher.combine("federated")
        case .community(let name):
            return hasher.combine("community:\(name)")
        case .trending(let name):
            return hasher.combine("trending:\(name)")
        case .hashtag(let hashtag):
            return hasher.combine("hashtag:\(hashtag.url)")
        case .list(let list):
            return hasher.combine("list:\(list.id)")
        case .likes:
            return hasher.combine("likes")
        case .bookmarks:
            return hasher.combine("bookmarks")
        case .mentionsIn:
            return hasher.combine("mentionsIn")
        case .mentionsOut:
            return hasher.combine("mentionsOut")
        case .activity(let type):
            return hasher.combine("activity:\(type?.rawValue ?? "all")")
        case .channel(let channel):
            return hasher.combine("channel:\(channel.id)")
        }
    }
    
    static func ==(lhs: NewsFeedTypes, rhs: NewsFeedTypes) -> Bool {
        switch (lhs, rhs) {
        case (.community(let lhsName), .community(let rhsName)):
            return lhsName == rhsName
        case (.trending(let lhsName), .trending(let rhsName)):
            return lhsName == rhsName
        case (.hashtag(let lhsTag), .hashtag(let rhsTag)):
            return lhsTag.name == rhsTag.name
        case (.list(let lhsList), .list(let rhsList)):
            return lhsList.id == rhsList.id && lhsList.title == rhsList.title
        case (.forYou, .forYou):
            return true
        case (.following, .following):
            return true
        case (.federated, .federated):
            return true
        case (.likes, .likes):
            return true
        case (.bookmarks, .bookmarks):
            return true
        case (.mentionsIn, .mentionsIn):
            return true
        case (.mentionsOut, .mentionsOut):
            return true
        case (.activity(let lhsType), .activity(let rhsType)):
            return lhsType == rhsType
        case (.channel(let lhsChannel), .channel(let rhsChannel)):
            return lhsChannel.id == rhsChannel.id
        default:
            return false
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .following:
            return FontAwesome.image(fromChar: "\u{f0a9}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate)
        case .federated:
            return FontAwesome.image(fromChar: "\u{f0ac}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate)
        case .channel:
            return "/".image(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .heavy)])?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        case .forYou:
            return FontAwesome.image(fromChar: "\u{f890}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate)
        case .hashtag:
            return FontAwesome.image(fromChar: "\u{23}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate)
        case .list:
            return FontAwesome.image(fromChar: "\u{f0ca}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate)
        case .community:
            return FontAwesome.image(fromChar: "\u{e594}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate)
        default:
            return FontAwesome.image(fromChar: "\u{f0a9}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate)
        }
    }
    
    func attributedTitle() -> NSAttributedString {
        switch self {
        case .channel:
            let title = NSMutableAttributedString(string: "/", attributes: [.baselineOffset: 1])
            title.addAttribute(.font, value: UIFont.systemFont(ofSize: 16, weight: .heavy), range: NSMakeRange(0, title.length))
            
            let spacerImage = NSTextAttachment()
            spacerImage.image = UIImage()
            spacerImage.bounds = CGRect.init(x: 0, y: 0, width: 1.5, height: 0.0001)

            title.append(NSAttributedString(attachment: spacerImage))
            title.append(NSAttributedString(string: self.title()))
            
            title.addAttribute(.foregroundColor, value: UIColor.custom.gold, range: NSMakeRange(0, 1))
            title.addAttribute(.foregroundColor, value: UIColor.custom.highContrast, range: NSMakeRange(1, title.length-1))
            title.addAttribute(.baselineOffset, value: 0.5, range: .init(location: 0, length: 1))
            title.addAttribute(.baselineOffset, value: 0.5, range: .init(location: 2, length: self.title().count))
            
            return title
        case .hashtag(let tag):
            let title = NSMutableAttributedString(string: "#")
            title.addAttribute(.font, value: UIFont.systemFont(ofSize: 16, weight: .heavy), range: NSMakeRange(0, title.length))
            
            let spacerImage = NSTextAttachment()
            spacerImage.image = UIImage()
            spacerImage.bounds = CGRect.init(x: 0, y: 0, width: 1, height: 0.0001)

            title.append(NSAttributedString(attachment: spacerImage))
            title.append(NSAttributedString(string: tag.name))
            
            title.addAttribute(.foregroundColor, value: UIColor.custom.gold, range: NSMakeRange(0, 1))
            title.addAttribute(.foregroundColor, value: UIColor.custom.highContrast, range: NSMakeRange(1, title.length-1))
            title.addAttribute(.baselineOffset, value: 0.5, range: .init(location: 0, length: 1))
            title.addAttribute(.baselineOffset, value: 0.5, range: .init(location: 2, length: tag.name.count))
            
            return title
        default:
            return NSAttributedString(string: self.title())
        }
    }
    
    var shouldSyncItems: Bool {
        switch self {
        case .activity, .mentionsIn, .mentionsOut, .bookmarks:
            return false
        default:
            return true
        }
    }
    
    var shouldPollForListData: Bool {
        switch self {
        case .activity, .mentionsIn, .mentionsOut, .bookmarks:
            return false
        default:
            return true
        }
    }
}
     
class NewsFeedViewModel {
    
    class NewsFeedDiffableDataSource: UITableViewDiffableDataSource<NewsFeedSections, NewsFeedListItem> {}
    public var dataSource: NewsFeedDiffableDataSource?
    public var snapshot = NewsFeedSnapshot()
    
    var isJumpToNowButtonDisabled: Bool = false
    
    internal var state: ViewState
    internal var listData = NewsFeedListData()
    internal var isLoadMoreEnabled: Bool = true
        
    internal var pollingTask: Task<Void, Error>?
    internal var pollingFrequency: Double { //seconds
        switch self.type {
        case .mentionsIn, .activity:
            return 10
        case .mentionsOut:
            return 60
        default:
            return 30
        }
    }
        
    internal var postSyncingTasks: [IndexPath: Task<Void, Error>] = [:]
    internal var forYouStatus: ForYouStatus? = nil
    
    internal var cursorId: String?
    internal var nextPageRange: RequestRange?
    internal var previousPageRange: RequestRange?
    
    internal var newestSectionLength: Int = 35
    internal var newItemsThreshold: Int {
        switch self.type {
        case .mentionsIn, .mentionsOut, .activity, .bookmarks:
            return 1
        default:
            return 5
        }
    }
    
    internal var makePaginatedRequest: Bool {
        switch self.type {
        case .bookmarks, .likes:
            return true
        default:
            return false
        }
    }
    
    internal var scrollPositions = NewsFeedScrollPositions()
    internal var unreadCounts = NewsFeedUnreadStates()

    internal let savingQueue = DispatchQueue(label: "NewsFeedViewModel Saving", qos: .utility)

    public weak var delegate: NewsFeedViewModelDelegate?
    public var type: NewsFeedTypes

    init(_ type: NewsFeedTypes = .forYou) {
        self.state = .idle
        self.type = type
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onPostCardUpdate),
                                               name: PostActions.didUpdatePostCardNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onStatusUpdate),
                                               name: didChangeFollowStatusNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onModerationChange),
                                               name: didChangeModerationNotification,
                                               object: nil)
        
        // Websocket updates for activity and mentions tab
        if [.mentionsIn].contains(type) || NewsFeedTypes.allActivityTypes.contains(type) {
            RealtimeManager.shared.onEvent { [weak self] data in
                guard let self else { return }
                switch data {
                case .notification(let notification):
                    if [.direct, .mention].contains(notification.type) {
                        guard type == .mentionsIn else { return }
                        if let status = notification.status {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "showIndActivity2"), object: self)
                            let newPost = PostCardModel(status: status)
                            let newItem = NewsFeedListItem.postCard(newPost)
                            
                            self.insertUnreadIds(ids: [newItem.uniqueId()], forFeed: .mentionsIn)
                            self.setUnreadEnabled(enabled: true, forFeed: .mentionsIn)
                            
                            if !self.isItemInSnapshot(newItem) {
                                newPost.preloadQuotePost()
                                self.insertNewest(items: [newItem], includeLoadMore: false, forType: .mentionsIn)
                            }
                        }
                    } else {
                        if case .activity(let activityType) = type, notification.type == activityType {
                            let newItem = NewsFeedListItem.activity(ActivityCardModel(notification: notification))
                            
                            self.insertUnreadIds(ids: [newItem.uniqueId()], forFeed: .activity(nil))
                            self.setUnreadEnabled(enabled: true, forFeed: .activity(nil))
                            
                            if !self.isItemInSnapshot(newItem) {
                                self.insertNewest(items: [newItem], includeLoadMore: false, forType: .activity(activityType))
                            }
                        } else if case .activity(let activityType) = type, activityType == nil { // activityType == nil means All activity
                            let newItem = NewsFeedListItem.activity(ActivityCardModel(notification: notification))
                            
                            self.insertUnreadIds(ids: [newItem.uniqueId()], forFeed: .activity(nil))
                            self.setUnreadEnabled(enabled: true, forFeed: .activity(nil))
                            
                            if !self.isItemInSnapshot(newItem) {
                                self.insertNewest(items: [newItem], includeLoadMore: false, forType: .activity(nil))
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "showIndActivity"), object: self)
                            }
                        }
                    }
                default: break
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func changeFeed(type: NewsFeedTypes) {
        guard type != self.type else { return }
        
        self.cursorId = nil
        self.stopPollingListData()
        let previousType = self.type
        self.delegate?.willChangeFeed(fromType: previousType, toType: type)
        self.type = type
        self.hideEmpty(forType: type)
        self.clearErrorState(type: self.type)
        log.debug("[NewsFeedViewModel] Sync data source from `changeFeed`")
        self.syncDataSource(type: type) { [weak self] in
            guard let self else { return }
            self.delegate?.didChangeFeed(type: type)
            
            if self.snapshot.indexOfSection(.main) == nil || self.snapshot.itemIdentifiers(inSection: .main).isEmpty {
                self.displayLoader(forType: type)
                Task { [weak self] in
                    guard let self else { return }
                    try await self.loadListData(type: type, fetchType: .refresh)
                }
            }
            
            if (self.type.shouldPollForListData) {
                self.startPollingListData(forFeed: type)
            }
        }
    }
    
    func clearErrorState(type: NewsFeedTypes) {
        if case .error(_) = self.state {
            self.state = .success
            self.hideError(feedType: self.type)
        }
        
        self.isLoadMoreEnabled = true
    }
    
    func cleanUpMemoryOfCurrentFeed() {
        self.snapshot.itemIdentifiers.forEach({
            if case .postCard(let postCard) = $0 {
                postCard.clearCache()
            } else if case .activity(let activityCard) = $0 {
                activityCard.postCard?.clearCache()
            }
        })
    }
    
    func pauseAllVideos() {
        self.snapshot.itemIdentifiers.forEach({
            if case .postCard(let postCard) = $0 {
                postCard.videoPlayer?.pause()
            } else if case .activity(let activityCard) = $0 {
                activityCard.postCard?.videoPlayer?.pause()
            }
        })
    }
    
    func updateCurrentRange(newPagination: Pagination?) {
        guard let newPagination = newPagination else { return }
        guard let nextPage = newPagination.next else { 
            self.nextPageRange = nil
            return
        }
        extendNextPageRange(newRange: nextPage)
        guard let previousPage = newPagination.previous else {
            self.previousPageRange = nil
            return
        }
        extendPreviousPageRange(newRange: previousPage)
    }
    
    func extendNextPageRange(newRange: RequestRange) {
        if self.nextPageRange == nil {
            self.nextPageRange = newRange
        } else if (newRange < self.nextPageRange!) {
            self.nextPageRange = newRange
        }
    }
    
    func extendPreviousPageRange(newRange: RequestRange) {
        if self.previousPageRange == nil {
            self.previousPageRange = newRange
        } else if (newRange > self.nextPageRange!) {
            self.previousPageRange = newRange
        }
    }
}

// MARK: - Force reload ForYou feed
extension NewsFeedViewModel {
    func forceReloadForYou() -> Void {
        if self.type == .forYou {
            self.removeAll(type: .forYou)
            let type = self.type
            self.displayLoader(forType: type)
            Task { [weak self] in
                guard let self else { return }
                try await self.loadListData(type: type, fetchType: .refresh)
            }
        } else {
            // silently clear cache
            self.listData.clear(forType: .forYou)
            self.saveToDisk(items: [], position: NewsFeedScrollPosition(), feedType: .forYou)
        }
    }
}

// MARK: - Notification handlers
private extension NewsFeedViewModel {
    
    @objc func onPostCardUpdate(notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let postCard = notification.userInfo?["postCard"] as? PostCardModel {
                if let isDeleted = notification.userInfo?["deleted"] as? Bool, isDeleted == true {
                    // Delete post card data in list data and data source
                    self.remove(card: postCard, forType: self.type)
                } else {
                    // Replace activity data in list that include this post card
                    if NewsFeedTypes.allActivityTypes.contains(self.type) {
                        self.listData.activity.forEach { (key, activities) in
                            if let index = activities.firstIndex(where: {$0.extractPostCard()?.uniqueId == postCard.uniqueId}) {
                                if case .activity(let activity) = activities[index] {
                                    activity.postCard = postCard
                                    let activityType: NotificationType? = key == "all" ? nil : NotificationType(rawValue: key)
                                    self.update(with: .activity(activity), forType: .activity(activityType))
                                }
                            }
                        }
                    } else {
                        // Replace post card data in list data and data source
                        self.update(with: .postCard(postCard), forType: self.type)
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
                    self.updateFollowStatusForPosts(fromAccount: fullAcct)
                }
            }
        }
    }
    
    @objc private func onModerationChange(notification: Notification) {
        self.refreshSnapshot()
    }
}
