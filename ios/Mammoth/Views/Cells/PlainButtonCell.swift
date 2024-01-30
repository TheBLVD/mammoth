//
//  PlainButtonCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 20/04/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class PlainButtonCell: UITableViewCell {
    
    var bg = UIButton()
    var titleText = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.backgroundColor = .clear
        contentView.addSubview(bg)
        
        titleText.translatesAutoresizingMaskIntoConstraints = false
        titleText.backgroundColor = .clear
        titleText.text = ""
        titleText.textColor = UIColor.label
        titleText.isUserInteractionEnabled = false
        titleText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        contentView.addSubview(titleText)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "bg" : bg,
            "titleText" : titleText,
        ]
        let metricsDict = [
            "offset" : UIFont.preferredFont(forTextStyle: .body).pointSize + 40
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bg]-0-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(offset)-[titleText]-15-|", options: [], metrics: metricsDict, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[bg]-0-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[titleText]-12-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
