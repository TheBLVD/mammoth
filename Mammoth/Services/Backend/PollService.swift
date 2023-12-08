//
//  PollService.swift
//  Mammoth
//
//  Created by Benoit Nolens on 07/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

struct PollService {
    
    static func vote(pollId: String, choices: [Int]) async throws -> Poll {
        let request = Polls.vote(id: pollId, choices: choices)
        let result = try await ClientService.runRequest(request: request)
        return result
    }
}
