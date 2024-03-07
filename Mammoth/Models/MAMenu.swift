//
//  MAMenu.swift
//  Mammoth
//
//  Created by Jesse Tomchak on 4/19/23.
//  List of labels and icons
//  https://fontawesome.com/v5/cheatsheet/pro/light
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

struct MenuStyle {
    let title: String
    let image: UIImage
}

enum MAMenu {
    case activity
    case messages
    case favorites
    case search
    
    case mention
    case message
    case unfollow
    case follow
    case disableReposts
    case enableReposts
    case topFriends
    case listItem
    case addToList
    case removeFromList
    case enableNotifications
    case disableNotifications
    
    case muteOneDay
    case muteForever
    case unblock
    case block
    case report
    
    case jumpToNewest
    case following
    case federated
    case trendingPosts
    
    case list
    case hashtag
    case community
    case localCommunity
    case newList
    case browseCommunities

    case allActivity
    case sentMentions
    case receivedMentions
    case likes
    case reposts
    
    case recentMedia
    case bookmarks
    case filters
    case explore
    case muted
    case blocked
    case pinnedUsers
    case translateBio
    case editProfile
    case editAvatar
    case editHeader
    case editDetails
    case editInfoAndLinks
}

extension MAMenu {
    private var menuStyle: MenuStyle {
        switch self {
            
        // feed menus
        case .activity:
            return MenuStyle(title: NSLocalizedString("title.activity", comment: ""), image: FontAwesome.image(fromChar: "\u{f0f3}"))
        case .messages:
            return MenuStyle(title: "Messages", image: FontAwesome.image(fromChar: "\u{f0e0}"))
        case .favorites:
            return MenuStyle(title: NSLocalizedString("title.likes", comment: ""), image: FontAwesome.image(fromChar: "\u{f004}"))
        case .search:
            return MenuStyle(title: NSLocalizedString("discover.search", comment: ""), image: FontAwesome.image(fromChar: "\u{f002}"))
            
        // contextual menus
        case .mention: /* @ */
            return MenuStyle(title: "Mention", image: FontAwesome.image(fromChar: "\u{40}"))
        case .message: /* envelop */
            return MenuStyle(title: "Message", image: FontAwesome.image(fromChar: "\u{f0e0}"))
        case .unfollow: /* persion - */
            return MenuStyle(title: "Unfollow", image: FontAwesome.image(fromChar: "\u{f503}"))
        case .follow: /* person + */
            return MenuStyle(title: "Follow", image: FontAwesome.image(fromChar: "\u{f234}"))
        case .disableReposts: /* circle arrows */
            return MenuStyle(title: "Disable Reposts", image: FontAwesome.image(fromChar: "\u{f361}"))
        case .enableReposts: /* circle arrows */
            return MenuStyle(title: "Enable Reposts", image: FontAwesome.image(fromChar: "\u{f361}"))
        case .topFriends: /* star */
            return MenuStyle(title: "Top Friends", image: FontAwesome.image(fromChar: "\u{f03a}"))
        case .listItem: /* bullet list */
            return MenuStyle(title: "List item", image: FontAwesome.image(fromChar: "\u{f0ca}"))
        case .addToList: /* plus sign */
            return MenuStyle(title: NSLocalizedString("list.addTo", comment: ""), image: FontAwesome.image(fromChar: "\u{2b}"))
        case .removeFromList: /* minus sign */
            return MenuStyle(title: NSLocalizedString("list.removeFrom", comment: ""), image: FontAwesome.image(fromChar: "\u{f068}"))
        case .enableNotifications: /* plus sign */
            return MenuStyle(title: "Enable Notifications", image: FontAwesome.image(fromChar: "\u{f0f3}"))
        case .disableNotifications: /* plus sign */
            return MenuStyle(title: "Disable Notifications", image: FontAwesome.image(fromChar: "\u{f1f6}"))
        case .muteOneDay: /* speaker marked out */
            return MenuStyle(title: "Mute 1 Day", image: FontAwesome.image(fromChar: "\u{f2e2}"))
        case .muteForever: /* speech bubble marked out */
            return MenuStyle(title: "Mute Forever", image: FontAwesome.image(fromChar: "\u{f4a9}"))
        case .unblock: /* circle marked out */
            return MenuStyle(title: "Unblock", image: FontAwesome.image(fromChar: "\u{f05e}"))
        case .block: /* circle marked out */
            return MenuStyle(title: "Block", image: FontAwesome.image(fromChar: "\u{f05e}"))
        case .report:
            return MenuStyle(title: "Report", image: FontAwesome.image(fromChar: "\u{f024}"))
        
        // main menus
        case .jumpToNewest: /* arrow-up */
            return MenuStyle(title: "Jump to Newest", image: FontAwesome.image(fromChar: "\u{f062}"))
        case .following:
            return MenuStyle(title: NSLocalizedString("title.following", comment: ""), image: FontAwesome.image(fromChar: "\u{f234}"))
        case .federated:
            return MenuStyle(title: NSLocalizedString("title.federated", comment: ""), image: FontAwesome.image(fromChar: "\u{f57d}"))
        case .trendingPosts:
            return MenuStyle(title: "Trending Posts", image: FontAwesome.image(fromChar: "\u{f06d}"))

            
        case .list:
            return MenuStyle(title: "list", image: FontAwesome.image(fromChar: "\u{f03a}"))
        case .hashtag:
            return MenuStyle(title: "hashtag", image: FontAwesome.image(fromChar: "\u{23}"))
        case .community:
            return MenuStyle(title: "community", image: FontAwesome.image(fromChar: "\u{e594}", weight: .bold))
        case .localCommunity:
            return MenuStyle(title: "local community", image: FontAwesome.image(fromChar: "\u{f0c0}", weight: .bold))
        case .newList:
            return MenuStyle(title: NSLocalizedString("title.newList", comment: ""), image: FontAwesome.image(fromChar: "\u{2b}"))
        case .browseCommunities:
            return MenuStyle(title: NSLocalizedString("title.browseCommunities", comment: ""), image: FontAwesome.image(fromChar: "\u{e03e}"))

        // activity
        case .allActivity:
            return MenuStyle(title: "All Activity", image: FontAwesome.image(fromChar: "\u{f0f3}"))
        case .sentMentions:
            return MenuStyle(title: NSLocalizedString("title.mentionsOut", comment: ""), image: FontAwesome.image(fromChar: "\u{40}"))
        case .receivedMentions:
            return MenuStyle(title: NSLocalizedString("title.mentionsIn", comment: ""), image: FontAwesome.image(fromChar: "\u{40}"))
        case .likes:
            return MenuStyle(title: "Likes", image: FontAwesome.image(fromChar: "\u{f004}"))
        case .reposts:
            return MenuStyle(title: "Reposts", image: FontAwesome.image(fromChar: "\u{f361}"))

        // profile menu
        case .recentMedia:
            return MenuStyle(title: "Recent Media", image: FontAwesome.image(fromChar: "\u{f2bd}"))
        case .bookmarks:
            return MenuStyle(title: NSLocalizedString("title.bookmarks", comment: ""), image: FontAwesome.image(fromChar: "\u{f02e}"))
        case .filters:
            return MenuStyle(title: NSLocalizedString("profile.filters", comment: ""), image: FontAwesome.image(fromChar: "\u{e17e}"))
        case .explore:
            return MenuStyle(title: "Explore", image: FontAwesome.image(fromChar: "\u{e03e}"))
        case .muted:
            return MenuStyle(title: NSLocalizedString("profile.muted", comment: ""), image: FontAwesome.image(fromChar: "\u{f4a9}"))
        case .blocked:
            return MenuStyle(title: NSLocalizedString("profile.blocked", comment: ""), image: FontAwesome.image(fromChar: "\u{f05e}"))
        case .pinnedUsers:
            return MenuStyle(title: "Pinned Users", image: FontAwesome.image(fromChar: "\u{f08d}"))
        case .translateBio:
            return MenuStyle(title: "Translate Bio", image: FontAwesome.image(fromChar: "\u{f0ac}"))
        case .editProfile:
            return MenuStyle(title: "Edit Profile", image: FontAwesome.image(fromChar: "\u{f303}"))

        case .editAvatar:
            return MenuStyle(title: "Edit Avatar", image: FontAwesome.image(fromChar: "\u{f2bd}"))
        case .editHeader:
            return MenuStyle(title: "Edit Header", image: FontAwesome.image(fromChar: "\u{f03e}"))
        case .editDetails:
            return MenuStyle(title: "Edit Details", image: FontAwesome.image(fromChar: "\u{f866}"))
        case .editInfoAndLinks:
            return MenuStyle(title: "Edit Info and Links", image: FontAwesome.image(fromChar: "\u{f0c1}"))
        }
        
            
    }
}

extension MAMenu {
    var image: UIImage {
        return menuStyle.image
    }
    
    var title: String {
        return menuStyle.title
    }
}

