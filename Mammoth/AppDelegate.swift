//
//  AppDelegate.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 03/11/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import UserNotifications
import BackgroundTasks
import ArkanaKeys
import AVFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var restrictRotation: UIInterfaceOrientationMask = .all
    var restrictRotationPhone: UIInterfaceOrientationMask = .portrait
    
    static let shared = AppDelegate()
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            if let rotatingVC = UIApplication.topViewController(controller: window?.rootViewController) as? RotatingViewController {
                return rotatingVC.customSupportedRotations()
            }
            return self.restrictRotationPhone
        } else {
            return self.restrictRotation
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        DispatchQueue.main.async {
            if GlobalStruct.activityBadges {
                let userDefaults = UserDefaults(suiteName: "group.com.theblvd.mammoth.wormhole")
                let id = userDefaults?.value(forKey: "notificationId") as? String ?? ""
                self.checkNotificationTypeForID(id)
            }
        }
        if application.applicationState == .inactive || application.applicationState == .background {
            UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
            NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchFromNotif"), object: self)
        }
        completionHandler(.noData)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        let info = response.notification.request.content.userInfo
        if let id = info["id"] as? Int64 {
            GlobalStruct.curIDNoti = "\(id)"
            self.checkNotificationTypeForID(GlobalStruct.curIDNoti, alsoGoToTab: true)
        }
        
        // Open URL in customer.io push notifications
        if let urlStr = (info as? Dictionary<String, Any>)?[keyPath: "CIO.push.link"] as? String, let url = URL(string: urlStr) {
            let prevValue = GlobalStruct.openLinksInBrowser
            GlobalStruct.openLinksInBrowser = false
            PostActions.openLink(url)
            GlobalStruct.openLinksInBrowser = prevValue
        }
    }
        
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        log.debug("didRegisterForRemoteNotificationsWithDeviceToken")

        // When running on Mac (Designed for iPad), we've seen this get called twice
        // during a single launch / single call to registerForRemoteNotifications().
        // As a result, we will exit early if this is called twice with the same
        // deviceToken and currentAccount.
        let tokenDidChange = (GlobalStruct.deviceToken != deviceToken)
        GlobalStruct.deviceToken = deviceToken
        
        UserDefaults.standard.setValue(deviceToken, forKey: "deviceToken")
        
        let currentAccount = AccountsManager.shared.currentAccount as? MastodonAcctData
        if currentAccount == nil {
            log.error("currentAccount is nil in didRegisterForRemoteNotificationsWithDeviceToken")
        } else {
            AccountsManager.shared.syncIdentityData()
        }
        
        let accountDidChange = (GlobalStruct.deviceTokenAccountUID != currentAccount?.uniqueID)
        GlobalStruct.deviceTokenAccountUID = currentAccount?.uniqueID
        
        if tokenDidChange || accountDidChange {
            Task {
                // Make sure there is a server associated with the current account before
                // we call deleteSubscription()
                let server = currentAccount?.instanceData.returnedText
                guard server ?? "" != "" else {
                    log.error("need to support push notification work for other account types")
                    return
                }
                
                // Migration if needed for old (corrupt) keys
                await PushNotificationManager.migrate()
                
                // Sign up for APNS for only the current account
                if let currentAccount {
                    log.debug("didRegisterForRemoteNotificationsWithDeviceToken - subscribing")
                    try await PushNotificationManager.subscribe(deviceToken: deviceToken, account: currentAccount)
                }
            }
        } else {
            log.debug("Not re-subscribing; tokenDidChange:\(tokenDidChange), accountDidChange:\(accountDidChange) ")
        }
    }
    
    @objc func checkNotificationTypeForID(_ id: String, alsoGoToTab: Bool = false) {
        // called when the app is foregrounded
        let request = Notifications.notification(id: id)
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let error = statuses.error {
                log.error("Failed to fetch notification: \(error)")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "showIndActivity"), object: nil)
                    if alsoGoToTab {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "goToActivityTab"), object: self)
                    }
                }
            }
            if let stat = (statuses.value) {
                let postCard = stat.status != nil ? PostCardModel(status: stat.status!) : nil
                DispatchQueue.main.async {
                    switch stat.type {
                    case .direct, .mention:
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "showIndActivity2"), object: nil)
                        if alsoGoToTab {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "goToMessagesTab"), object: self, userInfo: postCard != nil ? ["postCard": postCard!] : nil)
                        }
                    default:
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "showIndActivity"), object: nil)
                        if alsoGoToTab {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "goToActivityTab"), object: self, userInfo: postCard != nil ? ["postCard": postCard!] : nil)
                        }
                    }
                    
                    if stat.status == nil {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "showIndActivity"), object: nil)
                        if alsoGoToTab {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "goToActivityTab"), object: self)
                        }
                    }
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        log.error("Failed to register: \(error)")
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        UIFont.swizzle()
        SwiftyGiphyAPI.shared.apiKey = ArkanaKeys.Global().swiftyGiphyAPI
        
        GlobalStruct.deviceToken = UserDefaults.standard.value(forKey: "deviceToken") as? Data
        
        GlobalStruct.singleColumn = UserDefaults.standard.value(forKey: "singleColumn") as? Bool ?? false
        GlobalStruct.padColWidth = UserDefaults.standard.value(forKey: "padColWidth") as? Int ?? 412
        
        GlobalStruct.overrideTheme = UserDefaults.standard.value(forKey: "overrideTheme") as? Int ?? 0
        GlobalStruct.overrideThemeHighContrast = UserDefaults.standard.value(forKey: "overrideThemeHighContrast") as? Bool ?? false
        GlobalStruct.customTextSize = UserDefaults.standard.value(forKey: "customTextSize") as? CGFloat ?? 0
        GlobalStruct.customLineSize = UserDefaults.standard.value(forKey: "customLineSize") as? CGFloat ?? 0
        GlobalStruct.timeStampStyle = UserDefaults.standard.value(forKey: "timeStampStyle") as? Int ?? 0
        GlobalStruct.originalPostTimeStamp = UserDefaults.standard.value(forKey: "originalPostTimeStamp") as? Bool ?? true
        let displayNameRawValue: Int = UserDefaults.standard.value(forKey: "displayName") as? Int ?? GlobalStruct.DisplayNameType.usernameOnly.rawValue
        GlobalStruct.displayName = GlobalStruct.DisplayNameType(rawValue: displayNameRawValue) ?? GlobalStruct.DisplayNameType.usernameOnly
        GlobalStruct.maxLines = UserDefaults.standard.value(forKey: "maxLines") as? Int ?? 6
        GlobalStruct.showCW = UserDefaults.standard.value(forKey: "showCW") as? Bool ?? true
        GlobalStruct.blurSensitiveContent = UserDefaults.standard.value(forKey: "blurSensitiveContent") as? Bool ?? true
        GlobalStruct.autoPlayVideos = UserDefaults.standard.value(forKey: "autoPlayVideos") as? Bool ?? true
        GlobalStruct.mediaSize = PostCardCell.PostCardMediaVariant(rawValue: (UserDefaults.standard.value(forKey: "mediaSize") ?? "") as! String) ?? PostCardCell.PostCardMediaVariant.large
        GlobalStruct.feedReadDirection = NewsFeedReadDirection(rawValue: (UserDefaults.standard.value(forKey: "feedReadDirection") ?? "") as! String) ?? NewsFeedReadDirection.bottomUp
        GlobalStruct.activityBadges = UserDefaults.standard.value(forKey: "activityBadges") as? Bool ?? true
        GlobalStruct.reviewPrompt = UserDefaults.standard.value(forKey: "reviewPrompt") as? Bool ?? true
        GlobalStruct.enableLogging = UserDefaults.standard.value(forKey: "enableLogging") as? Bool ?? true
        log.writeToFile(GlobalStruct.enableLogging)
        
        GlobalStruct.dmSecurityAlert = UserDefaults.standard.value(forKey: "dmSecurityAlert") as? Bool ?? true
        do {
            GlobalStruct.votedOnPolls = try Disk.retrieve("votedOnPolls.json", from: .documents, as: [String: Poll].self)
        } catch {
            // This can happen if the user has never voted on a poll
            // error fetching votedOnPolls from Disk
        }
        do {
            GlobalStruct.blockedUsers = try Disk.retrieve("blockedUsers.json", from: .documents, as: [String].self)
        } catch {
            // This can happen if the user hasn't blocked users yet
            // error fetching blocked users from Disk
        }
        
        GlobalStruct.pnMentions = UserDefaults.standard.value(forKey: "pnMentions") as? Bool ?? true
        GlobalStruct.pnLikes = UserDefaults.standard.value(forKey: "pnLikes") as? Bool ?? true
        GlobalStruct.pnReposts = UserDefaults.standard.value(forKey: "pnReposts") as? Bool ?? true
        GlobalStruct.pnFollows = UserDefaults.standard.value(forKey: "pnFollows") as? Bool ?? true
        GlobalStruct.pnPolls = UserDefaults.standard.value(forKey: "pnPolls") as? Bool ?? true
        GlobalStruct.pnStatuses = UserDefaults.standard.value(forKey: "pnStatuses") as? Bool ?? true
        GlobalStruct.pnFollowRequests = UserDefaults.standard.value(forKey: "pnFollowRequests") as? Bool ?? true
        
        GlobalStruct.linkPreviewCards1 = UserDefaults.standard.value(forKey: "linkPreviewCards1") as? Bool ?? true
        GlobalStruct.linkPreviewCards2 = UserDefaults.standard.value(forKey: "linkPreviewCards2") as? Bool ?? true
        GlobalStruct.linkPreviewCardsLarge = UserDefaults.standard.value(forKey: "linkPreviewCardsLarge") as? Bool ?? true
        
        GlobalStruct.VIPListID = UserDefaults.standard.value(forKey: "VIPListID") as? String ?? ""
        
        GlobalStruct.chatView = false // Disabled iMessage style chat until it's fixed. UserDefaults.standard.value(forKey: "chatView2") as? Bool ?? false
        GlobalStruct.circleProfiles = UserDefaults.standard.value(forKey: "circleProfiles") as? Bool ?? true

        GlobalStruct.tabBarTitles = UserDefaults.standard.value(forKey: "tabBarTitles") as? Bool ?? false
        GlobalStruct.tabBarAnimations = UserDefaults.standard.value(forKey: "tabBarAnimations") as? Bool ?? true
        GlobalStruct.tabBarProfileIcon = UserDefaults.standard.value(forKey: "tabBarProfileIcon") as? Bool ?? true
        
        GlobalStruct.langStr = UserDefaults.standard.value(forKey: "langStr") as? String ?? Locale.current.languageCode ?? "en"
        GlobalStruct.hideNavBars = UserDefaults.standard.value(forKey: "hideNavBars") as? Bool ?? false
        GlobalStruct.hideNavBars2 = UserDefaults.standard.value(forKey: "hideNavBars2") as? Bool ?? false
        GlobalStruct.scrollDirectionDown = UserDefaults.standard.value(forKey: "scrollDirectionDown") as? Bool ?? true
        GlobalStruct.openLinksInBrowser = UserDefaults.standard.value(forKey: "openLinksInBrowser") as? Bool ?? false
        GlobalStruct.appLock = UserDefaults.standard.value(forKey: "appLock") as? Bool ?? false
        GlobalStruct.shareAnalytics = UserDefaults.standard.value(forKey: "shareAnalytics") as? Bool ?? true
        
        GlobalStruct.tab2 = UserDefaults.standard.value(forKey: "tab2") as? Bool ?? true
        GlobalStruct.tab3 = UserDefaults.standard.value(forKey: "tab3") as? Bool ?? true
        GlobalStruct.tab4 = UserDefaults.standard.value(forKey: "tab4") as? Bool ?? true
        
        GlobalStruct.popupPostPosted = UserDefaults.standard.value(forKey: "popupPostPosted") as? Bool ?? true
        GlobalStruct.popupPostDeleted = UserDefaults.standard.value(forKey: "popupPostDeleted") as? Bool ?? true
        GlobalStruct.popupUserActions = UserDefaults.standard.value(forKey: "popupUserActions") as? Bool ?? true
        GlobalStruct.popupListActions = UserDefaults.standard.value(forKey: "popupListActions") as? Bool ?? true
        GlobalStruct.popupBookmarkActions = UserDefaults.standard.value(forKey: "popupBookmarkActions") as? Bool ?? true
        GlobalStruct.popupRateLimits = false
        
        GlobalStruct.keyboardType = UserDefaults.standard.value(forKey: "keyboardType") as? Int ?? 0
        GlobalStruct.altText = UserDefaults.standard.value(forKey: "altText") as? Bool ?? false
        
        GlobalStruct.threaderMode = UserDefaults.standard.value(forKey: "threaderMode") as? Bool ?? false
        GlobalStruct.threaderStyle = UserDefaults.standard.value(forKey: "threaderStyle") as? Int ?? 0
        
        GlobalStruct.idsToUnlike = UserDefaults.standard.value(forKey: "idsToUnlike") as? [String] ?? []
        
        GlobalStruct.notifs1 = UserDefaults.standard.value(forKey: "notifs1") as? Bool ?? false // Has the user enabled push notifications?
        
        GlobalStruct.savedPostSearch = UserDefaults.standard.value(forKey: "savedPostSearch") as? [String] ?? []
        
        GlobalStruct.tab1Index =  0 // home feed
        GlobalStruct.tab2Index =  1 // explore
        GlobalStruct.tab3Index =  2 // activity
        GlobalStruct.tab4Index =  3 // messages
        GlobalStruct.tab5Index =  4 // profile
        
        // Set FAColorTheme
        switch GlobalStruct.overrideTheme{
        case 1:
            FontAwesome.setColorTheme(theme: ColorTheme.dark)
        case 2:
            FontAwesome.setColorTheme(theme: ColorTheme.light)
        default:
            FontAwesome.setColorTheme(theme: ColorTheme.systemDefault)
        }
        
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
        
        if let userInfo = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] {
            if let urlStr = (userInfo as? Dictionary<String, Any>)?[keyPath: "CIO.push.link"] as? String, let url = URL(string: urlStr) {
                let prevValue = GlobalStruct.openLinksInBrowser
                GlobalStruct.openLinksInBrowser = false
                PostActions.openLink(url)
                GlobalStruct.openLinksInBrowser = prevValue
            }
        }

        return true
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("terminating")
        // save drafts when the app terminates whilst in the composer
        if GlobalStruct.showingNewPostComposer {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "saveDraft"), object: nil)
        }
    }
    
    #if targetEnvironment(macCatalyst)
    @objc func supportPage() {
        let url = URL(string: "https://www.getmammoth.app")!
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        
        builder.remove(menu: .newScene)
        builder.remove(menu: .format)
        builder.replaceChildren(ofMenu: .help) { oldChildren in
            var newChildren = oldChildren
            let newGameItem = UIKeyCommand(input: "h", modifierFlags: [.alternate], action: #selector(supportPage))
            newGameItem.title = "Support"
            newChildren.remove(at: 0)
            newChildren.insert(newGameItem, at: 0)
            return newChildren
        }
        
        // preferences
        let command1 = UIKeyCommand(input: ",", modifierFlags: [.command], action: #selector(SidebarViewController.shared.settingsTap))
        command1.title =  "Preferences..."
        let formatDataMenu1 = UIMenu(title: "Preferences...", image: nil, identifier: UIMenu.Identifier("settings"), options: .displayInline, children: [command1])
        builder.replace(menu: .services, with: formatDataMenu1)
        
        // actions
        let commandA1 = UIKeyCommand(input: "n", modifierFlags: [.command], action: #selector(SidebarViewController.shared.newPost))
        commandA1.title =  "New Post"
        let commandA2 = UIKeyCommand(input: "n", modifierFlags: [.command, .shift], action: #selector(SidebarViewController.shared.newMessage))
        commandA2.title =  "New Message"
        let formatDataMenuA1 = UIMenu(title: "New Post", image: nil, identifier: UIMenu.Identifier("newPost1"), options: .displayInline, children: [commandA1, commandA2])
        builder.insertChild(formatDataMenuA1, atStartOfMenu: .file)
        
        // go to view
        let command01 = UIKeyCommand(input: "1", modifierFlags: [.command], action: #selector(ColumnViewController.shared.scrollTo1))
        command01.title =  "Feed"
        let command02 = UIKeyCommand(input: "2", modifierFlags: [.command], action: #selector(ColumnViewController.shared.scrollTo2))
        command02.title =  "Activity"
        let command03 = UIKeyCommand(input: "3", modifierFlags: [.command], action: #selector(ColumnViewController.shared.scrollTo3))
        command03.title =  "Messages"
        let command04 = UIKeyCommand(input: "4", modifierFlags: [.command], action: #selector(ColumnViewController.shared.scrollTo4))
        command04.title =  "Explore"
        let command05 = UIKeyCommand(input: "5", modifierFlags: [.command], action: #selector(ColumnViewController.shared.scrollTo5))
        command05.title =  NSLocalizedString("navigator.profile", comment: "")
        let command06 = UIKeyCommand(input: "6", modifierFlags: [.command], action: #selector(ColumnViewController.shared.scrollTo6))
        command06.title =  NSLocalizedString("title.likes", comment: "")
        let command07 = UIKeyCommand(input: "7", modifierFlags: [.command], action: #selector(ColumnViewController.shared.scrollTo7))
        command07.title =  "Bookmarks"
        let command08 = UIKeyCommand(input: "8", modifierFlags: [.command], action: #selector(ColumnViewController.shared.scrollTo8))
        command08.title =  NSLocalizedString("profile.filters", comment: "")
        let command09 = UIKeyCommand(input: "f", modifierFlags: [.command], action: #selector(ColumnViewController.shared.scrollTo9))
        command09.title =  "Search"
        let formatDataMenu4 = UIMenu(title: "", image: nil, identifier: UIMenu.Identifier("goto"), options: .displayInline, children: [command01, command02, command03, command04, command05, command06, command07, command08, command09])
        builder.insertChild(formatDataMenu4, atStartOfMenu: .view)
        
        // multi column switch
        let commandMC = UIKeyCommand(input: "]", modifierFlags: [.command], action: #selector(self.toggleMultiColumn))
        commandMC.title =  "Toggle Multi-Column Layout"
        let formatDataMenuMC = UIMenu(title: "", image: nil, identifier: UIMenu.Identifier("togglemc"), options: .displayInline, children: [commandMC])
        builder.insertChild(formatDataMenuMC, atStartOfMenu: .view)
        
        // quit
        let commandQ1 = UIKeyCommand(input: "q", modifierFlags: [.command], action: #selector(self.quitA))
        commandQ1.title =  "Quit Mammoth"
        let formatDataMenuQ = UIMenu(title: "Quit", image: nil, identifier: UIMenu.Identifier("quit"), options: .displayInline, children: [commandQ1])
        builder.insertChild(formatDataMenuQ, atStartOfMenu: .quit)
    }
        
    @objc func quitA() {
        _ = UIApplication.shared.windows.map({ x in
            if let sess = x.windowScene?.session {
                UIApplication.shared.requestSceneSessionDestruction(sess, options: nil) { (err) in
                    log.error("err")
                }
            }
        })
        exit(-1)
    }
    
    @objc func searchTap() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "searchTap"), object: nil)
    }
    #endif

}

// Mark - State Restoration
extension AppDelegate {
    
    func application(_ application: UIApplication, shouldSaveSecureApplicationState coder: NSCoder) -> Bool {
        // Save restoration version to the archive
        coder.encode(1.0, forKey: "Restoration Version")
        return true
    }
    
    func application(_ application: UIApplication, shouldRestoreSecureApplicationState coder: NSCoder) -> Bool {
        let restorationVersion = coder.decodeFloat(forKey: "Restoration Version")
        if restorationVersion == 1.0 {
            return true
        }
        
        // Don't restore from invalid/unsupported data
        return false
    }
    
}
