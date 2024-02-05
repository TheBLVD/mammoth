//
//  AltTextCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 10/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class AltTextCell: UITableViewCell {
    
    var altText = UITextField()
    var charCount = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        altText.translatesAutoresizingMaskIntoConstraints = false
        altText.placeholder = "Option 1"
        altText.accessibilityLabel = "Option 1"
        altText.backgroundColor = .clear
        altText.text = ""
        altText.textColor = UIColor.label
        altText.isUserInteractionEnabled = true
        altText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        altText.smartDashesType = .no
        contentView.addSubview(altText)
        
        charCount.translatesAutoresizingMaskIntoConstraints = false
        charCount.text = ""
        charCount.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        charCount.textAlignment = .right
        charCount.textColor = .custom.baseTint
        contentView.addSubview(charCount)
        charCount.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "altText" : altText,
            "charCount" : charCount,
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[altText]-(>=15)-[charCount]-15-|", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[altText]-12-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[charCount]", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class AltTextMultiCell: UITableViewCell {
    
    var altText = MultilineTextField()
    var charCount = UILabel()
    var showCharCount = false {
        didSet {
            self.updateConstraints()
        }
    }
    var charCountConstraints: [NSLayoutConstraint] = []
    var noCharCountConstraints: [NSLayoutConstraint] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        altText.translatesAutoresizingMaskIntoConstraints = false
        altText.placeholder = "Option 1"
        altText.accessibilityLabel = "Option 1"
        altText.backgroundColor = .clear
        altText.text = ""
        altText.textColor = UIColor.label
        altText.isUserInteractionEnabled = true
        altText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        altText.smartDashesType = .no
        altText.isScrollEnabled = false
        contentView.addSubview(altText)
        
        charCount.translatesAutoresizingMaskIntoConstraints = false
        charCount.text = ""
        charCount.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        charCount.textAlignment = .right
        charCount.textColor = .custom.baseTint
        contentView.addSubview(charCount)
        charCount.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "altText" : altText,
            "charCount" : charCount,
        ]

        charCountConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[altText]-(>=15)-[charCount]-15-|", options: [], metrics: nil, views: viewsDict))
        charCountConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[altText]-12-|", options: [], metrics: nil, views: viewsDict))
        charCountConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[charCount]", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(charCountConstraints)

        noCharCountConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[altText]-15-|", options: [], metrics: nil, views: viewsDict))
        noCharCountConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[altText]-12-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(noCharCountConstraints)

       self.updateConstraints()
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        if showCharCount {
            charCount.isHidden = false
            NSLayoutConstraint.activate(charCountConstraints)
            NSLayoutConstraint.deactivate(noCharCountConstraints)
        } else {
            charCount.isHidden = true
            NSLayoutConstraint.activate(noCharCountConstraints)
            NSLayoutConstraint.deactivate(charCountConstraints)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class AltTextCell2: UITableViewCell {
    
    var altText = UITextField()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        altText.translatesAutoresizingMaskIntoConstraints = false
        altText.placeholder = "Option 1"
        altText.accessibilityLabel = "Option 1"
        altText.backgroundColor = .clear
        altText.text = ""
        altText.textColor = UIColor.label
        altText.isUserInteractionEnabled = true
        altText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        altText.smartDashesType = .no
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

