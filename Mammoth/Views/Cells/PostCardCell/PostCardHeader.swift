//
//  PostCardHeader.swift
//  Mammoth
//
//  Created by Benoit Nolens on 07/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import Combine

class PostCardHeader: UIView {
    
    enum PostCardHeaderTypes {
        case regular
        case forYou
        case channel
        case detail
        case quotePost
        case mentions
        case following
        case list
        
        func hasFollowButton(postCard: PostCardModel) -> Bool {
            let user = postCard.user
            let shouldShow = !postCard.isOwn && ((user?.followStatus as? FollowManager.FollowStatus) == .notFollowing || (user?.forceFollowButtonDisplay as? Bool) == true)
            
            switch self {
            case .mentions, .quotePost:
                return false
            case .list, .following:
                return postCard.isReblogged && shouldShow
            default:
                return shouldShow
            }
        }
        
        var showUsertagUnderneath: Bool {
            switch self {
            case .mentions, .quotePost:
                return false
            default:
                return true
            }
        }
    }
    
    // MARK: - Properties
    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.layoutMargins = .zero
        return stackView
    }()
    
    private var profilePic: PostCardProfilePic?
    
    private let headerTitleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 5
        stackView.layoutMargins = .zero
        return stackView
    }()
    
    private let headerMainTitleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 6
        stackView.isBaselineRelativeArrangement = true
        stackView.layoutMargins = .zero
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let rightAttributesStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 5
        stackView.layoutMargins = .zero
        return stackView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .custom.displayNames
        label.numberOfLines = 1
        label.isOpaque = true
        label.backgroundColor = .custom.background
        return label
    }()
    
    private let pinIcon: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let config = UIImage.SymbolConfiguration(pointSize: GlobalStruct.smallerFontSize, weight: .light)
        let icon = UIImage(systemName: "pin.fill", withConfiguration: config)?.withTintColor(.custom.feintContrast, renderingMode: .alwaysTemplate)
        imageView.contentMode = .right
        imageView.image = icon
        imageView.tintColor = .custom.feintContrast
        imageView.isOpaque = true
        imageView.backgroundColor = .custom.background
        return imageView
    }()

    private let userTagLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.custom.feintContrast
        label.isOpaque = true
        label.backgroundColor = .custom.background
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.custom.feintContrast
        label.isOpaque = true
        label.backgroundColor = .custom.background
        return label
    }()
    
    private var followButton: FollowButton?
    
    private var status: Status?
    private var postCard: PostCardModel?
    private var type: PostCardHeaderTypes = .regular
    public var onPress: PostCardButtonCallback?
    
    private var subscription: Cancellable?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.stopTimeUpdates()
        NotificationCenter.default.removeObserver(self)
    }
    
    func prepareForReuse() {
        self.status = nil
        self.postCard = nil
        self.onPress = nil
        self.profilePic?.prepareForReuse()
        self.titleLabel.text = nil
        self.userTagLabel.text = nil
        self.dateLabel.text = nil
        
        if self.rightAttributesStack.contains(self.pinIcon) {
            self.rightAttributesStack.removeArrangedSubview(self.pinIcon)
            self.pinIcon.removeFromSuperview()
        }
        
        if let profilePic = self.profilePic {
            headerTitleStackView.removeArrangedSubview(profilePic)
            profilePic.removeFromSuperview()
        }
        
        if let followButton = self.followButton, headerMainTitleStackView.arrangedSubviews.contains(followButton) {
            headerMainTitleStackView.removeArrangedSubview(followButton)
            followButton.removeFromSuperview()
        }
        
        self.stopTimeUpdates()
    }
    
    func setupUIFromSettings() {
        titleLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        userTagLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        dateLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        
        self.onThemeChange()
    }
}


// MARK: - Setup UI
private extension PostCardHeader {
    func setupUI() {
        self.isOpaque = true
        self.backgroundColor = UIColor.custom.background
        self.addSubview(mainStackView)
                
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        
        mainStackView.addArrangedSubview(headerTitleStackView)
        mainStackView.addArrangedSubview(rightAttributesStack)
        
        rightAttributesStack.addArrangedSubview(dateLabel)
        
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        userTagLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        headerTitleStackView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        headerTitleStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rightAttributesStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        headerMainTitleStackView.addArrangedSubview(titleLabel)

        headerTitleStackView.addArrangedSubview(headerMainTitleStackView)
        headerTitleStackView.addArrangedSubview(userTagLabel)
        
        NSLayoutConstraint.activate([
            headerMainTitleStackView.heightAnchor.constraint(equalToConstant: 23)
        ])
        
        setupUIFromSettings()
    }
}

// MARK: - Configuration
extension PostCardHeader {
    func configure(postCard: PostCardModel, headerType: PostCardHeaderTypes = .regular) {
        self.postCard = postCard

        if case .mastodon(let status) = postCard.data {
            self.status = status
        }
        
        if headerType == .mentions {
            self.titleLabel.isHidden = false
            self.userTagLabel.isHidden = false
            titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        } else {
            if GlobalStruct.displayName == .full {
                self.titleLabel.isHidden = false
                self.userTagLabel.isHidden = false
                titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            } else if GlobalStruct.displayName == .usernameOnly {
                self.titleLabel.isHidden = false
                self.userTagLabel.isHidden = true
                titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            } else if GlobalStruct.displayName == .usertagOnly {
                self.titleLabel.isHidden = false
                self.userTagLabel.isHidden = true
                titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            } else {                              // .none
                self.titleLabel.isHidden = true
                self.userTagLabel.isHidden = true
            }
        }
        
        if headerType.hasFollowButton(postCard: postCard) {
            if let user = postCard.user {
                if self.followButton == nil {
                    self.followButton = FollowButton(user: user)
                } else {
                    self.followButton?.user = user
                }
            }
            
            if let followButton = self.followButton {
                if !headerMainTitleStackView.arrangedSubviews.contains(followButton) {
                    headerMainTitleStackView.addArrangedSubview(followButton)
                }
            }
        } else {
            if let followButton = self.followButton {
                if headerMainTitleStackView.arrangedSubviews.contains(followButton) {
                    headerMainTitleStackView.removeArrangedSubview(followButton)
                    followButton.removeFromSuperview()
                }
            }
        }

        if headerType == .quotePost, let user = postCard.user {
            if self.profilePic == nil {
                self.profilePic = PostCardProfilePic(withSize: .small)
                self.profilePic!.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
            }

            self.profilePic!.configure(user: user)
            headerTitleStackView.insertArrangedSubview(self.profilePic!, at: 0)
        } else if let profilePic = self.profilePic, headerTitleStackView.arrangedSubviews.contains(profilePic) {
            headerTitleStackView.removeArrangedSubview(profilePic)
            profilePic.removeFromSuperview()
        }
        
        if GlobalStruct.displayName == .usertagOnly {
            self.titleLabel.text = headerType == .detail ? postCard.fullUserTag.lowercased() : postCard.userTag.lowercased()
        } else {
            if let name = postCard.richUsername {
                self.titleLabel.attributedText = formatRichText(string: name, label: self.titleLabel, emojis: postCard.account?.emojis)
                
            } else {
                self.titleLabel.text = postCard.username
            }
        }
        
        
        self.userTagLabel.text = headerType == .detail ? postCard.fullUserTag.lowercased() : postCard.userTag.lowercased()
        self.dateLabel.text = postCard.time
        
        if headerType.showUsertagUnderneath {
            headerTitleStackView.axis = .vertical
            headerTitleStackView.alignment = .leading
            headerTitleStackView.distribution = .fill
            headerTitleStackView.spacing = 0
        } else {
            headerTitleStackView.axis = .horizontal
            headerTitleStackView.alignment = .center
            headerTitleStackView.distribution = .fill
            headerTitleStackView.spacing = 5
        }
        
        if postCard.isPinned {
            self.rightAttributesStack.insertArrangedSubview(self.pinIcon, at: 0)
        }
    }
    
    func onThemeChange() {
        self.profilePic?.onThemeChange()
    }
    
    
    func startTimeUpdates() {
        if let createdAt = self.postCard?.createdAt {
            var interval: Double = 60*60
            var delay: Double = 60*15
            let now = Date()
            
            let secondsRange = now.addingTimeInterval(-60)...now
            let minutesRange = now.addingTimeInterval(-60*60)...now
            let hoursRange = now.addingTimeInterval(-60*60*24)...now
            
            if secondsRange ~= createdAt {
                interval = 5
                delay = 8
            } else if minutesRange ~= createdAt {
                interval = 30
                delay = 15
            } else if hoursRange ~= createdAt {
                interval = 60*60
                delay = 60*15
            }
            
            self.subscription = RunLoop.main.schedule(
                after: .init(Date(timeIntervalSinceNow: delay)),
                interval: .seconds(interval),
                tolerance: .seconds(1)
            ) { [weak self] in
                guard let self else { return }
                if let status = self.status {
                    let newTime = PostCardModel.formattedTime(status: status, formatter: GlobalStruct.dateFormatter)
                    self.postCard?.time = newTime
                    self.dateLabel.text = newTime
                }
            }
        }
    }
    
    @objc func stopTimeUpdates() {
        self.subscription?.cancel()
    }
}

// MARK: - Handlers
extension PostCardHeader {
    @objc func profileTapped() {
        self.onPress?(.profile, true, nil)
    }
}
