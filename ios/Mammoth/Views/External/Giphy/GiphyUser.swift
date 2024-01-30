//
//  GiphyUser.swift
//  Pods
//
//  Created by Brendan Lee on 3/15/17.
//
//

import Foundation

public struct GiphyUser: Mappable {
    
    public fileprivate(set) var avatarURL: URL?
    public fileprivate(set) var bannerURL: URL?
    public fileprivate(set) var profileURL: URL?
    public fileprivate(set) var username: String = ""
    public fileprivate(set) var displayName: String = ""
    public fileprivate(set) var twitterHandle: String?
    
    public init?(map: Map)
    {
        
    }
    
    mutating public func mapping(map: Map) {
        
        avatarURL       <- (map["avatar_url"], URLTransform())
        bannerURL       <- (map["banner_url"], URLTransform())
        profileURL      <- (map["profile_url"], URLTransform())
        username        <- map["username"]
        displayName     <- map["display_name"]
        twitterHandle   <- map["twitter"]
    }
}
