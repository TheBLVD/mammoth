//
//  FilterToots.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 03/02/2019.
//  Copyright © 2019 Shihab Mehboob. All rights reserved.
//

import Foundation

public struct FilterPosts {
    /// Fetches a user's filters.
    ///
    /// - Returns: Request for `[Filters]`.
    public static func all(range: RequestRange = .default) -> Request<[Filters]> {
        return Request<[Filters]>(path: "/api/v2/filters", method: .get(.empty))
    }
    
    /// Fetches a filter by id.
    ///
    /// - Parameters:
    ///   - id: The filter id.
    /// - Returns: Request for `Filters`.
    public static func singleFilter(id: String) -> Request<Filters> {
        return Request<Filters>(path: "/api/v2/filters/\(id)", method: .get(.empty))
    }
    
    /// Posts a new filter.
    ///
    /// - Parameters:
    ///   - phrase: The phrase to filter.
    ///   - context: The context to filter on.
    /// - Returns: Request for `Status`.
    public static func create(title: String, context: [String], filterAction: String, expiresAt: String? = nil) -> Request<Filters> {
        let parameters = [
            Parameter(name: "title", value: title),
            Parameter(name: "filter_action", value: filterAction),
            Parameter(name: "expires_in", value: expiresAt),
        ] + context.map(toArrayOfParameters(withName: "context"))

        let method = HTTPMethod.post(.parameters(parameters))
        return Request<Filters>(path: "/api/v2/filters", method: method)
    }
    
    public static func update(id: String, title: String, context: [String], filterAction: String, expiresAt: Int64? = nil) -> Request<Empty> {
        let parameters = [
            Parameter(name: "title", value: title),
            Parameter(name: "filter_action", value: filterAction),
            Parameter(name: "expires_in", value: expiresAt == nil ? "" : String(expiresAt!)),
        ] + context.map(toArrayOfParameters(withName: "context"))

        let method = HTTPMethod.put(.parameters(parameters))
        return Request<Empty>(path: "/api/v2/filters/\(id)", method: method)
    }
    
    /// Delete a filter.
    ///
    /// - Parameter id: The filter id.
    public static func delete(id: String) -> Request<Empty> {
        return Request<Empty>(path: "/api/v2/filters/\(id)", method: .delete(.empty))
    }
    
    public static func addKeyword(id: String, keyword: String) -> Request<FilterKeywords> {
        let parameter = [Parameter(name: "keyword", value: keyword)]
        let method = HTTPMethod.post(.parameters(parameter))
        return Request<FilterKeywords>(path: "/api/v2/filters/\(id)/keywords", method: method)
    }
    
    public static func removeKeyword(id: String) -> Request<Empty> {
        return Request<Empty>(path: "/api/v2/filters/keywords/\(id)", method: .delete(.empty))
    }
}
