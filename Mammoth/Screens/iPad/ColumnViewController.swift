//
//  ColumnViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 29/04/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class ColumnViewController: UIViewController {
    
    public static var shared = ColumnViewController()
    
    var doneOnceLayout: Bool = false
    var hasRotated: Bool = false
    
    let firstViewWidth = 87.0
    let auxColumnWidthRatio = (1.0 / 1.61803) // Use the golden ratio
    let verticalMargin = 25.0
    let horizontalGap = 20.0
    
    let newPostButton = NewPostButton()

    private var sidebarNavVC: UINavigationController? = nil
    private var sidebarViewController = SidebarViewController.shared

    // The main (left) column
    private var mainColumnNavVC: UINavigationController? = nil
    private var mainColumnPlaceholderView = ExtendedTouchView()
    // The auxilary (right) column
    private var auxColumnNavVC: UINavigationController? = nil
    private var auxColumnPlaceholderView = UIView()

    // Constraints to deal with rotation
    private var auxColumnWidthConstraintGolden: NSLayoutConstraint? = nil
    private var auxColumnWidthConstraintZero: NSLayoutConstraint? = nil
    private var auxGapWidthConstraint: NSLayoutConstraint? = nil

    private var mainVCList: [UINavigationController] = []
    
    required init() {
        super.init(nibName: nil, bundle: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.goToActivityTab), name: NSNotification.Name(rawValue: "goToActivityTab"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.goToMessagesTab), name: NSNotification.Name(rawValue: "goToMessagesTab"), object: nil)
    }
    
    private func setupUI() {
        
        // List of UINavigationController that can populate the main column
        mainVCList.append(UINavigationController(rootViewController: HomeViewController()))
        mainVCList.append(UINavigationController(rootViewController: SearchHostViewController()))
        mainVCList.append(UINavigationController(rootViewController: ActivityViewController()))
        mainVCList.append(UINavigationController(rootViewController: MentionsViewController()))
        mainVCList.append(UINavigationController(rootViewController: ProfileViewController(acctData: AccountsManager.shared.currentAccount)))
        
        // Lefthand view with buttons
        sidebarViewController.delegate = self
        sidebarNavVC = UINavigationController(rootViewController: sidebarViewController)
        sidebarNavVC!.view.translatesAutoresizingMaskIntoConstraints = false
        self.addChild(sidebarNavVC!)
        self.view.addSubview(sidebarNavVC!.view)
        
        // Since sidebarViewController is a singleton, make sure
        // it has the correct icon selected.
        sidebarViewController.reset()
        
        // Main column view
        mainColumnPlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(mainColumnPlaceholderView)

        // Side column view
        auxColumnPlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(auxColumnPlaceholderView)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func installInMainColumn(_ navController: UINavigationController) {
        if navController != mainColumnNavVC {
            let previousMainColumnVC = mainColumnNavVC
            mainColumnNavVC = navController
            
            navController.view.translatesAutoresizingMaskIntoConstraints = false
            navController.view.layer.cornerRadius = 10
            navController.view.layer.borderWidth = 0.6
            navController.view.layer.borderColor = UIColor.custom.outlines.cgColor
            self.addChild(navController)
            self.mainColumnPlaceholderView.addSubview(navController.view)
            self.mainColumnPlaceholderView.addConstraints( [
                navController.view.leadingAnchor.constraint(equalTo: self.mainColumnPlaceholderView.leadingAnchor),
                navController.view.trailingAnchor.constraint(equalTo: self.mainColumnPlaceholderView.trailingAnchor),
                navController.view.topAnchor.constraint(equalTo: self.mainColumnPlaceholderView.topAnchor),
                navController.view.bottomAnchor.constraint(equalTo: self.mainColumnPlaceholderView.bottomAnchor)
            ])
            
            previousMainColumnVC?.willMove(toParent: nil)
            previousMainColumnVC?.view.removeFromSuperview()
            previousMainColumnVC?.removeFromParent()
        }
    }
    
    private func installInAuxColumn(_ navController: UINavigationController) {
        if navController != auxColumnNavVC {
            let previousAuxColumnVC = auxColumnNavVC
            auxColumnNavVC = navController
            
            navController.view.translatesAutoresizingMaskIntoConstraints = false
            navController.view.layer.cornerRadius = 10
            navController.view.layer.borderWidth = 0.6
            navController.view.layer.borderColor = UIColor.custom.outlines.cgColor
            self.addChild(navController)
            self.auxColumnPlaceholderView.addSubview(navController.view)
            self.auxColumnPlaceholderView.addConstraints( [
                navController.view.leadingAnchor.constraint(equalTo: self.auxColumnPlaceholderView.leadingAnchor),
                navController.view.trailingAnchor.constraint(equalTo: self.auxColumnPlaceholderView.trailingAnchor),
                navController.view.topAnchor.constraint(equalTo: self.auxColumnPlaceholderView.topAnchor),
                navController.view.bottomAnchor.constraint(equalTo: self.auxColumnPlaceholderView.bottomAnchor)
            ])
            
            previousAuxColumnVC?.willMove(toParent: nil)
            previousAuxColumnVC?.view.removeFromSuperview()
            previousAuxColumnVC?.removeFromParent()
        }
    }
    
    @objc func goToActivityTab(notification: Notification) {
        self.sidebarViewController.barSingleTap(didSelect: 2)
        
        if let activityVC = self.mainColumnNavVC?.children.first as? ActivityViewController {
            activityVC.carouselItemPressed(withIndex: 0)
            activityVC.headerView.carousel.scrollTo(index: 0)
            
            // Delay required to finish the carousel animation smoothly first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                activityVC.jumpToNewest()
            }
            
            if let navController = self.mainColumnNavVC {
                navController.popToRootViewController(animated: true)
            }
            
            // Navigate to the target post if there's one included in the notification
            if let postCard = notification.userInfo?["postCard"] as? PostCardModel {
                if !postCard.isDeleted && !postCard.isMuted && !postCard.isBlocked {
                    let vc = DetailViewController(post: postCard)
                    if vc.isBeingPresented {} else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.mainColumnNavVC?.pushViewController(vc, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    @objc func goToMessagesTab(notification: Notification) {
        self.sidebarViewController.barSingleTap(didSelect: 3)
        
        if let mentionsVC = self.mainColumnNavVC?.children.first as? MentionsViewController {
            mentionsVC.carouselItemPressed(withIndex: 0)
            mentionsVC.headerView.carousel.scrollTo(index: 0)
            // Delay required to finish the carousel animation smoothly first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                mentionsVC.jumpToNewest()
            }
            
            if let navController = self.mainColumnNavVC {
                navController.popToRootViewController(animated: true)
            }
            
            // Navigate to the target post if there's one included in the notification
            if let postCard = notification.userInfo?["postCard"] as? PostCardModel {
                if !postCard.isDeleted && !postCard.isMuted && !postCard.isBlocked {
                    let vc = DetailViewController(post: postCard)
                    if vc.isBeingPresented {} else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.mainColumnNavVC?.pushViewController(vc, animated: true)
                        }
                    }
                }
            }
        }
    }

    
    @objc func switchSidebar1() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "gotoItem1"), object: self)
    }
    
    @objc func switchSidebar2() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "gotoItem2"), object: self)
    }
    
    @objc func switchSidebar3() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "gotoM"), object: self)
    }
    
    @objc func switchSidebar4() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "gotoP"), object: self)
    }
    
    @objc func switchSidebar5() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "goto1B"), object: self)
    }
    
    @objc func switchSidebar6() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "goto1M"), object: self)
    }
    
    @objc func switchSidebar66() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "goto1MS"), object: self)
    }
    
    @objc func switchSidebar7() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "goto1E"), object: self)
    }
    
    @objc func switchSidebar8() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "goto1U"), object: self)
    }
    
    @objc func switchSidebar9() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "goto1L"), object: self)
    }
    
    @objc func switchSidebar0() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "goto2M"), object: self)
    }
    
    @objc func switchSidebarSea() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "gotoFil"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        newPostButton.delegate = self
        newPostButton.allowsExtremeLeft = true
        newPostButton.installInView(self.mainColumnPlaceholderView)
        newPostButton.addInteraction(UIPointerInteraction(delegate: nil))
        
        // Show sign in view if appropriate
        if AccountsManager.shared.allAccounts.isEmpty {
            NotificationCenter.default.post(name: shouldChangeRootViewController, object: nil)
        }
    }
    
    override func viewDidLayoutSubviews() {
        if self.doneOnceLayout == false {
            self.doneOnceLayout = true
            
            self.view.addConstraints( [
                sidebarNavVC!.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                sidebarNavVC!.view.topAnchor.constraint(equalTo: self.view.topAnchor, constant: verticalMargin),
                sidebarNavVC!.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -verticalMargin),
                sidebarNavVC!.view.widthAnchor.constraint(equalToConstant: firstViewWidth)
            ])
            // Main column view
            auxGapWidthConstraint = mainColumnPlaceholderView.trailingAnchor.constraint(equalTo: auxColumnPlaceholderView.leadingAnchor, constant: -horizontalGap)
            self.view.addConstraints( [
                mainColumnPlaceholderView.leadingAnchor.constraint(equalTo: sidebarNavVC!.view.trailingAnchor),
                mainColumnPlaceholderView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: verticalMargin),
                mainColumnPlaceholderView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -verticalMargin),
                auxGapWidthConstraint!
            ])
            // Side column view
            auxColumnWidthConstraintGolden = auxColumnPlaceholderView.widthAnchor.constraint(equalTo: mainColumnPlaceholderView.widthAnchor, multiplier: auxColumnWidthRatio)
            auxColumnWidthConstraintZero = auxColumnPlaceholderView.widthAnchor.constraint(equalToConstant: 0)

            self.view.addConstraints( [
                auxColumnPlaceholderView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: verticalMargin),
                auxColumnPlaceholderView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -verticalMargin),
                auxColumnPlaceholderView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -horizontalGap),
            ])
        }

        // Adjust widths based on landscape/portrait
        let isPortrait = self.view.bounds.height > self.view.bounds.width
        // Use one of the aux column width constraints
        auxColumnWidthConstraintGolden?.isActive = !isPortrait
        auxColumnWidthConstraintZero?.isActive = isPortrait
        auxGapWidthConstraint?.constant = isPortrait ? 0.0 : -horizontalGap

        super.viewDidLayoutSubviews()
        
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        self.navigationController?.navigationBar.standardAppearance = navApp
        self.navigationController?.navigationBar.scrollEdgeAppearance = navApp
        self.navigationController?.navigationBar.compactAppearance = navApp
        if #available(iOS 15.0, *) {
            self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
        }
        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.hasRotated = true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        let newPost = UIKeyCommand(input: "n", modifierFlags: [.command], action: #selector(newPost))
        newPost.discoverabilityTitle = "New Post"
        if #available(iOS 15, *) {
            newPost.wantsPriorityOverSystemBehavior = true
        }
        let newMessage = UIKeyCommand(input: "n", modifierFlags: [.command, .shift], action: #selector(newMessage))
        newMessage.discoverabilityTitle = "New Message"
        if #available(iOS 15, *) {
            newMessage.wantsPriorityOverSystemBehavior = true
        }
        let goTo1 = UIKeyCommand(input: "1", modifierFlags: .command, action: #selector(scrollTo1))
        goTo1.discoverabilityTitle = "Feed"
        if #available(iOS 15, *) {
            goTo1.wantsPriorityOverSystemBehavior = true
        }
        let goTo2 = UIKeyCommand(input: "2", modifierFlags: .command, action: #selector(scrollTo2))
        goTo2.discoverabilityTitle = "Activity"
        if #available(iOS 15, *) {
            goTo2.wantsPriorityOverSystemBehavior = true
        }
        let goTo3 = UIKeyCommand(input: "3", modifierFlags: .command, action: #selector(scrollTo3))
        goTo3.discoverabilityTitle = "Messages"
        if #available(iOS 15, *) {
            goTo3.wantsPriorityOverSystemBehavior = true
        }
        let goTo4 = UIKeyCommand(input: "4", modifierFlags: .command, action: #selector(scrollTo4))
        goTo4.discoverabilityTitle = "Explore"
        if #available(iOS 15, *) {
            goTo4.wantsPriorityOverSystemBehavior = true
        }
        let goTo5 = UIKeyCommand(input: "5", modifierFlags: .command, action: #selector(scrollTo5))
        goTo5.discoverabilityTitle = NSLocalizedString("navigator.profile", comment: "")
        if #available(iOS 15, *) {
            goTo5.wantsPriorityOverSystemBehavior = true
        }
        let goTo6 = UIKeyCommand(input: "6", modifierFlags: .command, action: #selector(scrollTo6))
        goTo6.discoverabilityTitle = NSLocalizedString("title.likes", comment: "")
        if #available(iOS 15, *) {
            goTo6.wantsPriorityOverSystemBehavior = true
        }
        let goTo7 = UIKeyCommand(input: "7", modifierFlags: .command, action: #selector(scrollTo7))
        goTo7.discoverabilityTitle = "Bookmarks"
        if #available(iOS 15, *) {
            goTo7.wantsPriorityOverSystemBehavior = true
        }
        let goTo8 = UIKeyCommand(input: "8", modifierFlags: .command, action: #selector(scrollTo8))
        goTo8.discoverabilityTitle = NSLocalizedString("profile.filters", comment: "")
        if #available(iOS 15, *) {
            goTo8.wantsPriorityOverSystemBehavior = true
        }
        let search = UIKeyCommand(input: "f", modifierFlags: .command, action: #selector(scrollTo9))
        search.discoverabilityTitle = "Search"
        if #available(iOS 15, *) {
            search.wantsPriorityOverSystemBehavior = true
        }
        let settings = UIKeyCommand(input: ",", modifierFlags: .command, action: #selector(settingsTap))
        settings.discoverabilityTitle = "Settings"
        if #available(iOS 15, *) {
            settings.wantsPriorityOverSystemBehavior = true
        }
        return [newPost, newMessage, goTo1, goTo2, goTo3, goTo4, goTo5, goTo6, goTo7, search, settings]
    }
    
    @objc func newPost() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "newPost"), object: nil)
    }
    
    @objc func newMessage() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "newMessage"), object: nil)
    }
    
    @objc func scrollTo1() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 0
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }
    
    @objc func scrollTo2() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 1
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }
    
    @objc func scrollTo3() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 2
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }
    
    @objc func scrollTo4() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 3
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }
    
    @objc func scrollTo5() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 4
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }
    
    @objc func scrollTo6() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 5
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }
    
    @objc func scrollTo7() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 6
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }
    
    @objc func scrollTo8() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 7
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }
    
    @objc func scrollTo9() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 8
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }
    
    @objc func searchTap() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "searchTap"), object: nil)
        GlobalStruct.sidebarItem = 9
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }
    
    @objc func settingsTap() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "settingsTap"), object: nil)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        installInMainColumn(mainVCList[0])
        installInAuxColumn(UINavigationController(rootViewController: AuxColumnViewController()))

        self.view.backgroundColor = .custom.backgroundTint
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
    }
    
    @objc func reloadAll() {
        DispatchQueue.main.async {
            self.view.backgroundColor = .custom.backgroundTint
            let navApp = UINavigationBarAppearance()
            navApp.configureWithOpaqueBackground()
            navApp.backgroundColor = .custom.backgroundTint
            navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]

            self.mainColumnNavVC?.navigationBar.standardAppearance = navApp
            self.mainColumnNavVC?.navigationBar.scrollEdgeAppearance = navApp
            self.mainColumnNavVC?.navigationBar.compactAppearance = navApp

            self.auxColumnNavVC?.navigationBar.standardAppearance = navApp
            self.auxColumnNavVC?.navigationBar.scrollEdgeAppearance = navApp
            self.auxColumnNavVC?.navigationBar.compactAppearance = navApp

            self.mainColumnNavVC?.view.layer.borderColor = UIColor.custom.outlines.cgColor
            self.mainColumnNavVC?.navigationBar.backgroundColor = .custom.backgroundTint
            self.mainColumnNavVC?.view.layer.borderColor = UIColor.custom.outlines.cgColor
            self.auxColumnNavVC?.view.layer.borderColor = UIColor.custom.outlines.cgColor
            self.auxColumnNavVC?.navigationBar.backgroundColor = .custom.backgroundTint
            self.auxColumnNavVC?.view.layer.borderColor = UIColor.custom.outlines.cgColor
        }
    }
}

// MARK: Appearance changes
internal extension ColumnViewController {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 self.reloadAll()
             }
         }
    }
}

extension ColumnViewController: SidebarViewControllerDelegate {

    func didSelect(_ index: Int) {
        installInMainColumn(mainVCList[index])
        newPostButton.updateNewPostButtonImage()
        newPostButton.superview?.bringSubviewToFront(newPostButton)
    }
    
    func viewControllerAtIndex(_ index: Int) -> UIViewController? {
        guard index < mainVCList.count else {
            log.error("unexpected double-tap index")
            return nil
        }
        return mainVCList[index].viewControllers.first
    }

}

extension ColumnViewController: AppStateRestoration {
    
    public func storeUserActivity(in activity: NSUserActivity) {
        log.debug("ColumnViewController:" + #function)
        // Allow subviews to store their data, if any
        sidebarViewController.storeUserActivity(in: activity)
        
        if let mainColumnVC = mainColumnNavVC?.topViewController as? AppStateRestoration {
            mainColumnVC.storeUserActivity(in: activity)
        }
        if let auxColumnVC = auxColumnNavVC?.topViewController as? AppStateRestoration {
            auxColumnVC.storeUserActivity(in: activity)
        }
    }
    
    public func restoreUserActivity(from activity: NSUserActivity) {
        log.debug("ColumnViewController:" + #function)
        // Allow subviews to restore their data, if any
        sidebarViewController.restoreUserActivity(from: activity)
        if let mainColumnVC = mainColumnNavVC?.topViewController as? AppStateRestoration {
            mainColumnVC.restoreUserActivity(from: activity)
        }
        if let auxColumnVC = auxColumnNavVC?.topViewController as? AppStateRestoration {
            auxColumnVC.restoreUserActivity(from: activity)
        }
    }
        
}

extension ColumnViewController: NewPostButtonDelegate {

    private func isOnTab(vcType: AnyClass) -> Bool {
        var containsSpecificView = false
        if let vcStack = mainColumnNavVC?.viewControllers {
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
