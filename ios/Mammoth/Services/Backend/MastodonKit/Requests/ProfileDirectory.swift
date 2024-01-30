//
//  ProfileDirectory.swift
//  Mast
//
//  Created by Shihab Mehboob on 05/12/2019.
//  Copyright © 2019 Shihab Mehboob. All rights reserved.
//

import Foundation

public struct ProfileDirectory {
    public static func all(local: Bool? = nil,
                                order: String? = nil,
                                range: RequestRange = .default) -> Request<[Account]> {
        let rangeParameters = range.parameters(limit: between(1, and: 40, default: 20)) ?? []
        let parameters = rangeParameters + [
            Parameter(name: "local", value: local.flatMap(trueOrNil)),
            Parameter(name: "order", value: order)
        ]

        let method = HTTPMethod.get(.parameters(parameters))
        return Request<[Account]>(path: "/api/v1/directory", method: method)
    }
}
