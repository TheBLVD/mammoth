//
//  ActivityCardHeader.swift
//  Mammoth
//
//  Created by Benoit Nolens on 01/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import Combine
import Meta
import MetaTextKit
import MastodonMeta

class ActivityCardHeader: UIView {
    
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
        
    private let headerTitleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let rightAttributesStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
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
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }()
    
    private let pinIcon: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let config = UIImage.SymbolConfiguration(pointSize: GlobalStruct.smallerFontSize, weight: .light)
        let icon = UIImage(systemName: "pin.fill", withConfiguration: config)?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
        imageView.contentMode = .right
        imageView.image = icon
        imageView.isOpaque = true
        imageView.backgroundColor = .custom.background
        return imageView
    }()

    private let actionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.custom.feintContrast
        label.isOpaque = true
        label.backgroundColor = .custom.background
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.custom.feintContrast
        label.isOpaque = true
        label.backgroundColor = .custom.background
        return label
    }()
    
    private var activity: ActivityCardModel?
    public var onPress: PostCardButtonCallback?
    
    private var subscription: Cancellable?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(self.stopTimeUpdates), name: UIApplication.didEnterBackgroundNotification, object: nil)
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
        self.activity = nil
        self.onPress = nil
        self.titleLabel.reset()
        self.actionLabel.text = nil
        self.dateLabel.text = nil
        
        if self.rightAttributesStack.contains(self.pinIcon) {
            self.rightAttributesStack.removeArrangedSubview(self.pinIcon)
            self.pinIcon.removeFromSuperview()
        }

        self.stopTimeUpdates()
    }
    
    func setupUIFromSettings() {
        actionLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        dateLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        
        titleLabel.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold),
            .foregroundColor: UIColor.custom.displayNames
        ]

        titleLabel.linkAttributes = titleLabel.textAttributes
    }
}


// MARK: - Setup UI
private extension ActivityCardHeader {
    func setupUI() {
        self.isOpaque = true
        self.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
        ])
        
        mainStackView.addArrangedSubview(headerTitleStackView)
        mainStackView.addArrangedSubview(rightAttributesStack)
        
        rightAttributesStack.addArrangedSubview(dateLabel)
        
        // Don't compress but let siblings fill the space
        dateLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 752), for: .horizontal)
        
        headerTitleStackView.addArrangedSubview(titleLabel)
        headerTitleStackView.addArrangedSubview(actionLabel)
        
        setupUIFromSettings()
    }

}

// MARK: - Configuration
extension ActivityCardHeader {
    func configure(activity: ActivityCardModel, isVerticallyCentered: Bool = false) {
        self.activity = activity
        
        if GlobalStruct.displayName == .usertagOnly {
            let text = activity.user.userTag.lowercased()
            let content = MastodonMetaContent.convert(text: MastodonContent(content: text, emojis: [:]))
            self.titleLabel.configure(content: content)
        } else {
            if let metaContent = activity.user.metaName {
                self.titleLabel.configure(content: metaContent)
            } else {
                let text = activity.user.name
                let content = MastodonMetaContent.convert(text: MastodonContent(content: text, emojis: [:]))
                self.titleLabel.configure(content: content)
            }
        }
        
        self.actionLabel.text = self.mapTypeToAction(activity: activity)
        self.dateLabel.text = activity.time
        
        if [.favourite, .reblog].contains(activity.type), let text = activity.postCard?.postText, text.isEmpty {
            headerTitleStackView.axis = .vertical
            headerTitleStackView.alignment = .leading
            headerTitleStackView.spacing = 0
        } else {
            headerTitleStackView.axis = .horizontal
            headerTitleStackView.alignment = .center
            headerTitleStackView.spacing = 5
        }
        
        // center header content vertically when the post has a carousel and no post text
        if isVerticallyCentered {
            self.directionalLayoutMargins = .init(top: 10, leading: 0, bottom: 12, trailing: 0)
        } else {
            self.directionalLayoutMargins = .zero
        }
    }
    
   private func mapTypeToAction(activity: ActivityCardModel) -> String {
        switch activity.type {
        case .favourite:
            if let text = activity.postCard?.postText, text.isEmpty, let mediaType = activity.postCard?.mediaDisplayType.displayName {
                return String.localizedStringWithFormat(NSLocalizedString("activity.likedMedia", comment: "Could be image, video, GIF or carousel."), mediaType)
            }
            if let text = activity.postCard?.postText, text.isEmpty, let postCard = activity.postCard, postCard.hasQuotePost {
                return NSLocalizedString("activity.likedQuote", comment: "")
            }
            return NSLocalizedString("activity.liked", comment: "")
        case .follow:
            return NSLocalizedString("activity.followedYou", comment: "")
        case .follow_request:
            return NSLocalizedString("activity.followRequest", comment: "")
        case .poll:
            return NSLocalizedString("activity.pollEnded", comment: "")
        case .reblog:
            if let text = activity.postCard?.postText, text.isEmpty, let mediaType = activity.postCard?.mediaDisplayType.displayName {
                return String.localizedStringWithFormat(NSLocalizedString("activity.repostedMedia", comment: "Could be image, video, GIF or carousel."), mediaType)
            }
            if let text = activity.postCard?.postText, text.isEmpty, let postCard = activity.postCard, postCard.hasQuotePost {
                return NSLocalizedString("activity.repostedQuote", comment: "")
            }
            return NSLocalizedString("activity.reposted", comment: "")
        case .status:
            return NSLocalizedString("activity.posted", comment: "")
        case .update:
            return NSLocalizedString("activity.edited", comment: "")
        case .direct:
            return NSLocalizedString("activity.mention", comment: "")
        case .mention:
            if let postCard = activity.postCard, postCard.isPrivateMention {
                return NSLocalizedString("activity.mention", comment: "")
            }
            return NSLocalizedString("activity.mention", comment: "")
        }
    }
    
    func onThemeChange() {
        self.backgroundColor = .custom.background
        titleLabel.textColor = .custom.displayNames
        titleLabel.backgroundColor = .custom.background
        dateLabel.textColor = .custom.feintContrast
        dateLabel.backgroundColor = .custom.background
        actionLabel.textColor = .custom.feintContrast
        actionLabel.backgroundColor = .custom.background
        let config = UIImage.SymbolConfiguration(pointSize: GlobalStruct.smallerFontSize, weight: .light)
        pinIcon.image = UIImage(systemName: "pin.fill", withConfiguration: config)?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
        pinIcon.backgroundColor = .custom.background
    }
    
    func startTimeUpdates() {
        if let createdAt = self.activity?.createdAt {
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
            
            self.subscription = RunLoop.main.schedule(
                after: .init(Date(timeIntervalSinceNow: delay)),
                interval: .seconds(interval),
                tolerance: .seconds(1)
            ) { [weak self] in
                guard let self else { return }
                if let notification = self.activity?.notification {
                    let newTime = ActivityCardModel.formattedTime(notification: notification, formatter: GlobalStruct.dateFormatter)
                    self.activity?.time = newTime
                    self.dateLabel.text = newTime
                }
            }
            
            if let notification = self.activity?.notification {
                let newTime = ActivityCardModel.formattedTime(notification: notification, formatter: GlobalStruct.dateFormatter)
                self.activity?.time = newTime
                self.dateLabel.text = newTime
            }
        }
    }
    
    @objc func stopTimeUpdates() {
        self.subscription?.cancel()
    }
}

// MARK: - Handlers
extension ActivityCardHeader {
    @objc func profileTapped() {
        self.onPress?(.profile, true, nil)
    }
}
