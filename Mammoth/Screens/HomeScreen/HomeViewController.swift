//
//  HomeViewController.swift
//  Mammoth
//
//  Created by Riley Howard on 5/22/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

let FOR_YOU_FEED_TYPE = "ForYouFeedType"

class HomeViewController : UIViewController {

    private var feedCarousel = Carousel()
    private var accountsBarButton: UIBarButtonItem? = nil

    enum HomeViewSegment: Int {
        case feeds = 0
        case forYou = 1
    }
    
    private let pageViewController: UIPageViewController
    private var cachedPages: [NewsFeedTypes:NewsFeedViewController] = [:]
    private var currentFeedType: NewsFeedTypes = .following {
        didSet {
            self.updateNavBarButtons()
            self.updateQuickJumpMenu()
            self.updateForYouFeedType()
            self.showTutorialIfNeeded()
        }
    }
    
    required init() {

        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

        super.init(nibName: nil, bundle: nil)
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        if let scrollView = pageViewController.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.delegate = self
        }
        
        self.addChild(pageViewController)
        self.view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        
        feedCarousel.delegate = self
        navigationItem.titleView = feedCarousel
        navigationItem.title = "Feeds"
        
        self.updateNavBarButtons()
        self.updateCarousel()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onForYouChange),
                                               name: didUpdateAccountForYou,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateCarousel),
                                               name: didChangeFeedTypeItemsNotification,
                                               object: nil)
    }
    
    override func viewDidLoad() {
        let initialViewController = self.pageForType(type: self.currentFeedType)
        pageViewController.setViewControllers([initialViewController], direction: .forward, animated: false)
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.updateQuickJumpMenu()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.cachedPages = [:]
      }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Update the appearance of the navbar
        configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
        self.navigationController?.additionalSafeAreaInsets.top = 5
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.showTutorialIfNeeded()
    }
    
    func showTutorialIfNeeded() {
        
        if FeedsManager.shared.feeds.count >= 5 && TutorialOverlay.shouldShowOverlay(forType: .quickFeedSwitcher) {
            // Force this on the next runloop to make sure rootViewController is set
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if let currentTabBarController = getTabBarController(),
                   let item = currentTabBarController.animatedTabBar.tabBarItems.first {
                    currentTabBarController.selectedIndex = 0
                    TutorialOverlay.showOverlay(type: .quickFeedSwitcher, onRef: item)
                }
            }
        } else {
            
            switch self.currentFeedType {
            case .forYou:
                if let itemIndex = self.indexOfCarouselItem(item: .forYou),
                   let item = self.feedCarousel.cellAtIndexPath(indexPath: IndexPath(item: itemIndex, section: 0)) {
                    // The delay is needed to let the carousel animation finish before
                    // taking a snapshot of the reference and positioning on the scrim
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                        guard let self else { return }
                        guard self.currentFeedType == .forYou else { return }
                        guard self.isInWindowHierarchy() else { return }
                        
                        // Display tutorial overlay
                        if TutorialOverlay.shouldShowOverlay(forType: .forYou) {
                            TutorialOverlay.showOverlay(type: .forYou, onRef: item) { [weak self] in
                                guard let self else { return }
                                guard self.currentFeedType == .forYou else { return }
                                guard self.isInWindowHierarchy() else { return }
                                
                                if TutorialOverlay.shouldShowOverlay(forType: .customizeFeed) {
                                    TutorialOverlay.showOverlay(type: .customizeFeed, onRef: self.feedCarousel.contextButton)
                                }
                            }
                        } else if TutorialOverlay.shouldShowOverlay(forType: .customizeFeed) {
                            TutorialOverlay.showOverlay(type: .customizeFeed, onRef: self.feedCarousel.contextButton)
                        }
                    }
                }
            case .channel:
                if let itemIndex = self.indexOfCarouselItem(item: self.currentFeedType),
                   let item = self.feedCarousel.cellAtIndexPath(indexPath: IndexPath(item: itemIndex, section: 0)) {
                    let selectedFeed = self.currentFeedType
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                        guard let self else { return }
                        guard self.currentFeedType == selectedFeed else { return }
                        guard self.isInWindowHierarchy() else { return }
                        
                        // Display tutorial overlay
                        if TutorialOverlay.shouldShowOverlay(forType: .smartList) {
                            TutorialOverlay.showOverlay(type: .smartList, onRef: item)
                        }
                    }
                }
            default:
                break
            }
        }
    }
}

// MARK: - UIPageViewController delegate methods and helper methods
extension HomeViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate {
    
    func pageForType(type: NewsFeedTypes) -> NewsFeedViewController {
        return cachedPages[type] ?? {
            let newVC = NewsFeedViewController(type: type)
            newVC.delegate = self
            cachedPages[type] = newVC
            return newVC
        }()
    }
    
    func currentPage() -> NewsFeedViewController {
        return self.pageForType(type: self.currentFeedType)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let previousItem = self.previousCarouselItem(currentItem: self.currentFeedType) {
            return self.pageForType(type: previousItem)
        }

        return nil
    }
      
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let nextItem = self.nextCarouselItem(currentItem: self.currentFeedType) {
            return self.pageForType(type: nextItem)
        }

        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if let currentPageViewController = pageViewController.viewControllers?.first as? NewsFeedViewController {
            
            self.currentFeedType = currentPageViewController.type
            
            if let index = self.indexOfCarouselItem(item: currentPageViewController.type) {
                self.feedCarousel.selectItem(atIndex: index)
                
                // Pause all videos when switching feeds
                if let previousPageViewController = previousViewControllers.first as? NewsFeedViewController {
                    DispatchQueue.main.async {
                        previousPageViewController.pauseAllVideos()
                    }
                }
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging {
            let width = scrollView.frame.size.width
            let offset = scrollView.contentOffset.x
            let offsetPercentage = (offset - width) / width
            self.feedCarousel.adjustScrollOffset(withPercentageToNextItem: offsetPercentage)
        }
    }
}

//MARK: - NewsFeedViewControllerDelegate
extension HomeViewController: NewsFeedViewControllerDelegate {
    func didScrollToTop() {}
    
    func userActivityStorageIdentifier() -> String {
        return "HomeViewController.currentMenuItemIdentifier"
    }
    
    func didChangeFeed(_ type: NewsFeedTypes) {
        // If views are added/removed from the feed, the related navbar items may be outdated
         self.currentFeedType = type
    }
    
    func willChangeFeed(_ type: NewsFeedTypes) {
        if let index = self.indexOfCarouselItem(item: type) {
            self.feedCarousel.scrollTo(index: index)
        }
    }
    
    func isActiveFeed(_ type: NewsFeedTypes) -> Bool {
        return type == self.currentFeedType
    }
}

// MARK: - Feed context menu
extension HomeViewController {
    private func updateNavBarButtons() {
        if let accountsBarButton {
            self.navigationItem.setRightBarButtonItems([accountsBarButton], animated: false)
        }
        
        let generalOptions = self.generalContextMenu()
        let menu = UIMenu(title: "", options: [], children: [generalOptions])
        self.feedCarousel.contextButton.menu = menu
    }
    
    private func updateQuickJumpMenu() {
        if let currentTabBarController = getTabBarController(), 
            let item = currentTabBarController.animatedTabBar.tabBarItems.first {
            item.menu = UIMenu(title: "", options: [], children: [self.jumpToContextMenu()])
        }
    }
    private func generalContextMenu() -> UIMenu {
        let addList = UIAction(title: NSLocalizedString("list.add", comment: ""), image: FontAwesome.image(fromChar: "\u{2b}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] action in
            guard let self else { return }
            DispatchQueue.main.async {
                let alert = UIAlertController(title: NSLocalizedString("list.add", comment: ""), message: NSLocalizedString("list.prompt", comment: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("list.smart.browse", comment: ""), style: .default, handler: { _ in
                    let vc = ChannelsViewController(viewModel: ChannelsViewModel(singleSection: true)) { [weak self] in
                        self?.showTutorialIfNeeded()
                    }
                    self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("list.create", comment: ""), style: .default, handler: { _ in
                    let vc = AltTextViewController() { [weak self] in
                        self?.showTutorialIfNeeded()
                    }
                    vc.newList = true
                    self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("generic.cancel", comment: ""), style: .destructive, handler: nil))
                self.present(alert, animated: true)
            }
        }
        
        let organize = UIAction(title: NSLocalizedString("home.manageFeeds", comment: ""), image: FontAwesome.image(fromChar: "\u{f03a}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] action in
            guard let self else { return }
            DispatchQueue.main.async {
                let vc = FeedEditorViewController { [weak self] in
                    self?.showTutorialIfNeeded()
                }
                if !vc.isBeingPresented {
                    self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
                }
            }
        }
        let customize_string = NSLocalizedString("feed.customize", comment: "Button for customizing the 'for you' page.")
        let forYou = UIAction(title: customize_string, image: FontAwesome.image(fromChar: "\u{f890}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] _ in
            guard let self else { return }
            
            triggerHapticImpact(style: .light)
            let vc = ForYouCustomizationViewController()
            vc.isModalInPresentation = true
            self.navigationController?.present(vc, animated: true)
        }
        forYou.accessibilityLabel = customize_string

        let settings_string = NSLocalizedString("title.settings", comment: "Button for opening the settings menu.")
        let settings = UIAction(title: settings_string, image: FontAwesome.image(fromChar: "\u{f013}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] _ in
            guard self != nil else { return }
            triggerHapticImpact(style: .light)
            DispatchQueue.main.async {
                let vc = SettingsViewController()
                UIApplication.topViewController()?.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
            }
        }
        forYou.accessibilityLabel = settings_string

        return UIMenu(title: "", options: [.displayInline], children: [forYou, organize, addList, settings])
    }
    
    private func jumpToContextMenu() -> UIMenu {
        let jumpToMenu = UIMenu(title: NSLocalizedString("home.jumpToAList", comment: "Appears when holding in the 'home' button, before a list of feeds."), options: [.displayInline], children: FeedsManager.shared.feeds.sorted(by: { (_, right) in !right.isEnabled }).map { item in
            return UIAction(title: item.type.plainTitle(), image: item.type.icon, identifier: nil) { [weak self] _ in
                guard let self else { return }
                
                if item.isEnabled {
                    if let index = self.indexOfCarouselItem(item: item.type) {
                        self.feedCarousel.scrollTo(index: index)
                        self.carouselItemPressed(withIndex: index)
                    }
                    
                    if self.navigationController?.parent != nil {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                } else {
                    let feedView = NewsFeedViewController(type: item.type)
                    self.navigationController?.pushViewController(feedView, animated: true)
                }
                
                // Navigate to home if needed
                if let currentTabBarController = getTabBarController(), currentTabBarController.selectedIndex != 0 {
                    currentTabBarController.selectedIndex = 0
                }
            }
        })
        
        return jumpToMenu
    }
}

// MARK: - Jump to newest
extension HomeViewController: JumpToNewest {
    @objc func jumpToNewest() {
        if let currentPage = self.pageViewController.viewControllers?.first as? NewsFeedViewController {
            currentPage.jumpToNewest()
        }
    }
}

// MARK: - Carousel delegate and helpers
extension HomeViewController: CarouselDelegate {
     
    func carouselMenu() -> [NewsFeedTypes] {
        return FeedsManager.shared.feeds.filter({ $0.isEnabled }).map { $0.type }
    }
    
    @objc private func updateCarousel() {
        self.feedCarousel.richContent = self.carouselMenu().map({$0.attributedTitle()})
        if let index = self.indexOfCarouselItem(item: self.currentFeedType) {
            self.feedCarousel.scrollTo(index: index, animated: false)
        } else {
            self.currentFeedType = .following
            self.feedCarousel.scrollTo(index: self.indexOfCarouselItem(item: self.currentFeedType) ?? 0, animated: false)
        }
        
        let vc = self.pageForType(type: self.currentFeedType)
        self.pageViewController.setViewControllers([vc], direction: .forward, animated: false)
        
        self.updateNavBarButtons()
        self.updateQuickJumpMenu()
    }
    
    func indexOfCarouselItem(item: NewsFeedTypes) -> Int? {
        let items = self.carouselMenu()
        return items.firstIndex(of: item)
    }
    
    func nextCarouselItem(currentItem: NewsFeedTypes) -> NewsFeedTypes? {
        let items = self.carouselMenu()
        if let currentIndex = self.indexOfCarouselItem(item: currentItem) {
            guard items.count > currentIndex + 1 else { return nil}
            return items[currentIndex + 1]
        }
        
        return nil
    }
    
    func previousCarouselItem(currentItem: NewsFeedTypes) -> NewsFeedTypes? {
        let items = self.carouselMenu()
        if let currentIndex = self.indexOfCarouselItem(item: currentItem) {
            guard currentIndex > 0 else { return nil}
            return items[currentIndex - 1]
        }
        
        return nil
    }
    
    func carouselItem(atIndex index: Int) -> NewsFeedTypes? {
        let items = self.carouselMenu()
        guard items.count > index else { return nil }
        return items[index]
    }
    
    func carouselItemPressed(withIndex index: Int) {
        let menuItems = self.carouselMenu()
        guard menuItems.count > index else { return }
        
        var direction = UIPageViewController.NavigationDirection.reverse
        if let oldIndex = self.indexOfCarouselItem(item: self.currentFeedType) {
            if oldIndex < index {
                direction = UIPageViewController.NavigationDirection.forward
            }
            
            let previousViewController = self.pageForType(type: self.currentFeedType)
            previousViewController.pauseAllVideos()
        }
        
        self.currentFeedType = self.carouselItem(atIndex: index) ?? .following
        let vc = self.pageForType(type: self.currentFeedType)
        self.pageViewController.setViewControllers([vc], direction: direction, animated: true)
    }
    
    func carouselActiveItemDoublePressed() {
        self.currentPage().jumpToNewest()
    }
    
    func contextMenuForItem(withIndex index: Int) -> UIMenu? {
        let items = self.carouselMenu()
        let type = items[index]
        let page = self.pageForType(type: type)
        let feedOptions = page.contextMenu()
        
        if !feedOptions.children.isEmpty {
            return UIMenu(title: "", options: [], children: [feedOptions])
        }
        
        return nil
    }
}

// MARK: - App state restoration
extension HomeViewController: AppStateRestoration {
    
    public func storeUserActivity(in activity: NSUserActivity) {
        log.debug("HomeViewController:" + #function)
        activity.userInfo?["HomeViewController.carouselIndex"] = self.feedCarousel.selectedIndexPath.item
    }
    
    public func restoreUserActivity(from activity: NSUserActivity) {
        log.debug("HomeViewController:" + #function)
        if let selectedCarouselIndex = activity.userInfo?["HomeViewController.carouselIndex"] as? Int {
            log.debug("HomeViewController:" + #function + " selectedCarouselIndex:\(selectedCarouselIndex)")
            
            if let currentType = self.carouselItem(atIndex: selectedCarouselIndex) {
                self.currentFeedType = currentType
                self.feedCarousel.scrollTo(index: selectedCarouselIndex, animated: false)
                let vc = self.pageForType(type: currentType)
                self.pageViewController.setViewControllers([vc], direction: .forward, animated: false)
            }
        }
    }
}

// MARK: - Appearance changes
internal extension HomeViewController {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
             }
         }
    }
}

// MARK: - ForYou User Settings
/// Keeps track of the current user's ForYou feed type as a
extension HomeViewController {
    
    func forYouUserSettingKey() -> String  {
        if let currentUser  = AccountsManager.shared.currentAccount?.remoteFullOriginalAcct {
            return "\(currentUser):\(FOR_YOU_FEED_TYPE)"
        } else {
            return ""
        }
    }
    
     func forYouUserSetting() -> String? {
         let key: String = forYouUserSettingKey()
         return UserDefaults.standard.object(forKey:key) as? String
        }
    
    func updateForYouUserSetting(type: String) -> Void {
        UserDefaults.standard.set(type, forKey: self.forYouUserSettingKey())
    }
    
    func triggerPersonalFeedAlert(remoteFullOriginalAcct: String) -> Void {
        let dialogMessage = UIAlertController(title: "Success", message: "You're now able to see posts from friends of friends.", preferredStyle: .alert)
        dialogMessage.addAction(UIAlertAction(title: "Done", style: .default))
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    // We want to check type of the ForYou Feed (public | personal)
    // On return of 'personal' set user default and launch confetti!
    private func updateForYouFeedType() -> Void {
        // Only for For You feed
        guard self.currentFeedType == .forYou else { return }
        // Don't check if state is already personal
        let storedSetting = self.forYouUserSetting()
        guard storedSetting != ForYouAccountType.personal.rawValue else { return }
        // Only if we have an account name
        guard let remoteFullOriginalAcct = AccountsManager.shared.currentAccount?.remoteFullOriginalAcct else { return }
        
        let currentAccount = AccountsManager.shared.currentAccount
        
        Task {
            // Fetch ForYou Type
            let result = try await TimelineService.forYouMe(remoteFullOriginalAcct: remoteFullOriginalAcct)
            log.debug("For You personalization status: \(result.forYou.type.rawValue)")
            await MainActor.run { [weak self] in
                guard let self else { return }
                guard currentAccount?.remoteFullOriginalAcct == AccountsManager.shared.currentAccount?.remoteFullOriginalAcct else { return }
                
                // Update our local forYou settings based on what the server just returned
                AccountsManager.shared.updateCurrentAccountForYou(result.forYou, writeToServer: false)

                // If api value matches saved setting return early
                if self.forYouUserSetting() == result.forYou.type.rawValue { return }
                // Store the new value
                updateForYouUserSetting(type: result.forYou.type.rawValue)
                // Server/Client values do not match. Update and Reload
                if storedSetting != nil {
                    self.pageForType(type: .forYou).forceReloadForYou()
                }
                
                // If the setting went from 'something' (not nil) to .personal,
                // it's confetti time!
                if result.forYou.type == ForYouAccountType.personal && storedSetting != nil {
                    triggerPersonalFeedAlert(remoteFullOriginalAcct: remoteFullOriginalAcct)
                }
            }
        }
    }
    
    @objc private func onForYouChange() {
        // This notification is triggered when the user changes their For You
        // account settings.
        DispatchQueue.main.async {
            log.debug(#function)
            self.pageForType(type: .forYou).startCheckingFYStatus()
        }
    }

}
