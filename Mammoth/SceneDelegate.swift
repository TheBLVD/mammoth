//
//  SceneDelegate.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 03/11/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

/// Called when the scene did become active
/// Used to fetch data on app launch
public let appDidBecomeActiveNotification = Notification.Name("appDidBecomeActiveNotification")

protocol AppStateRestoration {
    func storeUserActivity(in activity: NSUserActivity)
    func restoreUserActivity(from activity: NSUserActivity)
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator!
    var blurredEffectView: UIVisualEffectView?
    static let sharedInstance = SceneDelegate()
    var inBG: Bool = false
    var isBioLocked: Bool = GlobalStruct.appLock

    // Listen for theme changes and update global tint values
    let appearanceManager = AppearanceManager()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        l10n.start()
        l10n.checkForSupportedLanguage()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.overrideTheme), name: NSNotification.Name(rawValue: "overrideTheme"), object: nil)
        self.overrideTheme()
        
        // user defaults
        GlobalStruct.soundsEnabled = UserDefaults.standard.value(forKey: "sounds") as? Bool ?? true
        GlobalStruct.hapticsEnabled = UserDefaults.standard.value(forKey: "haptics") as? Bool ?? true
        
        let hcText = UserDefaults.standard.value(forKey: "hcText") as? Bool ?? true
        if hcText == true {
            UIColor.custom.mainTextColor = .label
        } else {
            UIColor.custom.mainTextColor = .secondaryLabel
        }
        let hcText2 = UserDefaults.standard.value(forKey: "hcText2") as? Bool ?? false
        if hcText2 == true {
            UIColor.custom.mainTextColor2 = .label
        } else {
            UIColor.custom.mainTextColor2 = .secondaryLabel
        }
        
        // app tint
        window?.tintColor = .custom.baseTint
        
        #if targetEnvironment(macCatalyst)
        if let windowScene = scene as? UIWindowScene {
            windowScene.titlebar?.toolbarStyle = .unifiedCompact
            windowScene.titlebar?.separatorStyle = .none
            windowScene.titlebar?.titleVisibility = .hidden
            if let titlebar = windowScene.titlebar {
                titlebar.toolbar?.displayMode = .iconOnly
            }
        }
        #endif
        
        // register analytics listeners
        AnalyticsManager.shared.prepareForUse()
        // register modaration listeners
        ModerationManager.shared.prepareForUse()
        // register mute/unmute listeners
        AVManager.shared.prepareForUse()
        
        InstanceManager.shared.prepareForUse()
        RealtimeManager.shared.prepareForUse()
        IAPManager.shared.prepareForUse()
        
        Task {
            try await AccountsManager.shared.prepareForUse()
            await MainActor.run {
                self.setupWindows(forScene: windowScene)
                
                if connectionOptions.urlContexts.first?.url != nil {
                    let theURL = connectionOptions.urlContexts.first?.url.absoluteString ?? ""
                    if theURL.contains("shareExtensionMedia") {
                        // open composer with media from Share Extension
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "composerFromShareImage"), object: nil)
                    } else if theURL.contains("shareExtensionVideo") {
                        // open composer with videos from Share Extension
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "composerFromShareVideo"), object: nil)
                    } else if theURL.contains("shareExtensionText") {
                        // open composer with text from Share Extension
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "composerFromShareText"), object: nil)
                    } else if theURL.contains("undo000") {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "undoTapped"), object: self)
                    } else if theURL.contains("status") {
                        let zz = (theURL.split(separator: "=")).first
                        var zz2 = (zz ?? " ")
                        if theURL.contains("=") {
                            zz2 = zz2.dropLast().dropLast()
                        }
                        let idArr = zz2.split(separator: "/")
                        let aaa = String(idArr.last ?? "")
                        let bbb = aaa.split(separator: "?")
                        let ccc = String(bbb.first ?? "")
                        GlobalStruct.schemeId = ccc
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchPost"), object: self)
                    } else if theURL.contains("twitter.com") {
                        let zz = (theURL.split(separator: "=")).first
                        var zz2 = (zz ?? " ")
                        if theURL.contains("=") {
                            zz2 = zz2.dropLast().dropLast()
                        }
                        let idArr = zz2.split(separator: "/")
                        let aaa = String(idArr.last ?? "")
                        let bbb = aaa.split(separator: "?")
                        let ccc = String(bbb.first ?? "")
                        GlobalStruct.schemeProfileName = ccc
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchUser"), object: self)
                    } else if theURL.contains("newpost") {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "gotoN"), object: self)
                    }
                }
                
                if let userActivity = session.stateRestorationActivity {
                    self.restoreUserActivity(from: userActivity)
                }
            }
        }
    }
    
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        let activity = NSUserActivity(activityType: "Initial view setup")
        self.storeUserActivity(in: activity)
        return activity
    }
    
    private func storeUserActivity(in activity: NSUserActivity) {
        log.debug("SceneDelegate:" + #function)
        if let rootViewController = self.window?.rootViewController as? AppStateRestoration {
            rootViewController.storeUserActivity(in: activity)
        }
    }
    
    private func restoreUserActivity(from activity: NSUserActivity) {
        log.debug("SceneDelegate:" + #function)
        if let rootViewController = self.window?.rootViewController as? AppStateRestoration {
            rootViewController.restoreUserActivity(from: activity)
        }
    }
    
    func setupWindows(forScene windowScene: UIWindowScene) {
        if self.window == nil {
            self.window = UIWindow(windowScene: windowScene)
        }
        self.appCoordinator = AppCoordinator(window: self.window!)
        self.appCoordinator.start()
    }
    
    func windowScene(_ windowScene: UIWindowScene, didUpdate previousCoordinateSpace: UICoordinateSpace, interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation, traitCollection previousTraitCollection: UITraitCollection) {
        #if !targetEnvironment(macCatalyst)
        if self.inBG == false {
            if UIApplication.shared.isRunningInFullScreen() == GlobalStruct.fullScreen {} else {
                GlobalStruct.fullScreen = UIApplication.shared.isRunningInFullScreen()
                if UIDevice.current.userInterfaceIdiom == .pad {
                    GlobalStruct.hasSetupNewsDots = false
                    self.setupWindows(forScene: windowScene)
                }
            }
        }
        #endif
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if userActivity.activityType == "com.theblvd.mammoth.new" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "gotoN"), object: self)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        GlobalStruct.canLoadLink = true
        let theURL = URLContexts.first?.url.absoluteString ?? ""
        if theURL.contains("shareExtensionMedia") {
            // open composer with media from Share Extension
            NotificationCenter.default.post(name: Notification.Name(rawValue: "composerFromShareImage"), object: nil)
        } else if theURL.contains("shareExtensionVideo") {
            // open composer with videos from Share Extension
            NotificationCenter.default.post(name: Notification.Name(rawValue: "composerFromShareVideo"), object: nil)
        } else if theURL.contains("shareExtensionText") {
            // open composer with text from Share Extension
            NotificationCenter.default.post(name: Notification.Name(rawValue: "composerFromShareText"), object: nil)
        } else if theURL.contains("addNewInstance2") {
            print("Response ==> \(theURL)")
            let x = theURL
            let z = x.split(separator: "&")
            let y = z.first?.split(separator: "=")
            if GlobalStruct.newInstance != nil {
                GlobalStruct.newInstance!.authCode = y?.last?.description ?? ""
            } else {
                log.error("expected GlobalStruct.newInstance to be valid")
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: "newInstanceLogged"), object: nil)
        } else if theURL.contains("addNewInstance") {
            print("Response ==> \(theURL)")
            let x = theURL
            let z = x.split(separator: "&")
            let y = z.first?.split(separator: "=")
            if GlobalStruct.newInstance != nil {
                GlobalStruct.newInstance!.authCode = y?.last?.description ?? ""
            } else {
                log.error("newInstance does not exist")
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: "newInstanceLogged"), object: nil)
        } else if theURL.contains("undo000") {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "undoTapped"), object: self)
        } else {
            print("Response ==> \(theURL)")
            let x = theURL
            if let ur = URL(string: x.replacingOccurrences(of: "mammoth://", with: "https://")) {
                PostActions.openLink(ur)
            }
        }
    }
    
    @objc func overrideTheme() {
        if GlobalStruct.overrideTheme == 0 {
            UIApplication.shared.statusBarStyle = .default
            window?.overrideUserInterfaceStyle = .unspecified
        } else if GlobalStruct.overrideTheme == 1 {
            UIApplication.shared.statusBarStyle = .darkContent
            self.window?.overrideUserInterfaceStyle = .light
        } else {
            UIApplication.shared.statusBarStyle = .lightContent
            self.window?.overrideUserInterfaceStyle = .dark
        }
        
        if #available(iOS 17.0, *) {
            var themeContrast: ThemeContrast
            if GlobalStruct.overrideThemeHighContrast {
                themeContrast = ThemeContrast.highContrast
            } else {
                themeContrast = ThemeContrast.standard
            }
            
            self.window?.windowScene?.traitOverrides.themeContrast = themeContrast
        }

    }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if shortcutItem.type == "com.theblvd.mammoth.post" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "gotoN"), object: self)
            completionHandler(true)
        } else if shortcutItem.type == "com.theblvd.mammoth.home" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "gotoH"), object: self)
            completionHandler(true)
        } else if shortcutItem.type == "com.theblvd.mammoth.community" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "gotoC"), object: self)
            completionHandler(true)
        } else if shortcutItem.type == "com.theblvd.mammoth.everything" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "gotoE"), object: self)
            completionHandler(true)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.

        // This can happen when the user swipes the app into the app carousel, but
        // then immediately returns to the app. In that case no need to re-authenticate.
        if GlobalStruct.appLock {
            // If we never fully locked, then hide the locked view
            if !self.isBioLocked {
                self.hideAppLockedView()
            }
        }
        self.inBG = false
        NotificationCenter.default.post(name: appDidBecomeActiveNotification, object: nil)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        
        // Show the blurredEffectView if the user has appLock enabled,
        // so the current posts are obscured before the app goes into the background
        if GlobalStruct.appLock {
            self.showAppLockedView()
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        if GlobalStruct.appLock {
            self.showAppLockedView()
            self.biometricAuth()
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "startTimer"), object: nil)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        self.inBG = true
        if GlobalStruct.appLock {
            self.isBioLocked = true
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "stopTimer"), object: nil)
    }
    
    func showAppLockedView() {
        log.debug(#function)
        if self.blurredEffectView == nil {
            self.blurredEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))
            self.window?.addSubview(self.blurredEffectView!)
            self.blurredEffectView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
        self.blurredEffectView!.frame = UIApplication.shared.windows.last?.bounds ?? UIWindow().bounds
        self.window?.bringSubviewToFront(self.blurredEffectView!)
        self.blurredEffectView!.layer.zPosition = CGFloat(Float.greatestFiniteMagnitude)
    }
    
    func hideAppLockedView() {
        log.debug(#function)
        self.blurredEffectView?.removeFromSuperview()
        self.blurredEffectView = nil
    }
    
    func biometricAuth() {
        BioMetricAuthenticator.authenticateWithBioMetrics(reason: "") { [weak self] (result) in
            switch result {
            case .success( _):
                DispatchQueue.main.async {
                    self?.isBioLocked = false
                    self?.hideAppLockedView()
                }
            case .failure(let error):
                log.error(error.message())
                DispatchQueue.main.async {
                    self?.showPasscodeAuthentication(message: "")
                }
            }
        }
    }
    
    func showPasscodeAuthentication(message: String) {
        BioMetricAuthenticator.authenticateWithPasscode(reason: message) { [weak self] (result) in
            switch result {
            case .success( _):
                DispatchQueue.main.async {
                    self?.isBioLocked = false
                    self?.hideAppLockedView()
                }
            case .failure(let error):
                log.error(error.message())
                DispatchQueue.main.async {
                    self?.biometricAuth()
                }
            }
        }
    }

}

