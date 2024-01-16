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

    private var header = PostCardHeader()
    private var headerTrailingConstraint: NSLayoutConstraint?
    
    private var postTextLabel: MetaText = {
        let metaText = MetaText()
        metaText.textView.isOpaque = true
        metaText.textView.backgroundColor = .custom.background
        metaText.textView.translatesAutoresizingMaskIntoConstraints = false
        metaText.textView.isEditable = false
        metaText.textView.isScrollEnabled = false
        metaText.textView.isSelectable = false
        metaText.textView.textContainer.lineFragmentPadding = 0
        metaText.textView.textContainerInset = .zero
        metaText.textView.textDragInteraction?.isEnabled = false
        metaText.textView.textContainer.lineBreakMode = .byTruncatingTail
        metaText.textView.textContainer.maximumNumberOfLines = 4
        
        metaText.textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        metaText.textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        metaText.textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        metaText.textView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        metaText.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]

        metaText.linkAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold),
            .foregroundColor: UIColor.custom.highContrast,
        ]

        metaText.paragraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = DeviceHelpers.isiOSAppOnMac() ? 1 : 0
            style.paragraphSpacing = 8
            style.alignment = .natural
            return style
        }()

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
    
    private var imageAttachment: PostCardImageAttachment?
    private var imageAttachmentTrailingConstraint: NSLayoutConstraint?
    
    private var linkPreview: PostCardLinkPreview?
    private var linkPreviewTrailingConstraint: NSLayoutConstraint?
    
    private var postNotFound: PostCardQuoteNotFound?
    private var postNotFoundTrailingConstraint: NSLayoutConstraint?
    
    private var postLoader: PostCardQuoteActivityIndicator?
    private var postLoaderTrailingConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
        
        contentStackView.removeArrangedSubview(self.postTextLabel.textView)
        self.postTextLabel.textView.removeFromSuperview()
        
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
            contentStackView.addArrangedSubview(self.header)
            headerTrailingConstraint = headerTrailingConstraint ?? self.header.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: -self.contentStackView.directionalLayoutMargins.trailing)
            headerTrailingConstraint?.isActive = true
            
            // Display post text
            if let postTextContent = quotePostCard.metaPostText, !postTextContent.original.isEmpty {
                self.postTextLabel.configure(content: postTextContent)
            }
            
            self.postTextLabel.textView.isUserInteractionEnabled = false
            contentStackView.addArrangedSubview(self.postTextLabel.textView)

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
                    self.image = PostCardImage()
                    self.image!.translatesAutoresizingMaskIntoConstraints = false
                }
                
                self.image!.configure(postCard: quotePostCard)
                mediaContainer.addArrangedSubview(self.image!)
                imageTrailingConstraint = imageTrailingConstraint ?? self.image!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor, constant: -self.mediaContainer.directionalLayoutMargins.trailing)
                imageTrailingConstraint?.isActive = true
            }
            
            // Display single video/gif if needed
            if quotePostCard.hasMediaAttachment && quotePostCard.mediaDisplayType == .singleVideo {
                if self.video == nil {
                    self.video = PostCardVideo()
                    self.video!.translatesAutoresizingMaskIntoConstraints = false
                }
                
                self.video!.configure(postCard: quotePostCard)
                mediaContainer.addArrangedSubview(self.video!)
                videoTrailingConstraint = videoTrailingConstraint ?? self.video!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor, constant: -self.mediaContainer.directionalLayoutMargins.trailing)
                videoTrailingConstraint?.isActive = true
            }
            
            // Display the image carousel if needed
            if quotePostCard.hasMediaAttachment && quotePostCard.mediaDisplayType == .carousel {
                if self.imageAttachment == nil {
                    self.imageAttachment = PostCardImageAttachment()
                }
                
                self.imageAttachment!.isUserInteractionEnabled = false
                mediaContainer.addArrangedSubview(self.imageAttachment!)

                if !quotePostCard.hasLink {
                    // If there's only an image (no link) - remove the padding around the image
                    self.imageAttachment!.configure(postCard: quotePostCard, withRoundedCorners: false)

                    mainStackView.directionalLayoutMargins.bottom = 0
                    mediaContainer.directionalLayoutMargins.leading = 0
                    mediaContainer.directionalLayoutMargins.trailing = 0
                } else {
                    self.imageAttachment!.configure(postCard: quotePostCard, withRoundedCorners: true)
                }
                
                imageAttachmentTrailingConstraint = self.imageAttachment!.trailingAnchor.constraint(equalTo: self.mediaContainer.trailingAnchor, constant: -self.mediaContainer.directionalLayoutMargins.trailing)
                imageAttachmentTrailingConstraint?.isActive = true
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
