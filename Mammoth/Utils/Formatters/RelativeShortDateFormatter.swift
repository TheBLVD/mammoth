//
//  RelativeShortDateFormatter.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

struct RelativeShortDateFormatter {
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        return f
    }()
    
    static func string(from date: Date) -> String {
        let now = Date()
        
        let dc = Calendar.current.dateComponents(
            [.second, .minute, .hour, .day],
            from: date, to: now)
        
        let day = dc.day ?? 0
        let hour = dc.hour ?? 0
        let minute = dc.minute ?? 0
        let second = dc.second ?? 0
        
        if day >= 7 {
            return dateFormatter.string(from: date)
        } else if day > 0 {
            return "\(day)d"
        } else if hour > 0 {
            return "\(hour)h"
        } else if minute > 0 {
            return "\(minute)m"
        } else {
            return "\(second)s"
        }
    }
    
}
