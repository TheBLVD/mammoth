//
//  UILabel+IsTruncated.swift
//  Mammoth
//
//  Created by Benoit Nolens on 06/02/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit
import MetaTextKit

extension UILabel {

    var isTruncated: Bool {

        guard let labelText = attributedText else {
            return false
        }

        let labelTextSize = labelText.boundingRect(
            with: CGSize(width: frame.size.width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            context: nil).size

        return labelTextSize.height > bounds.size.height
    }
}
