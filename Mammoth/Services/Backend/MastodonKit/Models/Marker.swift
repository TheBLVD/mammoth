//
//  Marker.swift
//  Mast
//
//  Created by Shihab Mehboob on 22/11/2019.
//  Copyright © 2019 Shihab Mehboob. All rights reserved.
//

import Foundation

public class Marker: Codable {
    let home: Mark?
    let notifications: Mark?
}

public class Mark: Codable {
    let lastReadID: String
    let version: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case lastReadID = "last_read_id"
        case version
        case updatedAt = "updated_at"
    }
}

