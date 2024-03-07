//
//  MessageCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 17/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class MessageCell: UITableViewCell {
    
    var bgView = UIView()
    var profileIcon = UIButton()
    var lockedBadge = UIImageView()
    var lockedBackground = UIView()
    var userTag = UILabel()
    var userName = UILabel()
    var bioText = ActiveLabel()
    var indi = UIView()
    var dateTime = UILabel()
    
    var profileIcon21 = UIButton()
    var profileIcon22 = UIButton()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        bgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bgView)
        
        profileIcon.translatesAutoresizingMaskIntoConstraints = false
        profileIcon.layer.cornerRadius = 25
        profileIcon.backgroundColor = .custom.quoteTint
        profileIcon.contentMode = .scaleAspectFill
        profileIcon.layer.masksToBounds = true
        profileIcon.imageView?.contentMode = .scaleAspectFill
        profileIcon.contentMode = .scaleAspectFill
        profileIcon.accessibilityLabel = NSLocalizedString("navigator.profile", comment: "")
        bgView.addSubview(profileIcon)
        
        // create 2 user group
        
        profileIcon21.frame = CGRect(x: -1, y: -1, width: 28, height: 28)
        profileIcon21.layer.cornerRadius = 14
        profileIcon21.backgroundColor = .custom.quoteTint
        profileIcon21.contentMode = .scaleAspectFill
        profileIcon21.layer.masksToBounds = true
        profileIcon21.imageView?.contentMode = .scaleAspectFill
        profileIcon21.contentMode = .scaleAspectFill
        profileIcon21.accessibilityLabel = NSLocalizedString("navigator.profile", comment: "")
        profileIcon21.alpha = 0
        profileIcon.addSubview(profileIcon21)
        
        profileIcon22.frame = CGRect(x: 26, y: 26, width: 28, height: 28)
        profileIcon22.layer.cornerRadius = 14
        profileIcon22.backgroundColor = .custom.quoteTint
        profileIcon22.contentMode = .scaleAspectFill
        profileIcon22.layer.masksToBounds = true
        profileIcon22.imageView?.contentMode = .scaleAspectFill
        profileIcon22.contentMode = .scaleAspectFill
        profileIcon22.accessibilityLabel = NSLocalizedString("navigator.profile", comment: "")
        profileIcon22.alpha = 0
        profileIcon.addSubview(profileIcon22)
        
        let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: GlobalStruct.smallerFontSize, weight: .bold)
        lockedBadge.translatesAutoresizingMaskIntoConstraints = false
        lockedBadge.backgroundColor = .clear
        lockedBadge.image = UIImage(systemName: "checkmark.seal.fill", withConfiguration: symbolConfig0)?.withTintColor(UIColor.label, renderingMode: .alwaysOriginal)
        lockedBadge.alpha = 0
        bgView.addSubview(lockedBadge)
        
        lockedBackground.backgroundColor = .custom.backgroundTint
        lockedBackground.frame = CGRect(x: 57, y: 51, width: 12, height: 12)
        lockedBackground.layer.cornerRadius = 6
        lockedBackground.alpha = 0
        bgView.insertSubview(lockedBackground, belowSubview: lockedBadge)
        
        userName.translatesAutoresizingMaskIntoConstraints = false
        userName.textAlignment = .left
        userName.textColor = UIColor.label
        userName.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        bgView.addSubview(userName)
        
        userTag.translatesAutoresizingMaskIntoConstraints = false
        userTag.textAlignment = .left
        userTag.textColor = UIColor.secondaryLabel
        userTag.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
        bgView.addSubview(userTag)
        
        bioText.translatesAutoresizingMaskIntoConstraints = false
        bioText.numberOfLines = 0
        bioText.textColor = .custom.mainTextColor
        bioText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        bioText.enabledTypes = [.mention, .hashtag, .url, .email]
        bioText.mentionColor = .custom.baseTint
        bioText.hashtagColor = .custom.baseTint
        bioText.URLColor = .custom.baseTint
        bioText.emailColor = .custom.baseTint
        bioText.urlMaximumLength = 30
        bgView.addSubview(bioText)
        
        indi.translatesAutoresizingMaskIntoConstraints = false
        indi.layer.cornerRadius = 4
        indi.backgroundColor = .custom.baseTint
        bgView.addSubview(indi)
        indi.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        dateTime.translatesAutoresizingMaskIntoConstraints = false
        dateTime.textAlignment = .right
        dateTime.textColor = UIColor.secondaryLabel
        dateTime.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
        bgView.addSubview(dateTime)
        dateTime.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let viewsDict = [
            "bgView" : bgView,
            "profileIcon" : profileIcon,
            "lockedBadge" : lockedBadge,
            "userName" : userName,
            "userTag" : userTag,
            "bioText" : bioText,
            "indi" : indi,
            "dateTime" : dateTime,
        ]
        let metricsDict = [
            "offset" : 14 + ((UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize)/2) - 2
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
#if targetEnvironment(macCatalyst)
        if GlobalStruct.singleColumn {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-85-[bgView]-85-|", options: [], metrics: nil, views: viewsDict))
        } else {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        }
#elseif !targetEnvironment(macCatalyst)
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && self.window?.traitCollection.horizontalSizeClass != .compact {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-85-[bgView]-85-|", options: [], metrics: nil, views: viewsDict))
        } else {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        }
#endif
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-52-[lockedBadge(20)]", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-46-[lockedBadge(20)]", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[profileIcon(50)]-12-[userName]-4-[userTag]-(>=20)-[indi(8)]-4-[dateTime]-16-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[profileIcon(50)]-12-[bioText]-16-|", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[profileIcon(50)]-(>=14)-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userName]-0-[bioText]-14-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userTag]-0-[bioText]", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(offset)-[indi(8)]", options: [], metrics: metricsDict, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[dateTime]", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
