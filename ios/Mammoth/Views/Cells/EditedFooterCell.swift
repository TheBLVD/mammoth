//
//  EditedFooterCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 10/10/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class EditedFooterCell: UITableViewCell {
    
    var dateTime = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        dateTime.translatesAutoresizingMaskIntoConstraints = false
        dateTime.textAlignment = .left
        dateTime.textColor = UIColor.secondaryLabel
        self.contentView.addSubview(dateTime)
        
        let attachment1 = NSTextAttachment()
        let symbolConfig1 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .regular)
        let downImage1 = UIImage(systemName: "clock", withConfiguration: symbolConfig1) ?? UIImage()
        attachment1.image = downImage1.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal)
        let attStringNewLine000 = NSMutableAttributedString()
        let attStringNewLine00 = NSMutableAttributedString(string: "Edit version history - oldest to newest ", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular), NSAttributedString.Key.foregroundColor : UIColor.secondaryLabel])
        let attString00 = NSAttributedString(attachment: attachment1)
        attStringNewLine000.append(attStringNewLine00)
        attStringNewLine000.append(attString00)
        dateTime.attributedText = attStringNewLine000
        
        let viewsDict = [
            "dateTime" : dateTime,
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[dateTime]-20-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[dateTime]-12-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}



