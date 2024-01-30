//
//  UndoStruct.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 30/09/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
#if canImport(ActivityKit)
import ActivityKit

struct UndoStruct: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let state: Int
        let text: String
        var deliveryTimer: ClosedRange<Date>
    }
}
#endif
