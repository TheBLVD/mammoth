//
//  String+Height.swift
//  Mammoth
//
//  Created by Benoit Nolens on 02/04/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit

extension String {
    func height(width: CGFloat, font: UIFont, maxHeight: CGFloat = .greatestFiniteMagnitude) -> CGFloat {
        (self as NSString).boundingRect(
            with: CGSize(width: width, height: maxHeight),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil)
            .height
    }
    
    func height(width: CGFloat, attributes: [NSAttributedString.Key: Any]?, maxHeight: CGFloat = .greatestFiniteMagnitude) -> CGFloat {
        (self as NSString).boundingRect(
            with: CGSize(width: width, height: maxHeight),
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil)
            .height
    }
    
    func numberOfParagraphs() -> Int {
        self.components(separatedBy: "<p>").count-1
    }
}
