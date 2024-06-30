//
//  ProfileViewController.swift
//  Mammoth
//
//  Created by Benoit Nolens on 12/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate {
    
    private let navigationBarAnimationThreshold = 120.0
    private let titleView = ProfileNavigationTitle()
    private let header = ProfileHeader()
    private let coverImage = ProfileCoverImage()
    private var backButton: ProfileBackButton?
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        PostCardCell.registerForReuseIdentifierVariants(on: tableView)
        tableView.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
        tableView.register(EmptyFeedCell.self, forCellReuseIdentifier: EmptyFeedCell.reuseIdentifier)
        tableView.register(ProfileSectionHeader.self, forHeaderFooterViewReuseIdentifier: ProfileSectionHeader.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }
        
        // Hides the last separator
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        
        return tableView
    }()
    
    private lazy var photoPicker = PhotoPicker()
    private var settingsButton: ProfileViewSettingsButton?
    
    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.backgroundColor = .clear
        refresh.addTarget(self, action: #selector(self.onDragToRefresh(_:)), for: .valueChanged)
        return refresh
    }()

    private var viewModel: ProfileViewModel

    required init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        self.header.onButtonPress = { [weak self] type, data in
            guard let self else { return }
            self.onUserActionPress(type: type, data: data)
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.reloadAll),
                                               name: NSNotification.Name(rawValue: "reloadAll"),
                                               object: nil)
        
        if self.viewModel.screenType == .own {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self else { return }
                self.updateQuickAccountSwitcher()
            }
        }
    }

    convenience init(user: UserCardModel? = nil, screenType: ProfileViewModel.ProfileScreenType = .own) {
        let viewModel = ProfileViewModel(.posts, user: user, screenType: screenType)
        self.init(viewModel: viewModel)
    }

    convenience init(acctData: (any AcctDataType)?) {
        if let mastodonAccount = (acctData as? MastodonAcctData)?.account {
            let userCardModel = UserCardModel(account: mastodonAccount)
            self.init(user: userCardModel)
        } else {
            self.init()
        }
    }
    
    convenience init(fullAcct: String, serverName: String = AccountsManager.shared.currentAccountClient.baseHost) {
        let viewModel = ProfileViewModel(fullAcct: fullAcct, serverName: serverName)
        self.init(viewModel: viewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.titleView.didScroll(scrollView: self.tableView)
        self.coverImage.didScroll(scrollView: self.tableView)
        self.settingsButton?.didScroll(scrollView: self.tableView)
        self.backButton?.didScroll(scrollView: self.tableView)

        let maxOffset = navigationBarAnimationThreshold - self.tableView.safeAreaInsets.top
        if self.tableView.contentOffset.y < maxOffset {
            self.setupNav(isOpaque: false)
        } else {
            self.setupNav(isOpaque: true)
        }
                
        tableView.setTableHeaderView(headerView: self.header)
        tableView.updateHeaderViewFrame()
        
        self.navigationItem.titleView = self.titleView
        titleView.sizeToFit()
        
        if let stackVCs = self.navigationController?.viewControllers, stackVCs.count > 1 {
            self.backButton = ProfileBackButton({ [weak self] in
                guard let self else { return }
                self.navigationController?.popViewController(animated: true)
            })
            
            self.navigationItem.setLeftBarButton(UIBarButtonItem(customView: self.backButton!), animated: false)
        }
        
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        self.navigationController?.navigationBar.setNeedsLayout()
        
        self.settingsButton?.user = self.viewModel.user
        
        Task { [weak self] in
            guard let self else { return }
            if self.viewModel.screenType == .own {
                await self.viewModel.reloadUser()
                await self.viewModel.loadListData()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.viewModel.screenType == .own {
            self.showTutorialIfNeeded()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.viewModel.stopAllVideos()
        AVManager.shared.currentPlayer?.pause()
    }
    
    @objc private func onDragToRefresh(_ sender: Any) {
        Task { [weak self] in
            guard let self else { return }
            Sound().playSound(named: "soundSuction", withVolume: 1)
            await self.viewModel.reloadUser()
            await self.viewModel.loadListData()
        }
    }
    
    @objc private func reloadAll() {
        self.view.backgroundColor = .custom.background
        self.refreshControl.backgroundColor = .clear
        self.tableView.reloadData()
        self.titleView.onThemeChange()
        self.header.onThemeChange()
        self.coverImage.onThemeChange()
        self.settingsButton?.onThemeChange()
    }
    
    private func updateQuickAccountSwitcher() {
        if let currentTabBarController = getTabBarController(),
            let item = currentTabBarController.animatedTabBar.tabBarItems.last {
            item.menu = UIMenu(title: "", options: [], children: [self.accountSwitcherContextMenu()])
        }
    }
}

// MARK: UI Setup
private extension ProfileViewController {
    func setupUI() {
        
        self.view.backgroundColor = .custom.background

        let isPastOnboarding: Bool = !AccountsManager.shared.shouldShowOnboardingForCurrentAccount()

        if isPastOnboarding {
            self.settingsButton = ProfileViewSettingsButton({ [weak self] type, data in
                guard let self else { return }
                self.onUserActionPress(type: type, data: data)
            })
            navigationItem.setRightBarButton(UIBarButtonItem(customView: self.settingsButton!), animated: false)
            
            if self.viewModel.screenType == .own {
                let accountSwitch = AccountSwitcherButton()
                navigationItem.setLeftBarButton(UIBarButtonItem(customView: accountSwitch), animated: false)
            }
        }
        

        tableView.refreshControl = self.refreshControl
        coverImage.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(coverImage)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            self.coverImage.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.coverImage.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.coverImage.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.coverImage.heightAnchor.constraint(equalToConstant: 270),
            
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])
    }
    
    func setupNav(isOpaque: Bool, forceUpdate: Bool = false) {
        
        var shouldUpdate = false
        if let navController = self.navigationController, (navController.navigationBar.standardAppearance.backgroundEffect == nil && isOpaque) {
            shouldUpdate = true
        }
        
        if let navController = self.navigationController, (navController.navigationBar.standardAppearance.backgroundEffect != nil && !isOpaque) {
            shouldUpdate = true
        }
        
        guard (shouldUpdate || forceUpdate) else { return }
        
        let navApp = UINavigationBarAppearance()
        if isOpaque {
            navApp.configureWithTransparentBackground()
            navApp.backgroundEffect = NavBarBlurEffect()
            navApp.backgroundColor = NavBarBackgroundColor(userInterfaceStyle: self.traitCollection.userInterfaceStyle)
        } else {
            navApp.configureWithTransparentBackground()
            navApp.backgroundColor = .clear
        }
        
        self.navigationController?.navigationBar.standardAppearance = navApp
        self.navigationController?.navigationBar.scrollEdgeAppearance = navApp
        self.navigationController?.navigationBar.compactAppearance = navApp
        
        if #available(iOS 15.0, *) {
            self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
        }
    }
    
    func showTutorialIfNeeded() {
        if AccountsManager.shared.allAccounts.count > 1 && TutorialOverlay.shouldShowOverlay(forType: .quickAccountSwitcher) {
            // Force this on the next runloop to make sure rootViewController is set
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if let currentTabBarController = getTabBarController(),
                   let item = currentTabBarController.animatedTabBar.tabBarItems.last {
                    currentTabBarController.selectedIndex = 4
                    TutorialOverlay.showOverlay(type: .quickAccountSwitcher, onRef: item)
                }
            }
        }
    }
}

// MARK: Appearance changes
internal extension ProfileViewController {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 self.reloadAll()
                 
                 let maxOffset = navigationBarAnimationThreshold - self.tableView.safeAreaInsets.top
                 if self.tableView.contentOffset.y < maxOffset {
                     self.setupNav(isOpaque: false, forceUpdate: true)
                 } else {
                     self.setupNav(isOpaque: true, forceUpdate: true)
                 }
             }
         }
    }
}

// MARK: Actions
private extension ProfileViewController {
    func onUserActionPress(type: UserCardButtonType, data: UserCardButtonCallbackData?) {
        switch type {
        case .openFollowers:
            if let user = self.viewModel.user {
                UserActions.onFollowersTap(target: self, user: user)
            }
        case .openFollowing:
            if let user = self.viewModel.user {
                UserActions.onFollowingTap(target: self, user: user)
            }
        case .settings:
            UserActions.onSettingsTap(target: self)
            
        case .share:
            if let user = self.viewModel.user {
                UserActions.onShareTap(target: self, user: user)
            }
        
        case .filters:
            if let user = self.viewModel.user {
                UserActions.onFiltersTap(target: self, user: user)
            }
        case .muted:
            if let user = self.viewModel.user {
                UserActions.onMutedTap(target: self, user: user)
            }
        case .blocked:
            if let user = self.viewModel.user {
                UserActions.onBlockedTap(target: self, user: user)
            }
        case .bookmarks:
            if let user = self.viewModel.user {
                UserActions.onBookmarksTap(target: self, user: user)
            }
        case .likes:
            if let user = self.viewModel.user {
                UserActions.onLikesTap(target: self, user: user)
            }
        case .recentMedia:
            if let user = self.viewModel.user {
                UserActions.onRecentMediaTap(target: self, user: user)
            }
            
        case .editDetails:
            if let user = self.viewModel.user {
                UserActions.onEditDetails(target: self, user: user)
            }
            
        case .editInfoAndLink:
            if let user = self.viewModel.user {
                UserActions.onEditInfoAndLinks(target: self, user: user)
            }
            
        case .editHeader:
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.photoPicker.delegate = self
                    self.photoPicker.photoType = .Header
                    self.photoPicker.presentPicker(hostViewController: self, animated: true)
                }
            }
            
        case .editAvatar:
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.photoPicker.delegate = self
                    self.photoPicker.photoType = .Avatar
                    self.photoPicker.presentPicker(hostViewController: self, animated: true)
                }
            }
            
        case .link:
            switch(data) {
            case .url(let url):
                PostActions.onURLPress(url: url)
            case .email(let email):
                PostActions.onEmailPress(email: email)
            case .hashtag(let hashtag):
                PostActions.onHashtagPress(target: self, hashtag: hashtag)
            case .mention(let mention):
                guard let account = self.viewModel.user?.account else { break }
                PostActions.onMentionPress(target: self, mention: mention, serverName: account.server)
            default:
                break
            }
            
        case .mention:
            guard let account = self.viewModel.user?.account else { break }
            UserActions.onMention(target: self, user: account)
            
        case .message:
            guard let account = self.viewModel.user?.account else { break }
            UserActions.onMessage(target: self, user: account)

        case .muteOneDay:
            guard let account = self.viewModel.user?.preSyncAccount ?? self.viewModel.user?.account else { break }
            UserActions.onMuteOneDay(target: self, user: account)
            
        case .muteForever:
            guard let account = self.viewModel.user?.preSyncAccount ?? self.viewModel.user?.account else { break }
            UserActions.onMute(target: self, user: account)
            
        case .unmute:
            guard let account = self.viewModel.user?.preSyncAccount ?? self.viewModel.user?.account else { break }
            ModerationManager.shared.unmute(user: account)
            
        case .block:
            guard let account = self.viewModel.user?.preSyncAccount ?? self.viewModel.user?.account else { break }
            UserActions.onBlock(target: self, user: account)
            
        case .unblock:
            guard let account = self.viewModel.user?.preSyncAccount ?? self.viewModel.user?.account else { break }
            ModerationManager.shared.unblock(user: account)
            
        case .addToList:
            guard let account = self.viewModel.user?.preSyncAccount ?? self.viewModel.user?.account else { break }
            if case .list(let listId) = data {
                UserActions.addToList(user: account, listId: listId)
            }
            break
        case .removeFromList:
            guard let account = self.viewModel.user?.preSyncAccount ?? self.viewModel.user?.account else { break }
            if case .list(let listId) = data {
                UserActions.removeFromList(user: account, listId: listId)
            }
            break
        case .createNewList:
            let vc = AltTextViewController()
            vc.newList = true
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
            break
        case .enableReposts:
            guard let account = self.viewModel.user?.preSyncAccount ?? self.viewModel.user?.account else { break }
            UserActions.enableReposts(user: account)
            break
        case .disableReposts:
            guard let account = self.viewModel.user?.preSyncAccount ?? self.viewModel.user?.account else { break }
            UserActions.disableReposts(user: account)
            break
        case .enableNotifications:
            guard let account = self.viewModel.user?.preSyncAccount ?? self.viewModel.user?.account else { break }
            UserActions.enableNotifications(user: account)
            break
        case .disableNotifications:
            guard let account = self.viewModel.user?.preSyncAccount ?? self.viewModel.user?.account else { break }
            UserActions.disableNotifications(user: account)
            break
        }
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate & UITableViewDataSourcePrefetching
extension ProfileViewController: UITableViewDataSource, UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? PostCardCell {
            cell.willDisplay()
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? PostCardCell {
            cell.didEndDisplay()
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(forSection: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Display loader cell in last row if needed
        if viewModel.shouldDisplayLoader() && indexPath.row == viewModel.numberOfItems(forSection: indexPath.section) - 1 {
            if let cell = self.tableView.dequeueReusableCell(withIdentifier: LoadingCell.reuseIdentifier, for: indexPath) as? LoadingCell {
                cell.startAnimation()
                return cell
            }
        }
        
        if viewModel.isListEmpty() {
            if let cell = self.tableView.dequeueReusableCell(withIdentifier: EmptyFeedCell.reuseIdentifier, for: indexPath) as? EmptyFeedCell {
                cell.configure()
                return cell
            }
        }
        
        if let postCard = viewModel.getInfo(forIndexPath: indexPath),
           let cell = self.tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: postCard), for: indexPath) as? PostCardCell{
            cell.configure(postCard: postCard) { [weak self] (type, isActive, data) in
                guard let self else { return }
                PostActions.onActionPress(target: self, type: type, isActive: isActive, postCard: postCard, data: data)
            }
            return cell
        }
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: .textOnly), for: indexPath) as! PostCardCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let postCard = viewModel.getInfo(forIndexPath: indexPath),
            case .mastodon(_) = postCard.data
        else { return }
        
        // For non-mastodon posts we load them via the user's instance
        // and do not try to reload the original post
        if !self.viewModel.isLoadingOriginals {
            postCard.isSyncedWithOriginal = true
        }
        
        let vc = DetailViewController(post: postCard)
        if vc.isBeingPresented {} else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if viewModel.shouldFetchNext(prefetchRowsAt: indexPaths) {
            Task { [weak self] in
                guard let self else { return }
                await viewModel.loadListData(type: nil, loadNextPage: true)
            }
        }
        
        viewModel.preloadCards(atIndexPaths: indexPaths)
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        viewModel.cancelPreloadCards(atIndexPaths: indexPaths)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.viewModel.hasHeader(forSection: section) {
            return 54
        }
        
        return 0
    }
        
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if self.viewModel.hasHeader(forSection: section),
            let sectionHeader = tableView.dequeueReusableHeaderFooterView(withIdentifier: ProfileSectionHeader.reuseIdentifier) as? ProfileSectionHeader {
           sectionHeader.delegate = self.viewModel
           sectionHeader.onThemeChange()
           return sectionHeader
       }
       
       return nil
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.titleView.didScroll(scrollView: scrollView)
        self.coverImage.didScroll(scrollView: scrollView)
        self.settingsButton?.didScroll(scrollView: scrollView)
        self.backButton?.didScroll(scrollView: scrollView)

        let maxOffset = navigationBarAnimationThreshold - self.tableView.safeAreaInsets.top
        if scrollView.contentOffset.y < maxOffset {
            self.setupNav(isOpaque: false)
        } else {
            self.setupNav(isOpaque: true)
        }
        
        // Fetch next again if scrolling past the last elements
        if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height - 100,
               self.viewModel.shouldFetchNext(prefetchRowsAt: [IndexPath(row: viewModel.numberOfItems(forSection: 0), section: 0)]) {
            Task { [weak self] in
                guard let self else { return }
                await self.viewModel.loadListData(type: nil, loadNextPage: true)
            }
        }
        
    }
}

// MARK: UIContextMenuInteractionDelegate
extension ProfileViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if let postCard = viewModel.getInfo(forIndexPath: indexPath),
           let cell = self.tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: postCard), for: indexPath) as? PostCardCell {

            return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { nil }, actionProvider: { suggestedActions in
                return cell.createContextMenu(postCard: postCard) { [weak self] type, isActive, data in
                    guard let self else { return }
                    PostActions.onActionPress(target: self, type: type, isActive: isActive, postCard: postCard, data: data)
                }
            })
        }
        
        return nil
    }
    
    private func accountSwitcherContextMenu() -> UIMenu {
        let accountsMenu = UIMenu(title: "", options: [.displayInline], children: AccountsManager.shared.allAccounts.map({ item in
            let isSelected = AccountsManager.shared.currentAccount?.uniqueID == item.uniqueID
            let accountAction = UIAction(title: "@\(item.fullAcct)", image: isSelected ? FontAwesome.image(fromChar: "\u{f00c}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate) : nil, identifier: nil) { action in
                // switch account
                DispatchQueue.main.async {
                    let account = item
                    // Only switch if not already the current account
                    if account.uniqueID != AccountsManager.shared.currentAccount?.uniqueID {
                        AccountsManager.shared.switchToAccount(account)
                    }
                }
            }
            return accountAction
        }))
        
        let addAccount = UIAction(title: NSLocalizedString("profile.addAccount", comment: ""), image: FontAwesome.image(fromChar: "\u{2b}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { _ in
            DispatchQueue.main.async {
                triggerHapticImpact(style: .light)
                let vc = IntroViewController()
                vc.fromPlus = true
                if vc.isBeingPresented {} else {
                    getTopMostViewController()?.present(UINavigationController(rootViewController: vc), animated: true)
                }
            }
        }
        
        let accountSettings = UIAction(title: NSLocalizedString("settings.accountSettings", comment: ""), image: FontAwesome.image(fromChar: "\u{f013}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { _ in
            DispatchQueue.main.async {
                triggerHapticImpact(style: .light)
                let vc = AccountsSettingsViewController()
                if vc.isBeingPresented {} else {
                    getTopMostViewController()?.present(UINavigationController(rootViewController: vc), animated: true)
                }
            }
        }
        
        let settingsMenu = UIMenu(title: "", options: [.displayInline], children: [
            AccountsManager.shared.allAccounts.count > 1 ? accountSettings : nil,
            addAccount
        ].compactMap({$0}))
        
        return UIMenu(title: "", options: [.displayInline], children: [settingsMenu, accountsMenu])
    }
}


// MARK: RequestDelegate
extension ProfileViewController: RequestDelegate {
    func didUpdate(with state: ViewState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let user = self.viewModel.user {
                let needsLayout = user != self.header.user
                if needsLayout {
                    self.header.configure(user: user, screenType: self.viewModel.screenType)
                    self.coverImage.configure(user: user)
                    self.tableView.updateHeaderViewFrame()
                    self.settingsButton?.user = user
                    self.titleView.configure(title: user.isSelf ? NSLocalizedString("navigator.profile", comment: "") : "@\(user.username)")
                    self.navigationItem.title = user.isSelf ? NSLocalizedString("navigator.profile", comment: "") : "@\(user.username)"
                }
            }
            
            switch state {
            case .idle:
                break
            case .loading:
                if self.viewModel.shouldDisplayLoader() {
                    self.tableView.reloadData()
                }
                break
            case .success:
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                }
                self.tableView.reloadData()
                break
            case .error(let error):
                self.tableView.reloadData()
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                }
                log.error("Error on ProfileYouViewController didUpdate: \(error)")
                
                if case ProfileViewModel.NetworkError.userNotFound = error {
                    self.showAlert(title: "User can't be found", message: "We could not find this user") {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
                break
            }
        }
    }
    
    func didUpdateCard(at indexPath: IndexPath) {
        if self.isInWindowHierarchy() {
            if self.viewModel.numberOfSections > indexPath.section,
               self.viewModel.numberOfItems(forSection: indexPath.section) > indexPath.row {
                self.tableView.reloadRows(at: [indexPath], with: .none)
            } else {
                log.warning("Unexpected card update")
            }
        } else {
            self.tableView.reloadData()
        }
    }
    
    func didDeleteCard(at indexPath: IndexPath) {
        if self.isInWindowHierarchy() {
            self.tableView.deleteRows(at: [indexPath], with: .bottom)
        } else {
            self.tableView.reloadData()
        }
    }
}

extension ProfileViewController: JumpToNewest {
    @objc func jumpToNewest() {
        self.tableView.setContentOffset( CGPoint(x: 0, y: -self.tableView.safeAreaInsets.top) , animated: true)
    }
}

extension ProfileViewController: PhotoPickerDelegate {
    func didUpdateImage(image: UIImage) {
        switch photoPicker.photoType {
        case .Avatar:
            UserActions.onAvatarEdit(image: image)
            self.header.optimisticUpdate(image: image)
            
        case .Header:
            UserActions.onHeaderEdit(image: image)
            self.coverImage.optimisticUpdate(image: image)
        }
    }
}
