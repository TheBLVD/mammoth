//
//  ProfileNoteCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 04/05/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class ProfileNoteCell: UITableViewCell {
    
    var altText = UITextField()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        altText.translatesAutoresizingMaskIntoConstraints = false
        altText.backgroundColor = .clear
        altText.text = ""
        altText.isUserInteractionEnabled = true
        altText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        altText.smartDashesType = .no
        altText.textColor = .label
        contentView.addSubview(altText)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "altText" : altText,
        ]

        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[altText]-15-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[altText(50)]-0-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
