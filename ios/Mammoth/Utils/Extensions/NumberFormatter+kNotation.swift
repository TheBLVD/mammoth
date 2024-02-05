//
//  NumberFormatter+kNotation.swift
//  Mammoth
//
//  Created by Benoit Nolens on 10/07/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension NumberFormatter {
    func dividedByK(number: Double) -> String? {
        let suffixes = ["", "k", "M", "B"]
        var idx = 0
        var d = number
        while idx < 4 && abs(d) >= 1000.0 {
            d /= 1000.0
            idx += 1
        }
        
        if idx == 0 {
            return self.string(from: NSNumber(value: number))
        } else {
            let numStr = String(format: "%.1f", d)
            return numStr + suffixes[idx]
        }
    }
}
