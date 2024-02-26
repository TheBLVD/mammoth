//
//  TabBarViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 26/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import WatchConnectivity
import AuthenticationServices
import AVKit
#if canImport(ActivityKit)
import ActivityKit
#endif

class TabBarViewController: AnimateTabController, UIGestureRecognizerDelegate, UIDropInteractionDelegate, ASWebAuthenticationPresentationContextProviding, ShareableViewController {
    
    let undoButton = UIButton()
    let newPostButton = NewPostButton()
    var newContent1 = UIView()
    var newContent2 = UIView()
    var customTabsBG = UIButton()
    var shadowLayer = UIView()
    var customTabsContainer = UIView()
    var customTabStartPosition: Int = 1
    var posX: Int = 0
    var customTabsCols: [UIColor] = [UIColor.systemBlue, UIColor.systemIndigo, UIColor.systemPurple, UIColor(red: 63/255, green: 180/255, blue: 78/255, alpha: 1), UIColor.systemOrange, UIColor.systemPink, UIColor(red: 245/255.0, green: 130/255.0, blue: 190/255.0, alpha: 1.000), UIColor(red: 252/255.0, green: 120/255.0, blue: 161/255.0, alpha: 1.000), UIColor.systemGray, UIColor.systemBlue, UIColor.systemIndigo, UIColor.systemPurple, UIColor(red: 63/255, green: 180/255, blue: 78/255, alpha: 1), UIColor.systemOrange, UIColor.systemPink, UIColor(red: 245/255.0, green: 130/255.0, blue: 190/255.0, alpha: 1.000), UIColor(red: 252/255.0, green: 120/255.0, blue: 161/255.0, alpha: 1.000)]
    var currentSwipeTag: Int = 0
    var fromSwitch: Bool = false
    var quickSwitcherImages: [UIImageView] = []
    let ind1 = UIImageView()
    let ind2 = UIImageView()
    let ind3 = UIImageView()
    let ind4 = UIImageView()
    let indActivity = UIImageView() // adds a small dot indicator under the activity tab when new activity comes in
    let indActivity2 = UIImageView() // adds a small dot indicator under the messages tab when new direct messages come in
    let counter = UIButton()
    var timer = Timer()
    
    var customTabsImagesUnselected2: [String] = ["heart.text.square", "bell", "tray.full", "binoculars", "heart", "bookmark", "line.3.horizontal.decrease.circle", "gear"]
    var customTabsImages2: [String] = ["heart.text.square.fill", "bell.fill", "tray.full.fill", "binoculars.fill", "heart.fill", "bookmark.fill", "line.horizontal.3.decrease.circle.fill", "gear"]
    var customTabsTitles2: [String] = ["Home", "Activity", "Messages", "Explore", "Likes", "Bookmarks", "Filters", "Settings"]
    var customTabsCols2: [UIColor] = [UIColor.systemBlue, UIColor.systemPurple, UIColor(red: 63/255, green: 180/255, blue: 78/255, alpha: 1), UIColor.systemBlue, UIColor.systemPink, UIColor.systemOrange, UIColor.systemIndigo, UIColor.systemGray]
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window!
    }
        
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.adjustIndicatorFrames()
        
        configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
        
        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }
    }
    
    func adjustIndicatorFrames() {
        var offsetX1: CGFloat = 28
        var offsetX2: CGFloat = 28
        var offsetX3: CGFloat = 28
        var offsetX4: CGFloat = 28
        if self.customTabsImagesUnselected2[GlobalStruct.tab1Index] == "tray.full" {
            offsetX1 = 32
        }
        if self.customTabsImagesUnselected2[GlobalStruct.tab2Index] == "tray.full" {
            offsetX2 = 32
        }
        if self.customTabsImagesUnselected2[GlobalStruct.tab3Index] == "tray.full" {
            offsetX3 = 32
        }
        if self.customTabsImagesUnselected2[GlobalStruct.tab4Index] == "tray.full" {
            offsetX4 = 32
        }
        let a1 = ((self.tabBar.bounds.width/5) * 1)
        let a2 = ((self.tabBar.bounds.width/5) * 2)
        let a3 = ((self.tabBar.bounds.width/5) * 3)
        let a4 = ((self.tabBar.bounds.width/5) * 4)
        let z = (self.tabBar.bounds.width/10)
        // location without tabbar titles showing
        ind1.frame = CGRect(x: a1 - z - offsetX1, y: 18, width: 12, height: 12)
        ind2.frame = CGRect(x: a2 - z - offsetX2, y: 18, width: 12, height: 12)
        ind3.frame = CGRect(x: a3 - z - offsetX3, y: 18, width: 12, height: 12)
        ind4.frame = CGRect(x: a4 - z - offsetX4, y: 18, width: 12, height: 12)
        indActivity.frame = CGRect(x: a3 - z - 3, y: 45, width: 6, height: 6)
        indActivity2.frame = CGRect(x: a4 - z - 3, y: 45, width: 6, height: 6)
    }
    
    @objc func gotoN() {
        let vc = NewPostViewController()
        vc.isModalInPresentation = true
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    @objc func goToActivityTab(notification: Notification) {
        self.selectedIndex = GlobalStruct.tab3Index
        
        if let activityVC = self.selectedViewController?.children.first as? ActivityViewController {
            activityVC.carouselItemPressed(withIndex: 0)
            activityVC.headerView.carousel.scrollTo(index: 0)
            
            // Delay required to finish the carousel animation smoothly first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                activityVC.jumpToNewest()
            }
            
            if let navController = self.selectedViewController as? UINavigationController {
                navController.popToRootViewController(animated: true)
            }
            
            // Navigate to the target post if there's one included in the notification
            if let postCard = notification.userInfo?["postCard"] as? PostCardModel {
                if !postCard.isDeleted && !postCard.isMuted && !postCard.isBlocked {
                    let vc = DetailViewController(post: postCard)
                    if vc.isBeingPresented {} else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            (self.selectedViewController as? UINavigationController)?.pushViewController(vc, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    @objc func goToMessagesTab(notification: Notification) {
        self.selectedIndex = GlobalStruct.tab4Index
        
        if let mentionsVC = self.selectedViewController?.children.first as? MentionsViewController {
            mentionsVC.carouselItemPressed(withIndex: 0)
            mentionsVC.headerView.carousel.scrollTo(index: 0)
            // Delay required to finish the carousel animation smoothly first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                mentionsVC.jumpToNewest()
            }
            
            if let navController = self.selectedViewController as? UINavigationController {
                navController.popToRootViewController(animated: true)
            }
            
            // Navigate to the target post if there's one included in the notification
            if let postCard = notification.userInfo?["postCard"] as? PostCardModel {
                if !postCard.isDeleted && !postCard.isMuted && !postCard.isBlocked {
                    let vc = DetailViewController(post: postCard)
                    if vc.isBeingPresented {} else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            (self.selectedViewController as? UINavigationController)?.pushViewController(vc, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    @objc func gotoS() {
        self.selectedIndex = 0
    }
    
    @objc func showNewContent1() {
        //        self.newContent1.alpha = 1
    }
    
    @objc func hideNewContent1() {
        self.newContent1.alpha = 0
    }
    
    @objc func showNewContent2() {
        //        self.newContent2.alpha = 1
    }
    
    @objc func hideNewContent2() {
        self.newContent2.alpha = 0
    }
    
    @objc func showComposer() {
        // show composer
        let vc = NewPostViewController()
        vc.isModalInPresentation = true
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "restoreFromTemplate"), object: nil)
        }
    }
    
    @objc func gotoH() {
        self.selectedIndex = 0
        NotificationCenter.default.post(name: Notification.Name(rawValue: "switchS1"), object: nil)
    }
    
    @objc func gotoC() {
        self.selectedIndex = 0
        NotificationCenter.default.post(name: Notification.Name(rawValue: "switchS2"), object: nil)
    }
    
    @objc func gotoE() {
        self.selectedIndex = 0
        NotificationCenter.default.post(name: Notification.Name(rawValue: "switchS3"), object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .custom.background
                
        if #available(iOS 16.0, *) {
            customTabsImagesUnselected2 = ["heart.text.square", "bell", "tray.full", "binoculars", "heart", "bookmark", "line.3.horizontal.decrease.circle", "gear.circle"]
            customTabsImages2 = ["heart.text.square.fill", "bell.fill", "tray.full.fill", "binoculars.fill", "heart.fill", "bookmark.fill", "line.horizontal.3.decrease.circle.fill", "gear.circle.fill"]
        }
        
        let dropInteraction = UIDropInteraction(delegate: self)
        self.view.addInteraction(dropInteraction)

        NotificationCenter.default.addObserver(self, selector: #selector(self.gotoH), name: NSNotification.Name(rawValue: "gotoH"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.gotoC), name: NSNotification.Name(rawValue: "gotoC"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.gotoE), name: NSNotification.Name(rawValue: "gotoE"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.goToActivityTab), name: NSNotification.Name(rawValue: "goToActivityTab"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.goToMessagesTab), name: NSNotification.Name(rawValue: "goToMessagesTab"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.startTimer), name: NSNotification.Name(rawValue: "startTimer"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.stopTimer), name: NSNotification.Name(rawValue: "stopTimer"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.showIndActivity), name: NSNotification.Name(rawValue: "showIndActivity"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideIndActivity), name: NSNotification.Name(rawValue: "hideIndActivity"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.showIndActivity2), name: NSNotification.Name(rawValue: "showIndActivity2"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideIndActivity2), name: NSNotification.Name(rawValue: "hideIndActivity2"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchDataFromSettings), name: NSNotification.Name(rawValue: "fetchDataFromSettings"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.undoTapped), name: NSNotification.Name(rawValue: "undoTapped"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.setFromSwitch), name: NSNotification.Name(rawValue: "setFromSwitch"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchCurrentUserData), name: NSNotification.Name(rawValue: "fetchUserData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.gotoN), name: NSNotification.Name(rawValue: "gotoN"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.gotoS), name: NSNotification.Name(rawValue: "gotoS"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.showNewContent1), name: NSNotification.Name(rawValue: "showNewContent1"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideNewContent1), name: NSNotification.Name(rawValue: "hideNewContent1"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.showNewContent2), name: NSNotification.Name(rawValue: "showNewContent2"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideNewContent2), name: NSNotification.Name(rawValue: "hideNewContent2"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchPost0), name: NSNotification.Name(rawValue: "fetchPost"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchUser0), name: NSNotification.Name(rawValue: "fetchUser"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.restoreFromDrafts2), name: NSNotification.Name(rawValue: "restoreFromDrafts2"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.showComposer), name: NSNotification.Name(rawValue: "showComposer"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.cleanupTabBar), name: NSNotification.Name(rawValue: "cleanupTabBar"), object: nil)
        subscribeToShareNotifications()

        // set up views
        setupViews()
    }
    
    @objc func restoreFromDrafts2() {
        let vc = NewPostViewController()
        vc.isModalInPresentation = true
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "restoreFromDrafts"), object: nil)
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
        
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        var dropProposal = UITableViewDropProposal(operation: .cancel)
        guard session.items.count == 1 else { return dropProposal }
        dropProposal = UITableViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
        return dropProposal
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        session.loadObjects(ofClass: NSString.self) { items in
            let stringItems = items as! [String]
            if let x = stringItems.first {
                let split = x.split(separator: "/")
                if (!x.contains("twitter.com")) && (split.count - 1 > 0) {
                    let lastSplit = split[split.count - 1]
                    if CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: "\(lastSplit)")) {
                        if split.count - 2 > 0 {
                            let secondLast = split[split.count - 2]
                            if "\(secondLast)".first == "@" {
                                // go to post
                                DispatchQueue.main.async {
                                    let request = Search.search(query: x, resolve: true)
                                    AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
                                        if let error = statuses.error {
                                            log.error("Failed to search: \(error)")
                                            DispatchQueue.main.async {
                                                PostActions.openLinks2(x)
                                            }
                                        }
                                        if let stat = (statuses.value) {
                                            DispatchQueue.main.async {
                                                if let x = stat.statuses.first {
                                                    let vc = DetailViewController(post: PostCardModel(status: x))
                                                    UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        let last = split[split.count - 1]
                        if "\(last)".first == "@" {
                            // go to user
                            let request = Search.search(query: x, resolve: true)
                            AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
                                if let error = statuses.error {
                                    log.error("Failed to search: \(error)")
                                    DispatchQueue.main.async {
                                        PostActions.openLinks2(x)
                                    }
                                }
                                if let stat = (statuses.value) {
                                    DispatchQueue.main.async {
                                        if let account = stat.accounts.first {
                                            let vc = ProfileViewController(user: UserCardModel(account: account), screenType: .others)
                                            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func fetchPost0() {
        self.fetchPost(GlobalStruct.schemeId)
    }
    
    func fetchPost(_ id: String) {
        
    }
    
    func fetchPost2(_ id: String) {
        
    }
    
    @objc func fetchUser0() {
        self.fetchUser(GlobalStruct.schemeProfileName)
    }
    
    func fetchUser(_ id: String) {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if ToastNotificationManager.shared == nil {
            ToastNotificationManager.shared = ToastNotificationManager(hostWindow: self.view.window!)
        }

        newPostButton.delegate = self
        newPostButton.installInView(self.view, additionalBottomOffset:self.tabBar.bounds.height)
        
        // set up new content indicator
        setupNewContentIndicators()
        
        self.startTimer()
                
        // Show sign in view if appropriate
        if AccountsManager.shared.allAccounts.isEmpty {
            NotificationCenter.default.post(name: shouldChangeRootViewController, object: nil)
        }
    }
    
    @objc func stopTimer() {
        GlobalStruct.timer1.invalidate()
    }
    
    @objc func startTimer() {
        if AccountsManager.shared.allAccounts.count > 0 {
            // auto-update feed
            // changing to 4 seconds as there are 4 endpoint calls happening with each timer fire
            // 300 calls allowed every 5 minutes = 1 call per second
            GlobalStruct.timer1.invalidate()
            GlobalStruct.timer1 = Timer(timeInterval: 7.0, target: self, selector: #selector(self.fireTimerAllFeeds), userInfo: [], repeats: true)
            RunLoop.current.add(GlobalStruct.timer1, forMode: .common)
        }
    }
    
    @objc func fireTimerAllFeeds(timer: Timer) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "fireTimerFeed"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "fireTimerActivity"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "fireTimerOther"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "fireTimerMessages"), object: nil)
    }
    
    func setupNewContentIndicators() {
        self.newContent1.removeFromSuperview()
        self.newContent1.frame = CGRect(x: self.tabBar.bounds.width/10 - 4, y: self.tabBar.bounds.height - 40, width: 8, height: 8)
        self.newContent1.backgroundColor = .custom.baseTint
        self.newContent1.layer.cornerRadius = 4
        self.newContent1.alpha = 0
        self.tabBar.addSubview(self.newContent1)
        
        self.newContent2.removeFromSuperview()
        self.newContent2.frame = CGRect(x: ((self.tabBar.bounds.width/10)*2) - 4, y: self.tabBar.bounds.height - 40, width: 8, height: 8)
        self.newContent2.backgroundColor = .custom.baseTint
        self.newContent2.layer.cornerRadius = 4
        self.newContent2.alpha = 0
        self.view.addSubview(self.newContent2)
    }
    
    private func fillPath(for percent: Double) -> CGPath {
        let height = self.view.bounds.height * CGFloat(percent)
        let rect = CGRect(x: 0, y: height, width: self.view.bounds.width, height: self.view.bounds.height - height)
        return UIBezierPath(rect: rect).cgPath
    }
    
    @objc func fetchCurrentUserData() {
        self.fetchData()
    }
    
    @objc func fireTimer(timer: Timer) {
        var count = (Int(self.counter.titleLabel?.text ?? "1") ?? 1) - 1
        if count < 0 {
            count = 0
        }
        self.counter.setTitle("\(count)", for: .normal)
    }
    
    @objc func undoTapped() {
        triggerHapticImpact(style: .light)
        self.timer.invalidate()
        GlobalStruct.canPostPost = false
        UIView.animate(withDuration: 1.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.16, options: [.curveEaseInOut]) {
            self.undoButton.frame = CGRect(x: self.view.bounds.width/2 - 83, y: self.view.bounds.height + 80, width: 166, height: 40)
        } completion: { x in
            self.undoButton.removeFromSuperview()
            GlobalStruct.currentlyPosting = false
        }
    }
    
    @objc func setupViews() {
        let home = NSLocalizedString("navigator.home", comment: "Bottom navigator title.")
        let v1 = HomeViewController()
        let vc1 = UINavigationController(rootViewController: v1)
        vc1.tabBarItem = UITabBarItem(title: home, image: FontAwesome.image(fromChar: "\u{f015}", size: 15, weight: .bold), selectedImage: FontAwesome.image(fromChar: "\u{f015}", weight: .bold))
        vc1.accessibilityLabel = home
        vc1.tabBarItem.tag = 0
        
        let discover = NSLocalizedString("navigator.discover", comment: "Bottom navigator title.")
        let v2 = SearchHostViewController()
        let vc2 = UINavigationController(rootViewController: v2)
        vc2.tabBarItem = UITabBarItem(title: discover, image: FontAwesome.image(fromChar: "\u{f002}", size: 15, weight: .bold), selectedImage: FontAwesome.image(fromChar: "\u{f002}", weight: .bold))
        vc2.accessibilityLabel = discover
        vc2.tabBarItem.tag = 1
        
        let activity = NSLocalizedString("navigator.activity", comment: "Bottom navigator title.")
        let v3 = ActivityViewController()
        let vc3 = UINavigationController(rootViewController: v3)
        vc3.tabBarItem = UITabBarItem(title: activity, image: FontAwesome.image(fromChar: "\u{f0f3}", size: 15, weight: .bold), selectedImage: FontAwesome.image(fromChar: "\u{f0f3}", weight: .bold))
        vc3.accessibilityLabel = activity
        vc3.tabBarItem.tag = 2
        
        let mentions = NSLocalizedString("navigator.mentions", comment: "Bottom navigator title.")
        let v4 = MentionsViewController()
        let vc4 = UINavigationController(rootViewController: v4)
        vc4.tabBarItem = UITabBarItem(title: mentions, image: FontAwesome.image(fromChar: "\u{40}", size: 15, weight: .bold), selectedImage: FontAwesome.image(fromChar: "\u{40}", weight: .bold))
        vc4.accessibilityLabel = mentions
        vc4.tabBarItem.tag = 3
        
        var userCardModel: UserCardModel? = nil
        let currentAccount = AccountsManager.shared.currentAccount
        if let mastodonAccount = (currentAccount as? MastodonAcctData)?.account {
            userCardModel = UserCardModel(account: mastodonAccount)
        }
        let newProfileVC = ProfileViewController(user: userCardModel)
        let v5: UIViewController = newProfileVC
        
        let profile = NSLocalizedString("navigator.profile", comment: "Bottom navigator title.")
        let vc5 = UINavigationController(rootViewController: v5)
        vc5.tabBarItem = UITabBarItem(title: profile, image: FontAwesome.image(fromChar: "\u{f007}", size: 15, weight: .bold), selectedImage: FontAwesome.image(fromChar: "\u{f007}", weight: .bold))
        vc5.accessibilityLabel = profile
        vc5.tabBarItem.tag = 4
        
        let vcs: [UIViewController] = [vc1, vc2, vc3, vc4, vc5]
        self.setViewControllers(vcs, animated: false)
        
        self.cleanupTabBar()
        
        indActivity.isHidden = true
        indActivity.layer.cornerRadius = 3
        indActivity.backgroundColor = .custom.baseTint
        self.tabBar.addSubview(indActivity)
        
        indActivity2.isHidden = true
        indActivity2.layer.cornerRadius = 3
        indActivity2.backgroundColor = .custom.baseTint
        self.tabBar.addSubview(indActivity2)
    }
    
    private func isOnTab(vcType: AnyClass) -> Bool {
        var containsSpecificView = false
        let navController = self.viewControllers?[self.selectedIndex]
        if let vcStack = (navController as? UINavigationController)?.viewControllers {
            containsSpecificView = vcStack.contains(where: { vc in
                type(of: vc) == vcType
            })
        }
        return containsSpecificView
    }
    
    private func isOnDiscoverTab() -> Bool {
        return isOnTab(vcType: SearchHostViewController.self)
    }

    private func isOnMessagesTab() -> Bool {
        return isOnTab(vcType: MentionsViewController.self)
    }
    
    @objc func hideIndActivity() {
        self.hideActivityUnreadIndicator()
    }
    
    @objc func showIndActivity() {
        self.showActivityUnreadIndicator()
    }
    
    @objc func hideIndActivity2() {
        self.hideMessagesUnreadIndicator()
    }
    
    @objc func showIndActivity2() {
        self.showMessagesUnreadIndicator()
    }
    
    @objc func cleanupTabBar() {

//        self.updateTabTitles()
        
        self.tabBar.items![0].imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        self.tabBar.items![1].imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        self.tabBar.items![2].imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        self.tabBar.items![3].imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        self.tabBar.items![4].imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
    }
    
    @objc func fetchDataFromSettings() {
        self.fetchData(true)
    }
    
    func fetchData(_ fromSwitch: Bool = false) {
        
    }
    
    @objc func setFromSwitch() {
        self.fromSwitch = true
    }
    
    func fetchUserData() {
        
    }
    
    override func barItemTap(_ sender: Any) {
        super.barItemTap(sender)
        
        newPostButton.updateNewPostButtonImage()
        self.storeSelectedIndex()
    }
}


@objc protocol JumpToNewest {
    @objc func jumpToNewest()
}

// Handles animation and JumpToNewest
class AnimateTabController: AnimatedTabBarController, Jumpable {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func barItemTap(_ sender: Any) {
        super.barItemTap(sender)
        
        guard let animatedTabBarItem = sender as? AnimatedTabBarItem else {
            log.error("unexpected type")
            return
        }
        if let itemIndex = self.animatedTabBar.indexOfTabBarItem(animatedTabBarItem) {
            if let navController = self.viewControllers?[itemIndex] as? UINavigationController, itemIndex == previousTappedIndex {
                navController.popToRootViewController(animated: true)
            }
            
            if itemIndex == previousTappedIndex {
                let tabBarItem = self.animatedTabBar.tabBarItems[itemIndex]
                let timeInterval: TimeInterval = 0.3
                let propertyAnimator = UIViewPropertyAnimator(duration: timeInterval, dampingRatio: 0.65) {
                    tabBarItem.transform = CGAffineTransform.identity.scaledBy(x: 1.14, y: 1.14)
                }
                propertyAnimator.addAnimations({ tabBarItem.transform = .identity }, delayFactor: CGFloat(timeInterval))
                propertyAnimator.startAnimation()
            }
            
            self.controlBar(didSelect: itemIndex)
        }
    }
}

extension AnimateTabController {
            
    func viewControllerAtIndex(_ index: Int) -> UIViewController? {
        let navController = self.viewControllers?[index]
        let currentViewController = (navController as? UINavigationController)?.viewControllers.first
        return currentViewController
    }

    func barSingleTap(didSelect index: Int) {}
}

// MARK - State restoration
extension AnimateTabController {
    
    func storeSelectedIndex() {
        UserDefaults.standard.set(self.selectedIndex, forKey: "AnimateTabController selectedIndex")
    }
    
    func restoreSelectedIndex() {
        self.selectedIndex = UserDefaults.standard.value(forKey: "AnimateTabController selectedIndex") as? Int ?? 0
    }
    
}

extension TabBarViewController: AppStateRestoration {
    
    public func storeUserActivity(in activity: NSUserActivity) {
        log.debug("ViewController:" + #function)
        activity.userInfo?["ViewController.selectedIndex"] = self.selectedIndex
        // Allow current selected view controller to store info if wanted
        let navController = self.viewControllers?[self.selectedIndex]
        if let currentViewController = (navController as? UINavigationController)?.viewControllers.first as? AppStateRestoration {
            currentViewController.storeUserActivity(in: activity)
        }
    }
    
    public func restoreUserActivity(from activity: NSUserActivity) {
        log.debug("TabBarViewController:" + #function)
        if let selectedIndex = activity.userInfo?["ViewController.selectedIndex"] as? Int {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self.selectedIndex = selectedIndex
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self.selectedIndex = 0
            }
        }
        log.debug("TabBarViewController:" + #function + " selectedIndex:\(selectedIndex)")
        // Allow current selected view controller to store info if wanted
        let navController = self.viewControllers?[self.selectedIndex]
        if let currentViewController = (navController as? UINavigationController)?.viewControllers.first as? AppStateRestoration {
            currentViewController.restoreUserActivity(from: activity)
        }
    }
        
}

extension TabBarViewController: NewPostButtonDelegate {

    func newPostTypeForCurrentViewController() -> NewPostType {
        if self.isOnMessagesTab() {
            return .newMessage
        } else {
            return .newPost
        }
    }
    
    func shouldShowNewPostButton() -> Bool {
        return !self.isOnDiscoverTab()
    }
    
}

// MARK: Appearance changes
internal extension TabBarViewController {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 self.view.backgroundColor = .custom.background
                 self.newContent1.backgroundColor = .custom.baseTint
                 self.newContent2.backgroundColor = .custom.baseTint
                 self.indActivity.backgroundColor = .custom.baseTint
                 self.indActivity2.backgroundColor = .custom.baseTint
             }
         }
    }
}
