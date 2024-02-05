//
//  AccountCacher.swift
//  Mammoth
//
//  Created by Benoit Nolens on 19/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

struct AccountCacher {
    static func clearCache(forAccount account: Account) {
        // Documents folder
        [
            account.id,
            "allInstances.json",
            "votedOnPolls.json",
            "blockedUsers.json",
            "drafts/\(account.id)"
        ].forEach { path in
            do {
                try Disk.remove(path, from: .documents)
            } catch let error {
                log.error("error clearing cache in Documents at path \(path) - \(error)")
            }
        }
        
        // Cache folder
        [
            account.fullAcct
        ].forEach { path in
            do {
                try Disk.remove(path, from: .caches)
            } catch let error {
                log.error("error clearing cache in Library/Caches at path \(path) - \(error)")
            }
        }
        
        GlobalStruct.drafts = []
    }
    
}
