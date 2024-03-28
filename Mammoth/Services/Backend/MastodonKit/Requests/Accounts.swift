//
//  Accounts.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation
import UIKit

public struct Accounts {
    /// Fetches an account.
    ///
    /// - Parameter id: The account id.
    /// - Returns: Request for `Account`.
    public static func account(id: String) -> Request<Account> {
        return Request<Account>(path: "/api/v1/accounts/\(id)")
    }

    /// Gets the current user.
    ///
    /// - Returns: Request for `Account`.
    public static func currentUser() -> Request<Account> {
        return Request<Account>(path: "/api/v1/accounts/verify_credentials")
    }

    /// Updates the current user.
    ///
    /// - Parameters:
    ///   - displayName: The name to display in the user's profile.
    ///   - note: A new biography for the user.
    ///   - avatar: The media attachment to display as the user's avatar.
    ///   - header: The media attachment to display as the user's header image.
    /// - Returns: Request for `Account`.
    public static func updateCurrentUser(displayName: String? = nil,
                                         note: String? = nil,
                                         avatar: MediaAttachment? = nil,
                                         header: MediaAttachment? = nil,
                                         locked: Bool? = nil,
                                         bot: Bool? = nil,
                                         discoverable: Bool? = nil,
                                         indexable: Bool? = nil,
                                         hideCollections: Bool? = nil,
                                         sensitive: Bool? = nil,
                                         privacy: String? = nil,
                                         language: String? = nil,
                                         fieldName1: String? = nil,
                                         fieldValue1: String? = nil,
                                         fieldName2: String? = nil,
                                         fieldValue2: String? = nil,
                                         fieldName3: String? = nil,
                                         fieldValue3: String? = nil,
                                         fieldName4: String? = nil,
                                         fieldValue4: String? = nil) -> Request<Account> {

        let lockText = (locked ?? false) ? "true" : "false"
        let botText = (bot ?? false) ? "true" : "false"
        let discoverableText = (discoverable ?? false) ? "true" : "false"
        let indexableText = (indexable ?? false) ? "true" : "false"
        let sensitiveText = (sensitive ?? false) ? "true" : "false"
        let hideCollectionsText = (hideCollections ?? false) ? "true" : "false"
        
        var parameters = [
            Parameter(name: "display_name", value: displayName),
            Parameter(name: "note", value: note),
            Parameter(name: "locked", value: lockText),
            Parameter(name: "bot", value: botText),
            Parameter(name: "discoverable", value: discoverableText),
            Parameter(name: "indexable", value: indexableText),
            Parameter(name: "hide_collections", value: hideCollectionsText),
            Parameter(name: "source[sensitive]", value: sensitiveText),
            Parameter(name: "source[privacy]", value: privacy),
            Parameter(name: "fields_attributes[0][name]", value: fieldName1),
            Parameter(name: "fields_attributes[0][value]", value: fieldValue1),
            Parameter(name: "fields_attributes[1][name]", value: fieldName2),
            Parameter(name: "fields_attributes[1][value]", value: fieldValue2),
            Parameter(name: "fields_attributes[2][name]", value: fieldName3),
            Parameter(name: "fields_attributes[2][value]", value: fieldValue3),
            Parameter(name: "fields_attributes[3][name]", value: fieldName4),
            Parameter(name: "fields_attributes[3][value]", value: fieldValue4)
        ]
        if language != nil {
            parameters.append(Parameter(name: "source[language]", value: language))
        }

        if avatar != nil {
            parameters.append(Parameter(name: "avatar", value: avatar?.base64EncondedString))
        }

        if header != nil {
            parameters.append(Parameter(name: "header", value: header?.base64EncondedString))
        }
            
        let method = HTTPMethod.patch(.parameters(parameters))
        return Request<Account>(path: "/api/v1/accounts/update_credentials", method: method)

        
        
    }

    /// Gets an account's followers.
    ///
    /// - Parameters:
    ///   - id: The account id.
    ///   - range: The bounds used when requesting data from Mastodon.
    /// - Returns: Request for `[Account]`.
    public static func followers(id: String, range: RequestRange = .default) -> Request<[Account]> {
        let parameters = range.parameters(limit: between(1, and: 80, default: 40))
        let method = HTTPMethod.get(.parameters(parameters))

        return Request<[Account]>(path: "/api/v1/accounts/\(id)/followers", method: method)
    }

    /// Gets who account is following.
    ///
    /// - Parameters:
    ///   - id: The account id
    ///   - range: The bounds used when requesting data from Mastodon.
    /// - Returns: Request for `[Account]`.
    public static func following(id: String, range: RequestRange = .default) -> Request<[Account]> {
        let parameters = range.parameters(limit: between(1, and: 80, default: 40))
        let method = HTTPMethod.get(.parameters(parameters))

        return Request<[Account]>(path: "/api/v1/accounts/\(id)/following", method: method)
    }
    
    public static func familiarFollowers(ids: [String]) -> Request<[Familiar]> {
        let parameters = ids.map(toArrayOfParameters(withName: "id"))
        let method = HTTPMethod.get(.parameters(parameters))

        return Request<[Familiar]>(path: "/api/v1/accounts/familiar_followers", method: method)
    }
    
    /// Follow suggestions.
    ///
    /// - Returns: Request for `[Account]`.
    public static func followSuggestions() -> Request<[Account]> {
        return Request<[Account]>(path: "/api/v1/suggestions", method: .get(.empty))
    }

    /// Follow suggestions.
    ///
    /// - Returns: Request for `[Suggestion]`.
    public static func followSuggestionsV2() -> Request<[Suggestion]> {
        return Request<[Suggestion]>(path: "/api/v2/suggestions", method: .get(.empty))
    }

    /// Delete follow suggestion.
    ///
    /// - Returns: Request for `[Account]`.
    public static func deleteFollowSuggestion(id: String) -> Request<Empty> {
        return Request<Empty>(path: "/api/v1/suggestions/\(id)", method: .delete(.empty))
    }
    
    /// Endorse an account.
    ///
    /// - Parameters:
    ///   - id: The account id
    /// - Returns: Request for `Relationship`.
    public static func endorse(id: String) -> Request<Relationship> {
        return Request<Relationship>(path: "/api/v1/accounts/\(id)/pin", method: .post(.empty))
    }
    
    /// Remove endorsement from an account.
    ///
    /// - Parameters:
    ///   - id: The account id
    /// - Returns: Request for `Relationship`.
    public static func endorseRemove(id: String) -> Request<Relationship> {
        return Request<Relationship>(path: "/api/v1/accounts/\(id)/unpin", method: .post(.empty))
    }
    
    public static func addPrivateNote(id: String, comment: String) -> Request<Relationship> {
        let parameter = [Parameter(name: "comment", value: comment)]
        let method = HTTPMethod.post(.parameters(parameter))

        return Request<Relationship>(path: "/api/v1/accounts/\(id)/note", method: method)
    }
    
    public static func updateNotify(id: String, notify: Bool) -> Request<Relationship> {
        var reb = "true"
        if notify == false {
            reb = "false"
        }
        let parameter = [Parameter(name: "notify", value: reb)]
        let method = HTTPMethod.post(.parameters(parameter))

        return Request<Relationship>(path: "/api/v1/accounts/\(id)/follow", method: method)
    }
    
    public static func updateRepost(id: String, repost: Bool) -> Request<Relationship> {
        var reb = "true"
        if repost == false {
            reb = "false"
        }
        let parameter = [Parameter(name: "reblogs", value: reb)]
        let method = HTTPMethod.post(.parameters(parameter))

        return Request<Relationship>(path: "/api/v1/accounts/\(id)/follow", method: method)
    }
    
    /// Get endorsements.
    ///
    /// - Returns: Request for `[Account]`.
    public static func allEndorsements() -> Request<[Account]> {
        return Request<[Account]>(path: "/api/v1/endorsements", method: .get(.empty))
    }

    /// Gets an account's statuses.
    ///
    /// - Parameters:
    ///   - id: The account id.
    ///   - mediaOnly: Only return statuses that have media attachments.
    ///   - pinnedOnly: Only return statuses that have been pinned.
    ///   - excludeReplies: Skip statuses that reply to other statuses.
    ///   - excludeReblogs: Skip statuses that are boosts.
    ///   - range: The bounds used when requesting data from Mastodon.
    /// - Returns: Request for `[Status]`.
    public static func statuses(id: String,
                                mediaOnly: Bool? = nil,
                                pinnedOnly: Bool? = nil,
                                excludeReplies: Bool? = nil,
                                excludeReblogs: Bool? = nil,
                                range: RequestRange = .default) -> Request<[Status]> {
        let rangeParameters = range.parameters(limit: between(1, and: 40, default: 20)) ?? []
        let parameters = rangeParameters + [
            Parameter(name: "only_media", value: mediaOnly.flatMap(trueOrNil)),
            Parameter(name: "pinned", value: pinnedOnly.flatMap(trueOrNil)),
            Parameter(name: "exclude_replies", value: excludeReplies.flatMap(trueOrNil)),
            Parameter(name: "exclude_reblogs", value: excludeReblogs.flatMap(trueOrNil))
        ]

        let method = HTTPMethod.get(.parameters(parameters))
        return Request<[Status]>(path: "/api/v1/accounts/\(id)/statuses", method: method)
    }

    /// Follows an account.
    ///
    /// - Parameter id: The account id.
    /// - Parameter reblogs: Whether to display the account's reblogs on the home timeline.
    /// - Parameter rebuild: Request that the feed be rebuild (moth.social only).
    /// - Returns: Request for `Account`.
    public static func follow(id: String, reblogs: Bool, rebuild: Bool = false) -> Request<Relationship> {
        let reb = reblogs ? "true" : "false"
        var parameters = [Parameter(name: "reblogs", value: reb)]
        if rebuild {
            parameters.append(Parameter(name: "rebuild", value: "true"))
        }
        let method = HTTPMethod.post(.parameters(parameters))
        return Request<Relationship>(path: "/api/v1/accounts/\(id)/follow", method: method)
    }

    /// Unfollow an account.
    ///
    /// - Parameter id: The account id.
    /// - Parameter rebuild: Request that the feed be rebuild (moth.social only).
    /// - Returns: Request for `Account`.
    public static func unfollow(id: String, rebuild: Bool = false) -> Request<Relationship> {
        var method: HTTPMethod
        if rebuild {
            let parameters = [Parameter(name: "rebuild", value: "true")]
            method = HTTPMethod.post(.parameters(parameters))
        } else {
            method = HTTPMethod.post(.empty)
        }        
        return Request<Relationship>(path: "/api/v1/accounts/\(id)/unfollow", method: method)
    }

    /// Follows a remote user:.
    ///
    /// - Parameter uri: The 'username@domain' of the remote user to follow.
    /// - Returns: Request for `Account`.
    public static func remoteFollow(uri: String) -> Request<Account> {
        let parameter = [Parameter(name: "uri", value: uri)]
        let method = HTTPMethod.post(.parameters(parameter))

        return Request<Account>(path: "/api/v1/follows", method: method)
    }

    /// Blocks an account.
    ///
    /// - Parameter id: The account id.
    /// - Returns: Request for `Relationship`.
    public static func block(id: String) -> Request<Relationship> {
        return Request<Relationship>(path: "/api/v1/accounts/\(id)/block", method: .post(.empty))
    }

    /// Unblocks an account.
    ///
    /// - Parameter id: The account id.
    /// - Returns: Request for `Relationship`.
    public static func unblock(id: String) -> Request<Relationship> {
        return Request<Relationship>(path: "/api/v1/accounts/\(id)/unblock", method: .post(.empty))
    }

    /// Mutes an account.
    ///
    /// - Parameter id: The account id.
    /// - Returns: Request for `Relationship`.
    public static func mute(id: String, durationInSeconds: Int) -> Request<Relationship> {
        let parameters = [
            Parameter(name: "duration", value: String(durationInSeconds))
        ]
        let method = HTTPMethod.post(durationInSeconds == 0 ? .empty : .parameters(parameters))
        return Request<Relationship>(path: "/api/v1/accounts/\(id)/mute", method: method)
    }

    /// Unmutes an account.
    ///
    /// - Parameter id: The account id.
    /// - Returns: Request for `Relationship`.
    public static func unmute(id: String) -> Request<Relationship> {
        return Request<Relationship>(path: "/api/v1/accounts/\(id)/unmute", method: .post(.empty))
    }

    /// Gets an account's relationships.
    ///
    /// - Parameter ids: The account's ids.
    /// - Returns: Request for `[Relationship]`.
    public static func relationships(ids: [String], withSuspended: Bool = false) -> Request<[Relationship]> {
        var parameters = [
            Parameter(name: "with_suspended", value: String(withSuspended))
        ]
        parameters.append(contentsOf: ids.map(toArrayOfParameters(withName: "id")))
        let method = HTTPMethod.get(.parameters(parameters))

        return Request<[Relationship]>(path: "/api/v1/accounts/relationships", method: method)
    }

    public static func registerAccount(username: String, email: String, password: String, agreement: Bool, locale: String) -> Request<LoginSettings> {
        var agreementText = "false"
        if agreement == true {
            agreementText = "true"
        } else {
            agreementText = "false"
        }
        let parameter = [
            Parameter(name: "username", value: username),
            Parameter(name: "email", value: email),
            Parameter(name: "password", value: password),
            Parameter(name: "agreement", value: agreementText),
            Parameter(name: "locale", value: locale)
        ]
        let method = HTTPMethod.post(.parameters(parameter))

        return Request<LoginSettings>(path: "/api/v1/accounts", method: method)
    }
    
    public static func followRecommendations(_ id: String) -> Request<[Account]> {
        return Request<[Account]>(path: "/api/v1/accounts/\(id)/follow_recommendations", method: .get(.empty))
    }
    
    /// Looks up fedi-graph recommended followers via Moth.social
    ///
    /// - Parameter fullAcct: The fully qualified account name (e.g. "mammoth@moth.social")
    /// - Returns: Accounts from the users followers using fedi-graph
    public static func followRecommendationsV3(_ fullAcct: String) -> Request<[Account]> {
        let parameters = [
            Parameter(name: "acct", value: fullAcct),
        ]
        let method = HTTPMethod.get(.parameters(parameters))
        return Request<[Account]>(path: "/api/v1/followgraph", method: method)
    }

    public static func onboardingFollowRecommendations() -> Request<[Category]> {
        // Note: v1 returned [Accounts]
        //       v2 returned [Category], with each category having Accounts and/or Hashtags
        //       v2/accounts returns [Category], and every sub item in the Category is an Account
        return Request<[Category]>(path: "/api/v2/onboarding_follow_recommendations/accounts", method: .get(.empty))
    }

    /// Looks up an account ID on a given server.
    ///
    /// - Parameter acct: The account name to lookup (e.g., "mammoth").
    /// - Returns: Accounts that match.
    /// Requires 3.4 or better
    public static func lookup(acct: String) -> Request<Account> {
        let parameters = [
            Parameter(name: "acct", value: acct)
        ]
        let method = HTTPMethod.get(.parameters(parameters))
        return Request<Account>(path: "/api/v1/accounts/lookup", method: method)
    }
    
}
