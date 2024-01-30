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

    func icon(symbolConfig: UIImage.SymbolConfiguration? = nil) -> UIImage? {
        switch(self) {
        case .editAvatar:
            return MAMenu.editAvatar.image
        case .editHeader:
            return MAMenu.editHeader.image
        case .editDetails:
            return MAMenu.editDetails.image
        case .editInfoAndLink:
            return MAMenu.editInfoAndLinks.image
        case .settings:
            return FontAwesome.image(fromChar: "\u{f013}")
        case .share:
            return FontAwesome.image(fromChar: "\u{e09a}")
        case .filters:
            return MAMenu.filters.image
        case .muted:
            return MAMenu.muted.image
        case .blocked:
            return MAMenu.blocked.image
        case .bookmarks:
            return MAMenu.bookmarks.image
        case .likes:
            return MAMenu.likes.image
        case .recentMedia:
            return MAMenu.recentMedia.image
        case .message:
            return MAMenu.message.image
        case .mention:
            return MAMenu.mention.image
        case .muteOneDay:
            return MAMenu.muteOneDay.image
        case .muteForever:
            return MAMenu.muteForever.image
        case .block:
            return MAMenu.block.image
        case .addToList:
            return MAMenu.addToList.image.withRenderingMode(.alwaysTemplate)
        case .removeFromList:
            return MAMenu.removeFromList.image.withRenderingMode(.alwaysTemplate)
        case .enableReposts:
            return MAMenu.enableReposts.image.withRenderingMode(.alwaysTemplate)
        case .disableReposts:
            return MAMenu.disableReposts.image.withRenderingMode(.alwaysTemplate)
        case .enableNotifications:
            return MAMenu.enableNotifications.image.withRenderingMode(.alwaysTemplate)
        case .disableNotifications:
            return MAMenu.disableNotifications.image.withRenderingMode(.alwaysTemplate)
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
