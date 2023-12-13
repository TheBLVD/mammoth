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
        label.backgroundColor = .custom.background
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

// MARK: - Configuration
extension PostCardHeaderExtension {
    func configure(postCard: PostCardModel) {
        guard case .mastodon(let status) = postCard.data else { return }
        
        self.postCard = postCard
        
        if postCard.isReblogged {
            if let name = postCard.richRebloggerUsername {
                let string = NSMutableAttributedString(attributedString: formatRichText(string: name, label: self.titleLabel, emojis: status.account?.emojis))
                string.append(NSMutableAttributedString(string: " reposted"))
                self.titleLabel.attributedText = string
            } else {
                self.titleLabel.text = postCard.rebloggerUsername + " reposted"
            }
        }
        
        if postCard.isHashtagged {
            self.titleLabel.text = "[replace with hashtag]"
        }
        
        if postCard.isPrivateMention {
            self.titleLabel.text = "private mention"
        }
    }
    
    func onThemeChange() {
        self.titleLabel.textColor = .custom.feintContrast
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
