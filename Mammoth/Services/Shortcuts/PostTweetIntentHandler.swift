//
//  PostTweetIntentHandler.swift
//  Mammoth
//
//  Created by Josh Holtz on 6/3/21.
//  Thank you for letting me add this!
//  Aviary and Shihab are the best <3
//

import Foundation
import UIKit
import Intents
import Combine
import UniformTypeIdentifiers

class PostTweetIntentHandler: NSObject, PostTweetIntentHandling {
    private enum OhNo: Error {
        case postImage
    }
    
    // Accounts are loaded in SceneDelegate but if main app is kill off or not started
    // the accounts will not be loaded. If the accounts are empty, we will try to load them
    private func loadAccountsIfNeeded() {
//        if GlobalStruct.allAccounts.isEmpty {
//            GlobalStruct.loadAccounts()
//        }
    }
    
    func resolveAccount(for intent: PostTweetIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        guard let account = intent.account else {
            let allNames = Account.getAccounts().map({ x in
                x.acct
            })
            completion(INStringResolutionResult.disambiguation(with: allNames))
            return
        }
        completion(INStringResolutionResult.success(with: account))
    }
    
    func resolveText(for intent: PostTweetIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        guard let text = intent.text else {
            completion(INStringResolutionResult.needsValue())
            return
        }
        completion(INStringResolutionResult.success(with: text))
    }
    
    func provideAccountOptionsCollection(for intent: PostTweetIntent, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
        loadAccountsIfNeeded()
        let allNames = Account.getAccounts().map({ x in
            x.acct
        })
        let accounts: [NSString] = allNames as [NSString]
        
        let collection = INObjectCollection(items: accounts)
        completion(collection, nil)
    }
    
    func handle(intent: PostTweetIntent, completion: @escaping (PostTweetIntentResponse) -> Void) {
        
        // Verify account parameter
        guard let account = intent.account else {
            completion(PostTweetIntentResponse(code: .failureNoAccount, userActivity: nil))
            return
        }

        // Verify text and valid length
        guard let text = intent.text, text.count <= 280 else {
            completion(PostTweetIntentResponse(code: .failureTextTooLong, userActivity: nil))
            return
        }
        
        loadAccountsIfNeeded()
        
        // Find index of account for fetch oauth access token
        let allNames = AccountsManager.shared.allAccounts.map({ x in
            (x as? MastodonAcctData)?.account.acct ?? ""
        })
        guard let index = allNames.firstIndex(of: account) else {
            completion(PostTweetIntentResponse(code: .failureCannotFindAccount, userActivity: nil))
            return
        }

        let images = intent.images?.map({$0.data}) ?? []

        if index < AccountsManager.shared.allAccounts.count {
            let acct = AccountsManager.shared.allAccounts[index]
            let client = (acct as? MastodonAcctData)?.client
            var mediaIdStrings: [String] = []
            _ = images.map({ image in
                let request = Media.upload(media: .jpeg(image))
                client?.run(request) { (statuses) in
                    if let stat = (statuses.value) {
                        DispatchQueue.main.async {
                            mediaIdStrings.append(stat.id)
                        }
                    }
                }
            })
            let request = Statuses.create(status: text, mediaIDs: mediaIdStrings, visibility: .public)
            client?.run(request) { (statuses) in
                if let error = statuses.error {
                    log.error("Failed to create a status: \(error)")
                    DispatchQueue.main.async {
                        completion(PostTweetIntentResponse(code: .failureToTweet, userActivity: nil))
                        return
                    }
                }
                if let _ = statuses.value {
                    DispatchQueue.main.async {
                        completion(PostTweetIntentResponse(code: .success, userActivity: nil))
                    }
                }
            }
        } else {
            var mediaIdStrings: [String] = []
            var currentClient = AccountsManager.shared.currentAccountClient
            _ = images.map({ image in
                let request = Media.upload(media: .jpeg(image))
                currentClient.run(request) { (statuses) in
                    if let stat = (statuses.value) {
                        DispatchQueue.main.async {
                            mediaIdStrings.append(stat.id)
                        }
                    }
                }
            })
            let request = Statuses.create(status: text, mediaIDs: mediaIdStrings, visibility: .public)
            currentClient.run(request) { (statuses) in
                if let error = statuses.error {
                    log.error("Failed to create a status: \(error)")
                    DispatchQueue.main.async {
                        completion(PostTweetIntentResponse(code: .failureToTweet, userActivity: nil))
                        return
                    }
                }
                if let _ = statuses.value {
                    DispatchQueue.main.async {
                        completion(PostTweetIntentResponse(code: .success, userActivity: nil))
                    }
                }
            }
        }
    }
    
}
