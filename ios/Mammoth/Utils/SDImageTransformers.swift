//
//  SDImageTransformers.swift
//  Mammoth
//
//  Created by Benoit Nolens on 14/12/2023
//  Copyright © 2023 The BLVD. All rights reserved.
//

import SDWebImage

class ScaleDownTransformer : NSObject, SDImageTransformer {
    var transformerKey: String = "ScaleDownTransformer"
    
    func transformedImage(with image: UIImage, forKey key: String) -> UIImage? {
        /// scale down to the device scale factor
        let ratio = image.scale / UIScreen.main.scale
        
        if ratio > 1 {
            let newSize = CGSize(width: image.size.width / ratio, height: image.size.height / ratio)
            let newImage = image.sd_resizedImage(with: newSize, scaleMode: .fill)
            guard let cgImage = newImage?.cgImage else {
                return image
            }
            /// make the scale factor match the currernt device, both @3x, @2x, @1x share the same logic point size
            return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: image.imageOrientation)
        } else {
            return image
        }
    }
}
