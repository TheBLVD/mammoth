//
//  MammothCache.swift
//  Mammoth
//
//  Created by Joey Despiuvas on 16/03/24
//  Copyright © 2024 The BLVD. All rights reserved.
//

import Foundation
import SDWebImage

class MammothCache: SKImageCacheable {
    func imageForKey(_ key: String) -> UIImage? {
        return SDImageCache.shared.imageFromCache(forKey: key)
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        SDImageCache.shared.store(image, forKey: key)
    }
    
    func removeImageForKey(_ key: String) {
        SDImageCache.shared.removeImage(forKey: key)
    }
    
    func removeAllImages() {
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
        
    }
    
    
}
