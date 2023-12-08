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
    
    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
    
    public init() {
        self.id = ""
        self.title = ""
    }

}
