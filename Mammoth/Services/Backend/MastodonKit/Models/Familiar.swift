//
//  Familiar.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 29/12/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

public class Familiar: Codable {
    public let id: String
    public let accounts: [Account]

    private enum CodingKeys: String, CodingKey {
        case id
        case accounts
    }
}

