//
//  PostCardHeaderExtension.swift
//  Mammoth
//
//  Created by Benoit Nolens on 09/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class PostCardHeaderExtension: UIView {
    
    // MARK: - Properties
    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 5.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .custom.feintContrast
        label.numberOfLines = 1
        label.isOpaque = true
        return label
    }()
    
    public var onPress: PostCardButtonCallback?
    private var postCard: PostCardModel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.profileTapped))
        self.addGestureRecognizer(tapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        self.postCard = nil
        self.onPress = nil
        self.titleLabel.text = nil
    }
    
    func setupUIFromSettings() {
        titleLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
    }
}

// MARK: - Setup UI
private extension PostCardHeaderExtension {
    func setupUI() {
        self.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            mainStackView.heightAnchor.constraint(equalToConstant: 18),
            mainStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 55),
            mainStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
        
        mainStackView.addArrangedSubview(titleLabel)
        setupUIFromSettings()
    }
}

// MARK: - Estimated height
extension PostCardHeaderExtension {
    static func estimatedHeight() -> CGFloat {
        return 18
    }
}

// MARK: - Configuration
extension PostCardHeaderExtension {
    func configure(postCard: PostCardModel) {
        guard case .mastodon(_) = postCard.data else { return }
        
        self.postCard = postCard
        
        if postCard.isReblogged {
            let normalized_username = postCard
                .rebloggerUsername
                .stripCustomEmojiShortcodes()
                .stripEmojis()
                .stripLeadingTrailingSpaces()
            self.titleLabel.text = String.localizedStringWithFormat(NSLocalizedString("post.reposted", comment: "Shows up over a post in the timeline indicating who reposted it."), normalized_username)
        }
        
        if postCard.isHashtagged {
            self.titleLabel.text = "[replace with hashtag]"
        }
        
        if postCard.isPrivateMention {
            self.titleLabel.text = NSLocalizedString("post.privateMention", comment: "Shows up over a post in the timeline indicating that it's been sent privately.")
        }
        
        if let postCard = self.postCard, postCard.isPrivateMention {
            titleLabel.backgroundColor = .custom.OVRLYSoftContrast
        } else {
            titleLabel.backgroundColor = .custom.background
        }
    }
    
    func onThemeChange() {
        self.titleLabel.textColor = .custom.feintContrast
        if let postCard = self.postCard, postCard.isPrivateMention {
            titleLabel.backgroundColor = .custom.OVRLYSoftContrast
        } else {
            titleLabel.backgroundColor = .custom.background
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
       super.traitCollectionDidChange(previousTraitCollection)
       onThemeChange()
   }
}

// MARK: - Handlers
extension PostCardHeaderExtension {
    @objc func profileTapped() {
        guard case .mastodon(let status) = postCard?.data else { return }
        if let account = status.account {
            self.onPress?(.profile, true, .account(account))
        }
    }
}
