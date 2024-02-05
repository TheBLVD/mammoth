//
//  GiphyPagination.swift
//  Pods
//
//  Created by Brendan Lee on 3/9/17.
//
//

import Foundation

public struct GiphyPagination: Mappable {
    
    public fileprivate(set) var count: Int = 0
    public fileprivate(set) var offset: Int = 0
    
    public init?(map: Map)
    {
        
    }
    
    mutating public func mapping(map: Map) {
        
        count   <- map["count"]
        offset  <- map["offset"]
    }
}
