//
//  PostActions.swift
//  Mammoth
//
//  Created by Jesse Tomchak on 4/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import NaturalLanguage
import SafariServices
import UIKit

struct PostActions {
    static func onActionPress(target: UIViewController, type: PostCardButtonType, isActive: Bool, postCard: PostCardModel, data: PostCardButtonCallbackData?) {
        switch(type) {
        case .reply:
            PostActions.onReply(target: target, postCard: postCard)
        case .like:
            if !isActive {
                PostActions.onLike(postCard: postCard, withFetchPolicy: .retryLocally)
            } else {
                PostActions.onUnLike(postCard: postCard, withFetchPolicy: .retryLocally)
            }
        case .repost:
            if !isActive {
                PostActions.onRepost(postCard: postCard, withFetchPolicy: .retryLocally)
            } else {
                PostActions.onUnrepost(postCard: postCard, withFetchPolicy: .retryLocally)
            }
        case .quote:
            guard case .mastodon(let status) = postCard.data else { return }
            PostActions.presentQuotePostComposer(target: target, stat: status)
        case .bookmark:
            PostActions.onBookmark(postCard: postCard, withFetchPolicy: .retryLocally)
        case .unbookmark:
            PostActions.onUnbookmark(postCard: postCard, withFetchPolicy: .retryLocally)
            
        case .share:
            switch(data) {
            case .url(let url):
                PostActions.onShare(target: target, url: url)
            default:
                PostActions.onShare(target: target, postCard: postCard)
                break
            }
            
        case .copy:
            switch(data) {
            case .url(let url):
                PostActions.onCopy(target: target, url: url)
            default:
                PostActions.onCopy(target: target, postCard: postCard)
                break
            }
            
        case .translate:
            PostActions.onTranslate(target: target, postCard: postCard)
        case .viewInBrowser:
            PostActions.onViewInBrowser(postCard: postCard)
            
        case .link:
            switch(data) {
            case .url(let url):
                PostActions.onURLPress(url: url)
            case .hashtag(let hashtag):
                PostActions.onHashtagPress(target: target, hashtag: hashtag)
            case .mention((let mention, let status)):
                PostActions.onMentionPress(target: target, mention: mention, status: status)
            default:
                break
            }
            
        case .profile:
            switch data {
            case .user(let userCardModel):
                PostActions.onProfilePress(target: target, user: userCardModel)
            case .account(let account):
                PostActions.onProfilePress(target: target, account: account)
            default:
                PostActions.onProfilePress(target: target, postCard: postCard)
            }
            
        case .postDetails:
            switch(data) {
            case .post(let postCard):
                PostActions.onPostPress(target: target, postCard: postCard)
            default:
                break
            }
    
        case .editPost:
            PostActions.onEditPost(target: target, postCard: postCard)
        case .deletePost:
            PostActions.onDeletePost(target: target, postCard: postCard)
        case .pinPost:
            if !isActive {
                PostActions.onPinPost(target: target, postCard: postCard)
            } else {
                PostActions.onUnpinPost(target: target, postCard: postCard)
            }
            
        case .mention:
            guard let account = postCard.account else { break }
            UserActions.onMention(target: target, user: account)
            
        case .message:
            guard let account = postCard.account else { break }
            UserActions.onMessage(target: target, user: account)
            
        case .follow:
            guard let account = postCard.account else { break }
            if isActive {
                UserActions.onFollow(target: target, user: account)
            } else {
                UserActions.onUnfollow(target: target, user: account)
            }
            
        case .muteOneDay:
            guard let account = postCard.account else { break }
            UserActions.onMuteOneDay(target: target, user: account)
            
        case .muteForever:
            guard let account = postCard.account else { break }
            UserActions.onMute(target: target, user: account)
            
        case .unmute:
            guard let account = postCard.account else { break }
            ModerationManager.shared.unmute(user: account)
            
        case .block:
            guard let account = postCard.account else { break }
            UserActions.onBlock(target: target, user: account)
            
        case .unblock:
            guard let account = postCard.account else { break }
            ModerationManager.shared.unblock(user: account)
            
        case .reportUser:
            guard let account = postCard.account else { break }
            UserActions.report(account: account)
            
        case .reportPost:
            PostActions.report(postCard: postCard)
            
        case .addToList:
            guard let account = postCard.account else { break }
            if case .list(let listId) = data {
                UserActions.addToList(user: account, listId: listId)
            }
            break
        case .removeFromList:
            guard let account = postCard.account else { break }
            if case .list(let listId) = data {
                UserActions.removeFromList(user: account, listId: listId)
            }
            break
        case .createNewList:
            let vc = AltTextViewController()
            vc.newList = true
            target.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
            break
            
        case .likes:
            guard case .mastodon(_) = postCard.data else { return }
            triggerHapticImpact(style: .light)
            let vc = UserListViewController(type: .likes, post: postCard)
            target.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        case .replies:
            let vc = DetailViewController(post: postCard, showStatusSource: true, scrollToReplies: true)
            if vc.isBeingPresented {} else {
                target.navigationController?.pushViewController(vc, animated: true)
            }
            break
        case .reposts:
            guard case .mastodon(_) = postCard.data else { return }
            triggerHapticImpact(style: .light)
            let vc = UserListViewController(type: .reposts, post: postCard)
            target.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        default:
            break
        }
    }
    
    static func onActionPress(target: UIViewController, type: PostCardButtonType, isActive: Bool, userCard: UserCardModel, data: PostCardButtonCallbackData?) {
        switch(type) {

        case .share:
            if let url = URL(string: userCard.account?.url ?? "") {
                PostActions.onShare(target: target, url: url)
            }
            
        case .copy:
            switch(data) {
            case .url(let url):
                PostActions.onCopy(target: target, url: url)
            default:
                break
            }

        case .link:
            switch(data) {
            case .url(let url):
                PostActions.onURLPress(url: url)
            case .hashtag(let hashtag):
                PostActions.onHashtagPress(target: target, hashtag: hashtag)
            case .mention((let mention, let status)):
                PostActions.onMentionPress(target: target, mention: mention, status: status)
            case .email(let email):
                PostActions.onEmailPress(email: email)
            default:
                break
            }
            
        case .profile:
            switch data {
            case .user(let userCardModel):
                PostActions.onProfilePress(target: target, user: userCardModel)
            case .account(let account):
                PostActions.onProfilePress(target: target, account: account)
            default:
                break
            }
            
        case .postDetails:
            switch(data) {
            case .post(let postCard):
                PostActions.onPostPress(target: target, postCard: postCard)
            default:
                break
            }
            
        case .mention:
            guard let account = userCard.account else { break }
            UserActions.onMention(target: target, user: account)
            
        case .message:
            guard let account = userCard.account else { break }
            UserActions.onMessage(target: target, user: account)
            
        case .follow:
            guard let account = userCard.account else { break }
            if isActive {
                UserActions.onFollow(target: target, user: account)
            } else {
                UserActions.onUnfollow(target: target, user: account)
            }
            
        case .muteOneDay:
            guard let account = userCard.account else { break }
            UserActions.onMuteOneDay(target: target, user: account)
            
        case .muteForever:
            guard let account = userCard.account else { break }
            UserActions.onMute(target: target, user: account)
            
        case .unmute:
            guard let account = userCard.account else { break }
            ModerationManager.shared.unmute(user: account)
            
        case .block:
            guard let account = userCard.account else { break }
            UserActions.onBlock(target: target, user: account)
            
        case .unblock:
            guard let account = userCard.account else { break }
            ModerationManager.shared.unblock(user: account)
            
        case .addToList:
            guard let account = userCard.account else { break }
            if case .list(let listId) = data {
                UserActions.addToList(user: account, listId: listId)
            }
            break
        case .removeFromList:
            guard let account = userCard.account else { break }
            if case .list(let listId) = data {
                UserActions.removeFromList(user: account, listId: listId)
            }
            break
        case .createNewList:
            let vc = AltTextViewController()
            vc.newList = true
            target.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
            break
            
        default:
            break
        }
    }
}

extension PostActions {
    
    static let didUpdatePostCardNotification = Notification.Name("didUpdatePostCardNotification")
    
    static func presentQuotePostComposer(target: UIViewController, stat: Status?) {
        triggerHapticImpact(style: .light)
        
        guard let stat else { return }
        
        let vc = NewPostViewController()
        let embeddedStatusComponents = URLComponents(string: (stat.reblog?.url ?? stat.url) ?? "")
        vc.quotedAccount = stat.reblog?.account ?? stat.account ?? nil
        vc.isModalInPresentation = true
        vc.isQuotePost = true
        vc.fromPro = true
        vc.placeCursorAtEndOfText = false
        
        vc.proText = "\n\nRE: \(embeddedStatusComponents?.string ?? "")"
        target.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    // Handler call when pressing the reply button on a post
    static func onReply(target: UIViewController, postCard: PostCardModel) {
        guard case .mastodon(let status) = postCard.preSyncData ?? postCard.data else { return }
        
        let vc = NewPostViewController()
        vc.isModalInPresentation = true
        vc.inReplyId = "ID Requires Search"
        vc.allStatuses = [status]
        target.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    // Handler call when pressing the like button on a post
    static func onLike(postCard: PostCardModel, withFetchPolicy fetchPolicy: StatusService.FetchPolicy = .retryLocally) {
        if let uniqueId = postCard.uniqueId {
            // Optimistically update local cache
            StatusCache.shared.addLocalMetric(metricType: .like, statusId: uniqueId)
            postCard.likeTap()
            
            // Consolidate list data with updated post card data and request a cell refresh
            NotificationCenter.default.post(name: didUpdatePostCardNotification, object: nil, userInfo: ["postCard": postCard])
            
            Sound().playSound(named: "soundMallet", withVolume: 1)

            // HTTP request
            Task {
                do {
                    guard let _ = try await StatusService.like(postCard: postCard, withPolicy: fetchPolicy) else { return }
                    
                    // Enable this for Bluesky
                    // NotificationCenter.default.post(name: didUpdatePostCardNotification, object: nil, userInfo: ["postCard": postCard])
                } catch {
                    log.error("onLike error: \(error)")
                    StatusCache.shared.removeLocalMetric(metricType: .like, statusId: uniqueId)
                }
            }
        }
    }
    
    // Handler call when pressing the unlike button on a post
    static func onUnLike(postCard: PostCardModel, withFetchPolicy fetchPolicy: StatusService.FetchPolicy = .retryLocally) {
        if let uniqueId = postCard.uniqueId {
            // Optimistically update local cache
            StatusCache.shared.removeLocalMetric(metricType: .like, statusId: uniqueId)
            postCard.unlikeTap()
            
            // Consolidate list data with updated post card data and request a cell refresh
            NotificationCenter.default.post(name: didUpdatePostCardNotification, object: nil, userInfo: ["postCard": postCard])
            
            // HTTP request
            Task {
                do {
                    guard let _ = try await StatusService.unlike(postCard: postCard, withPolicy: fetchPolicy) else { return }
                    
                    // Enable this for Bluesky
                    // NotificationCenter.default.post(name: didUpdatePostCardNotification, object: nil, userInfo: ["postCard": postCard])
                } catch {
                    log.error("onUnlike error: \(error)")
                }
            }
        }
    }
    
    // Handler call when pressing the repost button on a post
    static func onRepost(postCard: PostCardModel, withFetchPolicy fetchPolicy: StatusService.FetchPolicy = .retryLocally) {
        if let uniqueId = postCard.uniqueId {
            // Optimistically update local cache
            StatusCache.shared.addLocalMetric(metricType: .repost, statusId: uniqueId)
            
            postCard.repostTap()
            
            // Consolidate list data with updated post card data and request a cell refresh
            NotificationCenter.default.post(name: didUpdatePostCardNotification, object: nil, userInfo: ["postCard": postCard])
            
            // HTTP request
            Task {
                do {
                    let _ = try await StatusService.repost(postCard: postCard, withPolicy: fetchPolicy)
                    
                    DispatchQueue.main.async {
                        if let returnedText = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.returnedText {
                            GlobalStruct.actionFromInstance = String.localizedStringWithFormat(NSLocalizedString("toast.repostedFrom", comment: ""), returnedText)
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "actionFrom"), object: nil)
                        }
                    }
                } catch let error {
                    log.error("onRepost error: \(error)")
                }
            }
        }
    }
    
    // Handler call when pressing the unrepost button on a post
    static func onUnrepost(postCard: PostCardModel, withFetchPolicy fetchPolicy: StatusService.FetchPolicy = .retryLocally) {
        if let uniqueId = postCard.uniqueId {
            // Optimistically update local cache
            StatusCache.shared.removeLocalMetric(metricType: .repost, statusId: uniqueId)
            
            postCard.unrepostTap()
            
            // Consolidate list data with updated post card data and request a cell refresh
            NotificationCenter.default.post(name: didUpdatePostCardNotification, object: nil, userInfo: ["postCard": postCard])
            
            // HTTP request
            Task {
                do {
                    let _ = try await StatusService.unRepost(postCard: postCard, withPolicy: fetchPolicy)
                    
                } catch {
                    log.error("onUnrepost error: \(error)")
                }
            }
        }
    }
    
    // Handler call when pressing the bookmark button on a post
    static func onBookmark(postCard: PostCardModel, withFetchPolicy fetchPolicy: StatusService.FetchPolicy = .retryLocally) {
        guard case .mastodon(let status) = postCard.preSyncData ?? postCard.data else { return }
        
        if let uniqueId = postCard.uniqueId {
            // Optimistically update local cache
            StatusCache.shared.addLocalMetric(metricType: .bookmark, statusId: uniqueId)

            DispatchQueue.main.async {
                // Consolidate list data with updated post card data and request a cell refresh
                NotificationCenter.default.post(name: didUpdatePostCardNotification, object: nil, userInfo: ["postCard": postCard])
            }

            // HTTP request
            Task {
                do {
                    let _ = try await StatusService.bookmark(status: status, withPolicy: fetchPolicy)

                    DispatchQueue.main.async {
                        // Display toast
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "postBookmarked"), object: nil)
                    }
                } catch {
                    log.error("onBookmark error: \(error)")
                }
            }
        }
    }
    
    // Handler call when pressing the unbookmark button on a post
    static func onUnbookmark(postCard: PostCardModel, withFetchPolicy fetchPolicy: StatusService.FetchPolicy = .retryLocally) {
        guard case .mastodon(let status) = postCard.preSyncData ?? postCard.data else { return }
        
        if let uniqueId = postCard.uniqueId {
            // Optimistically update local cache
            StatusCache.shared.removeLocalMetric(metricType: .bookmark, statusId: uniqueId)
            
            DispatchQueue.main.async {
                // Consolidate list data with updated post card data and request a cell refresh
                NotificationCenter.default.post(name: didUpdatePostCardNotification, object: nil, userInfo: ["postCard": postCard])
            }

            // HTTP request
            Task {
                do {
                    let _ = try await StatusService.unbookmark(status: status, withPolicy: fetchPolicy)
                    
                    DispatchQueue.main.async {
                        // Display toast
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "postUnbookmarked"), object: nil)
                    }
                } catch {
                    log.error("onUnbookmark error: \(error)")
                }
            }
        }
    }
    
    static func onEditPost(target: UIViewController, postCard: PostCardModel) {
        guard case .mastodon(let status) = postCard.preSyncData ?? postCard.data else { return }
        
        triggerHapticImpact(style: .light)
        
        let vc0 = NewPostViewController()
        vc0.fromEdit = status
        let vc = UINavigationController(rootViewController: vc0)
        vc.isModalInPresentation = true
        target.present(vc, animated: true, completion: nil)
    }
    
    static func onDeletePost(target: UIViewController, postCard: PostCardModel, withFetchPolicy fetchPolicy: StatusService.FetchPolicy = .retryLocally) {
        guard case .mastodon(let status) = postCard.preSyncData ?? postCard.data else { return }
        
        let alert = UIAlertController(title: nil, message: NSLocalizedString("post.delete.confirm", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.delete", comment: ""), style: .destructive , handler:{ (UIAlertAction) in
            
            Task {
                do {
                    let _ = try await StatusService.delete(status: status, withPolicy: fetchPolicy)
                    
                    print("deleted post - \(status.id ?? "")")
                    
                    DispatchQueue.main.async {
                        triggerHapticNotification()
                        
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "postDeleted"), object: nil)
                        GlobalStruct.idToDelete = status.reblog?.id ?? status.id ?? ""
                        
                        // Consolidate list data with updated post card data and request a cell refresh
                        NotificationCenter.default.post(name: PostActions.didUpdatePostCardNotification, object: nil, userInfo: ["deleted": true, "postCard": postCard])
                        
                        target.navigationController?.popViewController(animated: true)
                    }
                } catch {
                    log.error("delete error: \(error)")
                    
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler: nil))
        
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = getTopMostViewController()?.view
            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
        }
        getTopMostViewController()?.present(alert, animated: true, completion: nil)
    }
    
    // Handler call when pressing the pin post button on a post
    static func onPinPost(target: UIViewController, postCard: PostCardModel, withFetchPolicy fetchPolicy: StatusService.FetchPolicy = .retryLocally) {
        guard case .mastodon(let status) = postCard.preSyncData ?? postCard.data else { return }
        triggerHaptic3Notification()
        
        // HTTP request
        Task {
            do {
                let _ = try await StatusService.pin(status: status, withPolicy: fetchPolicy)

                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "postPinned"), object: nil)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadPinned"), object: nil)
                }
            } catch {
                log.error("onPin post error: \(error)")
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: NSLocalizedString("error.pin", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("generic.ok", comment: ""), style: .default, handler: nil))
                    target.present(alert, animated: true)
                }
            }
        }
    }
    
    // Handler call when pressing the unpin post button on a post
    static func onUnpinPost(target: UIViewController, postCard: PostCardModel, withFetchPolicy fetchPolicy: StatusService.FetchPolicy = .retryLocally) {
        guard case .mastodon(let status) = postCard.preSyncData ?? postCard.data else { return }
        
        triggerHaptic3Notification()

        // HTTP request
        Task {
            do {
                let _ = try await StatusService.unpin(status: status, withPolicy: fetchPolicy)

                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "postUnpinned"), object: nil)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadPinned"), object: nil)
                }
            } catch {
                log.error("onUnpin post error: \(error)")
            }
        }
    }
    
    static func onShare(target: UIViewController, postCard: PostCardModel) {
        guard case .mastodon(let status) = postCard.preSyncData ?? postCard.data else { return }
        
        let text = URL(string: "\(status.reblog?.url ?? status.url ?? "")")!
        self.onShare(target: target, url: text)
    }
    
    static func onShare(target: UIViewController, url: URL) {
        let textToShare = [url]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = target.view
        target.present(activityViewController, animated: true, completion: nil)
    }
    
    static func onViewInBrowser(postCard: PostCardModel) {
        guard case .mastodon(let status) = postCard.preSyncData ?? postCard.data else { return }
        
        if let str = status.reblog?.url ?? status.url {
            if let url = URL(string: str) {
                PostActions.openLink(url, fromViewInBrowser: true)
            }
        }
    }
    
    static func onCopy(target: UIViewController, url: URL) {
        UIPasteboard.general.string = url.absoluteString
    }
    
    static func onCopy(target: UIViewController, postCard: PostCardModel) {
        guard case .mastodon(let status) = postCard.data else { return }
        
        if let str = status.reblog?.url ?? status.url {
            if let url = URL(string: str) {
                PostActions.onCopy(target: target, url: url)
            }
        }
    }
    
    static func onTranslate(target: UIViewController, postCard: PostCardModel) {
        guard case .mastodon(let status) = postCard.data else { return }
        
        let unreserved = "-._~/?"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        let bodyText = status.reblog?.content.stripHTML() ?? status.content.stripHTML()
        let unreservedChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        let unreservedCharset = NSCharacterSet(charactersIn: unreservedChars)
        var trans = bodyText.addingPercentEncoding(withAllowedCharacters: unreservedCharset as CharacterSet)
        trans = trans!.replacingOccurrences(of: "\n\n", with: "%20")
        let urlString = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=\(GlobalStruct.langStr)&dt=t&q=\(trans!)&ie=UTF-8&oe=UTF-8"
        guard let requestUrl = URL(string:urlString) else {
            return
        }
        let request = URLRequest(url:requestUrl)
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if error == nil, let usableData = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: usableData, options: .mutableContainers) as! [Any]
                    var translatedText = ""
                    for i in (json[0] as! [Any]) {
                        translatedText = translatedText + ((i as! [Any])[0] as? String ?? "")
                    }
                    translatedText = translatedText.removingUrls()
                    if translatedText == "" {
                        translatedText = bodyText
                    }
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: nil, message: translatedText, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.copy", comment: ""), style: .default , handler:{ (UIAlertAction) in
                            UIPasteboard.general.string = translatedText
                        }))
                        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
                            
                        }))
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.alignment = NSTextAlignment.left
                        let messageText = NSMutableAttributedString(
                            string: translatedText,
                            attributes: [
                                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                                NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
                            ]
                        )
                        alert.setValue(messageText, forKey: "attributedMessage")
                        if let presenter = alert.popoverPresentationController {
                            presenter.sourceView = getTopMostViewController()?.view
                            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                        }
                        getTopMostViewController()?.present(alert, animated: true, completion: nil)
                    }
                } catch let error as NSError {
                    log.error(error.localizedDescription)
                }
            }
        }
        task.resume()
    }
    
    static func onHashtagPress(target: UIViewController, hashtag: String) {
        triggerHapticImpact(style: .light)
        let vc = NewsFeedViewController(type: .hashtag(Tag(name: hashtag, url: "")))
        if vc.isBeingPresented {} else {
            target.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    static func onURLPress(url: URL) {
        triggerHapticImpact(style: .light)
        
        self.openLink(url)
    }
    
    static func onEmailPress(email: String) {
        triggerHapticImpact(style: .light)
        
        let mailtoString = "mailto:\(email)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if let mailtoUrl = URL(string: mailtoString!) {
            UIApplication.shared.open(mailtoUrl, options: [:])
        }
    }
    
    static func onMentionPress(target: UIViewController, mention: String, status: Status) {
        triggerHapticImpact(style: .light)
        
        let mentions = status.reblog?.mentions ?? status.mentions
        if let fi = mentions.first(where: { x in
            x.username == mention
        }) {
            let vc = ProfileViewController(fullAcct: fi.acct, serverName: Account.server(fromUrl: fi.url))
            if vc.isBeingPresented {} else {
                target.navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            // If quote post mention but missing "mentions" array in the status, get the server out of the quote post url
            if let quotePostCard = status.reblog?.quotePostCard() ?? status.quotePostCard(), let url = URL(string: quotePostCard.url ?? ""), let host = url.host {
                let vc = ProfileViewController(fullAcct: mention, serverName: host)
                if vc.isBeingPresented {} else {
                  target.navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                let vc = ProfileViewController(fullAcct: mention)
                if vc.isBeingPresented {} else {
                    target.navigationController?.pushViewController(vc, animated: true)
                }
            }
            
        }
        
    }
    
    static func onMentionPress(target: UIViewController, mention: String, serverName: String) {
        triggerHapticImpact(style: .light)
        let vc = ProfileViewController(fullAcct: mention, serverName: serverName)
        if vc.isBeingPresented {} else {
            target.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    static func onProfilePress(target: UIViewController, postCard: PostCardModel) {
        if let user = postCard.user {
            self.onProfilePress(target: target, user: user)
        }
    }
    
    static func onProfilePress(target: UIViewController, account: Account) {
        triggerHapticImpact(style: .light)
        
        let userCardModel = UserCardModel(account: account, requestFollowStatusUpdate: .whenUncertain)
        let isSelf = account.remoteFullOriginalAcct == AccountsManager.shared.currentUser()?.remoteFullOriginalAcct
        let profileVC = ProfileViewController(user: userCardModel, screenType: isSelf ? .own : .others)
        if profileVC.isBeingPresented {} else {
            target.navigationController?.pushViewController(profileVC, animated: true)
        }
    }
    
    static func onProfilePress(target: UIViewController, user: UserCardModel) {
        triggerHapticImpact(style: .light)
        
        let isSelf = user.account?.remoteFullOriginalAcct == AccountsManager.shared.currentUser()?.remoteFullOriginalAcct
        let profileVC = ProfileViewController(user: user, screenType: isSelf ? .own : .others)
        if profileVC.isBeingPresented {} else {
            target.navigationController?.pushViewController(profileVC, animated: true)
        }
    }
    
    static func onPostPress(target: UIViewController, postCard: PostCardModel) {
        triggerHapticImpact(style: .light)
        
        guard case .mastodon(_) = postCard.data else { return }
        
        let vc = DetailViewController(post: postCard)
        if vc.isBeingPresented {} else {
            target.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    static func openLink(_ url: URL, fromViewInBrowser: Bool = false) {
        // will attempt to open Mastodon links in-app first
        if GlobalStruct.canLoadLink {
            GlobalStruct.canLoadLink = false
            let url2 = url.absoluteString
            if fromViewInBrowser == false {
                if url.isPostURL() {
                    triggerHapticImpact(style: .light)
                    let id = url.postIDFromURL()
                    if !id.isEmpty {
                        let request = Statuses.status(id: id)
                        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
                            if let error = statuses.error {
                                log.error("Failed to fetch status: \(error)")
                                DispatchQueue.main.async {
                                    self.openLinksB(url: url, url2: url2, id: id)
                                }
                            }
                            if let stat = (statuses.value) {
                                DispatchQueue.main.async {
                                    let vc = DetailViewController(post: PostCardModel(status: stat))
                                    if GlobalStruct.isCompact || UIDevice.current.userInterfaceIdiom == .phone {
                                        UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                                        GlobalStruct.canLoadLink = true
                                    } else {
                                        UIApplication.topViewController()?.present(UINavigationController(rootViewController: vc), animated: true)
                                        GlobalStruct.canLoadLink = true
                                    }
                                }
                            }
                        }
                    } else {
                        PostActions.openLinks2(url2)
                    }
                } else if url.isAccountURL() {
                    let split = url2.split(separator: "/")
                    let last = split[split.count - 1]
                    if "\(last)".first == "@" {
                        // go to user
                        triggerHapticImpact(style: .light)
                        let request = Search.search(query: url2, resolve: true)
                        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
                            if let error = statuses.error {
                                log.error("Failed to search: \(error)")
                                DispatchQueue.main.async {
                                    PostActions.openLinks2(url2)
                                }
                            }
                            if let stat = (statuses.value) {
                                DispatchQueue.main.async {
                                    if let account = stat.accounts.first {
                                        let userCardModel = UserCardModel(account: account, requestFollowStatusUpdate: .whenUncertain)
                                        let isSelf = account.fullAcct == AccountsManager.shared.currentUser()?.fullAcct
                                        let profileVC = ProfileViewController(user: userCardModel, screenType: isSelf ? .own : .others)
                                        
                                        if GlobalStruct.isCompact || UIDevice.current.userInterfaceIdiom == .phone {
                                            UIApplication.topViewController()?.navigationController?.pushViewController(profileVC, animated: true)
                                            GlobalStruct.canLoadLink = true
                                        } else {
                                            UIApplication.topViewController()?.present(UINavigationController(rootViewController: profileVC), animated: true)
                                            GlobalStruct.canLoadLink = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    PostActions.openLinks2(url2)
                }
            } else {
                PostActions.openLinks2(url2)
            }
        }
    }
    
    static func openLinksB(url: URL, url2: String, id: String) {
        // this is used when opening Mastodon links in-app from other instances
        let instance = "\(url2.replacingOccurrences(of: "https://", with: "").split(separator: "/").first ?? "")"
        let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken
        let currentClient = Client(
            baseURL: "https://\(instance)",
            accessToken: accessToken
        )
        let request = Statuses.status(id: id)
        currentClient.run(request) { (statuses) in
            if let error = statuses.error {
                log.error("Failed to fetch status: \(error)")
                DispatchQueue.main.async {
                    GlobalStruct.canLoadLink = true
                    PostActions.openLinks2(url2)
                }
            }
            if let stat = (statuses.value) {
                DispatchQueue.main.async {
                    let vc = DetailViewController(post: PostCardModel(status: stat))
                    if GlobalStruct.isCompact || UIDevice.current.userInterfaceIdiom == .phone {
                        UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                        GlobalStruct.canLoadLink = true
                    } else {
                        UIApplication.topViewController()?.present(UINavigationController(rootViewController: vc), animated: true)
                        GlobalStruct.canLoadLink = true
                    }
                }
            }
        }
    }
    
    // This is used when opening external links that aren't Mastodon links
    static func openLinks2(_ url: String) {
        // Add an https prefix if necessary
        var urlString = url
        if !urlString.hasPrefix("http") {
            urlString = "https://\(urlString)"
        }

        // Open URL in a window, or the browser
        if let urlToOpen = URL(string: urlString) {
            if GlobalStruct.openLinksInBrowser {
                UIApplication.shared.open(urlToOpen)
                GlobalStruct.canLoadLink = true
            } else {
                let config = SFSafariViewController.Configuration()
                let vc = SFSafariViewController(url: urlToOpen, configuration: config)
                getTopMostViewController()?.present(vc, animated: true)
                GlobalStruct.canLoadLink = true
            }
        } else {
            log.error("Unable to convert to URL: \(urlString)")
        }
    }
    
    static func onVote(postCard: PostCardModel, choices: [Int]) {
        Task {
            do {
                if case .mastodon(let status) = postCard.data {
                    let localStatus = try await StatusService.getLocalStatus(status: status)
                    if let pollId = localStatus?.reblog?.poll?.id ?? localStatus?.poll?.id {
                        let poll = try await PollService.vote(pollId: pollId, choices: choices)
                        log.debug("Vote Sent")
                        DispatchQueue.main.async {
                            triggerHapticNotification()
                            
                            GlobalStruct.votedOnPolls[pollId] = poll
                            do {
                                try Disk.save(GlobalStruct.votedOnPolls, to: .documents, as: "votedOnPolls.json")
                            } catch {
                                log.error("error saving votedOnPolls to Disk")
                            }
                            
                            // Consolidate list data with updated post card data and request a cell refresh
                            NotificationCenter.default.post(name: didUpdatePostCardNotification, object: nil, userInfo: ["postCard": postCard.withNewPoll(poll: poll)])
                            
                            // Display success toast
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "pollVoted"), object: nil)
                        }
                    }
                }
            } catch let error {
                if "\(error)".contains("ended") {
                    DispatchQueue.main.async {
                        triggerHapticNotification(feedback: .warning)
                        let alert = UIAlertController(title: NSLocalizedString("poll.ended.title", comment: ""),
                                                      message: NSLocalizedString("poll.ended.message", comment: ""),
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler: nil))
                        
                        if let presenter = alert.popoverPresentationController {
                            presenter.sourceView = getTopMostViewController()?.view
                            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                        }
                        getTopMostViewController()?.present(alert, animated: true, completion: nil)
                    }
                } else if "\(error)".contains("already voted") {
                    DispatchQueue.main.async {
                        triggerHapticNotification(feedback: .warning)
                        
                        let alert = UIAlertController(title: NSLocalizedString("poll.already.title", comment: ""),
                                                      message: NSLocalizedString("poll.already.message", comment: ""),
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler: nil))
                        
                        if let presenter = alert.popoverPresentationController {
                            presenter.sourceView = getTopMostViewController()?.view
                            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                        }
                        getTopMostViewController()?.present(alert, animated: true, completion: nil)
                    }
                }
                
                DispatchQueue.main.async {
                    // Consolidate list data with updated post card data and request a cell refresh
                    NotificationCenter.default.post(name: didUpdatePostCardNotification, object: nil, userInfo: ["postCard": postCard])
                }
            }
        }
    }
    
    static func report(postCard: PostCardModel, withFetchPolicy fetchPolicy: StatusService.FetchPolicy = .retryLocally) {
        guard let accountID = postCard.account?.id, case .mastodon(let status) = postCard.preSyncData ?? postCard.data else { return }
        
        let alert = UIAlertController(title: NSLocalizedString("post.report.title", comment: ""), message: NSLocalizedString("post.report.text", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("post.report", comment: ""), style: .destructive , handler:{ (UIAlertAction) in
            Task {
                do {
                    try await StatusService.report(accountID: accountID, status: status, withPolicy: .retryLocally)
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "postReported"), object: nil)
                    }
                } catch let error {
                    log.error("error reporting post - \(error)")
                }
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.cancel", comment: ""), style: .cancel))
        getTopMostViewController()?.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Legacy functions (deprecated)
// Moved out of deleted FirstViewController
extension PostActions {
    static func translateString(_ string: String) {
        let unreserved = "-._~/?"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        let bodyText = string
        let unreservedChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        let unreservedCharset = NSCharacterSet(charactersIn: unreservedChars)
        var trans = bodyText.addingPercentEncoding(withAllowedCharacters: unreservedCharset as CharacterSet)
        trans = trans!.replacingOccurrences(of: "\n\n", with: "%20")
        let urlString = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=\(GlobalStruct.langStr)&dt=t&q=\(trans!)&ie=UTF-8&oe=UTF-8"
        guard let requestUrl = URL(string:urlString) else {
            return
        }
        let request = URLRequest(url:requestUrl)
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if error == nil, let usableData = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: usableData, options: .mutableContainers) as! [Any]
                    var translatedText = ""
                    for i in (json[0] as! [Any]) {
                        translatedText = translatedText + ((i as! [Any])[0] as? String ?? "")
                    }
                    translatedText = translatedText.removingUrls()
                    if translatedText == "" {
                        translatedText = string
                    }
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: nil, message: translatedText, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.copy", comment: ""), style: .default , handler:{ (UIAlertAction) in
                            UIPasteboard.general.string = translatedText
                        }))
                        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
                            
                        }))
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.alignment = NSTextAlignment.left
                        let messageText = NSMutableAttributedString(
                            string: translatedText,
                            attributes: [
                                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                                NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
                            ]
                        )
                        alert.setValue(messageText, forKey: "attributedMessage")
                        if let presenter = alert.popoverPresentationController {
                            presenter.sourceView = getTopMostViewController()?.view
                            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                        }
                        getTopMostViewController()?.present(alert, animated: true, completion: nil)
                    }
                } catch let error as NSError {
                    log.error(error.localizedDescription)
                }
            }
        }
        task.resume()
    }
}
