//
//  MessageDisclaimerCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 31/12/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class MessageDisclaimerCell: UITableViewCell {
    
    var bgView = UIView()
    var messageText = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        if #available(iOS 15.0, *) {
            self.focusEffect = UIFocusHaloEffect()
        }
        
        bgView.translatesAutoresizingMaskIntoConstraints = false
        bgView.backgroundColor = .secondaryLabel.withAlphaComponent(0.09)
        bgView.layer.cornerRadius = 14
        bgView.layer.cornerCurve = .continuous
        contentView.addSubview(bgView)
        
        messageText.translatesAutoresizingMaskIntoConstraints = false
        messageText.text = "Please note that private messages on Mastodon are not end-to-end encrypted. Do not share any sensitive information over Mastodon."
        messageText.numberOfLines = 0
        messageText.textColor = .secondaryLabel
        messageText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize + GlobalStruct.customTextSize, weight: .regular)
        bgView.addSubview(messageText)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "bgView" : bgView,
            "messageText" : messageText,
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-12-[bgView]-12-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[bgView]-12-|", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[messageText]-15-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[messageText]-12-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

