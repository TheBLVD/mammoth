//
//  UserCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 28/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

class UserCell: UITableViewCell {
    
    var bgView = UIView()
    var profileIcon = UIButton()
    var lockedBadge = UIImageView()
    var lockedBackground = UIView()
    var userTag = UILabel()
    var userName = UILabel()
    var bioText = ActiveLabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        bgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bgView)
        
        profileIcon.translatesAutoresizingMaskIntoConstraints = false
        profileIcon.backgroundColor = .custom.quoteTint
        profileIcon.contentMode = .scaleAspectFill
        profileIcon.layer.masksToBounds = true
        profileIcon.isUserInteractionEnabled = true
        profileIcon.imageView?.contentMode = .scaleAspectFill
        profileIcon.contentMode = .scaleAspectFill
        profileIcon.accessibilityLabel = NSLocalizedString("navigator.profile", comment: "")
        bgView.addSubview(profileIcon)
        if GlobalStruct.circleProfiles {
            profileIcon.layer.cornerRadius = 25
        } else {
            profileIcon.layer.cornerRadius = 8
        }
        
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
        bioText.textColor = UIColor.secondaryLabel
        bioText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        bioText.enabledTypes = [.mention, .hashtag, .url, .email]
        bioText.mentionColor = .custom.baseTint
        bioText.hashtagColor = .custom.baseTint
        bioText.URLColor = .custom.baseTint
        bioText.emailColor = .custom.baseTint
        bioText.urlMaximumLength = 30
        bgView.addSubview(bioText)
        
        userName.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let viewsDict = [
            "bgView" : bgView,
            "profileIcon" : profileIcon,
            "lockedBadge" : lockedBadge,
            "userName" : userName,
            "userTag" : userTag,
            "bioText" : bioText,
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
#if targetEnvironment(macCatalyst)
        if GlobalStruct.singleColumn {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[bgView]-10-|", options: [], metrics: nil, views: viewsDict))
        } else {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        }
#elseif !targetEnvironment(macCatalyst)
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && self.window?.traitCollection.horizontalSizeClass != .compact {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[bgView]-10-|", options: [], metrics: nil, views: viewsDict))
        } else {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        }
#endif
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-52-[lockedBadge(20)]", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-46-[lockedBadge(20)]", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[profileIcon(50)]-12-[userName]-4-[userTag]-(>=16)-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[profileIcon(50)]-12-[bioText]-16-|", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[profileIcon(50)]-(>=14)-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userName]-0-[bioText]-14-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userTag]-0-[bioText]", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupConstraints(_ stat: Account? = nil) {
        if GlobalStruct.circleProfiles {
            profileIcon.layer.cornerRadius = 25
        } else {
            profileIcon.layer.cornerRadius = 8
        }
        
        if stat?.emojis.isEmpty ?? false {

        } else {
            let attributedString = NSMutableAttributedString(string: "\(stat?.note.stripHTML() ?? "")", attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
            if let z = stat?.emojis {
                let _ = z.map({
                    let textAttachment = NSTextAttachment()
                    textAttachment.kf.setImage(with: $0.url, attributedView: self.bioText, completionHandler:  { r in
                        self.bioText.setNeedsDisplay()
                    })
                    textAttachment.bounds = CGRect(x:0, y: Int(-2), width: Int(self.bioText.font.lineHeight - 6), height: Int(self.bioText.font.lineHeight - 6))
                    let attrStringWithImage = NSAttributedString(attachment: textAttachment)
                    while attributedString.mutableString.contains(":\($0.shortcode):") {
                        let range: NSRange = (attributedString.mutableString as NSString).range(of: ":\($0.shortcode):")
                        attributedString.replaceCharacters(in: range, with: attrStringWithImage)
                    }
                })
#if !targetEnvironment(macCatalyst)
                self.bioText.attributedText = attributedString
#endif
            }
        }

        if stat?.emojis.isEmpty ?? false {

        } else {
            let attributedString = NSMutableAttributedString(string: "\(stat?.displayName ?? "")", attributes: [NSAttributedString.Key.foregroundColor: UIColor.label])
            if let z = stat?.emojis {
                let _ = z.map({
                    let textAttachment = NSTextAttachment()
                    textAttachment.kf.setImage(with: $0.url, attributedView: self.userName, completionHandler:  { r in
                        self.userName.setNeedsDisplay()
                    })
                    textAttachment.bounds = CGRect(x:0, y: Int(-2), width: Int(self.userName.font.lineHeight - 6), height: Int(self.userName.font.lineHeight) - 4)
                    let attrStringWithImage = NSAttributedString(attachment: textAttachment)
                    while attributedString.mutableString.contains(":\($0.shortcode):") {
                        let range: NSRange = (attributedString.mutableString as NSString).range(of: ":\($0.shortcode):")
                        attributedString.replaceCharacters(in: range, with: attrStringWithImage)
                    }
                })
#if !targetEnvironment(macCatalyst)
                self.userName.attributedText = attributedString
#endif
            }
        }
    }
    
}


protocol AccountCellDelegate: AnyObject {
    func signOutAccount(_ account: any AcctDataType)
}

class AccountCell: UITableViewCell {
    
    weak var delegate: AccountCellDelegate? = nil
    var account: (any AcctDataType)? = nil
    
    var bgView = UIView()
    var profileIcon = UIButton()
    var lockedBadge = UIImageView()
    var lockedBackground = UIView()
    var userTag = UILabel()
    var userName = UILabel()
    var bioText = ActiveLabel()
    var signOutButton = UIButton()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        bgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bgView)
        
        profileIcon.translatesAutoresizingMaskIntoConstraints = false
        profileIcon.backgroundColor = .custom.quoteTint
        profileIcon.contentMode = .scaleAspectFill
        profileIcon.layer.masksToBounds = true
        profileIcon.isUserInteractionEnabled = true
        profileIcon.imageView?.contentMode = .scaleAspectFill
        profileIcon.contentMode = .scaleAspectFill
        profileIcon.accessibilityLabel = NSLocalizedString("navigator.profile", comment: "")
        bgView.addSubview(profileIcon)
        if GlobalStruct.circleProfiles {
            profileIcon.layer.cornerRadius = 22
        } else {
            profileIcon.layer.cornerRadius = 8
        }
        
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
        userName.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .semibold)
        bgView.addSubview(userName)
        
        userTag.translatesAutoresizingMaskIntoConstraints = false
        userTag.textAlignment = .left
        userTag.textColor = UIColor.secondaryLabel
        userTag.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .light)
        bgView.addSubview(userTag)
        
        bioText.translatesAutoresizingMaskIntoConstraints = false
        bioText.numberOfLines = 0
        bioText.textColor = UIColor.secondaryLabel
        bioText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular)
        bioText.enabledTypes = [.mention, .hashtag, .url, .email]
        bioText.mentionColor = .custom.baseTint
        bioText.hashtagColor = .custom.baseTint
        bioText.URLColor = .custom.baseTint
        bioText.emailColor = .custom.baseTint
        bioText.urlMaximumLength = 30
        bioText.handleMentionTap { (str) in }
        bioText.handleHashtagTap { (str) in }
        bioText.handleURLTap { (str) in }
        bioText.handleEmailTap { (str) in }
        bgView.addSubview(bioText)
        
        signOutButton.translatesAutoresizingMaskIntoConstraints = false
        signOutButton.backgroundColor = .clear
        signOutButton.setTitleColor(.custom.destructive, for: .normal)
        signOutButton.setTitle(NSLocalizedString("settings.accounts.signOut", comment: ""), for: .normal)
        signOutButton.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .bold)
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        bgView.addSubview(signOutButton)
        
        separatorInset = .zero
        let bgColorView = UIView()
        bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
        selectedBackgroundView = bgColorView
        backgroundColor = .custom.OVRLYSoftContrast
        
        let viewsDict = [
            "bgView" : bgView,
            "profileIcon" : profileIcon,
            "lockedBadge" : lockedBadge,
            "userName" : userName,
            "userTag" : userTag,
            "bioText" : bioText,
            "signOutButton" : signOutButton,
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && self.window?.traitCollection.horizontalSizeClass != .compact {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[bgView]-10-|", options: [], metrics: nil, views: viewsDict))
        } else {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        }
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-52-[lockedBadge(20)]", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-46-[lockedBadge(20)]", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[profileIcon(44)]-12-[userName]-(>=16)-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[profileIcon(44)]-12-[userTag]-(>=16)-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[profileIcon(44)]-12-[bioText]-16-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[profileIcon(44)]-12-[signOutButton]-(>=16)-|", options: [], metrics: nil, views: viewsDict))

        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[profileIcon(44)]-(>=14)-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userName]-0-[userTag]-3-[bioText]-10-[signOutButton]-14-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupConstraints(_ stat: Account? = nil) {
        if GlobalStruct.circleProfiles {
            profileIcon.layer.cornerRadius = 22
        } else {
            profileIcon.layer.cornerRadius = 8
        }
        
        if stat?.emojis.isEmpty ?? false {

        } else {
            let attributedString = NSMutableAttributedString(string: "\(stat?.note.stripHTML() ?? "")", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.custom.mainTextColor.withAlphaComponent(0.85)])
            if let z = stat?.emojis {
                let _ = z.map({
                    let textAttachment = NSTextAttachment()
                    textAttachment.kf.setImage(with: $0.url, attributedView: self.bioText, completionHandler:  { r in
                        self.bioText.setNeedsDisplay()
                    })
                    textAttachment.bounds = CGRect(x:0, y: Int(-2), width: Int(self.bioText.font.lineHeight - 6), height: Int(self.bioText.font.lineHeight - 6))
                    let attrStringWithImage = NSAttributedString(attachment: textAttachment)
                    while attributedString.mutableString.contains(":\($0.shortcode):") {
                        let range: NSRange = (attributedString.mutableString as NSString).range(of: ":\($0.shortcode):")
                        attributedString.replaceCharacters(in: range, with: attrStringWithImage)
                    }
                })
                self.bioText.attributedText = attributedString
            }
        }

        if stat?.emojis.isEmpty ?? false {

        } else {
            let attributedString = NSMutableAttributedString(string: "\(stat?.displayName ?? "")", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.custom.mainTextColor.withAlphaComponent(0.85)])
            if let z = stat?.emojis {
                let _ = z.map({
                    let textAttachment = NSTextAttachment()
                    textAttachment.kf.setImage(with: $0.url, attributedView: self.userName, completionHandler:  { r in
                        self.userName.setNeedsDisplay()
                    })
                    textAttachment.bounds = CGRect(x:0, y: Int(-2), width: Int(self.userName.font.lineHeight - 6), height: Int(self.userName.font.lineHeight) - 4)
                    let attrStringWithImage = NSAttributedString(attachment: textAttachment)
                    while attributedString.mutableString.contains(":\($0.shortcode):") {
                        let range: NSRange = (attributedString.mutableString as NSString).range(of: ":\($0.shortcode):")
                        attributedString.replaceCharacters(in: range, with: attrStringWithImage)
                    }
                })
                self.userName.attributedText = attributedString
            }
        }
    }
    
    func configure(acctData: any AcctDataType) {
        if let mastodonAcctData = acctData as? MastodonAcctData {
            self.account = acctData
            let instance = mastodonAcctData.instanceData
            let account = mastodonAcctData.account
            if let ur = URL(string: account.avatar) {
                profileIcon.sd_setImage(with: ur, for: .normal)
            }
            userName.text = account.displayName
            let instanceAndAccount = "@\(instance.returnedText)"
            userTag.text = "@\(account.username)\(instanceAndAccount)"
            bioText.text = account.note.stripHTML()
        }
        
        if let account = acctData as? BlueskyAcctData {
            userName.text = account.displayName
            userTag.text = "@\(account.handle)"
            profileIcon.sd_setImage(
                with: URL(string: account.avatar),
                for: .normal)
        }
    }
 
}

// MARK: - User Action
extension AccountCell {
    @objc func signOutTapped() {
        if let account {
            delegate?.signOutAccount(account)
        }
    }
}
