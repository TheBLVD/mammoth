//
//  String+Image.swift
//  Mammoth
//
//  Created by Benoit Nolens on 30/10/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension String {
    func image(withAttributes attributes: [NSAttributedString.Key: Any]? = nil, size: CGSize? = nil) -> UIImage? {
        let size = size ?? (self as NSString).size(withAttributes: attributes)
        return UIGraphicsImageRenderer(size: size).image { _ in
            (self as NSString).draw(in: CGRect(origin: .zero, size: size),
                                    withAttributes: attributes)
        }
    }
    
}
