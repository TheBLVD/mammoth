//
//  IdentityData.swift
//  Mammoth
//
//  Created by Benoit Nolens on 17/04/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import Foundation

struct IdentityData: Codable {
    let id: String
    let server: String
    let lastStatusAt: String?
    let accountCreatedAt: String?
    let followersCount: Int
    let followingCount: Int
    let statusesCount: Int
    let numberOfSubscribedChannels: Int
    let numberOfAccounts: Int
    let theme: String
    let isGoldMember: Bool
    let appLanguage: String
    let isLanguageSupported: Bool
    let pushEnabled: Bool
    
    struct IOS: Codable {
        let pushToken: String?
    }
        
    let ios: IOS
    
    init(from acctData: MastodonAcctData, allAccounts: [any AcctDataType]) {
        self.id = acctData.account.id
        self.server = acctData.account.server
        self.followersCount = acctData.account.followersCount
        self.followingCount = acctData.account.followingCount
        self.statusesCount =  acctData.account.statusesCount
        self.lastStatusAt = acctData.account.lastStatusAt
        self.accountCreatedAt = acctData.account.createdAt
        self.numberOfSubscribedChannels = acctData.forYou.subscribedChannels.count
        self.numberOfAccounts = allAccounts.count
        self.isGoldMember = IAPManager.isGoldMember
        
        let themePrefix = GlobalStruct.overrideThemeHighContrast ? "HC:" : ""
        switch GlobalStruct.overrideTheme {
        case 1:
            self.theme = "\(themePrefix)light"
        case 2:
            self.theme = "\(themePrefix)dark"
        default:
            self.theme = "\(themePrefix)system"
        }
        
        self.appLanguage = l10n.getCurrentLocale() ?? "en"
        self.isLanguageSupported = l10n.isCurrentLanguageSupported()
        
        let notificationType = UIApplication.shared.currentUserNotificationSettings!.types
        if notificationType == [] {
            self.pushEnabled = false
        } else {
            self.pushEnabled = true
        }
        
        self.ios = IOS(pushToken: GlobalStruct.deviceToken?.hexString)
    }
}
