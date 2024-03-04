//
//  ActivityCardCell.swift
//  Mammoth
//
//  Created by Benoit Nolens on 01/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import MetaTextKit
import MastodonMeta

final class ActivityCardCell: UITableViewCell {
    static let reuseIdentifier = "ActivityCardCell"
    
    // MARK: - Properties
    
    // Includes the header extension and the rest of the cell
    private var wrapperStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
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
        stackView.isOpaque = true
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
        stackView.spacing = 11.0
        stackView.preservesSuperviewLayoutMargins = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // Includes header, text, media
    private var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 2
        stackView.isOpaque = true
        stackView.layoutMargins = .zero
        return stackView
    }()
    
    // Includes text, small media
    private var textAndSmallMediaStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 12
        stackView.isOpaque = true
        stackView.layoutMargins = .zero
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        return stackView
    }()
    
    private let profilePic = PostCardProfilePic(withSize: .regular)
    private let header = ActivityCardHeader()

    private var postTextLabel: MetaLabel = {
        let label = MetaLabel()
        label.textColor = .custom.mediumContrast
        label.isOpaque = true
        label.numberOfLines = 2
        label.textContainer.lineFragmentPadding = 0
        label.textContainer.maximumNumberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]

        label.linkAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold),
            .foregroundColor: UIColor.custom.highContrast,
        ]

        label.paragraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = DeviceHelpers.isiOSAppOnMac() ? 1 : 0
            style.paragraphSpacing = 12
            style.alignment = .natural
            return style
        }()

        return label
    }()
    
    // Contains image attachment, poll, and/or link preview if needed
    private var mediaContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.layoutMargins = .zero
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        return stackView
    }()
    
    private var poll: PostCardPoll?
    private var pollTrailingConstraint: NSLayoutConstraint? = nil
    
    private var thumbnailImage: PostCardImage?
    private var thumbnailImageTrailingConstraint: NSLayoutConstraint? = nil
    
    private var image: PostCardImage?
    private var imageTrailingConstraint: NSLayoutConstraint? = nil
    
    private var thumbnailVideo: PostCardVideo?
    private var thumbnailVideoTrailingConstraint: NSLayoutConstraint? = nil
    
    private var video: PostCardVideo?
    private var videoTrailingConstraint: NSLayoutConstraint? = nil
    
    private var mediaStack: PostCardMediaStack?
    private var mediaStackTrailingConstraint: NSLayoutConstraint? = nil
    
    private var mediaGallery: PostCardMediaGallery?
    private var mediaGalleryTrailingConstraint: NSLayoutConstraint? = nil
    
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
        self.postTextLabel.reset()
        self.postTextLabel.isUserInteractionEnabled = true
        
        self.header.prepareForReuse()
        self.resetMedia()
        
        contentStackView.setCustomSpacing(0, after: self.textAndSmallMediaStackView)
    }
    
    private func resetMedia() {
        self.thumbnailImage?.prepareForReuse()
        self.thumbnailImage?.isHidden = true
        imageTrailingConstraint?.isActive = true
        
        self.image?.prepareForReuse()
        self.image?.isHidden = true
        imageTrailingConstraint?.isActive = false
        
        self.video?.prepareForReuse()
        self.video?.isHidden = true
        videoTrailingConstraint?.isActive = false
        
        self.thumbnailVideo?.prepareForReuse()
        self.thumbnailVideo?.isHidden = true
        thumbnailVideoTrailingConstraint?.isActive = false
        
        self.mediaStack?.prepareForReuse()
        self.mediaStack?.isHidden = true
        mediaStackTrailingConstraint?.isActive = false
        
        self.mediaGallery?.prepareForReuse()
        self.mediaGallery?.isHidden = true
        mediaGalleryTrailingConstraint?.isActive = false
        
        self.linkPreview!.prepareForReuse()
        self.linkPreview!.isHidden = true
        linkPreviewTrailingConstraint?.isActive = false
        
        self.poll!.prepareForReuse()
        self.poll!.isHidden = true
        pollTrailingConstraint?.isActive = false
        
        self.quotePost!.prepareForReuse()
        self.quotePost!.isHidden = true
        quotePostTrailingConstraint?.isActive = false
    }
    
    /// the cell will be displayed in the tableview
    public func willDisplay() {
        if let postCard = self.activityCard?.postCard, postCard.hasMediaAttachment && [.singleVideo, .singleGIF].contains(postCard.mediaDisplayType) {
            if GlobalStruct.autoPlayVideos {
                self.video?.play()
            }
        }
        
        if let postCard = self.activityCard?.postCard, postCard.hasQuotePost {
            postCard.preloadQuotePost()
        }
        
        self.profilePic.willDisplay()
        self.header.startTimeUpdates()
    }
    
    // the cell will end being displayed in the tableview
    public func didEndDisplay() {
        if let postCard = self.activityCard?.postCard, postCard.hasMediaAttachment && [.singleVideo, .singleGIF].contains(postCard.mediaDisplayType) {
            self.video?.pause()
        }
        
        if let postCard = self.activityCard?.postCard, postCard.hasQuotePost, let quotePostCard = postCard.quotePostData, let video = quotePostCard.videoPlayer {
            video.pause()
        }
        
        self.header.stopTimeUpdates()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }
        if let mediaGallery = self.mediaGallery,
           self.activityCard?.postCard?.mediaDisplayType == .carousel,
            mediaGallery.isHidden == false,
            mediaGallery.alpha == 1 {
            let convertedPoint = mediaGallery.convert(point, from: self)
            return mediaGallery.hitTest(convertedPoint, with: event) ?? hitView
        }
        
        return hitView
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
        self.contentView.layoutMargins = .init(top: 18, left: 13, bottom: 18, right: 13)
        
        contentView.addSubview(wrapperStackView)
        wrapperStackView.addArrangedSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            wrapperStackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            wrapperStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            wrapperStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            wrapperStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            
            // Force main stack view to fill the parent width
            mainStackView.trailingAnchor.constraint(equalTo: wrapperStackView.layoutMarginsGuide.trailingAnchor),
        ])

        mainStackView.addArrangedSubview(profilePic)
        mainStackView.addArrangedSubview(contentStackView)
        
        contentStackView.addArrangedSubview(header)
        contentStackView.addArrangedSubview(textAndSmallMediaStackView)
        textAndSmallMediaStackView.addArrangedSubview(postTextLabel)
        contentStackView.addArrangedSubview(mediaContainer)
        
        postTextLabel.linkDelegate = self

        let postTextTrailing = postTextLabel.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor)
        postTextTrailing.priority = .defaultHigh

        NSLayoutConstraint.activate([
            // Force header to fill the parent width
            header.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
            // Force post text to fill the parent width
            postTextTrailing
        ])
        
        // Force media container to fill the parent width - with max width for big displays
        mediaContainer.addHorizontalFillConstraints(withParent: contentStackView, andMaxWidth: 340)
        
        // Poll
        self.poll = PostCardPoll()
        self.poll!.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addArrangedSubview(self.poll!)
        pollTrailingConstraint = self.poll!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor)
        self.poll!.isHidden = true
        
        // Quote Post
        self.quotePost = PostCardQuotePost(mediaVariant: .small)
        self.quotePost!.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addArrangedSubview(self.quotePost!)
        quotePostTrailingConstraint = self.quotePost!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor)
        self.quotePost!.isHidden = true
        
        // Link Preview
        self.linkPreview = PostCardLinkPreview()
        self.linkPreview!.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addArrangedSubview(self.linkPreview!)
        linkPreviewTrailingConstraint = self.linkPreview!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor)
        self.linkPreview!.isHidden = true
        
        // Thumbnail image
        self.thumbnailImage = PostCardImage(variant: .thumbnail)
        self.thumbnailImage!.translatesAutoresizingMaskIntoConstraints = false
        textAndSmallMediaStackView.addArrangedSubview(self.thumbnailImage!)
        thumbnailImageTrailingConstraint = self.thumbnailImage!.widthAnchor.constraint(equalToConstant: 60)
        self.thumbnailImage!.isHidden = true
        
        // Full size image
        self.image = PostCardImage(variant: .fullSize)
        self.image!.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addArrangedSubview(self.image!)
        imageTrailingConstraint = self.image!.trailingAnchor.constraint(equalTo: mediaContainer.layoutMarginsGuide.trailingAnchor)
        self.image!.isHidden = true
        
        // Thumbnail video
        self.thumbnailVideo = PostCardVideo(variant: .thumbnail)
        self.thumbnailVideo!.translatesAutoresizingMaskIntoConstraints = false
        textAndSmallMediaStackView.addArrangedSubview(self.thumbnailVideo!)
        thumbnailVideoTrailingConstraint = self.thumbnailVideo!.widthAnchor.constraint(equalToConstant: 60)
        self.thumbnailVideo!.isHidden = true
        
        // Full size video
        self.video = PostCardVideo(variant: .fullSize)
        self.video!.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addArrangedSubview(self.video!)
        videoTrailingConstraint = self.video!.trailingAnchor.constraint(equalTo: mediaContainer.layoutMarginsGuide.trailingAnchor)
        self.video!.isHidden = true
        
        // Media Stack
        self.mediaStack = PostCardMediaStack(variant: .thumbnail)
        self.mediaStack!.translatesAutoresizingMaskIntoConstraints = false
        textAndSmallMediaStackView.addArrangedSubview(self.mediaStack!)
        mediaStackTrailingConstraint = self.mediaStack!.widthAnchor.constraint(equalToConstant: 60)
        self.mediaStack!.isHidden = true
        
        // Media Gallery
        self.mediaGallery = PostCardMediaGallery()
        self.mediaGallery!.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addArrangedSubview(self.mediaGallery!)
        mediaGalleryTrailingConstraint = self.mediaGallery!.trailingAnchor.constraint(equalTo: mediaContainer.layoutMarginsGuide.trailingAnchor)
        self.mediaGallery!.isHidden = true
        
        setupUIFromSettings()
    }
    
    @objc func setupUIFromSettings() {
        self.postTextLabel.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]
        configurePostTextLabelAttributes()

        self.postTextLabel.paragraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = DeviceHelpers.isiOSAppOnMac() ? 1 : 0
            style.paragraphSpacing = 12
            style.alignment = .natural
            return style
        }()

        self.header.setupUIFromSettings()
        self.linkPreview?.setupUIFromSettings()
        self.quotePost?.setupUIFromSettings()
        
        self.onThemeChange()
    }
    
    func configurePostTextLabelAttributes() {
        let linkAttributeColor: UIColor
        let linkAttributeWeight: UIFont.Weight
        if let cardType = activityCard?.type {
            switch cardType {
            case .follow, .follow_request:
                linkAttributeColor = UIColor.custom.mediumContrast
                linkAttributeWeight = .regular
            default:
                linkAttributeColor = UIColor.custom.highContrast
                linkAttributeWeight = .semibold
            }
            self.postTextLabel.linkAttributes = [
                .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: linkAttributeWeight),
                .foregroundColor: linkAttributeColor
            ]
        }
    }
}

// MARK: - Configuration
extension ActivityCardCell {
    func configure(activity: ActivityCardModel, onButtonPress: @escaping PostCardButtonCallback) {
        self.activityCard = activity
        self.onButtonPress = onButtonPress
        
        let cellVariant = activity.postCard != nil ? PostCardCell.PostCardVariant.cellVariant(for: activity.postCard!, cellType: .regular) : nil

        self.profilePic.configure(user: activity.user, badgeIcon: mapTypeTBadgeImage(activity: activity))
        self.profilePic.onPress = onButtonPress
        
        let isVerticallyCentered = activity.postCard?.mediaDisplayType == .carousel
                                    && ((activity.postCard?.postText ?? "")?.isEmpty ?? false)
                                    && cellVariant?.mediaVariant == .large
                                    && activity.type == .status
        
        self.header.configure(activity: activity, isVerticallyCentered: isVerticallyCentered)
        self.header.onPress = onButtonPress
        
        configurePostTextLabelAttributes()
        switch activity.type {
        case .follow, .follow_request:
            let content = MastodonContent(content: activity.user.userTag, emojis: [:])
            postTextLabel.configure(content: MastodonMetaContent.convert(text: content))
            postTextLabel.isUserInteractionEnabled = false
            self.postTextLabel.isHidden = false
        default:
            if let content = activity.postCard?.metaPostText {
                if !content.original.isEmpty {
                    self.postTextLabel.configure(content: content)
                    self.postTextLabel.isHidden = false
                    
                } else if [.small, .hidden].contains(cellVariant?.mediaVariant) && activity.type == .status {
                    // If there's no post text, but a media attachment,
                    // set the post text to either:
                    //  - ([type])
                    //  - ([type] description: [meta description])
                    if let type = activity.postCard?.mediaDisplayType.captializedDisplayName  {
                        if let desc = activity.postCard?.mediaAttachments.first?.description {
                            let content = MastodonMetaContent.convert(text: MastodonContent(content: "(\(type) description: \(desc))", emojis: [:]))
                            self.postTextLabel.configure(content: content)
                            self.postTextLabel.isHidden = false
                        } else {
                            let content = MastodonMetaContent.convert(text: MastodonContent(content: "(\(type))", emojis: [:]))
                            self.postTextLabel.configure(content: content)
                            self.postTextLabel.isHidden = false
                        }
                    } else {
                        self.postTextLabel.isHidden = true
                    }
                } else {
                    self.postTextLabel.isHidden = true
                }
            }
        }
        
        
        if let postCard = activity.postCard {
            let hideMedia = [.favourite, .reblog].contains(activity.type)
            
            if activity.type == .status {
                if self.postTextLabel.textContainer.maximumNumberOfLines != GlobalStruct.maxLines {
                    self.postTextLabel.textContainer.maximumNumberOfLines = GlobalStruct.maxLines
                }
            }
            
            // Display poll if needed
            if postCard.containsPoll && !hideMedia {
                self.poll!.configure(postCard: postCard)
                self.poll!.isHidden = false
                pollTrailingConstraint?.isActive = true
            } else {
                self.poll!.isHidden = true
                pollTrailingConstraint?.isActive = false
            }

            // Display the quote post preview if needed
            if postCard.hasQuotePost && !hideMedia {
                self.quotePost!.configure(postCard: postCard)
                self.quotePost!.onPress = onButtonPress
                self.quotePost!.isHidden = false
                quotePostTrailingConstraint?.isActive = true
            } else {
                self.quotePost!.isHidden = true
                quotePostTrailingConstraint?.isActive = false
            }

            // Display the link preview if needed
            if postCard.hasLink && !postCard.hasQuotePost {
                self.linkPreview!.configure(postCard: postCard)
                self.linkPreview!.onPress = onButtonPress
                self.linkPreview!.isHidden = false
                linkPreviewTrailingConstraint?.isActive = true
            } else {
                self.linkPreview!.isHidden = true
                linkPreviewTrailingConstraint?.isActive = false
            }
            
            // Display single image if needed
            if postCard.hasMediaAttachment && postCard.mediaDisplayType == .singleImage && !hideMedia {
                if activity.type == .status, let postCard = activity.postCard {
                    switch cellVariant?.mediaVariant {
                    case .small:
                        self.thumbnailImage?.configure(postCard: postCard)
                        self.thumbnailImage?.isHidden = false
                        thumbnailImageTrailingConstraint?.isActive = true
                    case .large:
                        self.image?.configure(postCard: postCard)
                        self.image?.isHidden = false
                        imageTrailingConstraint?.isActive = true
                    default:
                        self.thumbnailImage?.isHidden = true
                        thumbnailImageTrailingConstraint?.isActive = false
                        self.image?.isHidden = true
                        imageTrailingConstraint?.isActive = false
                    }
                } else {
                    self.thumbnailImage?.configure(postCard: postCard)
                    self.thumbnailImage?.isHidden = false
                    thumbnailImageTrailingConstraint?.isActive = true
                }
            } else {
                self.thumbnailImage?.isHidden = true
                thumbnailImageTrailingConstraint?.isActive = false
                self.image?.isHidden = true
                imageTrailingConstraint?.isActive = false
            }
            
            // Display single video/gif if needed
            if postCard.hasMediaAttachment && [.singleVideo, .singleGIF].contains(postCard.mediaDisplayType) && !hideMedia {
                if activity.type == .status, let postCard = activity.postCard {
                    let cellVariant = PostCardCell.PostCardVariant.cellVariant(for: postCard, cellType: .regular)
                    switch cellVariant?.mediaVariant {
                    case .small:
                        self.thumbnailVideo?.configure(postCard: postCard)
                        self.thumbnailVideo?.isHidden = false
                        thumbnailVideoTrailingConstraint?.isActive = true
                    case .large:
                        self.video?.configure(postCard: postCard)
                        self.video?.isHidden = false
                        videoTrailingConstraint?.isActive = true
                    default:
                        self.video?.isHidden = true
                        videoTrailingConstraint?.isActive = false
                        self.thumbnailVideo?.isHidden = true
                        thumbnailVideoTrailingConstraint?.isActive = false
                        break
                    }
                } else {
                    self.thumbnailVideo?.configure(postCard: postCard)
                    self.thumbnailVideo?.isHidden = false
                    thumbnailVideoTrailingConstraint?.isActive = true
                }
            } else {
                self.video?.isHidden = true
                videoTrailingConstraint?.isActive = false
                self.thumbnailVideo?.isHidden = true
                thumbnailVideoTrailingConstraint?.isActive = false
            }

            // Display the image carousel if needed
            if postCard.hasMediaAttachment && postCard.mediaDisplayType == .carousel && !hideMedia {
                if activity.type == .status, let postCard = activity.postCard {
                    switch cellVariant?.mediaVariant {
                    case .small:
                        self.mediaStack?.configure(postCard: postCard)
                        self.mediaStack?.isHidden = false
                        mediaStackTrailingConstraint?.isActive = true
                    case .large:
                        self.mediaGallery?.configure(postCard: postCard)
                        self.mediaGallery?.isHidden = false
                        mediaGalleryTrailingConstraint?.isActive = true
                    default:
                        self.mediaStack?.isHidden = true
                        mediaStackTrailingConstraint?.isActive = false
                        self.mediaGallery?.isHidden = true
                        mediaGalleryTrailingConstraint?.isActive = false
                    }
                } else {
                    self.mediaStack?.configure(postCard: postCard)
                    self.mediaStack?.isHidden = false
                    mediaStackTrailingConstraint?.isActive = true
                }
            } else {
                self.mediaStack?.isHidden = true
                mediaStackTrailingConstraint?.isActive = false
                self.mediaGallery?.isHidden = true
                mediaGalleryTrailingConstraint?.isActive = false
            }

            // If we are hiding the link image, move the link view
            // so it's below any possible media.
            if let linkPreview = self.linkPreview, postCard.hideLinkImage && mediaContainer.arrangedSubviews.contains(linkPreview), !hideMedia {
                mediaContainer.insertArrangedSubview(linkPreview, at: mediaContainer.arrangedSubviews.count - 1)
            }
            
            // Add extra spacing between text and media
            let cellVariant = PostCardCell.PostCardVariant.cellVariant(for: postCard, cellType: .regular)
            if (postCard.hasLink || postCard.hasMediaAttachment) && activity.type == .status, !postCard.postText.isEmpty, cellVariant?.mediaVariant == .large {
                contentStackView.setCustomSpacing(12, after: self.textAndSmallMediaStackView)
            } else {
                if postCard.hasMediaAttachment {
                    contentStackView.setCustomSpacing(2, after: self.textAndSmallMediaStackView)
                } else {
                    contentStackView.setCustomSpacing(0, after: self.textAndSmallMediaStackView)
                }
            }
        } else {
            self.resetMedia()
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
            self.postTextLabel.reset()
            self.postTextLabel.text = "\(batchId) - \(batchItemIndex)"
            
            if let mediaStack = self.mediaStack {
                self.mediaStackTrailingConstraint?.isActive = false
                self.textAndSmallMediaStackView.removeArrangedSubview(mediaStack)
                mediaStack.removeFromSuperview()
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

// MARK: - MetaLabelDelegate
extension ActivityCardCell: MetaLabelDelegate {
    func metaLabel(_ metaLabel: MetaTextKit.MetaLabel, didSelectMeta meta: Meta) {
        switch meta {
        case .url(_, _, let urlString, _):
            if let url = URL(string: urlString) {
                self.onButtonPress?(.link, true, .url(url))
            }
        case .mention(_, let mention, _):
            if case .mastodon(let status) = self.activityCard?.postCard?.data {
                self.onButtonPress?(.link, true, .mention((mention, status)))
            }
        case .hashtag(_, let hashtag, _):
            self.onButtonPress?(.link, true, .hashtag(hashtag))
        default:
            if let postCard = self.activityCard?.postCard {
                self.onButtonPress?(.postDetails, true, .post(postCard))
            }
        }
    }
}

// MARK: Appearance changes
internal extension ActivityCardCell {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 self.setupUIFromSettings()
             }
         }
    }
}
