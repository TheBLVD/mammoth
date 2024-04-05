//
//  PostCardTextLabel.swift
//  Mammoth
//
//  Created by Benoit Nolens on 03/04/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import Foundation
import MetaTextKit

class PostCardTextLabel: MetaLabel {
    
    private var cachedSize: CGSize = .zero
    
    open override var intrinsicContentSize: CGSize {
        if self.cachedSize == .zero {
            return super.intrinsicContentSize
        } else {
            return .init(width: self.cachedSize.width, height: self.cachedSize.height)
        }
    }
}

extension PostCardTextLabel {
    func applySize(size: CGSize) {
        self.cachedSize = size
//        setNeedsDisplay()
    }
}
