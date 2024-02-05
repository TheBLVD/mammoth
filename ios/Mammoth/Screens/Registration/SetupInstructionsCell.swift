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

    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var instructionsLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    public func configure(title: String, instructions: String) {
        // For iPad, convert \n -> spaces
        let cellTitle: String
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            cellTitle = title.components(separatedBy: "\n").joined(separator: " ")
        } else {
            cellTitle = title
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.7
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.foregroundColor: UIColor.custom.highContrast,
            NSAttributedString.Key.kern: 0.48,
        ]
        let attributedString = NSAttributedString(string: cellTitle, attributes: attributes)
        titleTextView.attributedText = attributedString
        titleTextView.font = UIFont(name: "InstrumentSerif-Regular", size: 48)
        
        titleTextView.backgroundColor = .clear
        instructionsLabel.text = instructions
    }
}


