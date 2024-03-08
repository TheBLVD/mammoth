//
//  SignInInstanceCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 04/11/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class SignInInstanceCell: UITableViewCell {
    
    var profileIcon = UIButton()
    var titleLabel = UILabel()
    var sfw = UIButton()
    var bio = ActiveLabel()
    var users = UILabel()
    var lang = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        if #available(iOS 15.0, *) {
            self.focusEffect = UIFocusHaloEffect()
        }
        
        profileIcon.translatesAutoresizingMaskIntoConstraints = false
        profileIcon.backgroundColor = .systemGroupedBackground
        profileIcon.layer.cornerRadius = 20
        profileIcon.layer.masksToBounds = true
        profileIcon.imageView?.contentMode = .scaleAspectFill
        profileIcon.contentMode = .scaleAspectFill
        profileIcon.accessibilityLabel = NSLocalizedString("navigator.profile", comment: "")
        profileIcon.isUserInteractionEnabled = false
        contentView.addSubview(profileIcon)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 1
        titleLabel.text = ""
        titleLabel.textColor = .custom.highContrast
        titleLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        contentView.addSubview(titleLabel)
        
        sfw.translatesAutoresizingMaskIntoConstraints = false
        sfw.setTitle("Non-Explicit", for: .normal)
        sfw.setTitleColor(.white, for: .normal)
        sfw.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold)
        sfw.backgroundColor = UIColor(red: 63/255, green: 180/255, blue: 78/255, alpha: 1)
        sfw.layer.cornerRadius = 6
        sfw.layer.cornerCurve = .continuous
        sfw.isHidden = true
        sfw.contentEdgeInsets = UIEdgeInsets(top: 2, left: 5, bottom: 0, right: 5)
        sfw.sizeToFit()
        sfw.isUserInteractionEnabled = false
        contentView.addSubview(sfw)
        
        bio.translatesAutoresizingMaskIntoConstraints = false
        bio.commitUpdates {
            self.bio.numberOfLines = 0
            self.bio.text = ""
            self.bio.textColor = UIColor.custom.mediumContrast
            self.bio.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular)
            self.bio.enabledTypes = [.mention, .hashtag, .email, .url]
            self.bio.mentionColor = .custom.mediumContrast
            self.bio.hashtagColor = .custom.mediumContrast
            self.bio.emailColor = .custom.mediumContrast
            self.bio.URLColor = .custom.mediumContrast
            self.bio.linkWeight = .semibold
        }
        contentView.addSubview(bio)
        
        users.translatesAutoresizingMaskIntoConstraints = false
        users.numberOfLines = 1
        users.text = ""
        users.textColor = UIColor.custom.feintContrast
        users.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular)
        contentView.addSubview(users)
        
        lang.translatesAutoresizingMaskIntoConstraints = false
        lang.numberOfLines = 1
        lang.text = ""
        lang.textColor = UIColor.custom.feintContrast
        lang.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular)
        contentView.addSubview(lang)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "profileIcon" : profileIcon,
            "titleLabel" : titleLabel,
            "sfw" : sfw,
            "bio" : bio,
            "users" : users,
            "lang" : lang,
        ]
        let metrics = [
            "he" : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold).pointSize + 4
        ]
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-13-[profileIcon(40)]-12-[titleLabel]-8-[sfw]-(>=13)-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-13-[profileIcon(40)]-12-[bio]-13-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-13-[profileIcon(40)]-12-[users]-8-[lang]-(>=13)-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[profileIcon(40)]", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-13-[sfw(he)]", options: [], metrics: metrics, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[titleLabel]-4-[users]-4-[bio]-12-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[titleLabel]-4-[lang]-4-[bio]-12-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
