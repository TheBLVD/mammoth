//
//  GiphyImageSet.swift
//  Pods
//
//  Created by Brendan Lee on 3/9/17.
//
//

import Foundation

public struct GiphyImageSet: Mappable {
    
    public fileprivate(set) var url: URL?
    
    public fileprivate(set) var width: Int = 0
    
    public fileprivate(set) var height: Int = 0
    
    public fileprivate(set) var size: Int = 0
    
    public fileprivate(set) var mp4URL: URL?
    
    public fileprivate(set) var mp4Size: Int = 0
    
    public fileprivate(set) var webpURL: URL?
    
    public fileprivate(set) var webpSize: Int = 0
    
    public init?(map: Map)
    {
        
    }
    
    mutating public func mapping(map: Map) {
        
        url                 <- (map["url"], URLTransform())
        width               <- (map["width"], stringToIntTransform)
        height              <- (map["height"], stringToIntTransform)
        size                <- (map["size"], stringToIntTransform)
        mp4URL              <- (map["mp4"], URLTransform())
        mp4Size             <- (map["mp4_size"], stringToIntTransform)
        webpURL             <- (map["webp"], URLTransform())
        webpSize            <- (map["webp_size"], stringToIntTransform)
    }
}
