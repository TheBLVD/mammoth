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
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 4.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.layer.borderWidth = 0.4
        stackView.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        stackView.layer.masksToBounds = true
        stackView.layer.cornerRadius = 10
        stackView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 13, trailing: 0)
        
        return stackView
    }()
    
    private var contentStackView: UIStackView = {
        let stackView = UIStackView()
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
    
    private var image: PostCardImage?
    private var imageTrailingConstraint: NSLayoutConstraint? = nil
    
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
        
        if self.headerTrailingConstraint?.isActive == true {
            self.headerTrailingConstraint?.isActive = false
            self.contentStackView.removeArrangedSubview(header)
            header.removeFromSuperview()
            header.prepareForReuse()
        }
        
        mainStackView.directionalLayoutMargins.bottom = 13
        mediaContainer.directionalLayoutMargins.leading = 12
        mediaContainer.directionalLayoutMargins.trailing = 12
        
        self.postTextLabel.attributedText = nil
        textAndSmallMediaStackView.removeArrangedSubview(self.postTextLabel)
        self.postTextLabel.removeFromSuperview()
        
        if let poll = self.poll {
            self.pollTrailingConstraint?.isActive = false
            self.mediaContainer.removeArrangedSubview(poll)
            poll.removeFromSuperview()
            poll.prepareForReuse()
        }
        
        if let image = self.image, self.mediaContainer.arrangedSubviews.contains(image) {
            self.image?.prepareForReuse()
            self.imageTrailingConstraint?.isActive = false
            self.imageTrailingConstraint = nil
            self.mediaContainer.removeArrangedSubview(image)
            image.removeFromSuperview()
            self.image = nil
        }
        
        if let image = self.image, self.textAndSmallMediaStackView.arrangedSubviews.contains(image) {
            self.image?.prepareForReuse()
            self.imageTrailingConstraint?.isActive = false
            self.imageTrailingConstraint = nil
            self.textAndSmallMediaStackView.removeArrangedSubview(image)
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
        
        if let video = self.video, self.textAndSmallMediaStackView.arrangedSubviews.contains(video) {
            self.video?.prepareForReuse()
            self.videoTrailingConstraint?.isActive = false
            self.videoTrailingConstraint = nil
            self.textAndSmallMediaStackView.removeArrangedSubview(video)
            video.removeFromSuperview()
            self.video = nil
        }
        
        if let mediaStack = self.mediaStack {
            self.mediaStackTrailingConstraint?.isActive = false
            self.textAndSmallMediaStackView.removeArrangedSubview(mediaStack)
            mediaStack.removeFromSuperview()
        }
        
        if let mediaGallery = self.mediaGallery {
            self.mediaGalleryTrailingConstraint?.isActive = false
            self.mediaContainer.removeArrangedSubview(mediaGallery)
            mediaGallery.removeFromSuperview()
        }
        
        if let linkPreview = self.linkPreview {
            self.linkPreviewTrailingConstraint?.isActive = false
            self.mediaContainer.removeArrangedSubview(linkPreview)
            linkPreview.removeFromSuperview()
            linkPreview.prepareForReuse()
        }
        
        if let postNotFound = self.postNotFound {
            contentStackView.removeArrangedSubview(postNotFound)
            postNotFound.removeFromSuperview()
            self.postNotFoundTrailingConstraint?.isActive = false
        }
        
        if let postLoader = self.postLoader {
            contentStackView.removeArrangedSubview(postLoader)
            postLoader.removeFromSuperview()
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
            style.paragraphSpacing = 4
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
        contentStackView.addArrangedSubview(textAndSmallMediaStackView)
        mainStackView.addArrangedSubview(mediaContainer)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 9),
            mainStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
        
        NSLayoutConstraint.activate([
            // Force content container to fill the parent width
            contentStackView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),
            textAndSmallMediaStackView.trailingAnchor.constraint(equalTo: contentStackView.layoutMarginsGuide.trailingAnchor),
            
            // Force media container to fill the parent width
            mediaContainer.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor)
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
            
            if let postLoader = self.postLoader {
                contentStackView.removeArrangedSubview(postLoader)
                postLoader.removeFromSuperview()
                self.postLoaderTrailingConstraint?.isActive = false
            }
            
            // Display header
            self.header.configure(postCard: quotePostCard, headerType: .quotePost)
            self.header.isUserInteractionEnabled = false
            contentStackView.insertArrangedSubview(self.header, at: 0)
            headerTrailingConstraint = headerTrailingConstraint ?? self.header.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: -self.contentStackView.directionalLayoutMargins.trailing)
            headerTrailingConstraint?.isActive = true
            
            // Display post text
            if let postTextContent = quotePostCard.metaPostText, !postTextContent.original.isEmpty {
                self.postTextLabel.configure(content: postTextContent)
            } else if [.small, .hidden].contains(self.mediaVariant) {
                // If there's no post text, but a media attachment,
                // set the post text to either:
                //  - ([type])
                //  - ([type] description: [meta description])
                if let type = quotePostCard.mediaAttachments.first?.type.rawValue.capitalized  {
                    if let desc = quotePostCard.mediaAttachments.first?.description {
                        let content = MastodonMetaContent.convert(text: MastodonContent(content: "(\(type) description: \(desc))", emojis: [:]))
                        self.postTextLabel.configure(content: content)
                    } else {
                        let content = MastodonMetaContent.convert(text: MastodonContent(content: "(\(type))", emojis: [:]))
                        self.postTextLabel.configure(content: content)
                    }
                }
            }
            
            self.postTextLabel.isUserInteractionEnabled = false
            textAndSmallMediaStackView.addArrangedSubview(self.postTextLabel)

            // Display poll if needed
            if quotePostCard.containsPoll {
                if self.poll == nil {
                    self.poll = PostCardPoll()
                }

                self.poll!.configure(postCard: quotePostCard)
                self.poll!.isUserInteractionEnabled = false
                mediaContainer.addArrangedSubview(self.poll!)
                pollTrailingConstraint = pollTrailingConstraint ?? self.poll!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor, constant: -self.mediaContainer.directionalLayoutMargins.trailing)
                pollTrailingConstraint?.isActive = true
            }

            // Display the link preview if needed
            if quotePostCard.hasLink {
                if self.linkPreview == nil {
                    self.linkPreview = PostCardLinkPreview()
                }

                self.linkPreview!.configure(postCard: quotePostCard)
                self.linkPreview!.isUserInteractionEnabled = false
                mediaContainer.addArrangedSubview(self.linkPreview!)
                linkPreviewTrailingConstraint = linkPreviewTrailingConstraint ?? self.linkPreview!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor, constant: -self.mediaContainer.directionalLayoutMargins.trailing)
                linkPreviewTrailingConstraint?.isActive = true

                self.linkPreview!.onPress = onPress
            }
            
            // Display single image if needed
            if quotePostCard.hasMediaAttachment && quotePostCard.mediaDisplayType == .singleImage {
                if self.image == nil {
                    switch self.mediaVariant {
                    case .small:
                        self.image = PostCardImage(variant: .thumbnail)
                        self.image!.translatesAutoresizingMaskIntoConstraints = false
                    case .large:
                        self.image = PostCardImage(variant: .fullSize)
                        self.image!.translatesAutoresizingMaskIntoConstraints = false
                    default: break
                    }
                }
                
                self.image?.configure(postCard: quotePostCard)
                
                switch self.mediaVariant {
                case .small:
                    textAndSmallMediaStackView.addArrangedSubview(self.image!)
                    imageTrailingConstraint = imageTrailingConstraint ?? self.image!.widthAnchor.constraint(equalToConstant: 60)
                    imageTrailingConstraint?.isActive = true
                case .large:
                    mediaContainer.addArrangedSubview(self.image!)
                    imageTrailingConstraint = imageTrailingConstraint ?? self.image!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor, constant: -self.mediaContainer.directionalLayoutMargins.trailing)
                    imageTrailingConstraint?.isActive = true
                default: break
                }
            }
            
            // Display single video/gif if needed
            if quotePostCard.hasMediaAttachment && quotePostCard.mediaDisplayType == .singleVideo {
                if self.video == nil {
                    switch self.mediaVariant {
                    case .small:
                        self.video = PostCardVideo(variant: .thumbnail)
                        self.video!.translatesAutoresizingMaskIntoConstraints = false
                    case .large:
                        self.video = PostCardVideo(variant: .fullSize)
                        self.video!.translatesAutoresizingMaskIntoConstraints = false
                    default: break
                    }
                }
                
                self.video?.configure(postCard: quotePostCard)
                
                // Do not auto-play videos in thumbnail-mode
                if [.small, .hidden].contains(self.mediaVariant) {
                    self.video?.pause()
                }
                
                switch self.mediaVariant {
                case .small:
                    textAndSmallMediaStackView.addArrangedSubview(self.video!)
                    videoTrailingConstraint = videoTrailingConstraint ?? self.video!.widthAnchor.constraint(equalToConstant: 60)
                    videoTrailingConstraint?.isActive = true
                case .large:
                    mediaContainer.addArrangedSubview(self.video!)
                    videoTrailingConstraint = videoTrailingConstraint ?? self.video!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor, constant: -self.mediaContainer.directionalLayoutMargins.trailing)
                    videoTrailingConstraint?.isActive = true
                default: break
                }
            }
            
            // Display the image carousel if needed
            if quotePostCard.hasMediaAttachment && quotePostCard.mediaDisplayType == .carousel {
                switch self.mediaVariant {
                case .small:
                    self.mediaStack = PostCardMediaStack(variant: .thumbnail)
                    self.mediaStack?.translatesAutoresizingMaskIntoConstraints = false
                    self.mediaStack?.configure(postCard: quotePostCard)

                    textAndSmallMediaStackView.addArrangedSubview(self.mediaStack!)
                    mediaStackTrailingConstraint = self.mediaStack!.widthAnchor.constraint(equalToConstant: 60)
                    mediaStackTrailingConstraint?.isActive = true
                    self.mediaStack?.isHidden = false
                    self.mediaGallery?.isHidden = true
                case .large:
                    self.mediaGallery = PostCardMediaGallery()
                    self.mediaGallery?.translatesAutoresizingMaskIntoConstraints = false
                    self.mediaGallery?.configure(postCard: quotePostCard)

                    mediaContainer.addArrangedSubview(self.mediaGallery!)
                    mediaGalleryTrailingConstraint = self.mediaGallery!.trailingAnchor.constraint(equalTo: mediaContainer.layoutMarginsGuide.trailingAnchor)
                    mediaGalleryTrailingConstraint?.isActive = true
                    self.mediaGallery?.isHidden = false
                    self.mediaStack?.isHidden = true
                default: break
                }
            }

            // If we are hiding the link image, move the link view
            // so it's below any possible media.
            if let linkPreview = self.linkPreview, quotePostCard.hideLinkImage && mediaContainer.arrangedSubviews.contains(linkPreview) {
                mediaContainer.insertArrangedSubview(linkPreview, at: mediaContainer.arrangedSubviews.count - 1)
            }
            
        }
        
        if postCard.quotePostStatus == .notFound {
            if let postLoader = self.postLoader {
                contentStackView.removeArrangedSubview(postLoader)
                postLoader.removeFromSuperview()
                self.postLoaderTrailingConstraint?.isActive = false
            }
            
            // Quote post can't be found
            if self.postNotFound == nil {
                self.postNotFound = PostCardQuoteNotFound()
            }
            
            contentStackView.addArrangedSubview(self.postNotFound!)
            self.postNotFound!.isUserInteractionEnabled = false
            self.isUserInteractionEnabled = false
            postNotFoundTrailingConstraint = postNotFoundTrailingConstraint ?? self.postNotFound!.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: -self.contentStackView.directionalLayoutMargins.trailing)
            postNotFoundTrailingConstraint?.isActive = true
            
            mainStackView.directionalLayoutMargins.bottom = 10
        }
        
        if postCard.quotePostStatus == .loading  {
            // Quote post is being loaded
            if self.postLoader == nil {
                self.postLoader = PostCardQuoteActivityIndicator()
            }
            
            self.postLoader!.startAnimation()
            self.postLoader!.isUserInteractionEnabled = false
            contentStackView.addArrangedSubview(self.postLoader!)
            postLoaderTrailingConstraint = postLoaderTrailingConstraint ?? self.postLoader!.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: -self.contentStackView.directionalLayoutMargins.trailing)
            postLoaderTrailingConstraint?.isActive = true
            
            mainStackView.directionalLayoutMargins.bottom = 10
        }
    }
    
    func onThemeChange() {
        self.mainStackView.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        
        self.header.onThemeChange()
        self.linkPreview?.onThemeChange()
        self.poll?.onThemeChange()
        self.postNotFound?.onThemeChange()
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
                        self.createContextMenuAction("Open link", .link, isActive: false, data: .url(url), onPress: onButtonPress),
                        self.createContextMenuAction("Copy", .copy, isActive: false, data: .url(url), onPress: onButtonPress),
                        self.createContextMenuAction("Share", .share, isActive: false, data: .url(url), onPress: onButtonPress),
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
    
    func onThemeChange() {
        
    }
}
