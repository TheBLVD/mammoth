//
//  ParsingTransforms.swift
//  Pods
//
//  Created by Brendan Lee on 3/15/17.
//
//

import Foundation

let stringToIntTransform = TransformOf<Int, String>(fromJSON: { (value: String?) -> Int in

    return Int(value ?? "0") ?? 0
}, toJSON: { (value: Int?) -> String? in
    // transform value from Int? to String?
    if let value = value {
        return String(value)
    }
    return nil
})
