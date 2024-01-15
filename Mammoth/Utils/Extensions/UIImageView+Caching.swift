//
//  UIImageView+Caching.swift
//  Mammoth
//
//  Created by Benoit Nolens on 15/12/2023
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import SDWebImage

extension UIImageView {
    func ma_setImage(with imageURL: URL, cachedImage: UIImage?, placeholder: UIImage? = nil, imageTransformer: SDImageTransformer, completed: @escaping (UIImage?) -> Void) {
        self.sd_imageTransition = .fade
        if let cachedImage {
            self.image = cachedImage
        } else {
            self.sd_setImage(
                with: imageURL,
                placeholderImage: placeholder,
                context: [.imageTransformer: imageTransformer],
                progress: nil
            ) { image, error, _, _ in
                if let error {
                    // Likely the image request was cancelled
                } else {
                    completed(image)
                }
            }
        }
    }
}
