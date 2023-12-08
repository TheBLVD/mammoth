//
//  Bookmarks.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 08/11/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

public struct Bookmarks {
    public static func bookmarks(range: RequestRange = .default) -> Request<[Status]> {
        let rangeParameters = range.parameters(limit: between(1, and: 40, default: 20)) ?? []
        let method = HTTPMethod.get(.parameters(rangeParameters))
        
        return Request<[Status]>(path: "/api/v1/bookmarks", method: method)
    }
    
    public static func bookmark(id: String) -> Request<Status> {
        return Request<Status>(path: "/api/v1/statuses/\(id)/bookmark", method: .post(.empty))
    }
    
    public static func unbookmark(id: String) -> Request<Status> {
        return Request<Status>(path: "/api/v1/statuses/\(id)/unbookmark", method: .post(.empty))
    }
}
