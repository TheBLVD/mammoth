//
//  ActivityViewController.swift
//  Mammoth
//
//  Created by Benoit Nolens on 31/08/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class ActivityViewController : UIViewController {
    
    private let feedViewController = NewsFeedViewController(type: .activity)
    
    required init() {
        super.init(nibName: nil, bundle: nil)
        
        self.addChild(self.feedViewController)
        self.view.addSubview(self.feedViewController.view)
        
        self.navigationItem.title = "Activity"
        self.title = "Activity"
        
        self.feedViewController.delegate = self
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UIDevice.current.userInterfaceIdiom == .phone {
            let accountsBarButton = UIBarButtonItem(customView: AccountSwitcherButton())
            accountsBarButton.customView?.transform = CGAffineTransform(translationX: 2, y: -6)
            self.navigationItem.setRightBarButtonItems([accountsBarButton], animated: false)
        }

        let titleBarItem = UIBarButtonItem(customView: NavigationBarTitle(title: "Activity"))
        self.navigationItem.setLeftBarButtonItems([titleBarItem], animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.feedViewController.reloadData()
        
        // Prompt the user one time here, so we don't pester them each
        // time they switch to this view.
        EnablePushNotificationSetting(checkOnlyOnceFlag: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ActivityViewController: NewsFeedViewControllerDelegate {
    func willChangeFeed(_ type: NewsFeedTypes) {}
    
    func didChangeFeed(_ type: NewsFeedTypes) {}
    
    func userActivityStorageIdentifier() -> String {
        return "ActivityViewController"
    }
    
    func didScrollToTop() {
        // Hide the tab bar activity indicator (dot)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "hideIndActivity"), object: nil)
    }
    
    func isActiveFeed(_ type: NewsFeedTypes) -> Bool {
        return true
    }
}

// Jump to newest
extension ActivityViewController: JumpToNewest {
    @objc func jumpToNewest() {
        feedViewController.jumpToNewest()
    }
}
