//
//  AuxFeedViewController.swift
//  Mammoth
//
//  Created by Riley Howard on 6/8/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class AuxFeedViewController : UIViewController {
    private let newsFeedViewController = NewsFeedViewController(type: .following)
    private lazy var activityViewController = ActivityViewController(screenPosition: .aux)
    private lazy var sentMessagesViewController = NewsFeedViewController(type: .mentionsOut)
    private lazy var receivedMessagesViewController = NewsFeedViewController(type: .mentionsIn)
    private lazy var likesViewController = NewsFeedViewController(type: .likes)
    private lazy var bookmarksViewController = NewsFeedViewController(type: .bookmarks)
    private let discoveryViewController = DiscoveryViewController(viewModel: DiscoveryViewModel(screenPosition: .aux))
    
    var restoredViewController: UIViewController? = nil
    var restoredActionIdentifier: UIAction.Identifier? = nil
    var currentFeedController: UIViewController? = nil
    private var currentMenuItemIdentifier: UIAction.Identifier? = nil
    weak var delegate: AuxFeedViewControllerDelegate?
    var feedMenuItems : [UIMenu] = []
    
    required init() {
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.feedMenuItemsChanged),
                                               name: NSNotification.Name(rawValue: "updateClient"),
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let (initialVC, actionIdentifier) = initialViewController()
        self.switchToFeedController(initialVC, actionIdentifier: actionIdentifier)
    }
    
    override var title: String? {
        get {
            var title = currentFeedController?.title

            if title == nil {
                title = super.title
            }
            return title
        }
        set {
            super.title = newValue
        }
    }

    func initialViewController() -> (UIViewController, UIAction.Identifier) {
        if restoredViewController != nil && restoredActionIdentifier != nil {
            return (restoredViewController!, restoredActionIdentifier!)
        } else {
            let actionIdentifier = UIAction.Identifier("Discovery")
            let viewController = viewControllerFromActionIdentifier(actionIdentifier)
            return (viewController!, actionIdentifier)
        }
    }
    
    public func feedMenu() -> [UIMenu] {
        var menuItems: [UIMenu] = []
        menuItems.append(generalMenu())
        menuItems.append(standardFeedsMenu())
        menuItems.append(communitiesMenu())
        menuItems.append(listsMenu())
        menuItems.append(hashtagsMenu())
        return menuItems
    }

    
    func viewControllerFromActionIdentifier(_ actionIdentifier: UIAction.Identifier) -> UIViewController? {
        var vc: UIViewController? = nil
        let actionIDString = NSString(string: actionIdentifier.rawValue) as String
        
        if actionIDString == "Activity" {
            vc = self.activityViewController
        } else if actionIDString == "Sent Mentions" {
            vc = self.sentMessagesViewController
        } else if actionIDString == "Received Mentions" {
            vc = self.receivedMessagesViewController
        } else if actionIDString == "Likes" {
            vc = self.likesViewController
        } else if actionIDString == "Bookmarks" {
            vc = self.bookmarksViewController
        } else if actionIDString == "Discovery" {
            vc = self.discoveryViewController
        }

        if vc == nil {
            vc = self.newsFeedViewController
            
            // NewsFeedVC is lazy so set the delegate alap
            self.newsFeedViewController.delegate = self
        }
        
        return vc
    }
    
    func switchToFeedController(_ feedController: UIViewController, actionIdentifier: UIAction.Identifier) {
        if feedController != currentFeedController {
            let previousFeedController = currentFeedController
            currentFeedController = feedController
            self.addChild(feedController)
            self.view.addSubview(feedController.view)
            
            feedController.view.translatesAutoresizingMaskIntoConstraints = false
            self.view.addConstraints( [
                feedController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                feedController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                feedController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                feedController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
            previousFeedController?.willMove(toParent: nil)
            previousFeedController?.view.removeFromSuperview()
            previousFeedController?.removeFromParent()
        }
        currentMenuItemIdentifier = actionIdentifier

        delegate?.didChangeFeedController(currentFeedController)
    }
}

// MARK: - Feed menu
extension AuxFeedViewController {
    
    private func generalMenu() -> UIMenu {
        var sidebarActions: [UIAction] = []
        
        let activityIdentifier = UIAction.Identifier("Activity")
        let activityMenuItem = UIAction(title: MAMenu.activity.title, image: MAMenu.activity.image.withRenderingMode(.alwaysTemplate), identifier: activityIdentifier) { [weak self] action in
            guard let self else { return }
            let viewController = viewControllerFromActionIdentifier(activityIdentifier)
            self.switchToFeedController(viewController!, actionIdentifier: activityIdentifier)
        }
        sidebarActions.append(activityMenuItem)

        
        let sentMessagesIdentifier = UIAction.Identifier("Sent Mentions")
        let sentMessagesMenuItem = UIAction(title: MAMenu.sentMentions.title, image: MAMenu.sentMentions.image.withRenderingMode(.alwaysTemplate), identifier: sentMessagesIdentifier) { [weak self] action in
            guard let self else { return }
            let viewController = viewControllerFromActionIdentifier(sentMessagesIdentifier)
            self.switchToFeedController(viewController!, actionIdentifier: sentMessagesIdentifier)
        }

        sidebarActions.append(sentMessagesMenuItem)
        let receivedMessagesIdentifier = UIAction.Identifier("Received Mentions")
        let receivedMessagesMenuItem = UIAction(title: MAMenu.receivedMentions.title, image: MAMenu.receivedMentions.image.withRenderingMode(.alwaysTemplate), identifier: receivedMessagesIdentifier) { [weak self] action in
            guard let self else { return }
            let viewController = viewControllerFromActionIdentifier(receivedMessagesIdentifier)
            self.switchToFeedController(viewController!, actionIdentifier: receivedMessagesIdentifier)
        }
        sidebarActions.append(receivedMessagesMenuItem)

        let likesIdentifier = UIAction.Identifier("Likes")
        let favoritesMenuItem = UIAction(title: MAMenu.favorites.title, image: MAMenu.favorites.image.withRenderingMode(.alwaysTemplate), identifier: likesIdentifier) { [weak self] action in
            guard let self else { return }
            let viewController = viewControllerFromActionIdentifier(likesIdentifier)
            self.switchToFeedController(viewController!, actionIdentifier: likesIdentifier)
        }
        sidebarActions.append(favoritesMenuItem)

        let bookmarksIdentifier = UIAction.Identifier("Bookmarks")
        let bookmarksMenuItem = UIAction(title: MAMenu.bookmarks.title, image: MAMenu.bookmarks.image.withRenderingMode(.alwaysTemplate), identifier: bookmarksIdentifier) { [weak self] action in
            guard let self else { return }
            let viewController = viewControllerFromActionIdentifier(bookmarksIdentifier)
            self.switchToFeedController(viewController!, actionIdentifier: bookmarksIdentifier)
        }
        sidebarActions.append(bookmarksMenuItem)

        let discoveryIdentifier = UIAction.Identifier("Discovery")
        let searchMenuItem = UIAction(title: MAMenu.search.title, image: MAMenu.search.image.withRenderingMode(.alwaysTemplate), identifier: discoveryIdentifier) { [weak self] action in
            guard let self else { return }
            let viewController = viewControllerFromActionIdentifier(discoveryIdentifier)
            self.switchToFeedController(viewController!, actionIdentifier: discoveryIdentifier)
        }
        sidebarActions.append(searchMenuItem)

        let sidebarActionsMenu = UIMenu(title: "", options: [.displayInline], children: sidebarActions)
        return sidebarActionsMenu
    }
    
    private func communitiesMenu() -> UIMenu {
        var communitiesActions: [UIAction] = []
                
        // Add user's community
        let instanceName = AccountsManager.shared.currentUser()?.server ?? "Instance"
        let actionIdentifier = UIAction.Identifier("Community")
        let communityMenuItem = UIAction(title: "\(instanceName)", image: MAMenu.localCommunity.image.withRenderingMode(.alwaysTemplate), identifier: actionIdentifier) { [weak self] action in
            DispatchQueue.main.async {
                guard let self else { return }
                self.newsFeedViewController.changeFeed(type: .community(AccountsManager.shared.currentUser()?.server ?? "Instance"))
                self.switchToFeedController(self.newsFeedViewController, actionIdentifier: actionIdentifier)
            }
        }
        communitiesActions.append(communityMenuItem)
        
        // Add pinned communities
        let instances = InstanceManager.shared.pinnedInstances
        for x in instances {
            let actionIdentifier = UIAction.Identifier("Community:\(x)")
            let communityMenuItem = UIAction(title: x, image: MAMenu.community.image.withRenderingMode(.alwaysTemplate), identifier: actionIdentifier) { [weak self] action in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.newsFeedViewController.changeFeed(type: .community(x))
                    self.switchToFeedController(self.newsFeedViewController, actionIdentifier: actionIdentifier)
                }
            }
            communitiesActions.append(communityMenuItem)
        }
        
        // Append Browse Communities
        let menuItemBC = UIAction(title: MAMenu.browseCommunities.title, image: MAMenu.browseCommunities.image.withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] action in
            DispatchQueue.main.async {
                guard let self else { return }
                let browseVC = SignInViewController()
                browseVC.isFromSignIn = false
                self.present(UINavigationController(rootViewController: browseVC), animated: true, completion: nil)
            }
        }
        communitiesActions.append(menuItemBC)

        let communitiesActionsMenu = UIMenu(title: "", options: [.displayInline], children: communitiesActions)
        return communitiesActionsMenu
    }
    
    private func hashtagsMenu() -> UIMenu {
        var hashtagActions: [UIAction] = []
        
        for hashtag in HashtagManager.shared.allHashtags() {
            let visibleTitle = "#\(hashtag.name)"
            let actionIdentifier = UIAction.Identifier("Hashtag:\(visibleTitle)")
            let menuItem = UIAction(title: visibleTitle, image: MAMenu.hashtag.image.withRenderingMode(.alwaysTemplate), identifier: actionIdentifier) { [weak self] action in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.newsFeedViewController.changeFeed(type: .hashtag(hashtag))
                    self.switchToFeedController(self.newsFeedViewController, actionIdentifier: actionIdentifier)
                }
            }
            hashtagActions.append(menuItem)
        }
        let hashtagsMenu = UIMenu(title: "", options: [.displayInline], children: hashtagActions)
        return hashtagsMenu
    }
    
    
    private func listsMenu() -> UIMenu {
        var listActions: [UIAction] = []
                
        for list in ListManager.shared.allLists() {
            let actionIdentifier = UIAction.Identifier("List:\(list.id)")
            let menuItemL = UIAction(title: list.title, image: MAMenu.list.image.withRenderingMode(.alwaysTemplate), identifier: actionIdentifier) { [weak self] action in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.newsFeedViewController.changeFeed(type: .list(list))
                    self.switchToFeedController(self.newsFeedViewController, actionIdentifier: actionIdentifier)
                }
            }
            listActions.append(menuItemL)
        }
        // Sort the menu now that Top Friends is mixed in as well
        listActions = listActions.sorted(by: { action1, action2 in
            return action1.title <= action2.title
        })
        // Append "New List"
        let newListMenuItem = UIAction(title: MAMenu.newList.title, image: MAMenu.newList.image.withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] action in
            DispatchQueue.main.async {
                guard let self else { return }
                let vc = AltTextViewController()
                vc.newList = true
                self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
            }
        }
        listActions.append(newListMenuItem)
        let listActionsMenu = UIMenu(title: "", options: [.displayInline], children: listActions)
        return listActionsMenu
    }
        
    private func standardFeedsMenu() -> UIMenu {
        var standardActions: [UIAction] = []
        
        let followingActionIdentifier = UIAction.Identifier("Following")
        let followingMenuItem = UIAction(title: MAMenu.following.title, image: MAMenu.following.image.withRenderingMode(.alwaysTemplate), identifier: followingActionIdentifier) { [weak self] action in
            // Execute on next run loop so context menu closes smoothly
            DispatchQueue.main.async {
                guard let self else { return }
                self.newsFeedViewController.changeFeed(type: .following)
                self.switchToFeedController(self.newsFeedViewController, actionIdentifier: followingActionIdentifier)
            }
        }
        standardActions.append(followingMenuItem)

        let federatedActionIdentifier = UIAction.Identifier("Federated")
        let federatedMenuItem = UIAction(title: MAMenu.federated.title, image: MAMenu.federated.image.withRenderingMode(.alwaysTemplate), identifier: federatedActionIdentifier) { [weak self] action in
            // Execute on next run loop so context menu closes smoothly
            DispatchQueue.main.async {
                guard let self else { return }
                self.newsFeedViewController.changeFeed(type: .federated)
                self.switchToFeedController(self.newsFeedViewController, actionIdentifier: federatedActionIdentifier)
            }
        }
        standardActions.append(federatedMenuItem)

        let standardActionsMenu = UIMenu(title: "", options: [.displayInline], children: standardActions)
        return standardActionsMenu
    }
}

extension AuxFeedViewController {
    @objc func feedMenuItemsChanged() {
        feedMenuItems = []
        delegate?.didChangeFeedMenu(self.currentFeedController)
    }
}

// Navigation Bar Items
extension AuxFeedViewController {
    // Return additional navbar items for the current view controller
    func navBarItems() -> [UIBarButtonItem] {
        if currentFeedController == newsFeedViewController {
            return newsFeedViewController.navBarItems()
        }
        
        return []
    }
}

//MARK: NewsFeedViewControllerDelegate
extension AuxFeedViewController: NewsFeedViewControllerDelegate {
    func willChangeFeed(_ type: NewsFeedTypes) {}
    
    
    func userActivityStorageIdentifier() -> String {
        return "AuxFeedViewController.NewsFeedViewController.currentMenuItemIdentifier"
    }
    
    func didChangeFeed(_ type: NewsFeedTypes) {}
    
    func didScrollToTop() {}
    
    func isActiveFeed(_ type: NewsFeedTypes) -> Bool {
        if let currentFeed = currentFeedController as? NewsFeedViewController {
            return currentFeed.type == type
        }
        
        return false
    }
}

extension AuxFeedViewController: AppStateRestoration {
    public func storeUserActivity(in activity: NSUserActivity) {
        guard let userActivityStorage = self.delegate?.userActivityStorageIdentifier() else {
            log.error("expected a valid userActivityStorageIdentifier")
            return
        }
        activity.userInfo?[userActivityStorage] = currentMenuItemIdentifier
        log.debug("AuxFeedViewController:" + #function + " currentMenuItemIdentifier:\(String(describing: currentMenuItemIdentifier))")
        if let currentFeedController = currentFeedController as? AppStateRestoration {
            currentFeedController.storeUserActivity(in: activity)
            
            if let newsFeed = currentFeedController as? NewsFeedViewController {
                newsFeed.storeUserActivity(in: activity)
            }
        }
    }
    
    public func restoreUserActivity(from activity: NSUserActivity) {
        guard let userActivityStorage = self.delegate?.userActivityStorageIdentifier() else {
            log.error("expected a valid userActivityStorageIdentifier")
            return
        }
        if let menuItemIdentifier = activity.userInfo?[userActivityStorage] as? UIAction.Identifier {
            log.debug("AuxFeedViewController:" + #function + " menuItemIdentifier: \(menuItemIdentifier)")
            // Find the menu item with this identifier
            var matchingMenuItem: UIMenuElement? = nil
            for menu in feedMenu() {
                matchingMenuItem = menu.children.first(where: { menuElement in
                    let action = menuElement as? UIAction
                    let actionIdentifier = action?.identifier
                    return actionIdentifier == menuItemIdentifier
                })
                if matchingMenuItem != nil {
                    break
                }
            }
            // Select the matching menu item, if any
            if matchingMenuItem != nil {
                restoredActionIdentifier = menuItemIdentifier
                restoredViewController = viewControllerFromActionIdentifier(menuItemIdentifier)
            } else {
                log.warning(#function + " - no matching menu item")
            }

            // Switch to the view if this view has already loaded
            log.debug("AuxFeedViewController:" + #function + " menuItemIdentifier: \(menuItemIdentifier)")
            if restoredViewController != nil {
                self.switchToFeedController(restoredViewController!, actionIdentifier: menuItemIdentifier)
                
                if let newsFeed = restoredViewController as? NewsFeedViewController {
                    newsFeed.restoreUserActivity(from: activity)
                }
            }
        }
    }
}
