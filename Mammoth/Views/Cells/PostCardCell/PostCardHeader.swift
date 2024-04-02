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
import Meta
import MetaTextKit
import MastodonMeta

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
    
    private let titleLabel: MetaLabel = {
        let label = MetaLabel()
        label.textColor = .custom.displayNames
        label.numberOfLines = 1
        label.textContainer.maximumNumberOfLines = 1
        label.isOpaque = true
        label.backgroundColor = .custom.background
        label.textContainer.lineFragmentPadding = 0
        label.isUserInteractionEnabled = false
        label.lineBreakMode = .byTruncatingTail
        label.textContainer.lineBreakMode = .byTruncatingTail
        
        label.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold),
            .foregroundColor: UIColor.custom.displayNames
        ]

        label.linkAttributes = label.textAttributes
        
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
    private var headerType: PostCardHeaderTypes = .regular
    public var onPress: PostCardButtonCallback?
    private var isPrivateMention: Bool = false
    
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
        self.directionalLayoutMargins = .zero
        self.status = nil
        self.postCard = nil
        self.onPress = nil
        self.profilePic?.prepareForReuse()
        self.titleLabel.reset()
        self.userTagLabel.text = nil
        self.dateLabel.text = nil
        
        self.stopTimeUpdates()
    }
    
    func setupUIFromSettings() {
        userTagLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        dateLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        
        titleLabel.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold),
            .foregroundColor: UIColor.custom.displayNames
        ]

        titleLabel.linkAttributes = titleLabel.textAttributes
        
        self.onThemeChange()
    }
}


// MARK: - Setup UI
private extension PostCardHeader {
    func setupUI() {
        self.isOpaque = true
        self.directionalLayoutMargins = .zero
        self.addSubview(mainStackView)
                
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
            mainStackView.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        mainStackView.addArrangedSubview(headerTitleStackView)
        mainStackView.addArrangedSubview(rightAttributesStack)
        
        rightAttributesStack.insertArrangedSubview(pinIcon, at: 0)
        rightAttributesStack.addArrangedSubview(dateLabel)
        
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        userTagLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        headerTitleStackView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        headerTitleStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rightAttributesStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        headerMainTitleStackView.addArrangedSubview(titleLabel)
        
        self.followButton = FollowButton()
        headerMainTitleStackView.addArrangedSubview(followButton!)
        
        self.profilePic = PostCardProfilePic(withSize: .small)
        self.profilePic!.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
        headerTitleStackView.insertArrangedSubview(self.profilePic!, at: 0)
        
        headerTitleStackView.addArrangedSubview(headerMainTitleStackView)
        headerTitleStackView.addArrangedSubview(userTagLabel)
        
        NSLayoutConstraint.activate([
            headerMainTitleStackView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        setupUIFromSettings()
    }
}

// MARK: - Estimated height
extension PostCardHeader {
    static func estimatedHeight() -> CGFloat {
        return 24
    }
}

// MARK: - Configuration
extension PostCardHeader {
    func configure(postCard: PostCardModel, headerType: PostCardHeaderTypes = .regular, isVerticallyCentered: Bool = false) {
        self.postCard = postCard
        self.headerType = headerType

        if case .mastodon(let status) = postCard.data {
            self.status = status
        }
        
        let shouldChangeTheme = self.isPrivateMention != postCard.isPrivateMention
        self.isPrivateMention = postCard.isPrivateMention
        
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
                self.followButton?.user = user
                self.followButton?.alpha = self.followButton?.alpha == 1 ? 1 : 0
                self.followButton?.isHidden = false
                if self.followButton?.alpha == 0 {
                    self.followButton?.transform = CGAffineTransform.identity.scaledBy(x: 0.95, y: 0.95)
                    // Call animation in next RunLoop because current RunLoop
                    // blocks all animations (in didUpdateSnapshot)
                    DispatchQueue.main.async {
                        UIView.animate(withDuration: 0.3, delay: 0, options: [.allowAnimatedContent, .allowUserInteraction, .beginFromCurrentState], animations: { [weak self] in
                            guard let self else { return }
                            self.followButton?.transform = CGAffineTransform.identity.scaledBy(x: 1.02, y: 1.02)
                            self.followButton?.alpha = 1
                            }) { [weak self] finished in
                                UIView.animate(withDuration: 0.3 / 1.5, animations: {
                                    guard let self else { return }
                                    self.followButton?.transform = CGAffineTransform.identity
                                })
                            }
                    }
                }
                
            } else {
                self.followButton?.isHidden = true
                self.followButton?.alpha = 0
            }
        } else {
            self.followButton?.isHidden = true
            self.followButton?.alpha = 0
        }

        if headerType == .quotePost, let user = postCard.user {
            self.profilePic!.configure(user: user)
            self.profilePic!.isHidden = false
        } else if let profilePic = self.profilePic, headerTitleStackView.arrangedSubviews.contains(profilePic) {
            self.profilePic!.isHidden = true
        }
        
        self.configureMetaTextContent()
        
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
            self.pinIcon.isHidden = false
        } else {
            self.pinIcon.isHidden = true
        }
        
        // center header content vertically when the post has a carousel and no post text
        if isVerticallyCentered && self.userTagLabel.isHidden {
            self.directionalLayoutMargins = .init(top: 10, leading: 0, bottom: 12, trailing: 0)
        }
        
        if shouldChangeTheme {
            self.onThemeChange()
        }
    }
    
    func configureMetaTextContent() {
        if GlobalStruct.displayName == .usertagOnly {
            let text = headerType == .detail ? postCard?.fullUserTag.lowercased() ?? "" : postCard?.userTag.lowercased() ?? ""
            let content = MastodonMetaContent.convert(text: MastodonContent(content: text, emojis: [:]))
            self.titleLabel.configure(content: content)
        } else {
            if let metaContent = postCard?.user?.metaName {
                self.titleLabel.configure(content: metaContent)
            } else {
                let text = postCard?.user?.name ?? ""
                let content = MastodonMetaContent.convert(text: MastodonContent(content: text, emojis: [:]))
                self.titleLabel.configure(content: content)
            }
        }
    }
    
    func onThemeChange() {
        self.profilePic?.onThemeChange()
        var backgroundColor = UIColor.custom.background
        
        if let postCard = self.postCard, postCard.isPrivateMention {
            backgroundColor = .custom.OVRLYSoftContrast
        }
        
        self.backgroundColor = backgroundColor
        titleLabel.backgroundColor = backgroundColor
        userTagLabel.backgroundColor = backgroundColor
        dateLabel.backgroundColor = backgroundColor
        mainStackView.backgroundColor = backgroundColor
        headerTitleStackView.backgroundColor = backgroundColor
        rightAttributesStack.backgroundColor = backgroundColor
        headerMainTitleStackView.backgroundColor = backgroundColor
        headerTitleStackView.backgroundColor = backgroundColor
    }
    
    func willDisplay() {
        self.profilePic?.willDisplay()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Update all items that use .custom colors
        configureMetaTextContent()
        titleLabel.textColor = .custom.displayNames
        let config = UIImage.SymbolConfiguration(pointSize: GlobalStruct.smallerFontSize, weight: .light)
        pinIcon.image = UIImage(systemName: "pin.fill", withConfiguration: config)?.withTintColor(.custom.feintContrast, renderingMode: .alwaysTemplate)
        pinIcon.tintColor = .custom.feintContrast
        userTagLabel.textColor = .custom.feintContrast
        dateLabel.textColor = .custom.feintContrast
        
        setupUIFromSettings()
    }
    
    func startTimeUpdates() {
        if let createdAt = self.postCard?.createdAt {
            Task { [weak self] in
                guard let self else { return }
                var interval: Double = 60*60
                var delay: Double = 60*15
                let now = Date()
                
                let secondsRange = now.addingTimeInterval(-60)...now
                let minutesRange = now.addingTimeInterval(-60*60)...now
                let hoursRange = now.addingTimeInterval(-60*60*24)...now
                
                if secondsRange ~= createdAt {
                    interval = 5
                    delay = 2
                } else if minutesRange ~= createdAt {
                    interval = 30
                    delay = 15
                } else if hoursRange ~= createdAt {
                    interval = 60*60
                    delay = 60*15
                }
                
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.subscription = RunLoop.main.schedule(
                        after: .init(Date(timeIntervalSinceNow: delay)),
                        interval: .seconds(interval),
                        tolerance: .seconds(1)
                    ) { [weak self] in
                        guard let self else { return }
                        if let status = self.status {
                            Task { [weak self] in
                                guard let self else { return }
                                let newTime = PostCardModel.formattedTime(status: status, formatter: GlobalStruct.dateFormatter)
                                await MainActor.run { [weak self] in
                                    guard let self else { return }
                                    self.postCard?.time = newTime
                                    self.dateLabel.text = newTime
                                }
                            }
                        }
                    }
                }
                
                if let status = self.status {
                    let newTime = PostCardModel.formattedTime(status: status, formatter: GlobalStruct.dateFormatter)
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        self.postCard?.time = newTime
                        self.dateLabel.text = newTime
                    }
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
