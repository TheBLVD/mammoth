//
//  ClientError.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/22/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public enum ClientError: Error {
    /// Failed to build the URL to make the request.
    case malformedURL
    /// Failed to parse the Mastodon's JSON reponse.
    case malformedJSON
    /// Failed to parse Mastodon's model.
    case invalidModel
    /// Generic error.
    case genericError
    ///  Network error.
    case networkError(_ statusCode: Int)
    /// The Mastodon service returned an error.
    case mastodonError(_ message: String)
}

extension ClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .malformedURL:
            return "Malformed URL"
        case .malformedJSON:
            return "Malformed JSON"
        case .invalidModel:
            return "Invalid model"
        case .genericError:
            return "Unexpected error"
        case let .mastodonError(message):
            return message
        case let .networkError(statusCode):
            return "Network error; status code \(statusCode)"
        }
    }
}
