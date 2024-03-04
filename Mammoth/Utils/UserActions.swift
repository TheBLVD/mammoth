//
//  UserActions.swift
//  Mammoth
//
//  Created by Benoit Nolens on 14/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

struct UserActions {
    
    static let didUpdateUserCardNotification = Notification.Name("didUpdateUserCardNotification")
    
    static func onFollowingTap(target: UIViewController, user: UserCardModel) {
        triggerHapticImpact(style: .light)
        let vc = UserListViewController(type: .following, user: user)
        if vc.isBeingPresented {} else {
            target.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    static func onFollowersTap(target: UIViewController, user: UserCardModel) {
        triggerHapticImpact(style: .light)
        let vc = UserListViewController(type: .followers, user: user)
        if vc.isBeingPresented {} else {
            target.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    static func onSettingsTap(target: UIViewController) {
        triggerHapticImpact(style: .light)
        let vc = SettingsViewController()
        target.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    static func onShareTap(target: UIViewController, user: UserCardModel) {
        if let url = user.account?.url, let text = URL(string: url) {
            let textToShare = [text]
            let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)

            if let presenter = activityViewController.popoverPresentationController {
                presenter.sourceView = target.view
                // Magic numbers to point to the gear in the upper right of the view
                let upperRight = CGRect(x: CGRectGetMaxX(target.view.bounds)-40, y: CGRectGetMinY(target.view.bounds)+50, width: 1, height: 1)
                presenter.sourceRect = upperRight // CGRectNull// target.view.bounds
            }
            target.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    static func onFiltersTap(target: UIViewController, user: UserCardModel) {
        triggerHapticImpact(style: .light)
        let vc = FiltersViewController()
        vc.showingSearch = false
        if vc.isBeingPresented {} else {
            target.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    static func onMutedTap(target: UIViewController, user: UserCardModel) {
        triggerHapticImpact(style: .light)
        let vc = UserListViewController(type: .mutes, user: user)
        if vc.isBeingPresented {} else {
            target.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    static func onBlockedTap(target: UIViewController, user: UserCardModel) {
        triggerHapticImpact(style: .light)
        let vc = UserListViewController(type: .blocks, user: user)
        if vc.isBeingPresented {} else {
            target.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    static func onBookmarksTap(target: UIViewController, user: UserCardModel) {
        triggerHapticImpact(style: .light)
        let vc = NewsFeedViewController(type: .bookmarks)
        if vc.isBeingPresented {} else {
            target.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    static func onLikesTap(target: UIViewController, user: UserCardModel) {
        triggerHapticImpact(style: .light)
        let vc = NewsFeedViewController(type: .likes)
        if vc.isBeingPresented {} else {
            target.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    static func onRecentMediaTap(target: UIViewController, user: UserCardModel) {
        triggerHapticImpact(style: .light)
        let vc = GalleryViewController()
        vc.otherUserId = user.id
        if vc.isBeingPresented {} else {
            target.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    static func onHeaderEdit(image: UIImage) {
        AccountsManager.shared.updateCurrentAccountHeader(image)
    }
    
    static func onAvatarEdit(image: UIImage) {
        AccountsManager.shared.updateCurrentAccountAvatar(image)
    }

    static func onEditDetails(target: UIViewController, user: UserCardModel) {
        let vc = EditProfileViewController()
        target.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    static func onEditInfoAndLinks(target: UIViewController, user: UserCardModel) {
        let vc = EditFieldsViewController()
        vc.fields = user.account?.fields ?? []
        target.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    static func onFollow(target: UIViewController, user: Account) {
        FollowManager.shared.followAccount(user)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadFollowing"), object: nil)
    }
    
    static func onUnfollow(target: UIViewController, user: Account) {
        FollowManager.shared.unfollowAccount(user)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadFollowing"), object: nil)
    }
    
    static func onMention(target: UIViewController, user: Account) {
        let vc = NewPostViewController()
        vc.isModalInPresentation = true
        vc.fromPro = true
        vc.proText = "@\(user.remoteFullOriginalAcct) "
        target.present(UINavigationController(rootViewController: vc), animated: true)
    }
    
    static func onMessage(target: UIViewController, user: Account) {
        let vc = NewPostViewController()
        vc.isModalInPresentation = true
        vc.fromPro = true
        vc.proText = "@\(user.remoteFullOriginalAcct) "
        vc.whoCanReply = .direct
        target.present(UINavigationController(rootViewController: vc), animated: true)
    }
    
    static func onMute(target: UIViewController, user: Account) {
        ModerationManager.shared.mute(user: user)
    }
    
    static func onMuteOneDay(target: UIViewController, user: Account) {
        let duration = 86400
        ModerationManager.shared.mute(user: user, durationInSeconds: duration)
    }
    
    static func onBlock(target: UIViewController, user: Account) {
        ModerationManager.shared.block(user: user)
    }
    
    static func addToList(user: Account, listId: String) {
        Task {
            do {
                try await ListManager.shared.addToList(account: user, listId: listId)
                await MainActor.run {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "postListUserAdded"), object: nil)
                    triggerHapticNotification()
                }
            } catch let error {
                log.error("Failed to add to list")
                
                switch error as? ClientError {
                case .mastodonError(let message):
                    if message == "Validation failed: Account has already been taken" {
                        await MainActor.run {
                            let alert = UIAlertController(title: "You have already added this account to your list", message: nil, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.ok", comment: ""), style: .default, handler: nil))
                            getTopMostViewController()?.present(alert, animated: true)
                        }
                    } else {
                        fallthrough
                    }
                default:
                    await MainActor.run {
                        let alert = UIAlertController(title: "Unable to add this account to your list", message: "Please try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.ok", comment: ""), style: .default, handler: nil))
                        getTopMostViewController()?.present(alert, animated: true)
                    }
                }
            }
        }
    }
    
    static func removeFromList(user: Account, listId: String) {
        Task {
            do {
                try await ListManager.shared.removeFromList(account: user, listId: listId)
                await MainActor.run {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "postUnVIP"), object: nil)
                    triggerHapticNotification()
                }
            }
        }
    }
    
    static func enableNotifications(user: Account) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "userNotifsEnabled"), object: nil)
        Task {
            do {
                try await AccountService.enableNotifications(user: user)
                let _ = FollowManager.shared.relationshipForAccount(user, requestUpdate: true)
            } catch let error {
                log.error("error enabling alerts - \(error)")
            }
        }
    }
    
    static func disableNotifications(user: Account) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "userNotifsDisabled"), object: nil)
        Task {
            do {
                try await AccountService.disableNotifications(user: user)
                let _ = FollowManager.shared.relationshipForAccount(user, requestUpdate: true)
            } catch let error {
                log.error("error disabling alerts - \(error)")
            }
        }
    }
    
    static func enableReposts(user: Account) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "userRepostsEnabled"), object: nil)
        Task {
            do {
                try await AccountService.enableReposts(user: user)
                let _ = FollowManager.shared.relationshipForAccount(user, requestUpdate: true)
            } catch let error {
                log.error("error enabling reposts - \(error)")
            }
        }
    }
    
    static func disableReposts(user: Account) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "userRepostsDisabled"), object: nil)
        Task {
            do {
                try await AccountService.disableReposts(user: user)
                let _ = FollowManager.shared.relationshipForAccount(user, requestUpdate: true)
            } catch let error {
                log.error("error disabling reposts - \(error)")
            }
        }
    }
    
    static func report(account: Account) {
        let alert = UIAlertController(title: "Report this user?", message: "We'll notify your instance’s moderator.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Report user", style: .destructive , handler:{ (UIAlertAction) in
            Task {
                do {
                    try await AccountService.report(user: account, withPolicy: .retryLocally)
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "userReported"), object: nil)
                    }
                } catch let error {
                    log.error("error reporting user - \(error)")
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        getTopMostViewController()?.present(alert, animated: true, completion: nil)
    }
    
}
