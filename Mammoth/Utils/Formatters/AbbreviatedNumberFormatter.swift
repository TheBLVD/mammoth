//
//  AbbreviatedNumberFormatter.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

private let units = [
    (1_000, 10_000, "K"),
    (1_000_000, 1_000_000, "M"),
    (1_000_000_000, 1_000_000_000, "B"),
]

struct AbbreviatedNumberFormatter {
    
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.roundingMode = .down
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return f
    }()
    
    static func string(from number: Int) -> String {
        var scaledNumber = Double(number)
        var abbreviation: String? = nil
        
        for (value, threshold, abbr) in units {
            if number >= threshold {
                scaledNumber = Double(number) / Double(value)
                abbreviation = abbr
            }
        }
        
        let digits = formatter.string(
            from: scaledNumber as NSNumber)
        
        return "\(digits ?? "")\(abbreviation ?? "")"
    }
    
}
