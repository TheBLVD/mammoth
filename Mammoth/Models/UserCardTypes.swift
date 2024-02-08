//
//  UserCardTypes.swift
//  Mammoth
//
//  Created by Benoit Nolens on 14/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

enum UserCardButtonType: Int {
    case openFollowing
    case openFollowers
    case editAvatar
    case editHeader
    case editDetails
    case editInfoAndLink
    case settings
    
    case share
    case filters
    case muted
    case blocked
    case bookmarks
    case likes
    case recentMedia
    
    case link
    
    // profile actions
    case message
    case mention
    case muteOneDay
    case muteForever
    case unmute
    case block
    case unblock
    
    case addToList
    case removeFromList
    case createNewList
    case enableNotifications
    case disableNotifications
    case enableReposts
    case disableReposts

    func icon(symbolConfig: UIImage.SymbolConfiguration? = nil, weight: UIFont.Weight = .regular ) -> UIImage? {
        switch(self) {
        case .editAvatar:
            return FontAwesome.image(fromChar: "\u{f2bd}", weight: weight)
        case .editHeader:
            return FontAwesome.image(fromChar: "\u{f03e}", weight: weight)
        case .editDetails:
            return FontAwesome.image(fromChar: "\u{f866}", weight: weight)
        case .editInfoAndLink:
            return FontAwesome.image(fromChar: "\u{f0c1}", weight: weight)
        case .settings:
            return FontAwesome.image(fromChar: "\u{f013}", weight: weight)
        case .share:
            return FontAwesome.image(fromChar: "\u{e590}", weight: weight)
        case .filters:
            return FontAwesome.image(fromChar: "\u{f0b0}", weight: weight)
        case .muted:
            return FontAwesome.image(fromChar: "\u{f4a9}", weight: weight)
        case .blocked:
            return FontAwesome.image(fromChar: "\u{f05e}", weight: weight)
        case .bookmarks:
            return FontAwesome.image(fromChar: "\u{f02e}", weight: weight)
        case .likes:
            return FontAwesome.image(fromChar: "\u{f004}", weight: weight)
        case .recentMedia:
            return FontAwesome.image(fromChar: "\u{f2bd}", weight: weight)
        case .message:
            return FontAwesome.image(fromChar: "\u{f0e0}", weight: weight)
        case .mention:
            return FontAwesome.image(fromChar: "\u{40}", weight: weight)
        case .muteOneDay:
            return FontAwesome.image(fromChar: "\u{f2e2}", weight: weight)
        case .muteForever:
            return FontAwesome.image(fromChar: "\u{f4a9}", weight: weight)
        case .block:
            return FontAwesome.image(fromChar: "\u{f05e}", weight: weight)
        case .addToList:
            return FontAwesome.image(fromChar: "\u{2b}", weight: weight)
        case .removeFromList:
            return FontAwesome.image(fromChar: "\u{f068}", weight: weight)
        case .enableReposts:
            return FontAwesome.image(fromChar: "\u{f361}", weight: weight)
        case .disableReposts:
            return FontAwesome.image(fromChar: "\u{f361}", weight: weight)
        case .enableNotifications:
            return FontAwesome.image(fromChar: "\u{f0f3}", weight: weight)
        case .disableNotifications:
            return FontAwesome.image(fromChar: "\u{f1f6}", weight: weight)
        default:
            return nil
        }
    }
}

enum UserCardButtonCallbackData {
    case url(URL)
    case hashtag(String)
    case mention(String)
    case email(String)
    case user(UserCardModel)
    case list(String)
}

typealias UserCardButtonCallback = (_ type: UserCardButtonType,
                                    _ data: UserCardButtonCallbackData?) -> Void

let userCardSymbolConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
