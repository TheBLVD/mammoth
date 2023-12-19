//
//  UIView+Constraints.swift
//  Mammoth
//
//  Created by Benoit Nolens on 09/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    @discardableResult
    func addHorizontalFillConstraints(withParent parentView: UIView, andMaxWidth maxWidth: CGFloat, constant: CGFloat? = nil) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        // Fill width of parent if not exceeding max width
        let widthConstraint = self.widthAnchor.constraint(equalTo: parentView.layoutMarginsGuide.widthAnchor, constant: constant ?? 0)
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true
        // Make sure the max width is never exceeded
        let maxWidthConstraint = self.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth)
        maxWidthConstraint.priority = .required
        maxWidthConstraint.isActive = true
        
        return [widthConstraint, maxWidthConstraint]
    }
}
