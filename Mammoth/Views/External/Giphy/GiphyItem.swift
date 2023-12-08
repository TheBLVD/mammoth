//
//  GiphyItem.swift
//  Pods
//
//  Created by Brendan Lee on 3/9/17.
//
//

import Foundation
import UIKit

public struct GiphyItem: Mappable {
    
    public fileprivate(set) var type: String = "gif"
    
    public fileprivate(set) var identifier: String = ""
    
    public fileprivate(set) var slug: String = ""
    
    public fileprivate(set) var url: URL?
    
    public fileprivate(set) var bitlyGifURL: URL?
    
    public fileprivate(set) var bitlyURL: URL?
    
    public fileprivate(set) var embedURL: URL?
    
    public fileprivate(set) var username: String?
    
    public fileprivate(set) var source: URL?
    
    public fileprivate(set) var rating: SwiftyGiphyAPIContentRating = .g
    
    public fileprivate(set) var caption: String?
    
    public fileprivate(set) var contentURL: URL?
    
    public fileprivate(set) var sourceTld: String?
    
    public fileprivate(set) var sourcePostURL: URL?
    
    public fileprivate(set) var importDateTime: Date?
    
    public fileprivate(set) var trendingDateTime: Date?
    
    // MARK: Image options that are available. NOTE: Not all of these are always available.
    
    public fileprivate(set) var fixedHeightImage: GiphyImageSet?
    
    public fileprivate(set) var fixedHeightStillImage: GiphyImageSet?
    
    public fileprivate(set) var fixedHeightDownsampledImage: GiphyImageSet?
    
    public fileprivate(set) var fixedWidthImage: GiphyImageSet?
    
    public fileprivate(set) var fixedWidthStillImage: GiphyImageSet?
    
    public fileprivate(set) var fixedWidthDownsampledImage: GiphyImageSet?
    
    public fileprivate(set) var fixedHeightSmallImage: GiphyImageSet?
    
    public fileprivate(set) var fixedHeightSmallStillImage: GiphyImageSet?
    
    public fileprivate(set) var fixedWidthSmallImage: GiphyImageSet?
    
    public fileprivate(set) var fixedWidthSmallStillImage: GiphyImageSet?
    
    public fileprivate(set) var downsizedImage: GiphyImageSet?
    
    public fileprivate(set) var downsizedStillImage: GiphyImageSet?
    
    public fileprivate(set) var downsizedLargeImage: GiphyImageSet?
    
    public fileprivate(set) var originalImage: GiphyImageSet?
    
    public fileprivate(set) var originalStillImage: GiphyImageSet?
    
    public init?(map: Map)
    {
        
    }
    
    public mutating func mapping(map: Map) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let dateTransformer = DateFormatterTransform(dateFormatter: dateFormatter)

        type                            <- map["type"]
        identifier                      <- map["id"]
        slug                            <- map["slug"]
        url                             <- (map["url"], URLTransform())
        bitlyGifURL                     <- (map["bitly_gif_url"], URLTransform())
        bitlyURL                        <- (map["bitly_url"], URLTransform())
        embedURL                        <- (map["embed_url"], URLTransform())
        username                        <- map["username"]
        source                          <- (map["source"], URLTransform())
        rating                          <- map["rating"]
        caption                         <- map["caption"]
        contentURL                      <- (map["content_url"], URLTransform())
        sourceTld                       <- map["source_tld"]
        sourcePostURL                   <- (map["source_post_url"], URLTransform())
        importDateTime                  <- (map["import_datetime"], dateTransformer)
        trendingDateTime                <- (map["tendeing_datetime"], dateTransformer)
        
        fixedHeightImage                <- map["images.fixed_height"]
        fixedHeightStillImage           <- map["images.fixed_height_still"]
        fixedHeightDownsampledImage     <- map["images.fixed_height_downsampled"]
        
        fixedWidthImage                 <- map["images.fixed_width"]
        fixedWidthStillImage            <- map["images.fixed_width_still"]
        fixedWidthDownsampledImage      <- map["images.fixed_width_downsampled"]
        
        fixedHeightSmallImage           <- map["images.fixed_height_small"]
        fixedHeightSmallStillImage      <- map["images.fixed_height_small_still"]
        
        fixedWidthSmallImage            <- map["images.fixed_width_small"]
        fixedWidthSmallStillImage       <- map["images.fixed_width_small_still"]
        
        downsizedImage                  <- map["images.downsized"]
        downsizedStillImage             <- map["images.downsized_still"]
        downsizedLargeImage             <- map["images.downsized_large"]
        
        originalImage                   <- map["images.original"]
        originalStillImage              <- map["images.original_still"]
    }
    
    public func imageSetClosestTo(width: CGFloat, animated: Bool) -> GiphyImageSet? {
        
        var imageSetsForConsideration = [GiphyImageSet]()
        
        if animated
        {
            if fixedHeightImage != nil
            {
                imageSetsForConsideration.append(fixedHeightImage!)
            }
            
            if fixedHeightDownsampledImage != nil
            {
                imageSetsForConsideration.append(fixedHeightDownsampledImage!)
            }
            
            if fixedWidthImage != nil
            {
                imageSetsForConsideration.append(fixedWidthImage!)
            }
            
            if fixedWidthDownsampledImage != nil
            {
                imageSetsForConsideration.append(fixedWidthDownsampledImage!)
            }
            
            if fixedHeightSmallImage != nil
            {
                imageSetsForConsideration.append(fixedHeightSmallImage!)
            }
            
            if fixedWidthSmallImage != nil
            {
                imageSetsForConsideration.append(fixedWidthSmallImage!)
            }
            
            if downsizedImage != nil
            {
                imageSetsForConsideration.append(downsizedImage!)
            }
            
            if downsizedLargeImage != nil
            {
                imageSetsForConsideration.append(downsizedLargeImage!)
            }
            
            if originalImage != nil
            {
                imageSetsForConsideration.append(originalImage!)
            }
        }
        else
        {
            if fixedHeightStillImage != nil
            {
                imageSetsForConsideration.append(fixedHeightStillImage!)
            }
            
            if fixedWidthStillImage != nil
            {
                imageSetsForConsideration.append(fixedWidthStillImage!)
            }
            
            if fixedHeightSmallStillImage != nil
            {
                imageSetsForConsideration.append(fixedHeightSmallStillImage!)
            }
            
            if fixedWidthSmallStillImage != nil
            {
                imageSetsForConsideration.append(fixedWidthSmallStillImage!)
            }
            
            if downsizedStillImage != nil
            {
                imageSetsForConsideration.append(downsizedStillImage!)
            }
            
            if originalStillImage != nil
            {
                imageSetsForConsideration.append(originalStillImage!)
            }
        }
        
        // Search for matches
        
        guard imageSetsForConsideration.count > 0 else {
            return nil
        }
        
        var currentClosestSizeMatch: GiphyImageSet = imageSetsForConsideration[0]
        
        for item in imageSetsForConsideration
        {
            if item.width >= Int(width) && item.width < currentClosestSizeMatch.width
            {
                currentClosestSizeMatch = item
            }
        }
        
        return currentClosestSizeMatch
    }
}
