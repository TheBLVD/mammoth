//
//  Polls.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 05/03/2019.
//  Copyright © 2019 Shihab Mehboob. All rights reserved.
//

import Foundation

public struct Polls {
    
    /// Gets a single poll.
    ///
    /// - Parameter id: The poll id.
    /// - Returns: Request for `Poll`.
    public static func poll(id: String) -> Request<Poll> {
        return Request<Poll>(path: "/api/v1/polls/\(id)")
    }
    
    /// Vote on a poll.
    ///
    /// - Parameter id: The notification id.
    /// - Returns: Request for `Empty`.
    public static func vote(id: String, choices: [Int]) -> Request<Poll> {
        let parameter = choices.map(toArrayOfParameters(withName: "choices"))
        let method = HTTPMethod.post(.parameters(parameter))
        
        return Request<Poll>(path: "/api/v1/polls/\(id)/votes", method: method)
    }
}
