//
//  GiphyMeta.swift
//  Pods
//
//  Created by Brendan Lee on 3/9/17.
//
//

import Foundation

public struct GiphyMeta: Mappable {
    
    public fileprivate(set) var status: Int = 200
    public fileprivate(set) var message: String?
    
    public init?(map: Map)
    {
        
    }
    
    mutating public func mapping(map: Map) {
        
        status   <- map["status"]
        message  <- map["msg"]
    }
}
