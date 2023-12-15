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
    func ma_setImage(with imageURL: URL, cachedImage: UIImage?, imageTransformer: SDImageTransformer, completed: @escaping (UIImage?) -> Void) {
        if let cachedImage {
            self.image = cachedImage
        } else {
            self.sd_setImage(
                with: imageURL,
                placeholderImage: nil,
                context: [.imageTransformer: imageTransformer],
                progress: nil
            ) { image, _, _, _ in
                completed(image)
            }
        }
    }
}
