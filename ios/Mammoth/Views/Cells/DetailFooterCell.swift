//
//  DetailFooterCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 27/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class DetailFooterCell: UITableViewCell {
    
    var bgView = UIView()
    let repliesText = UILabel()
    let repostsText = UILabel()
    let likesText = UILabel()
    let stackView = UIStackView()
    let replies = CustomStackView()
    let reposts = CustomStackView()
    let likes = CustomStackView()
    var dateTime = UILabel()
    var whoCanReply = UIButton()
    var editHistory = UIButton()
    var language = UIButton()
    let stackView2 = UIStackView()
    var hasBeenEdited: Bool = false
    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        bgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bgView)
        
        // replies
        let repliesImage = UIImageView()
        repliesImage.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        repliesImage.image = UIImage(systemName: "arrowshape.turn.up.left", withConfiguration: symbolConfig)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal)
        repliesImage.contentMode = .scaleAspectFit
        repliesText.frame = CGRect(x: 30, y: 0, width: 30, height: 20)
        repliesText.text = "0"
        repliesText.textColor = .secondaryLabel
        repliesText.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        repliesText.sizeToFit()
        
        replies.addArrangedSubview(repliesImage)
        replies.addArrangedSubview(repliesText)
        replies.alignment = .center
        replies.axis = .horizontal
        replies.distribution = .equalSpacing
        replies.spacing = 4
        replies.isUserInteractionEnabled = true
        replies.isAccessibilityElement = false
        
        // reposts
        let repostsImage = UIImageView()
        repostsImage.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        repostsImage.image = UIImage(systemName: "arrow.2.squarepath", withConfiguration: symbolConfig)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal)
        repostsImage.contentMode = .scaleAspectFit
        repostsText.frame = CGRect(x: 30, y: 0, width: 30, height: 20)
        repostsText.text = "0"
        repostsText.textColor = .secondaryLabel
        repostsText.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        repostsText.sizeToFit()
        
        reposts.addArrangedSubview(repostsImage)
        reposts.addArrangedSubview(repostsText)
        reposts.alignment = .center
        reposts.axis = .horizontal
        reposts.distribution = .equalSpacing
        reposts.spacing = 4
        reposts.isUserInteractionEnabled = true
        reposts.isAccessibilityElement = false
        
        // likes
        let likesImage = UIImageView()
        likesImage.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        likesImage.image = UIImage(systemName: "heart", withConfiguration: symbolConfig)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal)
        likesImage.contentMode = .scaleAspectFit
        likesText.frame = CGRect(x: 30, y: 0, width: 30, height: 20)
        likesText.text = "0"
        likesText.textColor = .secondaryLabel
        likesText.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        likesText.sizeToFit()
        
        likes.addArrangedSubview(likesImage)
        likes.addArrangedSubview(likesText)
        likes.alignment = .center
        likes.axis = .horizontal
        likes.distribution = .equalSpacing
        likes.spacing = 4
        likes.isUserInteractionEnabled = true
        likes.isAccessibilityElement = false
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(replies)
        stackView.addArrangedSubview(reposts)
        stackView.addArrangedSubview(likes)
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = 2
        bgView.addSubview(stackView)
        
        dateTime.translatesAutoresizingMaskIntoConstraints = false
        dateTime.textAlignment = .center
        dateTime.textColor = UIColor.secondaryLabel
        dateTime.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .light)
        dateTime.numberOfLines = 0
        bgView.addSubview(dateTime)
        
        whoCanReply.translatesAutoresizingMaskIntoConstraints = false
        whoCanReply.titleLabel?.textAlignment = .center
        whoCanReply.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold)
        
        whoCanReply.setTitleColor(UIColor.secondaryLabel, for: .normal)
        whoCanReply.backgroundColor = .custom.backgroundTint
        
        whoCanReply.layer.cornerRadius = 8
        whoCanReply.layer.cornerCurve = .continuous
        whoCanReply.layer.masksToBounds = true
        whoCanReply.contentEdgeInsets = UIEdgeInsets(top: 4, left: 9, bottom: 4, right: 9)
        whoCanReply.isUserInteractionEnabled = true
        whoCanReply.layer.borderWidth = 0.2
        whoCanReply.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        bgView.addSubview(whoCanReply)
        
        editHistory.titleLabel?.textAlignment = .center
        editHistory.setTitleColor(UIColor.secondaryLabel, for: .normal)
        editHistory.backgroundColor = .custom.backgroundTint
        editHistory.layer.cornerRadius = 8
        editHistory.layer.cornerCurve = .continuous
        editHistory.layer.masksToBounds = true
        editHistory.contentEdgeInsets = UIEdgeInsets(top: 4, left: 9, bottom: 4, right: 9)
        editHistory.isUserInteractionEnabled = true
        editHistory.layer.borderWidth = 0.2
        editHistory.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        
        let attachment1 = NSTextAttachment()
        let symbolConfig1 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold)
        let downImage1 = UIImage(systemName: "pencil", withConfiguration: symbolConfig1) ?? UIImage()
        attachment1.image = downImage1.withTintColor(UIColor.secondaryLabel.withAlphaComponent(0.75), renderingMode: .alwaysOriginal)
        let attStringNewLine000 = NSMutableAttributedString()
        let attStringNewLine00 = NSMutableAttributedString(string: "Edit history ", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold), NSAttributedString.Key.foregroundColor : UIColor.secondaryLabel])
        let attString00 = NSAttributedString(attachment: attachment1)
        attStringNewLine000.append(attStringNewLine00)
        attStringNewLine000.append(attString00)
        editHistory.setAttributedTitle(attStringNewLine000, for: .normal)
        editHistory.accessibilityLabel = "Edit history"
        
        language.titleLabel?.textAlignment = .center
        language.setTitleColor(UIColor.secondaryLabel, for: .normal)
        language.backgroundColor = .custom.backgroundTint
        language.layer.cornerRadius = 8
        language.layer.cornerCurve = .continuous
        language.layer.masksToBounds = true
        language.contentEdgeInsets = UIEdgeInsets(top: 4, left: 9, bottom: 4, right: 9)
        language.isUserInteractionEnabled = true
        language.layer.borderWidth = 0.2
        language.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        
        stackView2.translatesAutoresizingMaskIntoConstraints = false
        stackView2.addArrangedSubview(editHistory)
        stackView2.addArrangedSubview(language)
        stackView2.alignment = .center
        stackView2.axis = .horizontal
        stackView2.distribution = .equalSpacing
        stackView2.spacing = 8
        bgView.addSubview(stackView2)
        
        let viewsDict = [
            "bgView" : bgView,
            "stackView" : stackView,
            "dateTime" : dateTime,
            "whoCanReply" : whoCanReply,
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
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-60-[stackView]-60-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[dateTime]-20-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupEdited(_ edited: Bool = false, languageName: String? = nil) {
        stackView.isHidden = false
        let viewsDict = [
            "bgView" : bgView,
            "stackView" : self.stackView,
            "dateTime" : dateTime,
            "whoCanReply" : whoCanReply,
            "editHistory" : editHistory,
            "language" : language,
            "stackView2" : stackView2,
        ]
        stackView2.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        if edited {
            editHistory.isHidden = false
        } else {
            editHistory.isHidden = true
        }
        if languageName != nil {
            language.isHidden = false
            let attachment2 = NSTextAttachment()
            let symbolConfig2 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold)
            let downImage2 = UIImage(systemName: "globe", withConfiguration: symbolConfig2) ?? UIImage()
            attachment2.image = downImage2.withTintColor(UIColor.secondaryLabel.withAlphaComponent(0.75), renderingMode: .alwaysOriginal)
            let attStringNewLine0002 = NSMutableAttributedString()
            let attStringNewLine002 = NSMutableAttributedString(string: "\(languageName ?? "English") ", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold), NSAttributedString.Key.foregroundColor : UIColor.secondaryLabel])
            let attString002 = NSAttributedString(attachment: attachment2)
            attStringNewLine0002.append(attStringNewLine002)
            attStringNewLine0002.append(attString002)
            language.setAttributedTitle(attStringNewLine0002, for: .normal)
            language.accessibilityLabel = "\(languageName ?? "English")"
        } else {
            language.isHidden = true
        }
        if languageName != nil || edited {
            whoCanReply.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[stackView]-10-[dateTime]-8-[whoCanReply]-10-[stackView2]-12-|", options: [], metrics: nil, views: viewsDict))
        } else {
            whoCanReply.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[stackView]-10-[dateTime]-8-[whoCanReply]-12-|", options: [], metrics: nil, views: viewsDict))
        }
    }
    
    func setupStats(replies: Int, reposts: Int, likes: Int, whoCanReply: Visibility) {
        repliesText.isHidden = false
        repostsText.isHidden = false
        likesText.isHidden = false
        
        if replies > 1000 {
            self.repliesText.text = "\(replies.formatUsingAbbrevation())"
            self.repliesText.accessibilityLabel = "\(replies.formatUsingAbbrevation()) replies"
        } else {
            self.repliesText.text = "\(replies.withCommas())"
            self.repliesText.accessibilityLabel = "\(replies.withCommas()) replies"
        }
        if reposts > 1000 {
            self.repostsText.text = "\(reposts.formatUsingAbbrevation())"
            self.repostsText.accessibilityLabel = "\(reposts.formatUsingAbbrevation()) reposts"
        } else {
            self.repostsText.text = "\(reposts.withCommas())"
            self.repostsText.accessibilityLabel = "\(reposts.withCommas()) reposts"
        }
        if likes > 1000 {
            self.likesText.text = "\(likes.formatUsingAbbrevation())"
            self.likesText.accessibilityLabel = "\(likes.formatUsingAbbrevation()) likes"
        } else {
            self.likesText.text = "\(likes.withCommas())"
            self.likesText.accessibilityLabel = "\(likes.withCommas()) likes"
        }
        if whoCanReply == .public {
            let attachment1 = NSTextAttachment()
            let symbolConfig1 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold)
            let downImage1 = UIImage(systemName: "person.2.fill", withConfiguration: symbolConfig1) ?? UIImage()
            attachment1.image = downImage1.withTintColor(UIColor.secondaryLabel.withAlphaComponent(0.75), renderingMode: .alwaysOriginal)
            let attStringNewLine000 = NSMutableAttributedString()
            let attStringNewLine00 = NSMutableAttributedString(string: "Everyone ", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold), NSAttributedString.Key.foregroundColor : UIColor.secondaryLabel])
            let attString00 = NSAttributedString(attachment: attachment1)
            attStringNewLine000.append(attStringNewLine00)
            attStringNewLine000.append(attString00)
            self.whoCanReply.setAttributedTitle(attStringNewLine000, for: .normal)
            self.whoCanReply.accessibilityLabel = "Everyone"
        } else if whoCanReply == .direct {
            let attachment1 = NSTextAttachment()
            let symbolConfig1 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold)
            let downImage1 = UIImage(systemName: "tray.full.fill", withConfiguration: symbolConfig1) ?? UIImage()
            attachment1.image = downImage1.withTintColor(UIColor.secondaryLabel.withAlphaComponent(0.75), renderingMode: .alwaysOriginal)
            let attStringNewLine000 = NSMutableAttributedString()
            let attStringNewLine00 = NSMutableAttributedString(string: "Private mention ", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold), NSAttributedString.Key.foregroundColor : UIColor.secondaryLabel])
            let attString00 = NSAttributedString(attachment: attachment1)
            attStringNewLine000.append(attStringNewLine00)
            attStringNewLine000.append(attString00)
            self.whoCanReply.setAttributedTitle(attStringNewLine000, for: .normal)
            self.whoCanReply.accessibilityLabel = "Private mention"
        } else if whoCanReply == .private {
            let attachment1 = NSTextAttachment()
            let symbolConfig1 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold)
            let downImage1 = UIImage(systemName: "lock.fill", withConfiguration: symbolConfig1) ?? UIImage()
            attachment1.image = downImage1.withTintColor(UIColor.secondaryLabel.withAlphaComponent(0.75), renderingMode: .alwaysOriginal)
            let attStringNewLine000 = NSMutableAttributedString()
            let attStringNewLine00 = NSMutableAttributedString(string: "Followers ", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold), NSAttributedString.Key.foregroundColor : UIColor.secondaryLabel])
            let attString00 = NSAttributedString(attachment: attachment1)
            attStringNewLine000.append(attStringNewLine00)
            attStringNewLine000.append(attString00)
            self.whoCanReply.setAttributedTitle(attStringNewLine000, for: .normal)
            self.whoCanReply.accessibilityLabel = "Followers"
        } else if whoCanReply == .unlisted {
            let attachment1 = NSTextAttachment()
            let symbolConfig1 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold)
            let downImage1 = UIImage(systemName: "lock.open.fill", withConfiguration: symbolConfig1) ?? UIImage()
            attachment1.image = downImage1.withTintColor(UIColor.secondaryLabel.withAlphaComponent(0.75), renderingMode: .alwaysOriginal)
            let attStringNewLine000 = NSMutableAttributedString()
            let attStringNewLine00 = NSMutableAttributedString(string: "Unlisted ", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold), NSAttributedString.Key.foregroundColor : UIColor.secondaryLabel])
            let attString00 = NSAttributedString(attachment: attachment1)
            attStringNewLine000.append(attStringNewLine00)
            attStringNewLine000.append(attString00)
            self.whoCanReply.setAttributedTitle(attStringNewLine000, for: .normal)
            self.whoCanReply.accessibilityLabel = "Unlisted"
        }
    }
    
}


