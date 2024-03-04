//
//  UserCardCell.swift
//  Mammoth
//
//  Created by Benoit Nolens on 11/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import Meta
import MetaTextKit

final class UserCardCell: UITableViewCell {
    static let reuseIdentifier = "UserCardCell"
    
    // MARK: - Properties
    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 8.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 4
        return stackView
    }()
    
    private var headerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var headerTitleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = -2
        return stackView
    }()
    
    private var followButton: FollowButton?
    private var actionButton: UserCardActionButton?
    private let profilePic = PostCardProfilePic(withSize: .regular)
    
    private let titleLabel: MetaLabel = {
        let label = MetaLabel()
        label.textColor = .custom.highContrast
        label.numberOfLines = 1
        label.isOpaque = true
        label.backgroundColor = .custom.background
        label.textContainer.lineFragmentPadding = 0
        label.isUserInteractionEnabled = false
        return label
    }()

    private var userTagLabel: UILabel = {
        let label = UILabel()
        label.textColor = .custom.feintContrast
        return label
    }()

    private var descriptionLabel: MetaLabel = {
        let label = MetaLabel()
        label.textColor = .custom.mediumContrast
        label.numberOfLines = 2
        label.textContainer.maximumNumberOfLines = 2
        label.isUserInteractionEnabled = false
        label.textContainer.lineFragmentPadding = 0
        return label
    }()
    
    private var userCard: UserCardModel?
    
    enum ActionButtonType {
        case follow
        case unblock
        case unmute
        case removeFromList
        case none
    }

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.userCard = nil
        self.profilePic.prepareForReuse()
        self.titleLabel.reset()
        self.userTagLabel.text = nil
        self.descriptionLabel.reset()
        setupUIFromSettings()
    }
}

// MARK: - Setup UI
private extension UserCardCell {
    func setupUI() {
        self.selectionStyle = .none
        self.separatorInset = .zero
        self.layoutMargins = .zero
        self.contentView.preservesSuperviewLayoutMargins = false
        self.contentView.backgroundColor = .custom.background
        self.contentView.layoutMargins = .init(top: 16, left: 13, bottom: 18, right: 13)
        
        contentView.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])

        mainStackView.addArrangedSubview(profilePic)

        mainStackView.addArrangedSubview(contentStackView)
        contentStackView.addArrangedSubview(headerStackView)
        contentStackView.addArrangedSubview(descriptionLabel)
        
        contentStackView.setCustomSpacing(4, after: headerStackView)
        
        headerStackView.addArrangedSubview(headerTitleStackView)
        
        NSLayoutConstraint.activate([
            // Force header to fill the parent width to align the follow button right
            headerStackView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
        ])
        
        headerTitleStackView.addArrangedSubview(titleLabel)
        headerTitleStackView.addArrangedSubview(userTagLabel)
        
        setupUIFromSettings()
    }

    func setupUIFromSettings() {
        userTagLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)

        self.descriptionLabel.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]
        
        self.descriptionLabel.linkAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]
        
        self.descriptionLabel.paragraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = DeviceHelpers.isiOSAppOnMac() ? 1 : -1
            style.paragraphSpacing = 12
            style.alignment = .left
            return style
        }()
        
        titleLabel.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold),
            .foregroundColor: UIColor.custom.highContrast
        ]

        titleLabel.linkAttributes = titleLabel.textAttributes
    }
}

// MARK: - Configuration
extension UserCardCell {
    func configure(info: UserCardModel, actionButtonType: ActionButtonType = .follow, onButtonPress: @escaping PostCardButtonCallback) {
        self.userCard = info
        
        if let metaContent = info.metaName {
            self.titleLabel.configure(content: metaContent)
        } else {
            self.titleLabel.text = info.name
        }
        
        self.userTagLabel.text = info.userTag
        
        if let desc = info.metaDescription {
            self.descriptionLabel.isHidden = false
            self.descriptionLabel.configure(content: desc)
        } else {
            self.descriptionLabel.isHidden = true
        }
        
        self.profilePic.configure(user: info)
        self.profilePic.willDisplay()
        self.profilePic.onPress = onButtonPress
                
        if actionButtonType == .follow, !info.isSelf, (info.followStatus == .notFollowing || info.forceFollowButtonDisplay) {
            if self.followButton == nil {
                self.followButton = FollowButton(user: info, type: .big)
            } else {
                self.followButton!.user = info
            }
            
            if !headerStackView.arrangedSubviews.contains(followButton!) {
                headerStackView.addArrangedSubview(followButton!)
            }
        } else if actionButtonType == .unblock {
            if self.actionButton == nil {
                self.actionButton = UserCardActionButton(user: info, type: .unblock, size: .big)
            } else {
                self.actionButton!.user = info
            }
            
            self.actionButton?.onPress = onButtonPress
            
            if !headerStackView.arrangedSubviews.contains(actionButton!) {
                headerStackView.addArrangedSubview(actionButton!)
            }
        } else if actionButtonType == .unmute {
            if self.actionButton == nil {
                self.actionButton = UserCardActionButton(user: info, type: .unmute, size: .big)
            } else {
                self.actionButton!.user = info
            }
            
            self.actionButton?.onPress = onButtonPress
            
            if !headerStackView.arrangedSubviews.contains(actionButton!) {
                headerStackView.addArrangedSubview(actionButton!)
            }
        } else if actionButtonType == .removeFromList {
            if self.actionButton == nil {
                self.actionButton = UserCardActionButton(user: info, type: .removeFromList, size: .big)
            } else {
                self.actionButton!.user = info
            }
            
            self.actionButton?.onPress = onButtonPress
                        
            if !headerStackView.arrangedSubviews.contains(actionButton!) {
                headerStackView.addArrangedSubview(actionButton!)
            }
        } else {
            if let followButton = self.followButton, headerStackView.arrangedSubviews.contains(followButton) {
                headerStackView.removeArrangedSubview(followButton)
                followButton.removeFromSuperview()
            }
        }
        
        self.onThemeChange()
    }
    
    func onThemeChange() {
        contentView.backgroundColor = .custom.background
        titleLabel.textColor = .custom.highContrast
        userTagLabel.textColor = .custom.feintContrast
        descriptionLabel.textColor = .custom.mediumContrast
        self.descriptionLabel.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]        
        self.descriptionLabel.linkAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]
    }
}

// MARK: Appearance changes
internal extension UserCardCell {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 self.onThemeChange()
             }
         }
    }
}
