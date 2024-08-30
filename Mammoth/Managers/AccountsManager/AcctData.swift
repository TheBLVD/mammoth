//
//  AcctData.swift
//  Mammoth
//
//  Created by Riley Howard on 6/27/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

// MastodonAccountData, BlueskyAccountData
//
// Data structures that encapsulate the info needed to login to accounts.
//      For Mastodon: account type, Account, InstanceData
//      For Bluesky: account type, ____TBD


import Foundation

enum NetworkAcctData: Codable {
    case mastodonAcctData(MastodonAcctData)
    case blueskyAcctData(BlueskyAcctData)
    
    
    var unassociated: Unassociated {
        switch self {
        case .mastodonAcctData: return .mastodonAcctData
        case .blueskyAcctData: return .blueskyAcctData
        }
    }

    func asAcctDataType() -> any AcctDataType {
        switch self {
        case .mastodonAcctData(let mastodonAcctData):
            return mastodonAcctData
        case .blueskyAcctData(let blueskyAcctData):
            return blueskyAcctData
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        switch try container.decode(String.self, forKey: .type) {
        case Unassociated.mastodonAcctData.rawValue:
            self = .mastodonAcctData(try container.decode(MastodonAcctData.self, forKey: .attributes))
        case Unassociated.blueskyAcctData.rawValue:
            self = .blueskyAcctData(try container.decode(BlueskyAcctData.self, forKey: .attributes))
        default: fatalError("Unknown type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .mastodonAcctData(let mastodonAcctData): try container.encode(mastodonAcctData, forKey: .attributes)
        case .blueskyAcctData(let blueskyAcctData): try container.encode(blueskyAcctData, forKey: .attributes)
        }

        try container.encode(unassociated.rawValue, forKey: .type)
    }

    enum Unassociated: String {
        case mastodonAcctData
        case blueskyAcctData
    }

    private enum CodingKeys: String, CodingKey {
        case attributes
        case type
    }

}

enum AcctType: String, Codable {
    case Mastodon
    case Bluesky
}


protocol AcctDataType: Equatable, Hashable, Codable, AcctDataViewModel {
    var acctType: AcctType { get }
    var uniqueID: String { get }
    func diskFolderName() -> String
}

extension Equatable where Self : AcctDataType {
  func isEqualTo(other: any AcctDataType) -> Bool {
    guard let o = other as? Self else { return false }
    return self == o
  }
}

struct MastodonAcctData: AcctDataType {

    static func == (lhs: MastodonAcctData, rhs: MastodonAcctData) -> Bool {
        return lhs.acctType == rhs.acctType &&
               lhs.account == rhs.account &&
               lhs.instanceData == rhs.instanceData
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(account.fullAcct)
    }

    var acctType: AcctType { .Mastodon }
    
    let uniqueID: String
    let account: Account
    let instanceData: InstanceData
    let defaultPostVisibility: Visibility
    let defaultPostingLanguage: String?
    let emoticons: [Emoji]
    var forYou: ForYouAccount
    @available(*, deprecated, message: "Using UserDefaults instead.")
    var wentThroughOnboarding: Bool // false for accounts coming from 1.x
    
    let client: Client
    let mothClient: Client
    let featureClient: Client

    private enum CodingKeys: String, CodingKey {
        case uniqueID
        case account
        case instanceData
        case defaultPostVisibility
        case defaultPostLanguage
        case emoticons
        case forYou
        case wentThroughOnboarding
    }
    
    init(account: Account, instanceData: InstanceData, client: Client, defaultPostVisibility: Visibility, defaultPostingLanguage: String?, emoticons: [Emoji], forYou: ForYouAccount, uniqueID: String? = nil) {
        self.uniqueID = uniqueID ?? UUID().uuidString
        self.account = account
        self.instanceData = instanceData
        self.client = Client(baseURL: "https://\(instanceData.returnedText)", accessToken: instanceData.accessToken)
        self.mothClient = Client(baseURL: "https://\(instanceData.returnedText)", accessToken: instanceData.accessToken)
        self.featureClient = Client(baseURL: "https://\(instanceData.returnedText)", accessToken: instanceData.accessToken)
        self.defaultPostVisibility = defaultPostVisibility
        self.defaultPostingLanguage = defaultPostingLanguage
        self.emoticons = emoticons
        self.forYou = forYou
        self.wentThroughOnboarding = false
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uniqueID = try container.decode(String.self, forKey: .uniqueID)
        account = try container.decode(Account.self, forKey: .account)
        instanceData = try container.decode(InstanceData.self, forKey: .instanceData)
        client = Client(baseURL: "https://\(instanceData.returnedText)", accessToken: instanceData.accessToken)
        mothClient = Client(baseURL: "https://\(instanceData.returnedText)", accessToken: instanceData.accessToken)
        featureClient = Client(baseURL: "https://\(instanceData.returnedText)", accessToken: instanceData.accessToken)
        // Below are new for 2.0
        do {
            defaultPostVisibility = try container.decode(Visibility.self, forKey: .defaultPostVisibility)
        } catch {
            defaultPostVisibility = .public
        }
        do {
            emoticons = try container.decode(type(of: emoticons).self, forKey: .emoticons)
        } catch {
            emoticons = []
        }
        do {
            forYou = try container.decode(type(of: forYou).self, forKey: .forYou)
        } catch {
            forYou = ForYouAccount()
        }
        // Although wentThroughOnboarding is deprecated, leave this here so we can
        // read old values to upgrade account info as needed.
        do {
            wentThroughOnboarding = try container.decode(type(of: wentThroughOnboarding).self, forKey: .wentThroughOnboarding)
        } catch {
            wentThroughOnboarding = false // for 1.x accounts
        }
        // Below are new for 2.1
        do {
            defaultPostingLanguage = try container.decode(type(of: defaultPostingLanguage).self, forKey: .defaultPostLanguage)
        } catch {
            defaultPostingLanguage = nil
        }
        
        _ = try container.superDecoder ( )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uniqueID, forKey: .uniqueID)
        try container.encode(account, forKey: .account)
        try container.encode(instanceData, forKey: .instanceData)
        try container.encode(defaultPostVisibility, forKey: .defaultPostVisibility)
        try container.encode(defaultPostingLanguage, forKey: .defaultPostLanguage)
        try container.encode(emoticons, forKey: .emoticons)
        try container.encode(forYou, forKey: .forYou)
        // try container.encode(wentThroughOnboarding, forKey: .wentThroughOnboarding) Deprecated
    }
    
    func diskFolderName() -> String {
        return account.fullAcct
    }
}


struct BlueskyAcctData: AcctDataType {

    static func == (lhs: BlueskyAcctData, rhs: BlueskyAcctData) -> Bool {
        return lhs.uniqueID == rhs.uniqueID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueID)
    }

    var acctType: AcctType { .Bluesky }
    var uniqueID: String { "Bluesky-\(userID)" }
    func diskFolderName() -> String { uniqueID }
    
    var userID: String
    var handle: String
    var displayName: String
    var avatar: String
    
    var tokenSet: BlueskyAPI.TokenSet
    
    let api: BlueskyAPI
    
    private enum CodingKeys: String, CodingKey {
        case userID
        case handle
        case displayName
        case avatar
        case tokenSet
    }
    
    init(
        userID: String,
        handle: String,
        displayName: String,
        avatar: String,
        tokenSet: BlueskyAPI.TokenSet
    ) {
        self.userID = userID
        self.handle = handle
        self.displayName = displayName
        self.avatar = avatar
        self.tokenSet = tokenSet
        
        api = BlueskyAPI(tokenSet: tokenSet)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userID = try container.decode(String.self, forKey: .userID)
        handle = try container.decode(String.self, forKey: .handle)
        displayName = try container.decode(String.self, forKey: .displayName)
        avatar = try container.decode(String.self, forKey: .avatar)
        tokenSet = try container.decode(BlueskyAPI.TokenSet.self, forKey: .tokenSet)
        
        api = BlueskyAPI(tokenSet: tokenSet)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(handle, forKey: .handle)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(avatar, forKey: .avatar)
        try container.encode(tokenSet, forKey: .tokenSet)
    }

}
