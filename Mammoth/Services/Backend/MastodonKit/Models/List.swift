//
//  List.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 1/2/18.
//  Copyright © 2018 MastodonKit. All rights reserved.
//

import Foundation

public class List: Codable {
    /// The ID of the list.
    public let id: String
    /// The Title of the list.
    public let title: String
    /// Which replies should be shown in the list.
    public let repliesPolicy: ListRepliesPolicy?
    /// Whether members of this list need to get removed from the “Home” feed
    public let exclusive: Bool?
    
    public init(id: String, title: String, repliesPolicy: ListRepliesPolicy = .none, exclusive: Bool = false) {
        self.id = id
        self.title = title
        self.repliesPolicy = repliesPolicy
        self.exclusive = exclusive
    }
    
    public init() {
        self.id = ""
        self.title = ""
        self.repliesPolicy = .none
        self.exclusive = false
    }

}

public enum ListRepliesPolicy: Codable {
    /// Show replies to any followed user
    case followed
    /// Show replies to members of the list
    case list
    /// Show replies to no one
    case none
}
