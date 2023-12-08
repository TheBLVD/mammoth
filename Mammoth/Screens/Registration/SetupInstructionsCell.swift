//
//  SetupInstructionsCell.swift
//  Mammoth
//
//  Created by Riley Howard on 10/9/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class SetupInstructionsCell: UITableViewCell {
    static let reuseIdentifier = "SetupInstructionsCell"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var instructionsLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    public func configure(title: String, instructions: String) {
        titleLabel.text = title
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.75
        paragraphStyle.lineSpacing = 0
        paragraphStyle.minimumLineHeight = 60
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.foregroundColor: UIColor.custom.highContrast]
        let attributedString = NSAttributedString(string: title, attributes: attributes)
        titleLabel.attributedText = attributedString
        
        instructionsLabel.text = instructions
    }
}


