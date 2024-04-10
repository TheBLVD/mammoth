//
//  NewsFeedViewController.swift
//  Mammoth
//
//  Created by Benoit Nolens on 26/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

protocol NewsFeedViewControllerDelegate: AnyObject {
    func willChangeFeed(_ type: NewsFeedTypes)
    func didChangeFeed(_ type: NewsFeedTypes)
    func didScrollToTop()
    func userActivityStorageIdentifier() -> String
    func isActiveFeed(_ type: NewsFeedTypes) -> Bool
}

class NewsFeedViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSourcePrefetching {
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .textOnly))
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .textAndMedia(.hidden)))
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .textAndMedia(.small)))
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .textAndMedia(.large)))
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .mediaOnly(.hidden)))
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .mediaOnly(.small)))
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .mediaOnly(.large)))
        tableView.register(ActivityCardCell.self, forCellReuseIdentifier: ActivityCardCell.reuseIdentifier)
        tableView.register(LoadMoreCell.self, forCellReuseIdentifier: LoadMoreCell.reuseIdentifier)
        tableView.register(ServerUpdatingCell.self, forCellReuseIdentifier: ServerUpdatingCell.reuseIdentifier)
        tableView.register(ServerUpdatedCell.self, forCellReuseIdentifier: ServerUpdatedCell.reuseIdentifier)
        tableView.register(ServerOverloadCell.self, forCellReuseIdentifier: ServerOverloadCell.reuseIdentifier)
        tableView.register(ErrorCell.self, forCellReuseIdentifier: ErrorCell.reuseIdentifier)
        tableView.register(EmptyFeedCell.self, forCellReuseIdentifier: EmptyFeedCell.reuseIdentifier)
        tableView.delegate = self
        tableView.prefetchDataSource = self
        tableView.backgroundColor = .custom.background
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInsetAdjustmentBehavior = .automatic
        tableView.delaysContentTouches = false
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }
        
        // Hides the last separator
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        return tableView
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(self.onDragToRefresh(_:)), for: .valueChanged)
        return refresh
    }()
    
    private var displayingIndexPath: IndexPath?
    
    private let latestPill = LatestPill()
    private let unreadIndicator = UnreadIndicator()
    private let jumpToNow = JumpToLatest()
    private var feedMenuItems : [UIMenu] = []
    private var viewModel: NewsFeedViewModel
    private var didInitializeOnce = false
    private var isInsertingContent: Bool = false
    private var isScrollingProgrammatically: Bool = false
    private var disableFeedUpdates: Bool = false
    
    // switchingAccounts is set to true in the period between
    // willSwitchAccount and didSwitchAccount, when currentAccount
    // should not be accessed.
    private var switchingAccounts = false
    
    weak var delegate: NewsFeedViewControllerDelegate?
    private var deferredSnapshotUpdatesCallbacks: [(() -> Void)] = []
    
    public var type: NewsFeedTypes {
        return self.viewModel.type
    }
    
    private var isActiveFeed: Bool {
        if let isActive = self.delegate?.isActiveFeed(self.type){
            return isActive
        }
        return true
    }
    
    convenience init(type: NewsFeedTypes) {
        let viewModel = NewsFeedViewModel(type)
        self.init(viewModel: viewModel)
    }

    required init(viewModel: NewsFeedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        self.title = self.viewModel.type.title()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.feedMenuItemsChanged),
                                               name: NSNotification.Name(rawValue: "updateClient"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onThemeChange),
                                               name: NSNotification.Name(rawValue: "reloadAll"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.feedMenuItemsChanged),
                                               name: didChangePinnedInstancesNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.feedMenuItemsChanged),
                                               name: didChangeHashtagsNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.feedMenuItemsChanged),
                                               name: didChangeListsNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.appWillResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.appDidBecomeActive),
                                               name: appDidBecomeActiveNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.willSwitchAccount),
                                               name: willSwitchCurrentAccountNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didSwitchAccount),
                                               name: didSwitchCurrentAccountNotification,
                                               object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.viewModel.stopPollingListData()
        if self.viewModel.type.shouldSyncItems {
            self.viewModel.cancelAllItemSyncs()
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupObservers()
                
        let gesturePill = UITapGestureRecognizer(target: self, action: #selector(self.onUnreadTapped))
        self.latestPill.addGestureRecognizer(gesturePill)
        
        let gestureUnread = UITapGestureRecognizer(target: self, action: #selector(self.onUnreadTapped))
        self.unreadIndicator.addGestureRecognizer(gestureUnread)
        
        let gestureToNow = UITapGestureRecognizer(target: self, action: #selector(self.onJumpToNow))
        self.jumpToNow.addGestureRecognizer(gestureToNow)
                        
        if (NewsFeedTypes.allActivityTypes + [.mentionsIn, .mentionsOut]).contains(self.viewModel.type) {
            if !self.didInitializeOnce {
                self.didInitializeOnce = true
                log.debug("[NewsFeedViewController] Sync data source from `viewDidLoad` - \(self.viewModel.type)")
                self.viewModel.syncDataSource(type: self.viewModel.type) { [weak self] in
                    guard let self else { return }
                    guard self.viewModel.snapshot.sectionIdentifiers.contains(.main) else { return }
                    if self.viewModel.snapshot.itemIdentifiers(inSection: .main).isEmpty {
                        let type = self.viewModel.type
                        self.viewModel.displayLoader(forType: type)
                    } else {
                        self.tableView.visibleCells.forEach({
                            if let cell = $0 as? PostCardCell {
                                cell.willDisplay()
                            } else if let cell = $0 as? ActivityCardCell {
                                cell.willDisplay()
                            }
                        })
                    }
                    
                    Task { [weak self] in
                        guard let self else { return }
                        if [.mentionsIn].contains(type) || NewsFeedTypes.allActivityTypes.contains(self.viewModel.type) {
                            try await self.viewModel.loadListData(type: type, fetchType: .refresh)
                        } else {
                            if GlobalStruct.feedReadDirection == .bottomUp {
                                try await self.viewModel.loadListData(type: self.viewModel.type, fetchType: .previousPage)
                            } else {
                                try await self.viewModel.loadLatest(feedType: type, threshold: 1)
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !self.didInitializeOnce {
            self.didInitializeOnce = true
            log.debug("[NewsFeedViewController] Sync data source from `viewDidAppear` - \(self.viewModel.type)")
            
            // This `DispatchQueue.main.async` allows the runloop to complete once before hydration.
            // If removed the tableview is not correctly initialized and will not be restored correctly.
            DispatchQueue.main.async {
                self.viewModel.syncDataSource(type: self.viewModel.type) { [weak self] in
                    guard let self else { return }
                    Task {
                        self.viewModel.snapshot = self.viewModel.appendMainSectionToSnapshot(snapshot: self.viewModel.snapshot)
                        self.viewModel.dataSource?.apply(self.viewModel.snapshot, animatingDifferences: false)
                        
                        if self.viewModel.snapshot.itemIdentifiers(inSection: .main).isEmpty {
                            let type = self.viewModel.type
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.viewModel.displayLoader(forType: type)
                            }
                            
                            Task { [weak self] in
                                guard let self else { return }
                                if [.mentionsIn].contains(type) || NewsFeedTypes.allActivityTypes.contains(self.viewModel.type) {
                                    try await self.viewModel.loadListData(type: type, fetchType: .refresh)
                                } else {
                                    if GlobalStruct.feedReadDirection == .bottomUp {
                                        try await self.viewModel.loadListData(type: type, fetchType: .previousPage)
                                    } else {
                                        try await self.viewModel.loadLatest(feedType: type, threshold: 1)
                                    }
                                }
                            }
                        } else {
                            self.showLoader(enabled: false)
                            
                            self.tableView.visibleCells.forEach({
                                if let cell = $0 as? PostCardCell {
                                    cell.willDisplay()
                                } else if let cell = $0 as? ActivityCardCell {
                                    cell.willDisplay()
                                }
                            })
                        }
                    }
                }
            }
        }
                
        if self.viewModel.type.shouldPollForListData {
            self.viewModel.startPollingListData(forFeed: self.viewModel.type, delay: 1)
        }
        
        // If the user disabled the JumpToNow button (pressed the close button)
        // re-enable it now
        self.viewModel.isJumpToNowButtonDisabled = false
        
        self.didUpdateSnapshot(self.viewModel.snapshot, feedType: self.viewModel.type, updateType: .insert, scrollPosition: nil, onCompleted: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.setRightBarButtonItems(self.navBarItems(), animated: false)
        
        if !self.didInitializeOnce {
            let type = self.viewModel.type
            self.viewModel.displayLoader(forType: type)
        }
        
        self.viewModel.clearErrorState(type: self.viewModel.type)
        
        configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !self.switchingAccounts {
            if !NewsFeedTypes.allActivityTypes.contains(self.viewModel.type) && self.viewModel.type != .mentionsIn {
                self.viewModel.stopPollingListData()
            }
            if self.viewModel.type.shouldSyncItems {
                self.viewModel.cancelAllItemSyncs()
            }
            self.cacheScrollPosition(tableView: self.tableView, forFeed: self.viewModel.type)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
                
        // Only clean up feed on tab change
        if !animated {
            self.viewModel.cleanUpMemoryOfCurrentFeed()
            AVManager.shared.currentPlayer?.pause()
        }
    }
    
    public func pauseAllVideos() {
        self.viewModel.cleanUpMemoryOfCurrentFeed()
        AVManager.shared.currentPlayer?.pause()
    }
    
    public func changeFeed(type: NewsFeedTypes) {
        self.title = type.title()
        self.viewModel.changeFeed(type: type)
    }
    
    public func reloadData() {
        self.viewModel.clearErrorState(type: self.viewModel.type)
        Task { [weak self] in
            guard let self else { return }
            try await self.viewModel.loadListData()
        }
    }
    
    @objc private func willSwitchAccount() {
        self.deferredSnapshotUpdatesCallbacks = []
        self.cacheScrollPosition(tableView: self.tableView, forFeed: self.viewModel.type)
        self.viewModel.removeAll(type: self.viewModel.type, clearScrollPosition: false)
        
        if self.isInWindowHierarchy() {
            self.viewModel.stopPollingListData()
            if self.viewModel.type.shouldSyncItems {
                self.viewModel.cancelAllItemSyncs()
            }
        }
        self.switchingAccounts = true
    }
    
    @objc private func didSwitchAccount() {
        self.switchingAccounts = false
    }
    
    @objc private func onDragToRefresh(_ sender: Any) {
        Sound().playSound(named: "soundSuction", withVolume: 0.6)
        self.viewModel.clearErrorState(type: self.viewModel.type)
        self.viewModel.stopPollingListData()

        Task { [weak self] in
            guard let self else { return }
            
            do {
                if [.mentionsIn].contains(type) || NewsFeedTypes.allActivityTypes.contains(self.viewModel.type) {
                    try await self.viewModel.loadListData(type: self.viewModel.type, fetchType: .refresh)
                } else {
                    if GlobalStruct.feedReadDirection == .bottomUp {
                        try await self.viewModel.loadListData(type: type, fetchType: .previousPage)
                    } else {
                        try await self.viewModel.loadLatest(feedType: type, threshold: 1)
                    }
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.refreshControl.endRefreshing()
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.refreshControl.endRefreshing()
                }
            }
        }
        
        // If the user disabled the JumpToNow button (pressed the close button)
        // re-enable it now
        self.viewModel.isJumpToNowButtonDisabled = false
    }
    
    @objc private func onThemeChange() {
        self.tableView.backgroundColor = .custom.background
        self.tableView.reloadData()
    }
    
    @objc func onJumpToNow() {
        self.viewModel.stopPollingListData()
        self.viewModel.cancelAllItemSyncs()
        self.deferredSnapshotUpdatesCallbacks = []
        
        self.isScrollingProgrammatically = true
        
        self.viewModel.clearSnapshot()
        self.disableFeedUpdates = true
        self.showLoader(enabled: true)
        
        self.viewModel.setShowJumpToNow(enabled: false, forFeed: self.viewModel.type)
        self.viewModel.clearAllUnreadIds(forFeed: self.viewModel.type)
        self.didUpdateUnreadState(type: self.viewModel.type)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
                        
            Task { [weak self] in
                guard let self else { return }
                try await self.viewModel.loadListData(type: self.viewModel.type, fetchType: .refresh)
            }
            
            self.disableFeedUpdates = false
        }
    }
    
    @objc func onUnreadTapped() {
        self.viewModel.setUnreadEnabled(enabled: false, forFeed: self.viewModel.type)
        self.latestPill.isEnabled = false
        self.unreadIndicator.isEnabled = false
        // Clear LatestPill state after scroll animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            self.latestPill.configure(unreadCount: 0, picUrls: [])
            self.unreadIndicator.configure(unreadCount: 0)
            
            if [.mentionsIn].contains(self.type) {
                // // Hide the tab bar mentions indicator (dot)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "hideIndActivity2"), object: nil)
            }
            
            if NewsFeedTypes.allActivityTypes.contains(self.viewModel.type) {
                // // Hide the tab bar activity indicator (dot)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "hideIndActivity"), object: nil)
            }
        }
    }
    
    @objc func appWillResignActive() {
        self.viewModel.stopPollingListData()
        if self.viewModel.type.shouldSyncItems {
            self.viewModel.cancelAllItemSyncs()
        }
        self.cacheScrollPosition(tableView: self.tableView, forFeed: self.viewModel.type)
    }
    
    @objc func appDidBecomeActive() {
        self.viewModel.clearErrorState(type: self.viewModel.type)
        if self.isActiveFeed && self.viewModel.type.shouldPollForListData {
            self.viewModel.startPollingListData(forFeed: self.type, delay: 2)
        }
        
        self.tableView.visibleCells.forEach({
            if let cell = $0 as? PostCardCell {
                cell.willDisplay()
            } else if let cell = $0 as? ActivityCardCell {
                cell.willDisplay()
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        self.cacheScrollPosition(tableView: self.tableView, forFeed: self.viewModel.type)
        self.viewModel.cleanUpMemoryOfCurrentFeed()
    }
}

// MARK: UI Setup
private extension NewsFeedViewController {
    func setupUI() {
        
        tableView.refreshControl = self.refreshControl
        view.addSubview(tableView)
        view.addSubview(latestPill)
        view.addSubview(unreadIndicator)
//        view.addSubview(jumpToNow)
        
//        jumpToNow.delegate = self
        
        if ![.mentionsIn, .mentionsOut].contains(self.viewModel.type) && !NewsFeedTypes.allActivityTypes.contains(self.viewModel.type)  {
            self.tableView.tableHeaderView = UIView()
        } else {
            let px = 1 / UIScreen.main.scale
            let line = UIView(frame: .init(x: 0, y: 0, width: self.tableView.frame.size.width, height: px))
            self.tableView.tableHeaderView = line
            line.backgroundColor = self.tableView.separatorColor
        }
                        
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            
            self.latestPill.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            self.latestPill.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 9),
            
//            self.jumpToNow.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
//            self.jumpToNow.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 9),
            
            self.unreadIndicator.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -10),
            self.unreadIndicator.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 9),
        ])
    }
}

// MARK: - Observers
extension NewsFeedViewController {
    func setupObservers() {
        self.viewModel.dataSource = NewsFeedViewModel.NewsFeedDiffableDataSource(tableView: tableView) { [weak self] (tableView, indexPath, listItemType) -> UITableViewCell? in
            guard let self else { return UITableViewCell() }
            
            switch listItemType {
            case .postCard(let model):
                
                if let cell = self.tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: model, cellType: viewModel.type.postCardCellType()), for: indexPath) as? PostCardCell {
                    
                    cell.configure(postCard: model, type: viewModel.type.postCardCellType()) { [weak self] (type, isActive, data) in
                        guard let self else { return }
                        guard !model.isDeleted, !model.isMuted, !model.isBlocked else { return }
                        PostActions.onActionPress(target: self, type: type, isActive: isActive, postCard: model, data: data)
                        
                        // Show the Upgrade alert if needed (only on home feeds)
                        if !(NewsFeedTypes.allActivityTypes + [.mentionsIn, .mentionsOut, .likes, .bookmarks]).contains(self.viewModel.type),
                            [.like, .reply, .repost, .quote, .bookmark].contains(type) {
                            IAPManager.shared.showUpgradeAlertIfNeeded()
                        }
                        
                        if [.profile, .deletePost, .link, .mention, .message, .muteForever, .muteOneDay, .postDetails, .quote, .viewInBrowser, .reply].contains(type) {
                            self.viewModel.pauseAllVideos()
                        }
                    }
                    
                    self.tableView.separatorStyle = .singleLine
                    return cell
                }
            case .activity(let model):
                if let cell = self.tableView.dequeueReusableCell(withIdentifier: ActivityCardCell.reuseIdentifier, for: indexPath) as? ActivityCardCell {
                    cell.configure(activity: model) { [weak self] (type, isActive, data) in
                        guard let self else { return }
                        let account = model.notification.account
                        let userCard = UserCardModel(account: account)
                        PostActions.onActionPress(target: self, type: type, isActive: isActive, userCard: userCard, data: data)
                        
                        if [.profile, .deletePost, .link, .mention, .message, .muteForever, .muteOneDay, .postDetails, .quote, .viewInBrowser, .reply].contains(type) {
                            self.viewModel.pauseAllVideos()
                        }
                    }
                    
                    self.tableView.separatorStyle = .singleLine
                    return cell
                }
                
            case .empty:
                if let cell = self.tableView.dequeueReusableCell(withIdentifier: EmptyFeedCell.reuseIdentifier, for: indexPath) as? EmptyFeedCell {
                    if case .list(_) = self.viewModel.type {
                        cell.configure(label: NSLocalizedString("list.hint", comment: ""))
                    } else {
                        cell.configure()
                    }
                    
                    self.tableView.separatorStyle = .none
                    return cell
                }
            case .loadMore:
                if let cell = self.tableView.dequeueReusableCell(withIdentifier: LoadMoreCell.reuseIdentifier, for: indexPath) as? LoadMoreCell {
                    if case .mentionsIn = self.viewModel.type {
                        cell.configure(label: "Load older mentions")
                    }
                    else if case .mentionsOut = self.viewModel.type {
                        cell.configure(label: "Load older mentions")
                    }
                    else if case .activity = self.viewModel.type {
                        cell.configure(label: "Load older activity")
                    }
                    return cell
                }
            case .serverUpdating:
                if let cell = self.tableView.dequeueReusableCell(withIdentifier: ServerUpdatingCell.reuseIdentifier, for: indexPath) as? ServerUpdatingCell {
                    return cell
                }
            case .serverUpdated:
                if let cell = self.tableView.dequeueReusableCell(withIdentifier: ServerUpdatedCell.reuseIdentifier, for: indexPath) as? ServerUpdatedCell {
                    cell.delegate = self
                    return cell
                }
            case .serverOverload:
                if let cell = self.tableView.dequeueReusableCell(withIdentifier: ServerOverloadCell.reuseIdentifier, for: indexPath) as? ServerOverloadCell {
                    return cell
                }
            case .error:
                if let cell = self.tableView.dequeueReusableCell(withIdentifier: ErrorCell.reuseIdentifier, for: indexPath) as? ErrorCell {
                    return cell
                }
            }

            log.error("#NewsFeedViewController - could not dequeue correct cell")
            return UITableViewCell()
        }
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate & UITableViewDataSourcePrefetching
extension NewsFeedViewController {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let item = self.viewModel.getItemForIndexPath(indexPath) {
            if case .postCard(let postCardModel) = item {
                postCardModel.cellHeight = cell.frame.size.height
            } else if case .activity(let activityModel) = item {
                activityModel.cellHeight = cell.frame.size.height
            }
            
            if self.viewModel.getUnreadEnabled(forFeed: self.viewModel.type) && !self.isInsertingContent {
                self.viewModel.removeUnreadId(id: item.uniqueId(), forFeed: self.viewModel.type)
                let count = self.viewModel.getUnreadCount(forFeed: self.viewModel.type)
                
                if GlobalStruct.feedReadDirection == .topDown {
                    switch self.viewModel.type {
                    case .mentionsIn, .mentionsOut, .activity:
                        self.unreadIndicator.isEnabled = true
                        self.unreadIndicator.configure(unreadCount: count)
                    default:
                        self.latestPill.isEnabled = true
                        let pics = self.viewModel.getUnreadPics(forFeed: self.viewModel.type)
                        self.latestPill.configure(unreadCount: count, picUrls: pics)
                    }
                } else {
                    self.unreadIndicator.isEnabled = true
                    self.unreadIndicator.configure(unreadCount: count)
                }
            }
        }
        
        self.displayingIndexPath = indexPath
        
        if self.isActiveFeed && self.viewModel.type.shouldSyncItems {
            if self.viewModel.postSyncingTasks.count > 15 {
                self.viewModel.cancelAllItemSyncs()
            }
            
            self.viewModel.requestItemSync(forIndexPath: indexPath, afterSeconds: 3.4)
        }
        
        if let cell = cell as? PostCardCell {
            cell.willDisplay()
        } else if let cell = cell as? ActivityCardCell {
            cell.willDisplay()
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.viewModel.cancelItemSync(forIndexPath: indexPath)
        
        if let cell = cell as? PostCardCell {
            cell.didEndDisplay()
        } else if let cell = cell as? ActivityCardCell {
            cell.didEndDisplay()
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let item = self.viewModel.getItemForIndexPath(indexPath) {
            if case .postCard(let postCardModel) = item {
                return postCardModel.cellHeight ?? UITableView.automaticDimension
            }
        }
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.getItemForIndexPath(indexPath) {
        case .postCard(let postCard):
            if !postCard.isDeleted && !postCard.isMuted && !postCard.isBlocked {
                // If it's from ForYou, indicate that the statusSource
                let showStatusSource = (self.type == .forYou)
                
                // we don't load the mention from its original server
                if [.mentionsIn, .mentionsOut].contains(self.viewModel.type) {
                    postCard.instanceName = AccountsManager.shared.currentAccountClient.baseHost
                    postCard.user?.instanceName = AccountsManager.shared.currentAccountClient.baseHost
                    postCard.isSyncedWithOriginal = true
                }
                
                let vc = DetailViewController(post: postCard, showStatusSource: showStatusSource)
                if vc.isBeingPresented {} else {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        case .activity(let activity):
            switch activity.type {
            case .follow, .follow_request:
                if let account = activity.user.account {
                    PostActions.onProfilePress(target: self, account: account)
                }
                break
            default:
                if let postCard = activity.postCard {
                    if !postCard.isDeleted && !postCard.isMuted && !postCard.isBlocked {
                        let vc = DetailViewController(post: postCard)
                        if vc.isBeingPresented {} else {
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
            }
        case .loadMore:
            if let _ = self.tableView.dequeueReusableCell(withIdentifier: LoadMoreCell.reuseIdentifier, for: indexPath) as? LoadMoreCell {
                Task { [weak self] in
                    guard let self else { return }
                    do {
                        try await self.viewModel.loadOlderPosts(feedType: self.viewModel.type)
                        await MainActor.run {
                            if let loadMoreIndexPath = self.viewModel.getIndexPathForItem(item: .loadMore) {
                                tableView.deselectRow(at: loadMoreIndexPath, animated: true)
                            }
                        }
                    } catch {}
                }
            }
            
        default:
            break
        }
        
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if viewModel.shouldFetchNext(prefetchRowsAt: indexPaths) {
            Task { [weak self] in
                guard let self else { return }
                try await self.viewModel.loadListData(type: nil, fetchType: .nextPage)
            }
        }

        viewModel.preloadCards(atIndexPaths: indexPaths)
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        viewModel.cancelPreloadCards(atIndexPaths: indexPaths)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        self.isScrollingProgrammatically = !self.tableView.isDecelerating && !self.tableView.isTracking && !(self.tableView.indexPathsForVisibleRows ?? []).isEmpty
        
        // scroll past the last item in feed (pull up)
        if (scrollView.contentOffset.y + self.view.safeAreaInsets.top) > max(scrollView.contentSize.height - (scrollView.bounds.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom), 0) + 130 {
            self.viewModel.clearErrorState(type: self.viewModel.type)
        }
        
        // Fetch next again if scrolling past the last elements
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if self.viewModel.snapshot.numberOfItems > 0, scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height - 600,
               viewModel.shouldFetchNext(prefetchRowsAt: [IndexPath(row: viewModel.numberOfItems(forSection: .main), section: 0)]) {
                Task { [weak self] in
                    guard let self else { return }
                    try await viewModel.loadListData(type: nil, fetchType: .nextPage)
                }
            }
        }
        
        // When scrollview reachs the top
        // We need to include an inset when the background is translucent
        if scrollView.contentOffset.y == 0 - self.view.safeAreaInsets.top {
            if !self.isInsertingContent {
                self.cacheScrollPosition(tableView: self.tableView, forFeed: self.viewModel.type)
            }
            self.viewModel.removeOldItems(forType: self.viewModel.type)
            self.delegate?.didScrollToTop()
        }
        
        if scrollView.contentOffset.y < 0 - self.view.safeAreaInsets.top + 60 {
            // Clean unread indicator when close to top
            if self.viewModel.getUnreadCount(forFeed: self.viewModel.type) > 0 {
                if let firstIndexPath = self.tableView.indexPathsForVisibleRows?.first,
                   let model = self.viewModel.getItemForIndexPath(firstIndexPath) {
                    self.viewModel.removeUnreadId(id: model.uniqueId(), forFeed: self.viewModel.type)
                    self.didUpdateUnreadState(type: self.viewModel.type)
                }
            }
            
            self.delegate?.didScrollToTop()
        }
        
        // When scrollview reaches the top
        // We need to include an inset when the background is translucent
        if scrollView.contentOffset.y <= 0 - self.view.safeAreaInsets.top + 3000 {
            // For feeds with many new posts a second we don't want to
            // nag the user with the unread pill right after they reached the top.
            if self.viewModel.type.shouldPollForListData && self.viewModel.snapshot.numberOfItems > 0 {
                if !self.viewModel.isPollingEnabled && !self.isScrollingProgrammatically {
                    self.viewModel.startPollingListData(forFeed: self.viewModel.type, delay: 2.5)
                }
            }
        }
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        self.isScrollingProgrammatically = false

        self.viewModel.cancelAllItemSyncs()
        
        if GlobalStruct.feedReadDirection == .topDown {
            switch self.viewModel.type {
            case .mentionsIn, .mentionsOut, .activity:
                self.unreadIndicator.configure(unreadCount: 0)
                self.unreadIndicator.isEnabled = true
            default:
                self.latestPill.configure(unreadCount: 0, picUrls: self.viewModel.getUnreadPics(forFeed: self.viewModel.type))
                self.latestPill.isEnabled = true
            }
        } else {
            self.unreadIndicator.configure(unreadCount: 0)
            self.unreadIndicator.isEnabled = true
        }
        
        if self.viewModel.type.shouldPollForListData && self.viewModel.snapshot.numberOfItems > 0 {
            if !self.viewModel.isPollingEnabled && !self.isScrollingProgrammatically {
                self.viewModel.startPollingListData(forFeed: self.viewModel.type, delay: 2.5)
            }
        }
        
        self.delegate?.didScrollToTop()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.cacheScrollPosition(tableView: self.tableView, forFeed: self.viewModel.type)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.isScrollingProgrammatically = false
        self.cacheScrollPosition(tableView: self.tableView, forFeed: self.viewModel.type)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) { [weak self] in
            guard let self else { return }
            
            guard !self.tableView.isTracking, !self.tableView.isDecelerating else { return }
            let callbacks = self.deferredSnapshotUpdatesCallbacks
            self.deferredSnapshotUpdatesCallbacks = []
            callbacks.forEach({ $0() })
            
            self.didUpdateSnapshot(self.viewModel.snapshot, feedType: self.viewModel.type, updateType: .insert, scrollPosition: nil, onCompleted: nil)
        }
    }
}


// MARK: NewsFeedViewModelDelegate
extension NewsFeedViewController: NewsFeedViewModelDelegate {

    func didUpdateSnapshot(_ snapshot: NewsFeedSnapshot,
                           feedType: NewsFeedTypes,
                           updateType: NewsFeedSnapshotUpdateType,
                           scrollPosition: NewsFeedScrollPosition?,
                           onCompleted: (() -> Void)?) {
        guard !self.switchingAccounts && !self.disableFeedUpdates else { return }
        
        let shouldFreezeAnimations = (self.isInWindowHierarchy() || updateType == .hydrate)
        let updateDisplay = (NewsFeedTypes.allActivityTypes + [.mentionsIn, .mentionsOut]).contains(feedType) || (self.isInWindowHierarchy() || updateType == .hydrate)
        
        guard ((!self.tableView.isTracking && !self.tableView.isDecelerating) || updateType == .removeAll),
                updateDisplay,
                !(updateType == .update && self.isScrollingProgrammatically) else {
            if let callback = onCompleted {
                self.deferredSnapshotUpdatesCallbacks.append(callback)
            }
            return
        }
        
        let callbacks = self.deferredSnapshotUpdatesCallbacks
        self.deferredSnapshotUpdatesCallbacks = []
        callbacks.forEach({ $0() })
        
        switch updateType {
        case .insert, .update, .remove, .replaceAll:

            log.debug("tableview change: \(updateType) for \(feedType)")
            
            self.isInsertingContent = true
            
            // Cache scroll position pre-update
            let scrollPosition = self.cacheScrollPosition(tableView: self.tableView, forFeed: feedType, scrollReference: .top)

            if shouldFreezeAnimations && self.viewModel.dataSource != nil {
                CATransaction.begin()
                CATransaction.disableActions()
            }
            
            self.viewModel.dataSource?.apply(snapshot, animatingDifferences: false) { [weak self] in
                guard let self else {
                    if shouldFreezeAnimations {
                        CATransaction.commit()
                    }
                    return
                }
                
                if let scrollPosition {
                    // Forcing a second scrollToPosition call on completion
                    // makes sure the scroll action happens correcty.
                    // Keep both of them to make the feed less jumpy on feed updates.
                    self.scrollToPosition(tableView: self.tableView, snapshot: snapshot, position: scrollPosition)
                }

                onCompleted?()
                
                DispatchQueue.main.async {
                    if let scrollPosition {
                        self.scrollToPosition(tableView: self.tableView, snapshot: snapshot, position: scrollPosition)
                    }
                    
                    if shouldFreezeAnimations {
                        CATransaction.commit()
                    }
                    
                    self.isInsertingContent = false
                }
                
                // This extra commit is needed when updating with .replaceAll (triggered by refresh snapshot)
                // Without it the UI feezes.
                if updateType == .replaceAll && shouldFreezeAnimations {
                    CATransaction.commit()
                }
            }
                        
            // Revert to pre-update scroll position
            if let scrollPosition {
                self.scrollToPosition(tableView: self.tableView, snapshot: snapshot, position: scrollPosition)
            }
            
        case .inject:
            guard self.isInWindowHierarchy() else { return }
            
            log.debug("tableview change: \(updateType) for \(feedType)")
                        
            // Cache scroll position pre-update
            let scrollPosition = self.cacheScrollPosition(tableView: self.tableView, forFeed: feedType, scrollReference: .top)

            if shouldFreezeAnimations {
                CATransaction.begin()
                CATransaction.disableActions()
            }
            
            self.viewModel.dataSource?.apply(snapshot, animatingDifferences: false) { [weak self] in
                guard let self else {
                    if updateDisplay {
                        CATransaction.commit()
                    }
                    return
                }
                
                if let scrollPosition {
                    // Forcing a second scrollToPosition call on completion
                    // makes sure the scroll action happens correcty.
                    // Keep both of them to make the feed less jumpy on feed updates.
                    self.scrollToPosition(tableView: self.tableView, snapshot: snapshot, position: scrollPosition)
                }
                
                if shouldFreezeAnimations {
                    CATransaction.commit()
                    UIView.setAnimationsEnabled(false)
                }
                onCompleted?()
                
                DispatchQueue.main.async {
                    if let scrollPosition {
                        self.scrollToPosition(tableView: self.tableView, snapshot: snapshot, position: scrollPosition)
                    }
                    
                    if shouldFreezeAnimations {
                        UIView.setAnimationsEnabled(true)
                    }
                }
            }
                        
            // Revert to pre-update scroll position
            if let scrollPosition {
                self.scrollToPosition(tableView: self.tableView, snapshot: snapshot, position: scrollPosition)
            }
            
        case .removeAll:
            log.debug("tableview change: \(updateType) for \(feedType)")
            self.viewModel.dataSource?.apply(snapshot, animatingDifferences: false) { [weak self] in
                guard let self else { return }
                if GlobalStruct.feedReadDirection == .topDown {
                    switch self.viewModel.type {
                    case .mentionsIn, .mentionsOut, .activity:
                        self.unreadIndicator.configure(unreadCount: 0)
                        self.unreadIndicator.isEnabled = true
                    default:
                        self.latestPill.configure(unreadCount: 0, picUrls: [])
                        self.latestPill.isEnabled = true
                    }
                } else {
                    self.unreadIndicator.configure(unreadCount: 0)
                    self.unreadIndicator.isEnabled = true
                    self.jumpToNow.isEnabled = false
                }
                
                self.cacheScrollPosition(tableView: self.tableView, forFeed: feedType)
                onCompleted?()
            }
            
        case .hydrate:
            log.debug("tableview change: \(updateType) for \(feedType)")
            let scrollPosition = scrollPosition ?? self.viewModel.getScrollPosition(forFeed: feedType)
            
            self.viewModel.dataSource?.apply(snapshot, animatingDifferences: false) { [weak self] in
                guard let self else { return }
                self.scrollToPosition(tableView: self.tableView, snapshot: snapshot, position: scrollPosition)
                onCompleted?()
            }
            
            self.scrollToPosition(tableView: self.tableView, snapshot: snapshot, position: scrollPosition)

       case .append:
            // Cache scroll position pre-update
            let scrollPosition = self.cacheScrollPosition(tableView: self.tableView, forFeed: feedType, scrollReference: .top)

            if shouldFreezeAnimations {
                CATransaction.begin()
                CATransaction.disableActions()
            }

            self.viewModel.dataSource?.apply(snapshot, animatingDifferences: false) { [weak self] in
               guard let self else {
                   if shouldFreezeAnimations {
                       CATransaction.commit()
                   }
                   return
               }
               // Forcing a second scrollToPosition call on completion
               // makes sure the scroll action happens correcty.
               // Keep both of them to make the feed less jumpy on feed updates.
               if let scrollPosition {
                   self.scrollToPosition(tableView: self.tableView, snapshot: snapshot, position: scrollPosition)
               }
               
                if shouldFreezeAnimations {
                    CATransaction.commit()
                }
               onCompleted?()
            }

            if let scrollPosition {
               self.scrollToPosition(tableView: self.tableView, snapshot: snapshot, position: scrollPosition)
            }
        }
    }
    
    func didUpdateUnreadState(type: NewsFeedTypes) {
        let unreadState = self.viewModel.getUnreadState(forFeed: type)
        if unreadState.enabled {
            switch self.viewModel.type {
            case .mentionsIn, .mentionsOut, .activity:
                self.unreadIndicator.configure(unreadCount: unreadState.unreadIDs.count)
                self.unreadIndicator.isEnabled = unreadState.enabled
            default:
                if GlobalStruct.feedReadDirection == .topDown {
                    if unreadState.unreadPics.count < 4 {
                        self.latestPill.configure(unreadCount: 0, picUrls: [])
                        self.latestPill.isEnabled = unreadState.enabled
                    } else {
                        self.latestPill.configure(unreadCount: unreadState.unreadIDs.count, picUrls: unreadState.unreadPics)
                        self.latestPill.isEnabled = unreadState.enabled
                    }
                } else {
                    self.unreadIndicator.configure(unreadCount: unreadState.unreadIDs.count)
                    self.unreadIndicator.isEnabled = unreadState.enabled
                }
            }
            
        } else {
            switch self.viewModel.type {
            case .mentionsIn, .mentionsOut, .activity:
                self.unreadIndicator.isEnabled = false
            default:
                if GlobalStruct.feedReadDirection == .topDown {
                    self.latestPill.isEnabled = false
                } else {
                    self.unreadIndicator.isEnabled = false
                }
            }
        }
        
        self.jumpToNow.isEnabled = unreadState.showJumpToNow
    }
    
    func willChangeFeed(fromType: NewsFeedTypes, toType: NewsFeedTypes) {
        // Cache scroll position of previous feed
        self.cacheScrollPosition(tableView: self.tableView, forFeed: fromType)
        self.latestPill.isEnabled = false
        self.unreadIndicator.isEnabled = false
        self.jumpToNow.isEnabled = false
    }
    
    func didChangeFeed(type: NewsFeedTypes) {
        self.title = type.title()
        self.delegate?.didChangeFeed(type)

        let unreadState = self.viewModel.getUnreadState(forFeed: type)

       switch self.viewModel.type {
       case .mentionsIn, .mentionsOut, .activity:
           self.unreadIndicator.isEnabled = unreadState.enabled
           self.unreadIndicator.configure(unreadCount: unreadState.unreadIDs.count)
       default:
           if GlobalStruct.feedReadDirection == .topDown {
               self.latestPill.isEnabled = unreadState.enabled
               self.latestPill.configure(unreadCount: unreadState.unreadIDs.count, picUrls: unreadState.unreadPics)
            } else {
                self.unreadIndicator.isEnabled = unreadState.enabled
                self.unreadIndicator.configure(unreadCount: unreadState.unreadIDs.count)
            }
        }
        
        if self.viewModel.type.shouldSyncItems {
            self.viewModel.cancelAllItemSyncs()
        }
        
        if self.viewModel.type.shouldPollForListData {
            self.viewModel.stopPollingListData()
            self.viewModel.startPollingListData(forFeed: self.viewModel.type, delay: 1)
        }
    }
    
    static let LoaderTag = 11
    
    func showLoader(enabled: Bool) {
        DispatchQueue.main.async {
            if enabled {
                if !self.isLoaderVisible() {
                    let loaderView = UIStackView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 40))
                    loaderView.alignment = .center
                    loaderView.layoutMargins = .init(top: 10, left: 10, bottom: 10, right: 10)
                    let loader = UIActivityIndicatorView()
                    loader.startAnimating()
                    loaderView.addArrangedSubview(loader)
                    loaderView.tag = Self.LoaderTag
                    self.tableView.tableFooterView = loaderView
                }
            } else {
                // Hack to hide last seperator
                self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 1))
            }
        }
    }
    
    func isLoaderVisible() -> Bool {
        return self.tableView.tableFooterView?.tag == Self.LoaderTag
    }
    
    func getVisibleIndexPaths() async -> [IndexPath]? {
        return await MainActor.run {
            return self.tableView.indexPathsForVisibleRows
        }
    }
}

// MARK: Appearance changes
internal extension NewsFeedViewController {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
                 onThemeChange()
             }
         }
    }
}


// MARK: - User action handler

extension NewsFeedViewController: UpdatedCellDelegate {
    func didTapRefresh() {
        forceReloadForYou()
    }
}

// MARK: - Scroll helpers
private extension NewsFeedViewController {
    func scrollToPosition(tableView: UITableView, position: NewsFeedScrollPosition) {
        if tableView.frame.width > 0 {
            if case .postCard = position.model {
                if let indexPath = viewModel.getIndexPathForItem(item: position.model!) {
                    let yOffset = tableView.rectForRow(at: indexPath).origin.y - position.offset
                    if yOffset > 0 {
                        // we need to include an inset when the background is translucent
                        var additionalOffset = 0.0
                        if UIDevice.current.userInterfaceIdiom == .phone && !self.additionalSafeAreaInsets.top.isZero {
                            additionalOffset = 25.0
                            tableView.contentOffset.y = yOffset - self.view.safeAreaInsets.top + additionalOffset
                        } else if !self.additionalSafeAreaInsets.top.isZero {
                            additionalOffset = 50.0
                            tableView.contentOffset.y = yOffset - additionalOffset
                        } else {
                            tableView.contentOffset.y = yOffset - self.view.safeAreaInsets.top
                        }
                    }
                } else {
                    log.error("#scrollToPosition1: no indexpath found")
                }
            }
        }
    }
    
    func scrollToPosition(tableView: UITableView, snapshot: NewsFeedSnapshot, position: NewsFeedScrollPosition) {
        if tableView.frame.width > 0 {
            if let model = position.model {
                if let indexPath = viewModel.getIndexPathForItem(snapshot: snapshot, item: model) {
                    let yOffset = tableView.rectForRow(at: indexPath).origin.y - position.offset
                    if yOffset > 0 {
                        // we need to include an inset when the background is translucent
                        var additionalOffset = 0.0
                        
                        UIView.setAnimationsEnabled(false)
                        if UIDevice.current.userInterfaceIdiom == .phone && !self.additionalSafeAreaInsets.top.isZero {
                            additionalOffset = 176
                            tableView.contentOffset.y = yOffset - self.view.safeAreaInsets.top + additionalOffset
                        } else if !self.additionalSafeAreaInsets.top.isZero {
                            additionalOffset = 50.0
                            tableView.contentOffset.y = yOffset - additionalOffset
                        } else {
                            tableView.contentOffset.y = yOffset - self.view.safeAreaInsets.top
                        }
                        UIView.setAnimationsEnabled(true)
                    }
                } else {
                    log.error("#scrollToPosition2: no indexpath found")
                }
            }
        }
    }
    
    enum ScrollPositionReference { case top, bottom }
    
    @discardableResult
    func cacheScrollPosition(tableView: UITableView, forFeed type: NewsFeedTypes, scrollReference: ScrollPositionReference = .top) -> NewsFeedScrollPosition? {
        if let navBar = self.navigationController?.navigationBar {
            let whereIsNavBarInTableView = tableView.convert(navBar.bounds, from: navBar)
            let pointWhereNavBarEnds = CGPoint(x: 0, y: whereIsNavBarInTableView.origin.y + whereIsNavBarInTableView.size.height)
            
            if let currentCellIndexPath = self.getCurrentCellIndexPath(tableView: tableView, scrollReference: scrollReference) {
                guard let model = self.viewModel.getItemForIndexPath(currentCellIndexPath) else {
                    return nil
                }
                let rectForTopRow = tableView.rectForRow(at: currentCellIndexPath)
                let offset = rectForTopRow.origin.y - pointWhereNavBarEnds.y
                return self.viewModel.setScrollPosition(model: model, offset: offset, forFeed: type)
            }
        }
        
        return nil
    }
    
    func getCurrentCellIndexPath(tableView: UITableView, scrollReference: ScrollPositionReference = .top) -> IndexPath? {
        switch scrollReference {
        case .top:
            return tableView.indexPathsForVisibleRows?.first
        case .bottom:
            return tableView.indexPathsForVisibleRows?.last
        }
    }
}

// MARK: - Jump to newest
extension NewsFeedViewController: JumpToNewest {
    func jumpToNewest() {
        if !self.viewModel.pollingReachedTop {
            
            self.viewModel.stopPollingListData()
            self.viewModel.cancelAllItemSyncs()
            self.deferredSnapshotUpdatesCallbacks = []
            
            self.isScrollingProgrammatically = true
            
            self.viewModel.clearSnapshot()
            self.disableFeedUpdates = true
            self.showLoader(enabled: true)
            
            self.viewModel.setShowJumpToNow(enabled: false, forFeed: self.viewModel.type)
            self.viewModel.clearAllUnreadIds(forFeed: self.viewModel.type)
            self.didUpdateUnreadState(type: self.viewModel.type)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self else { return }
                
                Task { [weak self] in
                    guard let self else { return }
                    try await self.viewModel.loadListData(type: self.viewModel.type, fetchType: .refresh)
                }
                
                self.disableFeedUpdates = false
            }
        } else {
            
            self.viewModel.stopPollingListData()
            self.viewModel.cancelAllItemSyncs()
            self.deferredSnapshotUpdatesCallbacks = []
            
            self.isScrollingProgrammatically = true

            self.disableFeedUpdates = true
            
            self.viewModel.setShowJumpToNow(enabled: false, forFeed: self.viewModel.type)
            self.viewModel.clearAllUnreadIds(forFeed: self.viewModel.type)
            self.didUpdateUnreadState(type: self.viewModel.type)
            
            self.tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            
            self.disableFeedUpdates = false
            
            self.viewModel.startPollingListData(forFeed: self.viewModel.type, delay: 1)
        }
    }
}

// MARK: - Force reload feed
extension NewsFeedViewController {
    func startCheckingFYStatus() {
        self.viewModel.startCheckingFYStatus {
            DispatchQueue.main.async {
                self.tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
    }
    
    func forceReloadForYou() {
        self.viewModel.forceReloadForYou()
    }
}

// MARK: UIContextMenuInteractionDelegate
extension NewsFeedViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard case .postCard(let postCard) = viewModel.getItemForIndexPath(indexPath)
        else { return nil }
        
        if let cell = self.tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: postCard), for: indexPath) as? PostCardCell {

            return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { nil }, actionProvider: { suggestedActions in
                return cell.createContextMenu(postCard: postCard) { [weak self] type, isActive, data in
                    guard let self else { return }
                    PostActions.onActionPress(target: self, type: type, isActive: isActive, postCard: postCard, data: data)
                }
            })
        }
        
        return nil
    }
}

// MARK: - App state restoration
extension NewsFeedViewController: AppStateRestoration {
    public func storeUserActivity(in activity: NSUserActivity) {
        guard let userActivityStorage = self.delegate?.userActivityStorageIdentifier() else {
            log.error("expected a valid userActivityStorageIdentifier")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            let typeData = try encoder.encode(self.viewModel.type)
            activity.userInfo?[userActivityStorage] = typeData
        } catch {
            log.error("Unable to encode app state in NewsFeedViewController: \(error)")
        }
    }
    public func restoreUserActivity(from activity: NSUserActivity) {
        guard let userActivityStorage = self.delegate?.userActivityStorageIdentifier() else {
            log.error("expected a valid userActivityStorageIdentifier")
            return
        }
                
        if let feedTypeData = activity.userInfo?[userActivityStorage] as? Data {
            do {
                let decoder = JSONDecoder()
                let feedType = try decoder.decode(NewsFeedTypes.self, from: feedTypeData)
                log.debug("NewsFeedViewController:" + #function + " feedType: \(feedType)")
                self.delegate?.willChangeFeed(feedType)
                self.viewModel.changeFeed(type: feedType)
            } catch {
                log.error("Unable to decode app state in NewsFeedViewController: \(error)")
            }
        }
    }
}


// MARK: - Additional nav bar items
extension NewsFeedViewController {
    // Return additional navbar items for the current view controller
    func navBarItems() -> [UIBarButtonItem] {
        switch(self.viewModel.type) {
        case .hashtag(let tag):
            return self.hashtagNavBarItems(hashtag: tag.name)
        case .list(let list):
            return self.listNavBarItems(list: list)
        case .forYou:
            return self.forYouNavBarItems()
        default:
            return []
        }
    }
    
    func contextMenu() -> UIMenu {
        var options: [UIAction] = []
        
        switch(self.viewModel.type) {
        case .community(let name):
            options = self.communityNavBarContextOptions(instanceName: name)
        case .list(let list):
            options = self.listNavBarContextOptions(list: list)
        default:
            break
        }
        
        return UIMenu(title: "", options: [.displayInline], children: options)
    }
    
    private func communityNavBarContextOptions(instanceName: String) -> [UIAction] {
        var contextMenuOptions: [UIAction] = []
        
        let view_trends = NSLocalizedString("home.viewTrends", comment: "Button for showing trends of an instance in the carousel.")
        let option = UIAction(title: view_trends, image: UIImage(systemName: "binoculars"), identifier: nil) { [weak self] _ in
            guard let self else { return }
            let vc = ExploreViewController()
            vc.showingSearch = false
            vc.fromOtherCommunity = true
            vc.otherInstance = instanceName
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        option.accessibilityLabel = view_trends
        contextMenuOptions.append(option)
        
        return contextMenuOptions
    }
    
    private func hashtagNavBarItems(hashtag: String) -> [UIBarButtonItem] {
        let followedHashtags = HashtagManager.shared.allHashtags()
        let isFollowing = followedHashtags.contains(where: { $0.name.lowercased() == hashtag.lowercased() })
        
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 19, weight: .regular)
        let btn = UIButton(type: .custom)
        
        if isFollowing {
            btn.addAction { [weak self] in
                guard let self else { return }
                triggerHapticImpact(style: .light)
                HashtagManager.shared.unfollowHashtag(hashtag.lowercased(), completion: { _ in })
                self.delegate?.willChangeFeed(.following)
                self.viewModel.changeFeed(type: .following)
            }
            
            btn.setImage(UIImage(systemName: "minus.circle", withConfiguration: symbolConfig)?.withTintColor(.custom.highContrast, renderingMode: .alwaysTemplate), for: .normal)
            btn.accessibilityLabel = NSLocalizedString("accessibility.unfollowTag", comment: "Screen reader only.")
            
        } else {
            btn.addAction {
                triggerHapticImpact(style: .light)
                HashtagManager.shared.followHashtag(hashtag.lowercased(), completion: { _ in })
            }
            btn.setImage(UIImage(systemName: "plus.circle", withConfiguration: symbolConfig)?.withTintColor(.custom.highContrast, renderingMode: .alwaysTemplate), for: .normal)
            btn.accessibilityLabel = NSLocalizedString("accessibility.followTag", comment: "Screen reader only.")
        }
        
        btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btn.imageEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: -1, right: 0)
        let moreButton = UIBarButtonItem(customView: btn)
        return [moreButton]
    }
    
    private func listNavBarItems(list: List) -> [UIBarButtonItem] {
        // Create nav button
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 19, weight: .regular)
        let btn = UIButton(type: .custom)
        btn.setImage(FontAwesome.image(fromChar: "\u{e10a}").withConfiguration(symbolConfig).withTintColor(.custom.highContrast, renderingMode: .alwaysTemplate), for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btn.accessibilityLabel = NSLocalizedString("generic.more", comment: "")
        btn.imageEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: -1, right: 0)
        
        // Create context menu
        let list_members = NSLocalizedString("list.members", comment: "As in 'members in the list'")
        let viewMembersMenu = UIAction(title: list_members, image: FontAwesome.image(fromChar: "\u{f500}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] _ in
            guard let self else { return }
            let vc = UserListViewController(listID: list.id)
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        viewMembersMenu.accessibilityLabel = list_members
        
        let edit_list_title = NSLocalizedString("list.editTitle", comment: "")
        let editTitleMenu = UIAction(title: edit_list_title, image: FontAwesome.image(fromChar: "\u{f304}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] _ in
            guard let self else { return }
            let vc = AltTextViewController()
            vc.editList = list.title
            vc.listId = list.id
            vc.delegate = self
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
        if !ListManager.shared.isTitleEditable(List(id: list.id, title: list.title)) {
            editTitleMenu.attributes = .disabled
        }
        editTitleMenu.accessibilityLabel = edit_list_title

        let delete_list = NSLocalizedString("list.delete", comment: "")
        let deleteMenu = UIAction(title: delete_list, image: FontAwesome.image(fromChar: "\u{f1f8}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] action in
            guard let self else { return }
            let alert = UIAlertController(title: nil, message: NSLocalizedString("list.delete.confirm", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.delete", comment: ""), style: .destructive , handler:{ (UIAlertAction) in
                ListManager.shared.deleteList(list.id) { success in
                    DispatchQueue.main.async {
                        self.delegate?.willChangeFeed(.following)
                        self.viewModel.changeFeed(type: .following)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchLists"), object: nil)
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
            }))
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = getTopMostViewController()?.view
                presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
            }
            getTopMostViewController()?.present(alert, animated: true, completion: nil)
        }
        deleteMenu.accessibilityLabel = delete_list
        deleteMenu.attributes = .destructive
        
        let itemMenu = UIMenu(title: "", options: [], children: [viewMembersMenu, editTitleMenu, deleteMenu])
        btn.menu = itemMenu
        btn.showsMenuAsPrimaryAction = true
        btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btn.imageEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: -1, right: 0)
        let moreButton = UIBarButtonItem(customView: btn)
        return [moreButton]
    }
    
    private func listNavBarContextOptions(list: List) -> [UIAction] {
        // Create context menu
        let list_members = NSLocalizedString("list.members", comment: "")
        let viewMembersMenu = UIAction(title: list_members, image: FontAwesome.image(fromChar: "\u{f500}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] _ in
            guard let self else { return }
            let vc = UserListViewController(listID: list.id)
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        viewMembersMenu.accessibilityLabel = list_members
        
        let edit_list_title = NSLocalizedString("list.editTitle", comment: "")
        let editTitleMenu = UIAction(title: edit_list_title, image: FontAwesome.image(fromChar: "\u{f304}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] _ in
            guard let self else { return }
            let vc = AltTextViewController()
            vc.editList = list.title
            vc.listId = list.id
            vc.delegate = self
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
        if !ListManager.shared.isTitleEditable(List(id: list.id, title: list.title)) {
            editTitleMenu.attributes = .disabled
        }
        editTitleMenu.accessibilityLabel = edit_list_title

        let delete_list = NSLocalizedString("list.delete", comment: "")
        let deleteMenu = UIAction(title: delete_list, image: FontAwesome.image(fromChar: "\u{f1f8}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] action in
            guard let self else { return }
            let alert = UIAlertController(title: nil, message: NSLocalizedString("list.delete.confirm", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.delete", comment: ""), style: .destructive , handler:{ (UIAlertAction) in
                ListManager.shared.deleteList(list.id) { success in
                    DispatchQueue.main.async {
                        self.delegate?.willChangeFeed(.following)
                        self.viewModel.changeFeed(type: .following)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchLists"), object: nil)
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
            }))
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = getTopMostViewController()?.view
                presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
            }
            getTopMostViewController()?.present(alert, animated: true, completion: nil)
        }
        deleteMenu.accessibilityLabel = delete_list
        deleteMenu.attributes = .destructive
    
        return [viewMembersMenu, editTitleMenu, deleteMenu]
    }
    
    private func forYouNavBarItems() -> [UIBarButtonItem] {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 19, weight: .regular)
        let btn = UIButton(type: .custom)
        
        btn.addAction {  [weak self] in
            guard let self else { return }
            triggerHapticImpact(style: .light)
            let vc = ForYouCustomizationViewController()
            vc.isModalInPresentation = true
            self.navigationController?.present(vc, animated: true)
        }
        btn.setImage(UIImage(systemName: "ellipsis.circle", withConfiguration: symbolConfig)?.withTintColor(.custom.highContrast, renderingMode: .alwaysTemplate), for: .normal)
        btn.accessibilityLabel = "…"

        btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btn.imageEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: -1, right: 0)
        let moreButton = UIBarButtonItem(customView: btn)
        return [moreButton]
    }
    
}

// MARK: - Edit list delegate
extension NewsFeedViewController: AltTextViewControllerDelegate {
    func didConfirmText(updatedText: String) {
        if case .list(let list) = self.viewModel.type  {
            self.viewModel.type = .list(List(id: list.id, title: updatedText))
            self.title = self.viewModel.type.title()
        }
    }
}


// MARK: - Feed menu
extension NewsFeedViewController {
        
    @objc func feedMenuItemsChanged() {
        self.feedMenuItems = []
        
        self.navigationItem.setRightBarButtonItems(self.navBarItems(), animated: false)
        self.title = self.viewModel.type.title()
    }
}

extension NewsFeedViewController: JumpToLatestDelegate {
    func onClosePress() {
        self.viewModel.setShowJumpToNow(enabled: false, forFeed: self.viewModel.type)
        self.jumpToNow.isEnabled = false
        self.viewModel.isJumpToNowButtonDisabled = true
    }
}
