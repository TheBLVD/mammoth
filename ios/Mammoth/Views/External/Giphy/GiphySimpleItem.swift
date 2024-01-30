//
//  GiphySimpleItem.swift
//  Pods
//
//  Created by Brendan Lee on 3/15/17.
//
//

import Foundation

public struct GiphySimpleItem: Mappable {
    
    public fileprivate(set) var type: String = "gif"
    
    public fileprivate(set) var identifier: String = ""
    
    public fileprivate(set) var url: URL?
    
    // Any of these could be nil
    public fileprivate(set) var imageOriginalURL: URL?
    public fileprivate(set) var imageURL: URL?
    public fileprivate(set) var imagemp4URL: URL?
    public fileprivate(set) var imageFrameCount: Int = 0
    public fileprivate(set) var imageWidth: Int = 0
    public fileprivate(set) var imageHeight: Int = 0
    
    public fileprivate(set) var fixedHeightDownsampledURL: URL?
    public fileprivate(set) var fixedHeightDownsampledWidth: Int = 0
    public fileprivate(set) var fixedHeightDownsampledHeight: Int = 0
    
    public fileprivate(set) var fixedWidthDownsampledURL: URL?
    public fileprivate(set) var fixedWidthDownsampledWidth: Int = 0
    public fileprivate(set) var fixedWidthDownsampledHeight: Int = 0
    
    public fileprivate(set) var fixedHeightSmallURL: URL?
    public fileprivate(set) var fixedHeightSmallStillURL: URL?
    public fileprivate(set) var fixedHeightSmallWidth: Int = 0
    public fileprivate(set) var fixedHeightSmallHeight: Int = 0
    
    public fileprivate(set) var fixedWidthSmallURL: URL?
    public fileprivate(set) var fixedWidthSmallStillURL: URL?
    public fileprivate(set) var fixedWidthSmallWidth: Int = 0
    public fileprivate(set) var fixedWidthSmallHeight: Int = 0
    
    public init?(map: Map)
    {
        
    }
    
    public mutating func mapping(map: Map) {
        
        type                            <- map["type"]
        identifier                      <- map["id"]
        url                             <- (map["url"], URLTransform())
        
        imageOriginalURL                <- (map["image_original_url"], URLTransform())
        imageURL                        <- (map["image_url"], URLTransform())
        imagemp4URL                     <- (map["image_mp4_url"], URLTransform())
        imageFrameCount                 <- (map["image_frames"], stringToIntTransform)
        imageWidth                      <- (map["image_width"], stringToIntTransform)
        imageHeight                     <- (map["image_height"], stringToIntTransform)
        
        fixedHeightDownsampledURL       <- (map["fixed_height_downsampled_url"], URLTransform())
        fixedHeightDownsampledWidth     <- (map["fixed_height_downsampled_width"], stringToIntTransform)
        fixedHeightDownsampledHeight    <- (map["fixed_height_downsampled_height"], stringToIntTransform)
        
        fixedWidthDownsampledURL        <- (map["fixed_width_downsampled_url"], URLTransform())
        fixedWidthDownsampledHeight     <- (map["fixed_width_downsampled_height"], stringToIntTransform)
        fixedWidthDownsampledWidth      <- (map["fixed_width_downsampled_width"], stringToIntTransform)
        
        fixedHeightSmallURL             <- (map["fixed_height_small_url"], URLTransform())
        fixedHeightSmallStillURL        <- (map["fixed_height_small_still_url"], URLTransform())
        fixedHeightSmallWidth           <- (map["fixed_height_small_width"], stringToIntTransform)
        fixedHeightSmallHeight          <- (map["fixed_height_small_height"], stringToIntTransform)
        
        fixedWidthSmallURL              <- (map["fixed_width_small_url"], URLTransform())
        fixedWidthSmallStillURL         <- (map["fixed_width_small_still_url"], URLTransform())
        fixedWidthSmallWidth            <- (map["fixed_width_small_width"], stringToIntTransform)
        fixedWidthSmallHeight           <- (map["fixed_width_small_height"], stringToIntTransform)
    }
    
}
