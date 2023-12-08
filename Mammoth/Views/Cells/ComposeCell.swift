//
//  ComposeCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 07/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class ComposeCell: UITableViewCell {
    
    var profileIcon = UIButton()
    var post = UITextView()
    var topThreadLine = UIView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.topThreadLine.alpha = 0
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // thread lines
        
        topThreadLine.translatesAutoresizingMaskIntoConstraints = false
        topThreadLine.backgroundColor = .custom.quoteTint
        topThreadLine.alpha = 0
        contentView.addSubview(topThreadLine)
        
        profileIcon.translatesAutoresizingMaskIntoConstraints = false
        profileIcon.backgroundColor = .custom.quoteTint
        profileIcon.imageView?.contentMode = .scaleAspectFill
        profileIcon.layer.masksToBounds = true
        profileIcon.imageView?.contentMode = .scaleAspectFill
        profileIcon.contentMode = .scaleAspectFill
        profileIcon.accessibilityLabel = "Switch Profile"
        if GlobalStruct.circleProfiles {
            profileIcon.layer.cornerRadius = 23
        } else {
            profileIcon.layer.cornerRadius = 10
        }
        contentView.addSubview(profileIcon)
        
        post.backgroundColor = .clear
        post.text = ""
        post.textColor = UIColor.label
        post.isEditable = true
        post.isUserInteractionEnabled = true
        post.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        post.smartDashesType = .no
        post.isScrollEnabled = false
        // Autocorrect is replacing text in an unexpected manner
        if ProcessInfo.processInfo.isiOSAppOnMac {
            post.autocorrectionType = .no
        }
        contentView.addSubview(post)
        post.translatesAutoresizingMaskIntoConstraints = false
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "profileIcon" : profileIcon,
            "topThreadLine" : topThreadLine,
            "post" : post
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-40-[topThreadLine(2)]", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[topThreadLine(24)]", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[profileIcon(46)]", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-20-[profileIcon(46)]", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-80-[post]-15-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-15-[post(>=50)]-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
