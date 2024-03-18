//
//  RequestRange.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 5/3/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public enum RequestRange {
    /// Gets a list with IDs less than or equal this value.
    case max(id: String, limit: Int?)
    /// Gets a list with IDs greater than this value.
    case since(id: String, limit: Int?)
    case min(id: String, limit: Int?)
    /// Sets the maximum number of entities to get.
    case limit(Int)
    /// Applies the default values.
    case `default`
}

extension RequestRange {
    func parameters(limit limitFunction: (Int) -> Int) -> [Parameter]? {
        switch self {
        case .max(let id, let limit):
            return [
                Parameter(name: "max_id", value: id),
                Parameter(name: "limit", value: limit.map(limitFunction).flatMap(toOptionalString))
            ]
        case .since(let id, let limit):
            return [
                Parameter(name: "since_id", value: id),
                Parameter(name: "limit", value: limit.map(limitFunction).flatMap(toOptionalString))
            ]
        case .min(let id, let limit):
//            if (UserDefaults.standard.object(forKey: "orderset") == nil) || (UserDefaults.standard.object(forKey: "orderset") as! Int == 0) {
                return [
                    Parameter(name: "min_id", value: id),
                    Parameter(name: "limit", value: limit.map(limitFunction).flatMap(toOptionalString))
                ]
//            } else {
//                return [
//                    Parameter(name: "since_id", value: id),
//                    Parameter(name: "limit", value: limit.map(limitFunction).flatMap(toOptionalString))
//                ]
//            }
        case .limit(let limit):
            return [Parameter(name: "limit", value: String(limitFunction(limit)))]
        default:
            return nil
        }
    }
}

extension RequestRange: Comparable {
    private static func requestRangeIdToIntegers(_ range: RequestRange) -> Int {
        switch range {
        case let .max(id, _):
            return Int(id) ?? 0
        case let .min(id, _):
            return Int(id) ?? 0
        default:
            print("Warning: unsupported comparison for RequestRange")
            return 0
        }
    }
    
    public static func < (lhs: RequestRange, rhs: RequestRange) -> Bool {
        // guard that both lhs and rhs have the same type
        let lhsVal = requestRangeIdToIntegers(lhs)
        let rhsVal = requestRangeIdToIntegers(rhs)
        
        return lhsVal < rhsVal
    }
}
// MARK: - Equatable

extension RequestRange: Equatable {}

extension RequestRange: Codable {}
