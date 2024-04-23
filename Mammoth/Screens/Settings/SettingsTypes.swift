//
//  SettingsTypes.swift
//  Mammoth
//
//  Created by Benoit Nolens on 22/04/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import Foundation

public enum SettingsItem {
    
    enum Style {
        case normal
        case destructive
    }
    
    case upgrade
    case appIcon
    case postAppearance
    case soundsAndHaptics
    case composer
    case accounts
    case pushNotifications
    case siriShortcuts
    
    case getInTouch
    case subscriptions
    case openSourceCredits
    
    case openLinks
    case development
    
    case analytics
    case sourceCode
    
    case appLock
    
    case clearData
    
    var title: String {
        switch self {
        case .upgrade: return ""
        case .appIcon: return NSLocalizedString("settings.appIcon", comment: "Button in settings.")
        case .postAppearance: return NSLocalizedString("settings.appearance", comment: "Button in settings.")
        case .soundsAndHaptics: return NSLocalizedString("settings.soundsAndHaptics", comment: "Button in settings.")
        case .composer: return NSLocalizedString("settings.composer", comment: "Button in settings.")
        case .accounts: return NSLocalizedString("settings.accounts", comment: "Button in settings.")
        case .pushNotifications: return NSLocalizedString("settings.notifications", comment: "")
        case .siriShortcuts: return NSLocalizedString("settings.siriShortcuts", comment: "")
        case .getInTouch: return NSLocalizedString("settings.getInTouch", comment: "As in, 'to get in touch'")
        case .subscriptions: return NSLocalizedString("settings.manageSubscriptions", comment: "")
        case .openSourceCredits: return NSLocalizedString("settings.about", comment: "")
        case .openLinks: return NSLocalizedString("settings.openLinks", comment: "")
        case .appLock: return NSLocalizedString("settings.appLock", comment: "")
        case .development: return NSLocalizedString("settings.development", comment: "")
        case .analytics: return NSLocalizedString("settings.analytics", comment: "")
        case .sourceCode: return NSLocalizedString("settings.sourceCode", comment: "")
        case .clearData: return NSLocalizedString("settings.clearData", comment: "")
        }
    }
    
    var imageName: String {
        switch self {
        case .upgrade: return ""
        case .appIcon: return "\u{e269}"
        case .postAppearance: return "\u{f1fc}"
        case .soundsAndHaptics: return "\u{f8f2}"
        case .composer: return "\u{f14b}"
        case .accounts: return "\u{e1b9}"
        case .pushNotifications: return "\u{f0f3}"
        case .siriShortcuts: return "\u{f130}"
        case .getInTouch: return "\u{f0e0}"
        case .subscriptions: return "\u{f336}"
        case .openSourceCredits: return "\u{f15c}"
        case .openLinks: return "\u{f08e}"
        case .appLock: return "\u{f023}"
        case .development: return "\u{f121}"
        case .analytics: return "\u{f681}"
        case .sourceCode: return "\u{f121}"
        case .clearData: return "\u{f1f8}"
        }
    }
    
    var style: Style {
        switch self {
        case .clearData: return .destructive
        default: return .normal
        }
    }
    
}

public struct SettingsSection {
    var items: [SettingsItem]
    var footerTitle: String? = nil
}
