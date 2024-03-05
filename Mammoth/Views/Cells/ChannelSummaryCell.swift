//
//  ChannelSummaryCell.swift
//  Mammoth
//
//  Created by Riley Howard on 9/27/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class ChannelSummaryCell: UITableViewCell {
    static let reuseIdentifier = "ChannelSummaryCell"
    
    public weak var delegate: ChannelCellDelegate? = nil

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
        return stackView
    }()
    
    private var addButton = {
        let button = UIButton(type: .custom)
        button.setTitle(NSLocalizedString("generic.subscribe", comment: "Subscribe button label"), for: .normal)
        button.setTitleColor(.custom.highContrast, for: .normal)
        button.backgroundColor = .custom.followButtonBG
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let channelPic = ChannelPic(withSize: .regular)

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .custom.highContrast
        label.numberOfLines = 1
        return label
    }()

    private var ownerButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.custom.feintContrast, for: .normal)
        return button
    }()

    private var channel: Channel?

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
        self.channel = nil
        self.titleLabel.text = nil
        self.ownerButton.setTitle("", for: .normal)
        setupUIFromSettings()
    }
}

// MARK: - Setup UI
private extension ChannelSummaryCell {
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

        mainStackView.addArrangedSubview(channelPic)

        mainStackView.addArrangedSubview(contentStackView)
        contentStackView.addArrangedSubview(headerStackView)
        
        headerStackView.addArrangedSubview(headerTitleStackView)
        headerStackView.addArrangedSubview(addButton)
        
        NSLayoutConstraint.activate([
            // Force header to fill the parent width to align the follow button right
            headerStackView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
        ])
        
        headerTitleStackView.addArrangedSubview(titleLabel)
        headerTitleStackView.addArrangedSubview(ownerButton)
        ownerButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        ownerButton.addTarget(self, action: #selector(self.userTagTapped), for: .touchUpInside)

        setupUIFromSettings()
    }

    func setupUIFromSettings() {
        titleLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        ownerButton.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
    }
}

// MARK: - Configuration
extension ChannelSummaryCell {
    func configure(channel: Channel, isSubscribed: Bool) {
        self.channel = channel
        self.titleLabel.attributedText = NewsFeedTypes.channel(channel).attributedTitle()
        self.ownerButton.setTitle(channel.owner?.displayName ?? "", for: .normal)
        self.channelPic.configure(channel: channel)
                
        if isSubscribed {
            addButton.setTitle(NSLocalizedString("generic.unsubscribe", comment: "Unsubscribe button label"), for: .normal)
            addButton.removeTarget(self, action: #selector(self.addTapped), for: .touchUpInside)
            addButton.addTarget(self, action: #selector(self.removeTapped), for: .touchUpInside)
        } else {
            addButton.setTitle(NSLocalizedString("generic.subscribe", comment: "Subscribe button label"), for: .normal)
            addButton.removeTarget(self, action: #selector(self.removeTapped), for: .touchUpInside)
            addButton.addTarget(self, action: #selector(self.addTapped), for: .touchUpInside)
        }
        
        self.onThemeChange()
    }
    
    func onThemeChange() {}
}

// MARK: Actions
internal extension ChannelSummaryCell {
    @objc func addTapped() {
        triggerHapticImpact(style: .light)
        if let channel = self.channel {
            ChannelManager.shared.subscribeToChannel(channel)
        }
    }
    
    @objc func removeTapped() {
        triggerHapticImpact(style: .light)
        if  let channel = self.channel {
            ChannelManager.shared.unsubscribeFromChannel(channel)
        }
    }
    
    @objc func userTagTapped() {
        if  let channel = self.channel {
            delegate?.didTapChannelOwner(channel: channel)
        }
    }
}

// MARK: Appearance changes
internal extension ChannelSummaryCell {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 self.onThemeChange()
             }
         }
    }
}
