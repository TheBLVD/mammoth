//
//  AppCoordinator.swift
//  Mammoth
//
//  Created by Benoit Nolens on 14/08/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

public let shouldChangeRootViewController = Notification.Name("shouldChangeRootViewController")

class AppCoordinator {

    // MARK: - Properties
    /// Remember to change the UIViewController instance to your Splash Screen
    private(set) var rootViewController: UIViewController = UIViewController() {
        didSet {
            self.window.rootViewController = self.rootViewController
        }
    }
    
    /// Window to manage
    let window: UIWindow
    
    // MARK: - Init
    public init(window: UIWindow) {
        self.window = window
        self.window.rootViewController = rootViewController
        self.window.makeKeyAndVisible()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.start),
                                               name: shouldChangeRootViewController,
                                               object: nil)
    }

    // MARK: - Functions
        
    private func setCurrentViewController(_ viewController: UIViewController) {
        rootViewController = viewController
    }
    
    /// Starts the coordinator
    @objc func start() {
        log.debug(#function)
        if AccountsManager.shared.allAccounts.count == 0 {
            let introVC = UINavigationController(rootViewController: IntroViewController())
            setCurrentViewController(introVC)
        } else {
            // Check if we need to show onboarding (for 1.x accounts)
            let showOnboarding = AccountsManager.shared.shouldShowOnboardingForCurrentAccount()
            log.debug("showOnboarding: \(showOnboarding)")
            if self.window.traitCollection.horizontalSizeClass == .compact || UIDevice.current.userInterfaceIdiom == .phone {
                // iPhone
                GlobalStruct.isCompact = true
                if showOnboarding {
                    showOnboardingScreens()
                } else {
                    setCurrentViewController(TabBarViewController())
                }
            } else {
                // iPad
                GlobalStruct.isCompact = false
                if showOnboarding {
                    let rootController = ColumnViewController()
                    ColumnViewController.shared = rootController
                    setCurrentViewController(rootController)
                    
                    showOnboardingScreens(isOverlay: true)
                } else {
                    let rootController = ColumnViewController()
                    ColumnViewController.shared = rootController
                    setCurrentViewController(rootController)
                }
            }
        }
    }
    
    private func showOnboardingScreens(isOverlay: Bool = false) {
        log.debug("showOnboardingScreens")
        // Give these a chance to preload
        SetupChannelsViewModel.preload()
        SetupAccountsViewModel.preload()
        SetupMammothViewModel.preload()
        // Show the first onboarding screen
        let setupChannelsNavVC = UINavigationController(rootViewController: SetupChannelsViewController())
        if isOverlay {
            rootViewController.present(setupChannelsNavVC, animated: true)
        } else {
            setCurrentViewController(setupChannelsNavVC)
        }
    }
}
