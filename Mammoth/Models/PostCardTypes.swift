//
//  PostCardTypes.swift
//  Mammoth
//
//  Created by Benoit Nolens on 31/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

enum PostCardButtonType: Int {
    case reply
    case repost
    case quote
    case like
    
    case more
    case bookmark
    case unbookmark
    case translate
    case viewInBrowser
    case share
    case copy
    case editPost
    case deletePost
    case pinPost
    
    case link
    case profile
    case postDetails
    
    // profile actions
    case follow
    case message
    case mention
    case disableReposts
    case addToList
    case removeFromList
    case createNewList
    case muteOneDay
    case muteForever
    case unmute
    case block
    case unblock
    case reportUser
    case reportPost
    
    case likes
    case reposts
    case replies
    
    func icon(symbolConfig: UIImage.SymbolConfiguration?) -> UIImage? {
        switch(self) {
        case .reply:
            return FontAwesome.image(fromChar: "\u{f075}", size: 16, weight: .regular)
        case .repost:
            return FontAwesome.image(fromChar: "\u{f361}", size: 16, weight: .regular)
        case .like:
            return FontAwesome.image(fromChar: "\u{f004}", size: 16, weight: .regular)
        case .more:
            return FontAwesome.image(fromChar: "\u{f141}", size: 16, weight: .bold)
        case .quote:
            return FontAwesome.image(fromChar: "\u{e14c}", size: 16, weight: .regular)
        case .bookmark:
            return FontAwesome.image(fromChar: "\u{f02e}", size: 16)
        case .unbookmark:
            return FontAwesome.image(fromChar: "\u{f02e}", size: 16, weight: .bold)
        case .translate:
            return UIImage(systemName: "globe", withConfiguration: symbolConfig)
        case .viewInBrowser:
            return UIImage(systemName: "safari")
        case .share:
            return UIImage(systemName: "square.and.arrow.up")
        case .link:
            return UIImage(systemName: "safari")
        case .copy:
            return UIImage(systemName: "doc.on.doc")
        case .editPost:
            return UIImage(systemName: "pencil")
        case .deletePost:
            return UIImage(systemName: "trash")
        case .follow:
            return MAMenu.follow.image
        case .message:
            return MAMenu.message.image
        case .mention:
            return MAMenu.mention.image
        case .disableReposts:
            return MAMenu.disableReposts.image
        case .addToList:
            return MAMenu.addToList.image
        case .muteOneDay:
            return MAMenu.muteOneDay.image
        case .muteForever:
            return MAMenu.muteForever.image
        case .block:
            return MAMenu.block.image
        case .reportUser, .reportPost:
            return MAMenu.report.image
        case .pinPost:
            return  UIImage(systemName: "pin", withConfiguration: symbolConfig)
        default:
            return nil
        }
    }
    
    func activeIcon(symbolConfig: UIImage.SymbolConfiguration?) -> UIImage? {
        switch(self) {
        case .like:
            return FontAwesome.image(fromChar: "\u{f004}", size: 16, weight: .bold)
        case .repost:
            return FontAwesome.image(fromChar: "\u{f361}", size: 16, weight: .regular)
        case .more:
            return FontAwesome.image(fromChar: "\u{f141}", weight: .bold)
        case .follow:
            return MAMenu.unfollow.image
        case .message:
            return MAMenu.message.image
        case .mention:
            return MAMenu.mention.image
        case .disableReposts:
            return MAMenu.enableReposts.image
        case .addToList:
            return MAMenu.addToList.image
        case .muteOneDay:
            return MAMenu.muteOneDay.image
        case .muteForever:
            return MAMenu.muteForever.image
        case .block:
            return MAMenu.unblock.image
        case .pinPost:
            return  UIImage(systemName: "pin.slash", withConfiguration: symbolConfig)
        default:
            return nil
        }
    }
    
    func tintColor(isActive: Bool) -> UIColor {
        switch(self) {
        case .like:
            if isActive {
                return UIColor.systemPink
            } else {
                return .custom.actionButtons
            }
        case .repost:
            if isActive {
                return UIColor.systemGreen
            } else {
                return .custom.actionButtons
            }
        default:
            return .custom.actionButtons
        }
    }
}

enum PostCardButtonCallbackData {
    case url(URL)
    case hashtag(String)
    case mention((String, Status))
    case email(String)
    case post(PostCardModel)
    case account(Account)
    case user(UserCardModel)
    case list(String)
}

typealias PostCardButtonCallback = (_ type: PostCardButtonType,
                                    _ isActive: Bool,
                                    _ data: PostCardButtonCallbackData?) -> Void

let postCardSymbolConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
