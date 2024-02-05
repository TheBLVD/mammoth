//
//  Filter.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 03/02/2019.
//  Copyright © 2019 Shihab Mehboob. All rights reserved.
//

import Foundation

public class FilterResult: Codable {
    public var filter: Filters2
    public let keywordMatches: [String]
//    public let statusMatches: [String]
    
    private enum CodingKeys: String, CodingKey {
        case filter
        case keywordMatches = "keyword_matches"
//        case statusMatches = "status_matches"
    }
}

public class Filters2: Codable {
    public var id: String
    public let title: String
    public let context: [String]
    public let filterAction: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case context
        case filterAction = "filter_action"
    }
}

public class Filters: Codable {
    public var id: String
    public let title: String
    public let context: [String]
    public let expiresAt: String?
    public let filterAction: String
    public var keywords: [FilterKeywords]
    public let statuses: [FilterStatuses]
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case context
        case expiresAt = "expires_at"
        case filterAction = "filter_action"
        case keywords
        case statuses
    }
}

public class FilterKeywords: Codable {
    public var id: String
    public let keyword: String
    public let wholeWord: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id
        case keyword
        case wholeWord = "whole_word"
    }
}

public class FilterStatuses: Codable {
    public var id: String
    public let statusId: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case statusId = "status_id"
    }
}

extension Filters: Equatable {}

public func ==(lhs: Filters, rhs: Filters) -> Bool {
    let areEqual = lhs.id == rhs.id &&
        lhs.id == rhs.id
    
    return areEqual
}

