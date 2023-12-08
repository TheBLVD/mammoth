//
//  ExtendedTouchView.swift
//  Mammoth
//
//  Created by Riley Howard on 6/20/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class ExtendedTouchView: UIView {
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if super.point(inside: point, with: event) { return true }
        for subview in subviews {
            let subviewPoint = subview.convert(point, from: self)
            if subview.point(inside: subviewPoint, with: event) { return true }
        }
        return false
    }

    
}
