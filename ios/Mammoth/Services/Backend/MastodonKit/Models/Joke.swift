//
//  Joke.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 22/04/2019.
//  Copyright © 2019 Shihab Mehboob. All rights reserved.
//

import Foundation

public class Joke: Codable {
    /// The last joke id.
    public let id: Int
    /// The joke type.
    public let type: String
    /// The joke setup.
    public let setup: String
    /// The joke punchline.
    public let punchline: String
}

