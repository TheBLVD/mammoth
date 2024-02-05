//
//  GiphySingleGIFResponse.swift
//  Pods
//
//  Created by Brendan Lee on 3/15/17.
//
//

import Foundation

public struct GiphySingleGIFResponse: Mappable {
    
    public fileprivate(set) var gif: GiphyItem?
    
    public fileprivate(set) var meta: GiphyMeta?
    
    public init?(map: Map)
    {
        
    }
    
    mutating public func mapping(map: Map) {
        
        gif         <- map["data"]
        meta        <- map["meta"]
    }
}
