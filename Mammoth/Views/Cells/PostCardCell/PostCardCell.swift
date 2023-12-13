//
//  PostCardCell.swift
//  Mammoth
//
//  Created by Benoit Nolens on 24/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class PostCardCell: UITableViewCell {
    static let reuseIdentifier = "PostCardCell"
    
    enum PostCardCellType {
        case regular    // regular post cell
        case forYou     // post in the For You feed
        case channel    // post in a channel feed
        case detail     // main post on the detail screen
        case parent     // parent post on the detail screen
        case reply      // reply post on the detail screen
        case mentions   // post in the Mentions feed
        case following
        case list
        
        var headerType: PostCardHeader.PostCardHeaderTypes {
            switch self {
            case .detail:
                return PostCardHeader.PostCardHeaderTypes.detail
            case .forYou:
                return PostCardHeader.PostCardHeaderTypes.forYou
            case .channel:
                return PostCardHeader.PostCardHeaderTypes.channel
            case .mentions:
                return PostCardHeader.PostCardHeaderTypes.mentions
            case .following:
                return PostCardHeader.PostCardHeaderTypes.following
            case .list:
                return PostCardHeader.PostCardHeaderTypes.list
            default:
                return PostCardHeader.PostCardHeaderTypes.regular
            }
        }
        
        var numberOfLines: Int {
            switch self {
            case .regular, .mentions, .following, .list, .forYou, .channel:
                return GlobalStruct.maxLines
            case .reply, .parent, .detail:
                return 0
            }
        }
        
        func shouldSyncFollowStatus(postCard: PostCardModel) -> Bool {
            switch self {
            case .mentions:
                return false
            case .list, .following:
                return postCard.isReblogged
            default:
                return true
            }
        }
        
        var shouldShowDetailedMetrics: Bool {
            switch self {
            case .reply, .parent:
                return false
            default:
                return true
            }
        }
        
        var shouldShowSourceAndApplicationName: Bool {
            switch self {
            case .detail:
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Properties
    
    // Includes the header extension and the rest of the cell
    private var wrapperStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 6.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
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
        stackView.preservesSuperviewLayoutMargins = false
        return stackView
    }()
    
    // Includes header, text, media and footer
    private var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 2
        stackView.isOpaque = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        return stackView
    }()
    
    private let profilePic = PostCardProfilePic(withSize: .regular)
    private let header = PostCardHeader()
    private let footer = PostCardFooter()
    
    private var contentWarningButton: UIButton = {
        let contentWarningButton = UIButton()
        contentWarningButton.backgroundColor = .custom.OVRLYSoftContrast
        contentWarningButton.layer.cornerRadius = 8
        contentWarningButton.layer.cornerCurve = .continuous
        contentWarningButton.setTitleColor(.secondaryLabel, for: .normal)
        contentWarningButton.titleLabel?.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize - 2, weight: .regular)
        contentWarningButton.titleLabel?.numberOfLines = 6
        contentWarningButton.layer.masksToBounds = true
        contentWarningButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        contentWarningButton.contentVerticalAlignment = .top
        contentWarningButton.contentHorizontalAlignment = .left
        contentWarningButton.translatesAutoresizingMaskIntoConstraints = false
        contentWarningButton.isOpaque = true
        return contentWarningButton
    }()
    private var contentWarningConstraints: [NSLayoutConstraint] = []
    
    private var deletedWarningButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .custom.OVRLYSoftContrast
        button.layer.cornerRadius = 8
        button.layer.cornerCurve = .continuous
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.titleLabel?.numberOfLines = 6
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = true

        button.isOpaque = true
        return button
    }()
    private var deletedWarningConstraints: [NSLayoutConstraint] = []

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
        label.backgroundColor = .custom.background
        label.urlMaximumLength = 30
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var postTextTrailingConstraint: NSLayoutConstraint?
    
    // Contains image attachment, poll, and/or link preview if needed
    private var mediaContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.layoutMargins = .zero
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var mediaContainerConstraints: [NSLayoutConstraint]? = []
    
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
    
    private var postCard: PostCardModel?
    private var onButtonPress: PostCardButtonCallback?
    private var headerExtension: PostCardHeaderExtension?
    private var metadata: PostCardMetadata?
    
    private let parentThread: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .custom.feintContrast
        view.isHidden = true
        return view
    }()
    
    private let childThread: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .custom.feintContrast
        view.isHidden = true
        return view
    }()
    
    private var textLongPressGesture: UILongPressGestureRecognizer?
    
    private enum MetricButtons: Int {
        case likes
        case reposts
        case replies
    }

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
        self.postCard = nil
        self.profilePic.prepareForReuse()
        self.footer.onButtonPress = nil
        self.separatorInset = .zero
        
        self.contentWarningButton.isHidden = true
        self.contentWarningButton.isUserInteractionEnabled = false
        NSLayoutConstraint.deactivate(self.contentWarningConstraints)
        
        self.deletedWarningButton.isHidden = true
        NSLayoutConstraint.deactivate(self.deletedWarningConstraints)
        
        self.header.prepareForReuse()
        
        self.parentThread.isHidden = true
        self.childThread.isHidden = true
        
        if let gesture = self.textLongPressGesture {
            self.postTextLabel.removeGestureRecognizer(gesture)
        }
        
        self.metadata?.prepareForReuse()
        
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
        
        if let imageAttachment = self.imageAttachment, self.mediaContainer.arrangedSubviews.contains(imageAttachment) {
            self.imageAttachmentTrailingConstraint?.isActive = false
            self.mediaContainer.removeArrangedSubview(imageAttachment)
            imageAttachment.removeFromSuperview()
        }
        
        if let linkPreview = self.linkPreview, self.mediaContainer.arrangedSubviews.contains(linkPreview) {
            self.linkPreviewTrailingConstraint?.isActive = false
            self.mediaContainer.removeArrangedSubview(linkPreview)
            linkPreview.removeFromSuperview()
            linkPreview.prepareForReuse()
        }
        
        if let poll = self.poll, self.mediaContainer.arrangedSubviews.contains(poll) {
            self.pollTrailingConstraint?.isActive = false
            self.mediaContainer.removeArrangedSubview(poll)
            poll.removeFromSuperview()
            poll.prepareForReuse()
        }
        
        if let quotePost = self.quotePost, self.mediaContainer.arrangedSubviews.contains(quotePost) {
            self.quotePostTrailingConstraint?.isActive = false
            self.mediaContainer.removeArrangedSubview(quotePost)
            quotePost.removeFromSuperview()
            quotePost.prepareForReuse()
        }
        
        if let headerExtension = self.headerExtension, self.wrapperStackView.arrangedSubviews.contains(headerExtension) {
            self.wrapperStackView.removeArrangedSubview(headerExtension)
            headerExtension.removeFromSuperview()
            headerExtension.prepareForReuse()
        }
    }
}

// MARK: - Setup UI
private extension PostCardCell {
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
            wrapperStackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            wrapperStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            wrapperStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            wrapperStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            
            // Force main stack view to fill the parent width
            mainStackView.trailingAnchor.constraint(equalTo: wrapperStackView.trailingAnchor),
        ])

        mainStackView.addArrangedSubview(profilePic)
        mainStackView.addArrangedSubview(contentStackView)
        
        mainStackView.addSubview(parentThread)
        mainStackView.addSubview(childThread)
        
        NSLayoutConstraint.activate([
            parentThread.widthAnchor.constraint(equalToConstant: 1),
            parentThread.topAnchor.constraint(equalTo: self.topAnchor),
            parentThread.bottomAnchor.constraint(equalTo: profilePic.topAnchor),
            parentThread.centerXAnchor.constraint(equalTo: profilePic.centerXAnchor),
            
            childThread.widthAnchor.constraint(equalToConstant: 1),
            childThread.topAnchor.constraint(equalTo: self.profilePic.bottomAnchor),
            childThread.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            childThread.centerXAnchor.constraint(equalTo: profilePic.centerXAnchor)
        ])
        
        contentStackView.addArrangedSubview(header)
        contentStackView.addArrangedSubview(footer)
        
        // Make sure the contentWarning covers the post text, image, link (just not the header, footer)
        contentStackView.addSubview(contentWarningButton)
        contentWarningButton.isHidden = true
        contentWarningButton.addTarget(self, action: #selector(self.contentWarningButtonTapped), for: .touchUpInside)
        contentWarningConstraints = [
            contentWarningButton.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 3),
            contentWarningButton.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: -48),
            contentWarningButton.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor, constant: -1),
            contentWarningButton.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: 1),
        ]
        
        // Make sure the deleted warning covers entire post text, image, link (just not the header, footer)
        self.addSubview(deletedWarningButton)
        deletedWarningButton.isHidden = true
        deletedWarningButton.setTitle("Post removed", for: .normal)
        deletedWarningConstraints = [
            deletedWarningButton.topAnchor.constraint(equalTo: contentStackView.topAnchor, constant: -1),
            deletedWarningButton.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: -8),
            deletedWarningButton.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor, constant: -1),
            deletedWarningButton.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: 1),
        ]

        NSLayoutConstraint.activate([
            // Force header to fill the parent width
            header.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
        ])
        
        setupUIFromSettings()
    }
    
    @objc func setupUIFromSettings() {
        deletedWarningButton.titleLabel?.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        postTextLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        postTextLabel.minimumLineHeight = DeviceHelpers.isiOSAppOnMac() ? UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 5 : 0
        
        if footer.isHidden {
            contentView.layoutMargins = .init(top: 16, left: 13, bottom: 10, right: 13)
        } else {
            contentView.layoutMargins = .init(top: 16, left: 13, bottom: 0, right: 13)
        }
        
        self.header.setupUIFromSettings()
        self.linkPreview?.setupUIFromSettings()
        self.quotePost?.setupUIFromSettings()
        self.headerExtension?.setupUIFromSettings()
        self.metadata?.setupUIFromSettings()
        
        self.onThemeChange()
    }
}

// MARK: - Configuration
extension PostCardCell {
    func configure(postCard: PostCardModel, type: PostCardCellType = .regular, hasParent: Bool = false, hasChild: Bool = false, onButtonPress: @escaping PostCardButtonCallback) {
        let mediaHasChanged = postCard.mediaAttachments != self.postCard?.mediaAttachments
        self.postCard = postCard
        self.onButtonPress = onButtonPress
        
        // Display header extension (reblogged or hashtagged indicator)
        if ((postCard.isReblogged && type != .detail) || postCard.isHashtagged || postCard.isPrivateMention) && type != .forYou {
            if self.headerExtension == nil {
                self.headerExtension = PostCardHeaderExtension()
            }
            
            self.headerExtension?.onPress = onButtonPress
            self.headerExtension!.configure(postCard: postCard)
            self.wrapperStackView.insertArrangedSubview(self.headerExtension!, at: 0)
        }
        
        if let user = postCard.user, !postCard.isDeleted, !postCard.isMuted, !postCard.isBlocked {
            if case .hide(_) = postCard.filterType {} else {
                self.profilePic.configure(user: user)
                self.profilePic.onPress = onButtonPress
            }
        }
        
        self.header.configure(postCard: postCard, headerType: type.headerType)
        self.header.onPress = onButtonPress
        
        // insert a text label if there's a post text
        if !postCard.postText.isEmpty {
            if !contentStackView.arrangedSubviews.contains(postTextLabel) {
                contentStackView.insertArrangedSubview(postTextLabel, at: 1)
                
                // Force post text to fill the parent width
                self.postTextTrailingConstraint = postTextLabel.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor)
                postTextTrailingConstraint!.priority = .defaultHigh
                postTextTrailingConstraint!.isActive = true
            }
        } else {
            if contentStackView.arrangedSubviews.contains(postTextLabel) {
                contentStackView.removeArrangedSubview(postTextLabel)
                postTextLabel.removeFromSuperview()
                if let constraint = self.postTextTrailingConstraint {
                    postTextLabel.removeConstraint(constraint)
                }
            }
        }
        
        self.postTextLabel.customize { label in
            if case .mastodon(let status) = postCard.data,
               let postText = postCard.richPostText {
                
                label.attributedText = formatRichText(string: postText, label: label, emojis: status.reblog?.emojis ?? status.emojis)
            } else {
                label.text = postCard.postText
            }
            label.numberOfLines = type.numberOfLines
            
            // Post text link handlers
            label.handleURLTap { url in
                onButtonPress(.link, true, .url(url))
            }
            label.handleHashtagTap { hashtag in
                onButtonPress(.link, true, .hashtag(hashtag))
            }
            
            if case .mastodon(let status) = postCard.data {
                label.handleMentionTap { mention in
                    onButtonPress(.link, true, .mention((mention, status)))
                }
            }
        }
        
        // insert a media stack if needed right above the footer
        if postCard.containsPoll || postCard.hasQuotePost || postCard.hasLink || postCard.hasMediaAttachment {
            if !contentStackView.arrangedSubviews.contains(mediaContainer) {
                if let footerIndex = contentStackView.arrangedSubviews.firstIndex(of: self.footer) {
                    contentStackView.insertArrangedSubview(mediaContainer, at: footerIndex)
                    // Force media container to fill the parent width - with max width for big displays
                    self.mediaContainerConstraints = mediaContainer.addHorizontalFillConstraints(withParent: contentStackView, andMaxWidth: 320)
                }
            }
        } else {
            if contentStackView.arrangedSubviews.contains(mediaContainer) {
                contentStackView.removeArrangedSubview(mediaContainer)
                if let mediaConstraints = self.mediaContainerConstraints {
                    mediaContainer.removeConstraints(mediaConstraints)
                }
                mediaContainer.removeFromSuperview()
            }
        }
        
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
        if postCard.hasMediaAttachment && postCard.mediaDisplayType == .singleVideo && mediaHasChanged {
            if self.video == nil {
                self.video = PostCardVideo()
                self.video!.translatesAutoresizingMaskIntoConstraints = false
            }
            
            self.video!.configure(postCard: postCard)
            if type == .detail {
                self.video!.play()
            }
            
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

        // Enable the content warning button if needed
        if let statID = postCard.id,
           !postCard.contentWarning.isEmpty,
            !GlobalStruct.allCW.contains(statID),
            GlobalStruct.showCW {
            NSLayoutConstraint.activate(self.contentWarningConstraints)
            self.contentWarningButton.setTitle(postCard.contentWarning, for: .normal)
            self.contentWarningButton.isHidden = false
            self.contentWarningButton.isUserInteractionEnabled = true
        } else if case .warn(let filterName) = postCard.filterType {
           NSLayoutConstraint.activate(self.contentWarningConstraints)
           self.contentWarningButton.setTitle("Content filter: \(filterName)", for: .normal)
           self.contentWarningButton.isHidden = false
           self.contentWarningButton.isUserInteractionEnabled = true
        }
        
        if postCard.isDeleted {
            NSLayoutConstraint.activate(self.deletedWarningConstraints)
            self.deletedWarningButton.isHidden = false
            self.profilePic.optimisticUpdate(image: UIImage())
            deletedWarningButton.setTitle("Post removed", for: .normal)
        } else if case .hide(let filterName) = postCard.filterType {
            NSLayoutConstraint.activate(self.deletedWarningConstraints)
            self.deletedWarningButton.isHidden = false
            self.profilePic.optimisticUpdate(image: UIImage())
            deletedWarningButton.setTitle("Content filter: \(filterName)", for: .normal)
        } else if postCard.isBlocked {
            NSLayoutConstraint.activate(self.deletedWarningConstraints)
            self.deletedWarningButton.isHidden = false
            self.profilePic.optimisticUpdate(image: UIImage())
            deletedWarningButton.setTitle("Blocked author", for: .normal)
        } else if postCard.isMuted {
            NSLayoutConstraint.activate(self.deletedWarningConstraints)
            self.deletedWarningButton.isHidden = false
            self.profilePic.optimisticUpdate(image: UIImage())
            deletedWarningButton.setTitle("Muted author", for: .normal)
        }
        
        self.footer.configure(postCard: postCard, includeMetrics: false)
        self.footer.onButtonPress = onButtonPress
        
        self.childThread.isHidden = !hasChild
        self.parentThread.isHidden = !hasParent
        
        if type.shouldShowDetailedMetrics {
            if self.metadata == nil {
                self.metadata = PostCardMetadata()
            }
            
            self.metadata!.configure(postCard: postCard, type: type, onButtonPress: onButtonPress)
            
            if !self.contentStackView.arrangedSubviews.contains(self.metadata!) {
                self.contentStackView.insertArrangedSubview(self.metadata!, at: self.contentStackView.arrangedSubviews.firstIndex(of: self.footer) ?? 0)
            } else {
                self.contentStackView.removeArrangedSubview(self.metadata!)
                self.contentStackView.insertArrangedSubview(self.metadata!, at: self.contentStackView.arrangedSubviews.firstIndex(of: self.footer) ?? 0)
            }
            
            // add custom spacing above the post details ("via Mammoth, public", and metrics)
            if self.contentStackView.arrangedSubviews.contains(self.mediaContainer) {
                self.contentStackView.setCustomSpacing(12, after: self.mediaContainer)
            } else if self.contentStackView.arrangedSubviews.contains(self.postTextLabel) {
                self.contentStackView.setCustomSpacing(10, after: self.postTextLabel)
            }
            
        } else {
            // remove the detailStack when not needed
            if let metadata = self.metadata {
                if self.contentStackView.arrangedSubviews.contains(metadata) {
                    self.contentStackView.removeArrangedSubview(metadata)
                    metadata.removeFromSuperview()
                }
            }
        }
        
        // set detail-specific UI
        if type == .detail {
            // long press to copy the post text
            self.textLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.onTextLongPress))
            postTextLabel.addGestureRecognizer(self.textLongPressGesture!)
            
            // make sure the thread lines are behind all the other elements
            mainStackView.sendSubviewToBack(parentThread)
            mainStackView.sendSubviewToBack(childThread)
        }
        
        // Make sure all views are underneath the contentWarningButton and the deletedWarningButton
        self.contentStackView.bringSubviewToFront(self.contentWarningButton)
        self.contentStackView.bringSubviewToFront(self.deletedWarningButton)
        
        if CommandLine.arguments.contains("-M_DEBUG_TIMELINES") {
            // Configure for debugging
            self.configureForDebugging(postCard: postCard)
        }
    }
    
    /// the cell will be displayed in the tableview
    public func willDisplay() {
        if let postCard = self.postCard, postCard.hasMediaAttachment && postCard.mediaDisplayType == .singleVideo {
            if GlobalStruct.autoPlayVideos {
                self.video?.play()
            }
        }
        
        if let postCard = self.postCard, postCard.hasQuotePost {
            postCard.preloadQuotePost()
        }
        
        self.header.startTimeUpdates()
    }
    
    // the cell will end being displayed in the tableview
    public func didEndDisplay() {
        if let postCard = self.postCard, postCard.hasMediaAttachment && postCard.mediaDisplayType == .singleVideo {
            self.video?.pause()
        }
        
        self.header.stopTimeUpdates()
    }
    
    @objc private func onTextLongPress(recognizer: UIGestureRecognizer) {
        if let view = recognizer.view, let superview = recognizer.view?.superview {
            view.becomeFirstResponder()
            let menuController = UIMenuController.shared
                    
            let copyItem = UIMenuItem(title: "Copy", action: #selector(self.copyText))
            menuController.menuItems = [copyItem]
            
            menuController.showMenu(from: superview, rect: view.frame)
        }
    }
    
    @objc private func onMetricPress(recognizer: UIGestureRecognizer) {
        if recognizer.view?.tag == MetricButtons.likes.rawValue {
            // Implementation done in separate ticket
            self.onButtonPress?(.likes, false, nil)
        }
        
        if recognizer.view?.tag == MetricButtons.reposts.rawValue {
            // Implementation done in separate ticket
            self.onButtonPress?(.reposts, false, nil)
        }
        
        if recognizer.view?.tag == MetricButtons.replies.rawValue {
            // Implementation done in separate ticket
            self.onButtonPress?(.replies, false, nil)
        }
    }
    
    @objc private func copyText() {
        UIPasteboard.general.setValue(self.postCard?.postText ?? "", forPasteboardType: "public.utf8-plain-text")
    }
    
    private func configureForDebugging(postCard: PostCardModel) {
        if let batchId = postCard.batchId, let batchItemIndex = postCard.batchItemIndex {
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
            
            self.contentWarningButton.isHidden = true
            NSLayoutConstraint.deactivate(self.contentWarningConstraints)
        }
    }
    
    func onThemeChange() {
        if let postCard = self.postCard, postCard.isPrivateMention {
            self.backgroundColor = .custom.OVRLYSoftContrast
            self.contentView.backgroundColor = .custom.OVRLYSoftContrast
        } else {
            self.backgroundColor = .custom.background
            self.contentView.backgroundColor = .custom.background
        }
        
        self.postTextLabel.customize { [weak self] label in
            guard let self else { return }
            label.mentionColor = .custom.highContrast
            label.hashtagColor = .custom.highContrast
            label.URLColor = .custom.highContrast
            label.emailColor = .custom.highContrast
            label.backgroundColor = self.contentView.backgroundColor
        }
        
        self.profilePic.onThemeChange()
        self.header.onThemeChange()
        self.poll?.onThemeChange()
        self.linkPreview?.onThemeChange()
        self.quotePost?.onThemeChange()
        self.footer.onThemeChange()
        self.footer.backgroundColor = self.contentView.backgroundColor
    }
}

// MARK: - Handlers
extension PostCardCell {
    @objc func contentWarningButtonTapped(_ sender: UIButton) {
        triggerHapticImpact(style: .light)
        self.contentWarningButton.isHidden = true
        self.contentWarningButton.isUserInteractionEnabled = false
        GlobalStruct.allCW.append(self.postCard?.id ?? "")
        self.postCard?.filterType = .none
    }
}

// MARK: - Context menu creators
extension PostCardCell {
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

