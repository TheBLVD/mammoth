//
//  TrendingTags.swift
//  Mast
//
//  Created by Shihab Mehboob on 05/12/2019.
//  Copyright © 2019 Shihab Mehboob. All rights reserved.
//

import Foundation

public struct TrendingTags {
    /// Fetches trending tags.
    ///
    /// - Returns: Request for `[Tag]`.
    public static func trendingTags() -> Request<[Tag]> {
        let parameters = [Parameter(name: "limit", value: "20")]
        let method = HTTPMethod.get(.parameters(parameters))
        return Request<[Tag]>(path: "/api/v1/trends", method: method)
    }
    
    public static func followedTags() -> Request<[Tag]> {
        return Request<[Tag]>(path: "/api/v1/followed_tags")
    }
    
    /// - Parameter rebuild: Request that the feed be rebuild (moth.social only).
    public static func follow(id: String, rebuild: Bool = false) -> Request<Tag> {
        var method: HTTPMethod
        if rebuild {
            let parameters = [Parameter(name: "rebuild", value: "true")]
            method = HTTPMethod.post(.parameters(parameters))
        } else {
            method = HTTPMethod.post(.empty)
        }
        return Request<Tag>(path: "/api/v1/tags/\(id)/follow", method: method)
    }
    
    /// - Parameter rebuild: Request that the feed be rebuild (moth.social only).
    public static func unfollow(id: String, rebuild: Bool = false) -> Request<Tag> {
        var method: HTTPMethod
        if rebuild {
            let parameters = [Parameter(name: "rebuild", value: "true")]
            method = HTTPMethod.post(.parameters(parameters))
        } else {
            method = HTTPMethod.post(.empty)
        }
        return Request<Tag>(path: "/api/v1/tags/\(id)/unfollow", method: method)
    }
    
    public static func links() -> Request<[Card]> {
        return Request<[Card]>(path: "/api/v1/trends/links")
    }
}

