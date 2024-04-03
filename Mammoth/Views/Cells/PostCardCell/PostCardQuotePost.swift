//
//  PostCardQuotePost.swift
//  Mammoth
//
//  Created by Benoit Nolens on 07/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import Meta
import MastodonMeta
import MetaTextKit

class PostCardQuotePost: UIView {
    
    // MARK: - Properties
    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 4.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .custom.background
        
        stackView.layer.borderWidth = 1.0 / UIScreen.main.scale
        stackView.layer.allowsEdgeAntialiasing = false
        stackView.layer.edgeAntialiasingMask = [.layerBottomEdge, .layerTopEdge, .layerLeftEdge, .layerRightEdge]
        stackView.layer.needsDisplayOnBoundsChange = false
        stackView.layer.rasterizationScale = UIScreen.main.scale
        stackView.layer.contentsScale = UIScreen.main.scale
        
        stackView.layer.borderColor = UIColor.custom.outlines.cgColor
        stackView.layer.masksToBounds = true
        stackView.layer.cornerRadius = 10
        stackView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 13, trailing: 0)
        
        return stackView
    }()
    
    private var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 4.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        
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

    private var header = PostCardHeader()
    private var headerTrailingConstraint: NSLayoutConstraint?
    
    private var mediaContainerConstraints: [NSLayoutConstraint]? = []
    
    private var postTextLabel: MetaLabel = {
        let metaText = MetaLabel()
        metaText.isOpaque = true
        metaText.backgroundColor = .custom.background
        metaText.translatesAutoresizingMaskIntoConstraints = false
        metaText.textContainer.lineFragmentPadding = 0
        metaText.numberOfLines = 4
        metaText.textContainer.maximumNumberOfLines = 4
        metaText.textContainer.lineBreakMode = .byTruncatingTail

        return metaText
    }()
        
    // Contains image attachment, poll, and/or link preview if needed
    private var mediaContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        return stackView
    }()
        
    private var postCard: PostCardModel?
    public var onPress: PostCardButtonCallback?
    
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
    
    private var mediaGallery: PostCardMediaGallery?
    private var mediaGalleryTrailingConstraint: NSLayoutConstraint? = nil
    
    private var mediaStack: PostCardMediaStack?
    private var mediaStackTrailingConstraint: NSLayoutConstraint? = nil
    
    private var linkPreview: PostCardLinkPreview?
    private var linkPreviewTrailingConstraint: NSLayoutConstraint?
    
    private var postNotFound: PostCardQuoteNotFound?
    private var postNotFoundTrailingConstraint: NSLayoutConstraint?
    
    private var postLoader: PostCardQuoteActivityIndicator?
    private var postLoaderTrailingConstraint: NSLayoutConstraint?
    
    private let mediaVariant: PostCardCell.PostCardMediaVariant
    
    init(mediaVariant: PostCardCell.PostCardMediaVariant = .large) {
        self.mediaVariant = mediaVariant
        super.init(frame: .zero)
        self.setupUI()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.onTapped))
        self.mainStackView.addGestureRecognizer(tapGesture)
        
        let contextMenu = UIContextMenuInteraction(delegate: self)
        self.mainStackView.addInteraction(contextMenu)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        self.postCard = nil
        self.onPress = nil
        self.isUserInteractionEnabled = true
        
        header.prepareForReuse()
        header.isHidden = true
        headerTrailingConstraint?.isActive = false
        
        mainStackView.directionalLayoutMargins.bottom = 13
        mediaContainer.directionalLayoutMargins.leading = 12
        mediaContainer.directionalLayoutMargins.trailing = 12
        
        self.postTextLabel.reset()
        self.postTextLabel.isHidden = true
        
        if let poll = self.poll {
            poll.prepareForReuse()
            poll.isHidden = true
            self.pollTrailingConstraint?.isActive = false
        }
        
        if let image = self.image, self.mediaContainer.arrangedSubviews.contains(image) {
            image.prepareForReuse()
            image.isHidden = true
            self.imageTrailingConstraint?.isActive = false
        }
        
        if let image = self.thumbnailImage {
            image.prepareForReuse()
            image.isHidden = true
            self.thumbnailImageTrailingConstraint?.isActive = false
        }
        
        if let video = self.thumbnailVideo {
            video.prepareForReuse()
            video.isHidden = true
            self.thumbnailVideoTrailingConstraint?.isActive = false
        }
        
        if let video = self.video {
            video.prepareForReuse()
            video.isHidden = true
            self.videoTrailingConstraint?.isActive = false
        }
        
        if let mediaStack = self.mediaStack {
            mediaStack.prepareForReuse()
            mediaStack.isHidden = true
            self.mediaStackTrailingConstraint?.isActive = false
        }
        
        if let mediaGallery = self.mediaGallery {
            mediaGallery.prepareForReuse()
            mediaGallery.isHidden = true
            self.mediaGalleryTrailingConstraint?.isActive = false
        }
        
        if let linkPreview = self.linkPreview {
            linkPreview.prepareForReuse()
            linkPreview.isHidden = true
            self.linkPreviewTrailingConstraint?.isActive = false
        }
        
        if let postNotFound = self.postNotFound {
            postNotFound.isHidden = true
            self.postNotFoundTrailingConstraint?.isActive = false
        }
        
        if let postLoader = self.postLoader {
            postLoader.isHidden = true
            self.postLoaderTrailingConstraint?.isActive = false
        }
    }
    
    func setupUIFromSettings() {
        self.postTextLabel.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]
        self.postTextLabel.linkAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold),
            .foregroundColor: UIColor.custom.highContrast,
        ]

        self.postTextLabel.paragraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = DeviceHelpers.isiOSAppOnMac() ? 1 : 0
            style.paragraphSpacing = 12
            style.alignment = .natural
            return style
        }()
    }
}


// MARK: - Setup UI
private extension PostCardQuotePost {
    func setupUI() {
        self.isOpaque = true
        self.addSubview(mainStackView)
        
        mainStackView.addArrangedSubview(contentStackView)
        
        self.header.isUserInteractionEnabled = false
        contentStackView.insertArrangedSubview(self.header, at: 0)
        headerTrailingConstraint = self.header.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: -self.contentStackView.directionalLayoutMargins.trailing)
        
        contentStackView.addArrangedSubview(textAndSmallMediaStackView)
        
        self.postTextLabel.isUserInteractionEnabled = false
        self.postTextLabel.isHidden = true
        textAndSmallMediaStackView.addArrangedSubview(self.postTextLabel)
        
        mainStackView.addArrangedSubview(mediaContainer)
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Poll
            self.poll = PostCardPoll()
            self.poll!.isUserInteractionEnabled = false
            self.poll!.isHidden = true
            self.mediaContainer.addArrangedSubview(self.poll!)
            self.pollTrailingConstraint = self.poll!.trailingAnchor.constraint(equalTo: self.mediaContainer.trailingAnchor, constant: -self.mediaContainer.directionalLayoutMargins.trailing)
            
            // Thumbnail image
            self.thumbnailImage = PostCardImage(variant: .thumbnail)
            self.thumbnailImage!.translatesAutoresizingMaskIntoConstraints = false
            self.thumbnailImage!.isHidden = true
            self.textAndSmallMediaStackView.addArrangedSubview(self.thumbnailImage!)
            self.thumbnailImageTrailingConstraint = self.thumbnailImage!.widthAnchor.constraint(equalToConstant: 60)
            
            // Fullsize image
            self.image = PostCardImage(variant: .fullSize)
            self.image!.translatesAutoresizingMaskIntoConstraints = false
            self.image!.isHidden = true
            self.mediaContainer.addArrangedSubview(self.image!)
            self.imageTrailingConstraint = self.image!.trailingAnchor.constraint(equalTo: self.mediaContainer.trailingAnchor, constant: -self.mediaContainer.directionalLayoutMargins.trailing)
            
            // Thumbnail video
            self.thumbnailVideo = PostCardVideo(variant: .thumbnail)
            self.thumbnailVideo!.translatesAutoresizingMaskIntoConstraints = false
            self.thumbnailVideo!.isHidden = true
            self.textAndSmallMediaStackView.addArrangedSubview(self.thumbnailVideo!)
            self.thumbnailVideoTrailingConstraint = self.thumbnailVideo!.widthAnchor.constraint(equalToConstant: 60)
            
            // Fullsize video
            self.video = PostCardVideo(variant: .fullSize)
            self.video!.translatesAutoresizingMaskIntoConstraints = false
            self.video!.isHidden = true
            self.mediaContainer.addArrangedSubview(self.video!)
            self.videoTrailingConstraint = self.video!.trailingAnchor.constraint(equalTo: self.mediaContainer.trailingAnchor, constant: -self.mediaContainer.directionalLayoutMargins.trailing)
            
            // Media stack
            self.mediaStack = PostCardMediaStack(variant: .thumbnail)
            self.mediaStack?.translatesAutoresizingMaskIntoConstraints = false
            self.mediaStack?.isHidden = true
            self.textAndSmallMediaStackView.addArrangedSubview(self.mediaStack!)
            self.mediaStackTrailingConstraint = self.mediaStack!.widthAnchor.constraint(equalToConstant: 60)
            
            // Media gallery
            self.mediaGallery = PostCardMediaGallery()
            self.mediaGallery?.isHidden = true
            self.mediaGallery?.translatesAutoresizingMaskIntoConstraints = false
            self.mediaContainer.addArrangedSubview(self.mediaGallery!)
            self.mediaGalleryTrailingConstraint = self.mediaGallery!.trailingAnchor.constraint(equalTo: self.mediaContainer.layoutMarginsGuide.trailingAnchor)
            
            // Link
            self.linkPreview = PostCardLinkPreview()
            self.linkPreview!.isUserInteractionEnabled = false
            self.linkPreview!.isHidden = true
            self.mediaContainer.addArrangedSubview(self.linkPreview!)
            self.linkPreviewTrailingConstraint = self.linkPreview!.trailingAnchor.constraint(equalTo: self.mediaContainer.trailingAnchor, constant: -self.mediaContainer.directionalLayoutMargins.trailing)
            
            NSLayoutConstraint.activate([
                // Force content container to fill the parent width
                self.contentStackView.trailingAnchor.constraint(equalTo: self.mainStackView.trailingAnchor),
                self.textAndSmallMediaStackView.trailingAnchor.constraint(equalTo: self.contentStackView.layoutMarginsGuide.trailingAnchor),
                
                // Force media container to fill the parent width
                self.mediaContainer.trailingAnchor.constraint(equalTo: self.mainStackView.trailingAnchor)
            ])
        }
        
        // Post loader
        self.postLoader = PostCardQuoteActivityIndicator()
        self.postLoader!.isUserInteractionEnabled = false
        self.postLoader!.isHidden = true
        self.contentStackView.addArrangedSubview(self.postLoader!)
        self.postLoaderTrailingConstraint = self.postLoader!.trailingAnchor.constraint(equalTo: self.contentStackView.trailingAnchor, constant: -self.contentStackView.directionalLayoutMargins.trailing)
        
        // Post not found
        self.postNotFound = PostCardQuoteNotFound()
        self.postNotFound!.isHidden = true
        self.postNotFound!.isUserInteractionEnabled = false
        self.postNotFound!.translatesAutoresizingMaskIntoConstraints = false
        self.contentStackView.addArrangedSubview(self.postNotFound!)
        self.postNotFoundTrailingConstraint = self.postNotFound!.trailingAnchor.constraint(equalTo: self.contentStackView.trailingAnchor, constant: -self.contentStackView.directionalLayoutMargins.trailing)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 9),
            mainStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
        
        setupUIFromSettings()
    }
}

// MARK: - Configuration
extension PostCardQuotePost {
    func configure(postCard: PostCardModel) {
        self.postCard = postCard
        self.isUserInteractionEnabled = true
                
        // If a quote post status is found and loaded
        if let quotePostCard = postCard.quotePostData {
            
            self.postLoader?.isHidden = true
            self.postLoader?.stopAnimation()
            
            // Display header
            self.header.configure(postCard: quotePostCard, headerType: .quotePost)
            self.header.willDisplay()
            self.header.isHidden = false
            headerTrailingConstraint?.isActive = true

            // Display post text
            if let postTextContent = quotePostCard.metaPostText, !postTextContent.original.isEmpty {
                self.postTextLabel.configure(content: postTextContent)
                self.postTextLabel.isHidden = false
            } else if [.small, .hidden].contains(self.mediaVariant) {
                // If there's no post text, but a media attachment,
                // set the post text to either:
                //  - ([type])
                //  - ([type] description: [meta description])
                if let type = quotePostCard.mediaDisplayType.captializedDisplayName  {
                    if let desc = quotePostCard.mediaAttachments.first?.description {
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

            // Display poll if needed
            if quotePostCard.containsPoll {
                self.poll?.configure(postCard: quotePostCard)
                self.poll?.isHidden = false
                pollTrailingConstraint?.isActive = true
            }

            // Display the link preview if needed
            if quotePostCard.hasLink {
                self.linkPreview?.configure(postCard: quotePostCard)
                self.linkPreview?.isHidden = false
                linkPreviewTrailingConstraint?.isActive = true
                self.linkPreview?.onPress = onPress
            }
            
            // Display single image if needed
            if quotePostCard.hasMediaAttachment && quotePostCard.mediaDisplayType == .singleImage {
                switch self.mediaVariant {
                case .small:
                    self.thumbnailImage?.configure(postCard: quotePostCard)
                    self.thumbnailImage?.isHidden = false
                    self.thumbnailImageTrailingConstraint?.isActive = true
                    
                    self.image?.isHidden = true
                    self.imageTrailingConstraint?.isActive = false
                case .large:
                    self.image?.configure(postCard: quotePostCard)
                    self.image?.isHidden = false
                    self.imageTrailingConstraint?.isActive = true
                    
                    self.thumbnailImage?.isHidden = true
                    self.thumbnailImageTrailingConstraint?.isActive = false
                default: break
                }
            }
            
            // Display single video/gif if needed
            if quotePostCard.hasMediaAttachment && [.singleVideo, .singleGIF].contains(quotePostCard.mediaDisplayType) {
                switch self.mediaVariant {
                case .small:
                    self.thumbnailVideo?.isHidden = false
                    self.thumbnailVideo?.configure(postCard: quotePostCard)
                    self.thumbnailVideo?.pause()
                    thumbnailVideoTrailingConstraint?.isActive = true
                    
                    self.video?.isHidden = true
                    videoTrailingConstraint?.isActive = false
                case .large:
                    self.video?.isHidden = false
                    self.video?.configure(postCard: quotePostCard)
                    videoTrailingConstraint?.isActive = true
                    
                    self.thumbnailVideo?.isHidden = true
                    thumbnailVideoTrailingConstraint?.isActive = false
                default:
                    self.video?.isHidden = true
                    videoTrailingConstraint?.isActive = false
                    self.thumbnailVideo?.isHidden = true
                    thumbnailVideoTrailingConstraint?.isActive = false
                }
            }
            
            // Display the image carousel if needed
            if quotePostCard.hasMediaAttachment && quotePostCard.mediaDisplayType == .carousel {
                switch self.mediaVariant {
                case .small:
                    self.mediaStack?.isHidden = false
                    self.mediaStack?.configure(postCard: quotePostCard)
                    mediaStackTrailingConstraint?.isActive = true
                    
                    self.mediaGallery?.isHidden = true
                    mediaGalleryTrailingConstraint?.isActive = false
                case .large:
                    self.mediaGallery?.isHidden = false
                    self.mediaGallery?.configure(postCard: quotePostCard)
                    mediaGalleryTrailingConstraint?.isActive = true
                    
                    self.mediaStack?.isHidden = true
                    mediaStackTrailingConstraint?.isActive = false
                default:
                    self.mediaGallery?.isHidden = true
                    mediaGalleryTrailingConstraint?.isActive = false
                    self.mediaStack?.isHidden = true
                    mediaStackTrailingConstraint?.isActive = false
                }
            }
        }

        if postCard.quotePostStatus == .notFound {
            self.postLoader?.isHidden = true
            self.postLoader?.stopAnimation()
            
            // Quote post can't be found
            self.postNotFound?.isHidden = false
            self.isUserInteractionEnabled = false
            postNotFoundTrailingConstraint?.isActive = true
            mainStackView.directionalLayoutMargins.bottom = 10
            
            header.isHidden = true
            headerTrailingConstraint?.isActive = false
            self.postTextLabel.isHidden = true
        }
        
        if postCard.quotePostStatus == .loading  {
            // Quote post is being loaded
            self.postLoader?.isHidden = false
            self.postLoader?.startAnimation()
            postLoaderTrailingConstraint?.isActive = true
            mainStackView.directionalLayoutMargins.bottom = 10
            
            self.postNotFound?.isHidden = true
            postNotFoundTrailingConstraint?.isActive = false
            
            header.isHidden = true
            headerTrailingConstraint?.isActive = false
            self.postTextLabel.isHidden = true
        }
    }
    
    func onThemeChange() {
        self.mainStackView.layer.borderColor = UIColor.custom.outlines.cgColor
        
        self.header.onThemeChange()
        self.linkPreview?.onThemeChange()
        self.poll?.onThemeChange()
        self.postNotFound?.onThemeChange()
        
        self.setupUIFromSettings()
        
        self.postTextLabel.backgroundColor = .custom.background
        self.mainStackView.backgroundColor = .custom.background
    }
    
    func willDisplay() {
        self.header.willDisplay()
    }
}

// MARK: - Handlers
extension PostCardQuotePost {
    @objc func onTapped() {
        if let quotedPost = self.postCard?.quotePostData {
            self.onPress?(.postDetails, true, .post(quotedPost))
        }
    }
}

// MARK: - Context menu creators
extension PostCardQuotePost: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        if let postCard = self.postCard, let onButtonPress = self.onPress {
            if let urlStr = postCard.quotePostCard?.url, let url = URL(string: urlStr) {
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { [weak self] _ in
                    guard let self else { return UIMenu() }
                    
                    let options = [
                        self.createContextMenuAction(NSLocalizedString("post.openLink", comment: ""), .link, isActive: false, data: .url(url), onPress: onButtonPress),
                        self.createContextMenuAction(NSLocalizedString("generic.copy", comment: ""), .copy, isActive: false, data: .url(url), onPress: onButtonPress),
                        self.createContextMenuAction(NSLocalizedString("generic.share", comment: ""), .share, isActive: false, data: .url(url), onPress: onButtonPress),
                    ].compactMap({$0})
                    
                    return UIMenu(title: "", options: [.displayInline], children: options)
                })
            }
        }
        
        return nil
    }

    private func createContextMenuAction(_ title: String, _ buttonType: PostCardButtonType, isActive: Bool, data: PostCardButtonCallbackData?, onPress: @escaping PostCardButtonCallback) -> UIAction {
        let action = UIAction(title: title,
                                  image: buttonType.icon(symbolConfig: postCardSymbolConfig),
                                  identifier: nil) { _ in
            onPress(buttonType, isActive, data)
        }
        action.accessibilityLabel = title
        return action
    }
}

// MARK: - Child views
fileprivate class PostCardQuoteNotFound: UIStackView {
    
    private var leftAttribute: UIImageView = {
        let imageView = UIImageView()
        imageView.image = FontAwesome.image(fromChar: "\u{f10d}", color: .secondaryLabel, size: 15, weight: .bold)
        return imageView
    }()
    
    private var rightAttribute: UIImageView = {
        let imageView = UIImageView()
        imageView.image = FontAwesome.image(fromChar: "\u{f05a}", color: .custom.baseTint, size: 15)
        return imageView
    }()
    
    var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .custom.mediumContrast
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.axis = .horizontal
        self.alignment = .center
        self.distribution = .fill
        self.spacing = 8.0
        
        self.isLayoutMarginsRelativeArrangement = true
        self.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0)
        
        self.titleLabel.text = "Post could not be found"
        
        self.addArrangedSubview(self.leftAttribute)
        self.addArrangedSubview(self.titleLabel)
        self.addArrangedSubview(self.rightAttribute)
        
        // Don't compress but let siblings fill the space
        leftAttribute.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
        leftAttribute.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        
        // Don't compress but let siblings fill the space
        rightAttribute.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
        rightAttribute.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
    }
    
    func onThemeChange() {
        self.leftAttribute.image = FontAwesome.image(fromChar: "\u{f10d}", color: .secondaryLabel, size: 15, weight: .bold)
        self.rightAttribute.image = FontAwesome.image(fromChar: "\u{f05a}", color: .custom.baseTint, size: 15)
    }
}

fileprivate class PostCardQuoteActivityIndicator: UIStackView {
    
    private var activityIndicator: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView()
        loader.startAnimating()
        return loader
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.axis = .horizontal
        self.alignment = .center
        self.distribution = .fill
        self.spacing = 0.0
        
        self.isLayoutMarginsRelativeArrangement = true
        self.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0)
                
        self.addArrangedSubview(self.activityIndicator)
    }
    
    func startAnimation() {
        self.activityIndicator.startAnimating()
    }
    
    func stopAnimation() {
        if self.activityIndicator.isAnimating {
            self.activityIndicator.stopAnimating()
        }
    }
    
    func onThemeChange() {
        
    }
}
