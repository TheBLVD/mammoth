//
//  ActivityCardCell.swift
//  Mammoth
//
//  Created by Benoit Nolens on 01/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class ActivityCardCell: UITableViewCell {
    static let reuseIdentifier = "ActivityCardCell"
    
    // MARK: - Properties
    
    // Includes the header extension and the rest of the cell
    private var wrapperStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 6.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // Basic cell columns: profile pic, and cell content
    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
        stackView.spacing = 11.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // Includes header, text, media
    private var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 2
        stackView.isOpaque = true
        return stackView
    }()
    
    private let profilePic = PostCardProfilePic(withSize: .regular)
    private let header = ActivityCardHeader()

    private var postTextLabel: ActiveLabel = {
        let label = ActiveLabel()
        label.textColor = .custom.mediumContrast
        label.enabledTypes = [.mention, .hashtag, .url, .email]
        label.mentionColor = .custom.highContrast
        label.hashtagColor = .custom.highContrast
        label.URLColor = .custom.highContrast
        label.emailColor = .custom.highContrast
        label.linkWeight = .semibold
        label.isOpaque = true
        label.urlMaximumLength = 30
        label.numberOfLines = 4
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Contains image attachment, poll, and/or link preview if needed
    private var mediaContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var poll: PostCardPoll?
    private var pollTrailingConstraint: NSLayoutConstraint? = nil
    
    private var image: PostCardImage?
    private var imageTrailingConstraint: NSLayoutConstraint? = nil
    
    private var video: PostCardVideo?
    private var videoTrailingConstraint: NSLayoutConstraint? = nil
    
    private var imageAttachment: PostCardImageAttachment?
    private var imageAttachmentTrailingConstraint: NSLayoutConstraint? = nil
    
    private var linkPreview: PostCardLinkPreview?
    private var linkPreviewTrailingConstraint: NSLayoutConstraint? = nil
    
    private var quotePost: PostCardQuotePost?
    private var quotePostTrailingConstraint: NSLayoutConstraint? = nil
    
    private var activityCard: ActivityCardModel?
    private var onButtonPress: PostCardButtonCallback?

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.setupUIFromSettings),
                                               name: NSNotification.Name(rawValue: "reloadAll"),
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.activityCard = nil
        self.profilePic.prepareForReuse()
        self.postTextLabel.text = nil
        self.postTextLabel.attributedText = nil
        self.postTextLabel.linkWeight = .semibold
        self.postTextLabel.isUserInteractionEnabled = true
        
        self.header.prepareForReuse()
        
        if let image = self.image, self.mediaContainer.arrangedSubviews.contains(image) {
            self.image?.prepareForReuse()
            self.imageTrailingConstraint?.isActive = false
            self.imageTrailingConstraint = nil
            self.mediaContainer.removeArrangedSubview(image)
            image.removeFromSuperview()
            self.image = nil
        }
        
        if let video = self.video, self.mediaContainer.arrangedSubviews.contains(video) {
            self.video?.prepareForReuse()
            self.videoTrailingConstraint?.isActive = false
            self.videoTrailingConstraint = nil
            self.mediaContainer.removeArrangedSubview(video)
            video.removeFromSuperview()
            self.video = nil
        }
        
        if let imageAttachment = self.imageAttachment {
            self.imageAttachmentTrailingConstraint?.isActive = false
            self.mediaContainer.removeArrangedSubview(imageAttachment)
            imageAttachment.removeFromSuperview()
        }
        
        if let linkPreview = self.linkPreview {
            self.linkPreviewTrailingConstraint?.isActive = false
            self.mediaContainer.removeArrangedSubview(linkPreview)
            linkPreview.removeFromSuperview()
            linkPreview.prepareForReuse()
        }
        
        if let poll = self.poll {
            self.pollTrailingConstraint?.isActive = false
            self.mediaContainer.removeArrangedSubview(poll)
            poll.removeFromSuperview()
            poll.prepareForReuse()
        }
        
        if let quotePost = self.quotePost {
            self.quotePostTrailingConstraint?.isActive = false
            self.mediaContainer.removeArrangedSubview(quotePost)
            quotePost.removeFromSuperview()
            quotePost.prepareForReuse()
        }
    }
    
    /// the cell will be displayed in the tableview
    public func willDisplay() {
        if let postCard = self.activityCard?.postCard, postCard.hasMediaAttachment && postCard.mediaDisplayType == .singleVideo {
            if GlobalStruct.autoPlayVideos {
                self.video?.play()
            }
        }
        
        self.header.startTimeUpdates()
    }
    
    // the cell will end being displayed in the tableview
    public func didEndDisplay() {
        if let postCard = self.activityCard?.postCard, postCard.hasMediaAttachment && postCard.mediaDisplayType == .singleVideo {
            self.video?.pause()
        }
        
        self.header.stopTimeUpdates()
    }
}

// MARK: - Setup UI
private extension ActivityCardCell {
    func setupUI() {
        self.selectionStyle = .none
        self.separatorInset = .zero
        self.layoutMargins = .zero
        self.contentView.preservesSuperviewLayoutMargins = false
        self.isOpaque = true
        self.contentView.isOpaque = true
        
        contentView.addSubview(wrapperStackView)
        wrapperStackView.addArrangedSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            wrapperStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            wrapperStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            wrapperStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 13),
            wrapperStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -13),
            
            // Force main stack view to fill the parent width
            mainStackView.trailingAnchor.constraint(equalTo: wrapperStackView.trailingAnchor),
        ])

        mainStackView.addArrangedSubview(profilePic)
        mainStackView.addArrangedSubview(contentStackView)
        
        contentStackView.addArrangedSubview(header)
        contentStackView.addArrangedSubview(postTextLabel)
        contentStackView.addArrangedSubview(mediaContainer)
                
        let postTextTrailing = postTextLabel.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor)
        postTextTrailing.priority = .defaultHigh

        NSLayoutConstraint.activate([
            // Force header to fill the parent width
            header.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
            // Force post text to fill the parent width
            postTextTrailing
        ])
        
        // Force media container to fill the parent width - with max width for big displays
        mediaContainer.addHorizontalFillConstraints(withParent: contentStackView, andMaxWidth: 320)
        
        setupUIFromSettings()
    }
    
    @objc func setupUIFromSettings() {
        postTextLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        
        self.header.setupUIFromSettings()
        self.linkPreview?.setupUIFromSettings()
        self.quotePost?.setupUIFromSettings()
        
        self.onThemeChange()
    }
}

// MARK: - Configuration
extension ActivityCardCell {
    func configure(activity: ActivityCardModel, onButtonPress: @escaping PostCardButtonCallback) {
        self.activityCard = activity
        self.onButtonPress = onButtonPress

        self.profilePic.configure(user: activity.user, badgeIcon: mapTypeTBadgeImage(activity: activity))
        self.profilePic.onPress = onButtonPress
        self.header.configure(activity: activity)
        self.header.onPress = onButtonPress
        
        self.postTextLabel.customize { [weak self] label in
            guard let self else { return }
            switch activity.type {
            case .follow, .follow_request:
                label.attributedText = nil
                label.text = activity.user.userTag
                label.linkWeight = .regular
                label.isUserInteractionEnabled = false
            default:
                if let postCard = activity.postCard {
                    if let postText = postCard.richPostText {
                        label.attributedText = formatRichText(string: postText, label: label, emojis: postCard.emojis)
                    } else {
                        label.text = postCard.postText
                    }
                }
            }
            
            // Post text link handlers
            label.handleURLTap { url in
                onButtonPress(.link, true, .url(url))
            }
            label.handleHashtagTap { hashtag in
                onButtonPress(.link, true, .hashtag(hashtag))
            }
            
            if case .mastodon(let status) = activity.postCard?.data {
                label.handleMentionTap { mention in
                    onButtonPress(.link, true, .mention((mention, status)))
                }
            }
        }
        
        
        if let postCard = activity.postCard {
            // Display poll if needed
            if postCard.containsPoll {
                if self.poll == nil {
                    self.poll = PostCardPoll()
                } else {
                    self.poll!.prepareForReuse()
                }

                self.poll!.configure(postCard: postCard)
                mediaContainer.addArrangedSubview(self.poll!)
                pollTrailingConstraint = pollTrailingConstraint ?? self.poll!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor)
                pollTrailingConstraint?.isActive = true
            }

            // Display the quote post preview if needed
            if postCard.hasQuotePost {
                if self.quotePost == nil {
                    self.quotePost = PostCardQuotePost()
                }

                self.quotePost!.configure(postCard: postCard)
                self.quotePost!.onPress = onButtonPress

                mediaContainer.addArrangedSubview(self.quotePost!)
                quotePostTrailingConstraint = quotePostTrailingConstraint ?? self.quotePost!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor)
                quotePostTrailingConstraint?.isActive = true
            }

            // Display the link preview if needed
            if postCard.hasLink && !postCard.hasQuotePost {
                if self.linkPreview == nil {
                    self.linkPreview = PostCardLinkPreview()
                }

                self.linkPreview!.configure(postCard: postCard)
                mediaContainer.addArrangedSubview(self.linkPreview!)
                linkPreviewTrailingConstraint = linkPreviewTrailingConstraint ?? self.linkPreview!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor)
                linkPreviewTrailingConstraint?.isActive = true

                self.linkPreview!.onPress = onButtonPress
            }
            
            // Display single image if needed
            if postCard.hasMediaAttachment && postCard.mediaDisplayType == .singleImage {
                if self.image == nil {
                    self.image = PostCardImage()
                    self.image!.translatesAutoresizingMaskIntoConstraints = false
                }
                
                self.image!.configure(postCard: postCard)
                mediaContainer.addArrangedSubview(self.image!)
                imageTrailingConstraint = imageTrailingConstraint ?? self.image!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor)
                imageTrailingConstraint?.isActive = true
            }
            
            // Display single video/gif if needed
            if postCard.hasMediaAttachment && postCard.mediaDisplayType == .singleVideo {
                if self.video == nil {
                    self.video = PostCardVideo()
                    self.video!.translatesAutoresizingMaskIntoConstraints = false
                }
                
                self.video!.configure(postCard: postCard)
                mediaContainer.addArrangedSubview(self.video!)
                videoTrailingConstraint = videoTrailingConstraint ?? self.video!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor)
                videoTrailingConstraint?.isActive = true
            }

            // Display the image carousel if needed
            if postCard.hasMediaAttachment && postCard.mediaDisplayType == .carousel {
                if self.imageAttachment == nil {
                    self.imageAttachment = PostCardImageAttachment()
                }

                self.imageAttachment!.configure(postCard: postCard)
                mediaContainer.addArrangedSubview(self.imageAttachment!)
                imageAttachmentTrailingConstraint = imageAttachmentTrailingConstraint ?? self.imageAttachment!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor)
                imageAttachmentTrailingConstraint?.isActive = true
            }

            // If we are hiding the link image, move the link view
            // so it's below any possible media.
            if let linkPreview = self.linkPreview, postCard.hideLinkImage && mediaContainer.arrangedSubviews.contains(linkPreview) {
                mediaContainer.insertArrangedSubview(linkPreview, at: mediaContainer.arrangedSubviews.count - 1)
            }
        }
        
        if CommandLine.arguments.contains("-M_DEBUG_TIMELINES") {
            // Configure for debugging
            self.configureForDebugging(activity: activity)
        }
    }
    
    private func mapTypeTBadgeImage(activity: ActivityCardModel) -> UIImage {
        switch activity.type {
        case .favourite:
            return FontAwesome.image(fromChar: "\u{f004}", weight: .bold).withRenderingMode(.alwaysTemplate)
        case .follow:
            return FontAwesome.image(fromChar: "\u{f007}", weight: .bold).withRenderingMode(.alwaysTemplate)
        case .follow_request:
            return FontAwesome.image(fromChar: "\u{f007}", weight: .bold).withRenderingMode(.alwaysTemplate)
        case .poll:
            return FontAwesome.image(fromChar: "\u{e149}", weight: .bold).withRenderingMode(.alwaysTemplate)
        case .reblog:
            return FontAwesome.image(fromChar: "\u{f079}", weight: .bold).withRenderingMode(.alwaysTemplate)
        case .status:
            return FontAwesome.image(fromChar: "\u{e149}", weight: .bold).withRenderingMode(.alwaysTemplate)
        case .update:
            return FontAwesome.image(fromChar: "\u{e149}", weight: .bold).withRenderingMode(.alwaysTemplate)
        case .direct:
            return FontAwesome.image(fromChar: "\u{e149}", weight: .bold).withRenderingMode(.alwaysTemplate)
        case .mention:
            if let postCard = activity.postCard, postCard.isPrivateMention {
                return FontAwesome.image(fromChar: "\u{e149}", weight: .bold).withRenderingMode(.alwaysTemplate)
            }
            return FontAwesome.image(fromChar: "\u{e149}", weight: .bold).withRenderingMode(.alwaysTemplate)
        }
    }
    
    private func configureForDebugging(activity: ActivityCardModel) {
        if let batchId = activity.batchId, let batchItemIndex = activity.batchItemIndex {
            self.postTextLabel.attributedText = nil
            self.postTextLabel.text = "\(batchId) - \(batchItemIndex)"
            
            if let imageAttachment = self.imageAttachment {
                self.imageAttachmentTrailingConstraint?.isActive = false
                self.mediaContainer.removeArrangedSubview(imageAttachment)
                imageAttachment.removeFromSuperview()
            }
            
            if let linkPreview = self.linkPreview {
                self.linkPreviewTrailingConstraint?.isActive = false
                self.mediaContainer.removeArrangedSubview(linkPreview)
                linkPreview.removeFromSuperview()
                linkPreview.prepareForReuse()
            }
            
            if let poll = self.poll {
                self.pollTrailingConstraint?.isActive = false
                self.mediaContainer.removeArrangedSubview(poll)
                poll.removeFromSuperview()
                poll.prepareForReuse()
            }
            
            if let quotePost = self.quotePost {
                self.quotePostTrailingConstraint?.isActive = false
                self.mediaContainer.removeArrangedSubview(quotePost)
                quotePost.removeFromSuperview()
                quotePost.prepareForReuse()
            }
        }
    }
    
    func onThemeChange() {
        self.backgroundColor = .custom.background
        self.contentView.backgroundColor = .custom.background
        self.postTextLabel.mentionColor = .custom.highContrast
        self.postTextLabel.hashtagColor = .custom.highContrast
        self.postTextLabel.URLColor = .custom.highContrast
        self.postTextLabel.emailColor = .custom.highContrast
        self.postTextLabel.backgroundColor = self.contentView.backgroundColor
        
        self.profilePic.onThemeChange()
        self.header.onThemeChange()
        self.poll?.onThemeChange()
        self.linkPreview?.onThemeChange()
        self.quotePost?.onThemeChange()
    }
}

// MARK: - Context menu creators
extension ActivityCardCell {
    private func createContextMenuAction(_ title: String, _ buttonType: PostCardButtonType, isActive: Bool, onPress: @escaping PostCardButtonCallback) -> UIAction {
        let action = UIAction(title: title,
                              image: isActive
                              ? buttonType.activeIcon(symbolConfig: postCardSymbolConfig)
                              : buttonType.icon(symbolConfig: postCardSymbolConfig),
                                  identifier: nil) { _ in
            onPress(buttonType, isActive, nil)
        }
        action.accessibilityLabel = title
        return action
    }
    
    // General cell context menu
    func createContextMenu(postCard: PostCardModel, onButtonPress: @escaping PostCardButtonCallback) -> UIMenu {
        let options = [
            createContextMenuAction("Reply", .reply, isActive: false, onPress: onButtonPress),
            
            (postCard.isReposted
             ? createContextMenuAction("Undo repost", .repost, isActive: true, onPress: onButtonPress)
             : createContextMenuAction("Repost", .repost, isActive: false, onPress: onButtonPress)),
            
            (postCard.isLiked
             ? createContextMenuAction("Unlike", .like, isActive: true, onPress: onButtonPress)
             : createContextMenuAction("Like", .like, isActive: false, onPress: onButtonPress)),
            
            (postCard.isBookmarked
                ? createContextMenuAction("Remove bookmark", .unbookmark, isActive: false, onPress: onButtonPress)
                : createContextMenuAction("Bookmark", .bookmark, isActive: false, onPress: onButtonPress)),
            
            createContextMenuAction("Translate post", .translate, isActive: false, onPress: onButtonPress),
            createContextMenuAction("View in browser", .viewInBrowser, isActive: false, onPress: onButtonPress),
            createContextMenuAction("Share", .share, isActive: false, onPress: onButtonPress),
            
            (postCard.isOwn
             ? UIMenu(title: "Modify post", options: [], children: [
                
                (postCard.isPinned
                    ? createContextMenuAction("Unpin post", .pinPost, isActive: true, onPress: onButtonPress)
                    : createContextMenuAction("Pin post", .pinPost, isActive: false, onPress: onButtonPress)),
                
                createContextMenuAction("Edit post", .editPost, isActive: false, onPress: onButtonPress),
                createContextMenuAction("Delete post", .deletePost, isActive: false, onPress: onButtonPress)])
             : nil)
        ].compactMap({$0})
        
        return UIMenu(title: "", options: [.displayInline], children: options)
    }
}
