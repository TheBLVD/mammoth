//
//  HashtagCell.swift
//  Mammoth
//
//  Created by Riley Howard on 9/27/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class HashtagCell: UITableViewCell {
    static let reuseIdentifier = "HashtagCell"
    
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
    
    private var addButton = {
        let button = UIButton(type: .custom)
        button.setTitle(NSLocalizedString("profile.follow", comment: ""), for: .normal)
        button.setTitleColor(.custom.highContrast, for: .normal)
        button.backgroundColor = .custom.followButtonBG
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let hashtagPic = StaticPic(withSize: .regular)

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .custom.highContrast
        label.numberOfLines = 1
        return label
    }()

    private var userTagLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.custom.feintContrast
        return label
    }()
    
    private var hashtag: Tag?

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
        self.hashtag = nil
        self.titleLabel.text = nil
        self.userTagLabel.text = nil
        setupUIFromSettings()
    }
}

// MARK: - Setup UI
private extension HashtagCell {
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

        hashtagPic.setImage(FontAwesome.image(fromChar: "#", size: 15).withRenderingMode(.alwaysTemplate))
        mainStackView.addArrangedSubview(hashtagPic)

        mainStackView.addArrangedSubview(contentStackView)
        contentStackView.addArrangedSubview(headerStackView)
        
        headerStackView.addArrangedSubview(headerTitleStackView)
        headerStackView.addArrangedSubview(addButton)
        
        NSLayoutConstraint.activate([
            // Force header to fill the parent width to align the follow button right
            headerStackView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
        ])
        
        headerTitleStackView.addArrangedSubview(titleLabel)
        headerTitleStackView.addArrangedSubview(userTagLabel)
        
        setupUIFromSettings()
    }

    func setupUIFromSettings() {
        titleLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        userTagLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
    }
}

// MARK: - Configuration
extension HashtagCell {
    func configure(hashtag: Tag, isSubscribed: Bool) {
        self.hashtag = hashtag
        self.titleLabel.attributedText = NewsFeedTypes.hashtag(hashtag).attributedTitle()

        // Figure out the # of people talking about this. The
        // web site shows "x people in the last 2 days", as often
        // the 'today' number will be zero.
        var numPeopleTalking = 0
        if hashtag.history?.count ?? 0 > 1 {
            numPeopleTalking = Int(hashtag.history![0].accounts)! + Int(hashtag.history![1].accounts)!
        }
        var numPeopleAsString: String
        if numPeopleTalking < 10 {
            numPeopleAsString = NSLocalizedString("discover.several", comment: "")
        } else {
            numPeopleAsString = numPeopleTalking.formatUsingAbbrevation()
        }
        self.userTagLabel.text = String.localizedStringWithFormat(NSLocalizedString("discover.peopleTalking", comment: ""), numPeopleAsString)
                
        if isSubscribed {
            addButton.setTitle(NSLocalizedString("profile.unfollow", comment: ""), for: .normal)
            addButton.removeTarget(self, action: #selector(self.addTapped), for: .touchUpInside)
            addButton.addTarget(self, action: #selector(self.removeTapped), for: .touchUpInside)
        } else {
            addButton.setTitle(NSLocalizedString("profile.follow", comment: ""), for: .normal)
            addButton.removeTarget(self, action: #selector(self.removeTapped), for: .touchUpInside)
            addButton.addTarget(self, action: #selector(self.addTapped), for: .touchUpInside)
        }
        
        self.onThemeChange()
    }
    
    func onThemeChange() {
        self.contentView.backgroundColor = .custom.background
        self.addButton.setTitleColor(.custom.highContrast, for: .normal)
        self.addButton.backgroundColor = .custom.followButtonBG
        self.titleLabel.textColor = .custom.highContrast
        self.userTagLabel.textColor = UIColor.custom.feintContrast
        if let hashtag {
            self.titleLabel.attributedText = NewsFeedTypes.hashtag(hashtag).attributedTitle()
        }
    }
}

// MARK: Actions
internal extension HashtagCell {
    @objc func addTapped() {
        triggerHapticImpact(style: .light)
        if let hashtag = self.hashtag {
            triggerHapticImpact(style: .light)
            HashtagManager.shared.followHashtag(hashtag.name, completion: { _ in })
        }
    }
    
    @objc func removeTapped() {
        triggerHapticImpact(style: .light)
        if let hashtag = self.hashtag {
            triggerHapticImpact(style: .light)
            HashtagManager.shared.unfollowHashtag(hashtag.name, completion: { _ in })
        }
    }
}

// MARK: Appearance changes
internal extension HashtagCell {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 self.onThemeChange()
             }
         }
    }
}
