//
//  TrendsCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 25/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class TrendsFeedCell: UITableViewCell {
    
    var bgView = UIView()
    var titleLabel = UILabel()
    var bio = ActiveLabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        if #available(iOS 15.0, *) {
            self.focusEffect = UIFocusHaloEffect()
        }
        
        bgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bgView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 1
        titleLabel.text = ""
        titleLabel.textColor = .custom.mainTextColor
        titleLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        bgView.addSubview(titleLabel)
        
        bio.translatesAutoresizingMaskIntoConstraints = false
        bio.commitUpdates {
            self.bio.numberOfLines = 0
            self.bio.text = ""
            self.bio.textColor = UIColor.secondaryLabel
            self.bio.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize + GlobalStruct.customTextSize, weight: .regular)
            self.bio.enabledTypes = [.mention, .hashtag, .cashtag, .url]
        }
        bgView.addSubview(bio)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "bgView" : bgView,
            "titleLabel" : titleLabel,
            "bio" : bio,
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
#if targetEnvironment(macCatalyst)
        if GlobalStruct.singleColumn {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        } else {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        }
#elseif !targetEnvironment(macCatalyst)
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && self.window?.traitCollection.horizontalSizeClass != .compact {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        } else {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        }
#endif
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[titleLabel]-20-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[bio]-20-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[titleLabel]-3-[bio]-12-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(_ titleLabel: String, bio: String, mode: String? = "", fave: Bool? = false) {
        self.titleLabel.text = titleLabel
        
        self.bio.commitUpdates {
            self.bio.mentionColor = .custom.baseTint
            self.bio.hashtagColor = .custom.baseTint
            self.bio.cashtagColor = .custom.baseTint
            self.bio.URLColor = .custom.baseTint
            self.bio.urlMaximumLength = 30
            
            if fave ?? false {
                self.bio.numberOfLines = 1
                let attachment00 = NSTextAttachment()
                let symbolConfig00 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular)
                let downImage00 = UIImage(systemName: "pin.fill", withConfiguration: symbolConfig00)
                attachment00.image = downImage00?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
                let normalFont00 = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
                let attStringNewLine000 = NSMutableAttributedString()
                let attStringNewLine00 = NSMutableAttributedString(string: " \(bio)", attributes: [NSAttributedString.Key.font : normalFont00, NSAttributedString.Key.foregroundColor : UIColor.secondaryLabel])
                let attString00 = NSAttributedString(attachment: attachment00)
                attStringNewLine000.append(attString00)
                attStringNewLine000.append(attStringNewLine00)
                self.bio.attributedText = attStringNewLine000
            } else if mode == "private" {
                let attachment00 = NSTextAttachment()
                let symbolConfig00 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular)
                let downImage00 = UIImage(systemName: "lock.fill", withConfiguration: symbolConfig00)
                attachment00.image = downImage00?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal)
                let normalFont00 = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
                let attStringNewLine000 = NSMutableAttributedString()
                let attStringNewLine00 = NSMutableAttributedString(string: " \(bio)", attributes: [NSAttributedString.Key.font : normalFont00, NSAttributedString.Key.foregroundColor : UIColor.secondaryLabel])
                let attString00 = NSAttributedString(attachment: attachment00)
                attStringNewLine000.append(attString00)
                attStringNewLine000.append(attStringNewLine00)
                self.bio.attributedText = attStringNewLine000
            } else {
                self.bio.text = bio
            }
        }
    }
}

class TrendsCell: UITableViewCell {
    
    static let reuseIdentifier = "TrendsCell"
    
    var bgView = UIView()
    var titleLabel = UILabel()
    var titleLabel2 = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        if #available(iOS 15.0, *) {
            self.focusEffect = UIFocusHaloEffect()
        }
        
        bgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bgView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 1
        titleLabel.text = ""
        titleLabel.textColor = .custom.mainTextColor
        titleLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        bgView.addSubview(titleLabel)
        
        titleLabel2.translatesAutoresizingMaskIntoConstraints = false
        titleLabel2.numberOfLines = 0
        titleLabel2.text = ""
        titleLabel2.textColor = .secondaryLabel
        titleLabel2.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular)
        bgView.addSubview(titleLabel2)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "bgView" : bgView,
            "titleLabel" : titleLabel,
            "titleLabel2" : titleLabel2,
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
#if targetEnvironment(macCatalyst)
        if GlobalStruct.singleColumn {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        } else {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        }
#elseif !targetEnvironment(macCatalyst)
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && self.window?.traitCollection.horizontalSizeClass != .compact {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        } else {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        }
#endif
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[titleLabel]-20-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[titleLabel2]-20-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[titleLabel]-4-[titleLabel2]-12-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(_ titleLabel: String, titleLabel2: String) {
        self.titleLabel.text = titleLabel
        self.titleLabel2.text = titleLabel2
    }
}

// MARK: - Cell configuration for DiscoveryVC
extension TrendsCell {
    func configure(_ tagName: String) {
        self.titleLabel.text = tagName
        
        self.selectionStyle = .none
        
        if (self.traitCollection.userInterfaceStyle == .light) {
            self.contentView.backgroundColor = .custom.backgroundTint.darker(by: 2)
        } else {
            self.contentView.backgroundColor = .custom.backgroundTint.lighter(by: 4)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
       super.traitCollectionDidChange(previousTraitCollection)
       
        if #available(iOS 13.0, *) {
            if (traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection)) {
                if (self.traitCollection.userInterfaceStyle == .light) {
                    self.contentView.backgroundColor = .custom.backgroundTint.darker(by: 2)
                } else {
                    self.contentView.backgroundColor = .custom.backgroundTint.lighter(by: 4)
                }
           }
        }
   }
}

class TrendsCellExtra: UITableViewCell {
    
    var bgView = UIView()
    var titleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        if #available(iOS 15.0, *) {
            self.focusEffect = UIFocusHaloEffect()
        }
        
        bgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bgView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 1
        titleLabel.text = ""
        titleLabel.textColor = .custom.mainTextColor
        titleLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        bgView.addSubview(titleLabel)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "bgView" : bgView,
            "titleLabel" : titleLabel,
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
#if targetEnvironment(macCatalyst)
        if GlobalStruct.singleColumn {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        } else {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        }
#elseif !targetEnvironment(macCatalyst)
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && self.window?.traitCollection.horizontalSizeClass != .compact {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        } else {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        }
#endif
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[titleLabel]-20-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[titleLabel]-12-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(_ titleLabel: String) {
        self.titleLabel.text = titleLabel
    }
}
