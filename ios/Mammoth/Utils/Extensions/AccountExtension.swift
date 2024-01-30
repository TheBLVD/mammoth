//
//  AccountExtension.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 06/11/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension Account: Equatable {
    static func addAccountToList(account:Account) -> Bool {
        guard let accountsData = UserDefaults.standard.object(forKey: "allAccounts") as? Data, var accounts = try? PropertyListDecoder().decode(Array<Account>.self, from: accountsData) else {
            let accounts = [account]
            UserDefaults.standard.set(try? PropertyListEncoder().encode(accounts), forKey: "allAccounts")
            return true
        }
        
        if !accounts.contains(account) {
            accounts.append(account)
            UserDefaults.standard.set(try? PropertyListEncoder().encode(accounts), forKey: "allAccounts")
            return true
        }
        
        return false
    }
        
    static func getAccounts() -> [Account] {
        guard let accountsData = UserDefaults.standard.object(forKey: "allAccounts") as? Data, let accounts = try? PropertyListDecoder().decode(Array<Account>.self, from: accountsData) else {
            return [Account]()
        }
        return accounts
    }
    
    static func clearAccounts() {
        UserDefaults.standard.setValue(nil, forKey: "allAccounts")
    }
        
    static public func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.fullAcct == rhs.fullAcct && lhs.id == rhs.id
    }
}

