//
//  PostCardCell.swift
//  Mammoth
//
//  Created by Benoit Nolens on 24/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import Meta
import MastodonMeta
import MetaTextKit

let screenWidth = UIScreen.main.bounds.width

final class PostCardCell: UITableViewCell {
    
    enum PostCardMediaVariant: String, Equatable, CaseIterable {
//        UNCOMMENT TO SUPPORT DYNAMIC MEDIA SIZE MODE
//        case auto
        case large
        case small
        case hidden
        
        var displayName: String {
            switch self {
//            UNCOMMENT TO SUPPORT DYNAMIC MEDIA SIZE MODE
//            case .auto: return "Dynamic"
                
            case .large: return NSLocalizedString("settings.appearance.mediaSize.large", comment: "")
            case .small: return NSLocalizedString("settings.appearance.mediaSize.small", comment: "")
            case .hidden: return NSLocalizedString("settings.appearance.mediaSize.hidden", comment: "")
            }
        }
    }

    static func reuseIdentifier(for variant: PostCardVariant) -> String {
        switch variant {
        case .textOnly:                         return "PostCardCell.TextOnly"
        case .textAndMedia(let mediaVariant):   return "PostCardCell.TextAndMedia(variant=\(mediaVariant.rawValue))"
        case .mediaOnly(let mediaVariant):      return "PostCardCell.MediaOnly(variant=\(mediaVariant.rawValue))"
        }
    }
    
    static func reuseIdentifier(for postCard: PostCardModel, cellType: PostCardCellType = .regular) -> String {
        if let variant = Self.PostCardVariant.cellVariant(for: postCard, cellType: cellType) {
            return self.reuseIdentifier(for: variant)
        }
        
        // Fallback to text-only
        log.error("PostCardCell fallback to .textOnly")
        return self.reuseIdentifier(for: .textOnly)
    }
    
    static func variant(for reusableIdentifier: String) -> PostCardVariant {
        switch reusableIdentifier {
        case "PostCardCell.TextOnly": return .textOnly
        case "PostCardCell.TextAndMedia(variant=hidden)": return .textAndMedia(.hidden)
        case "PostCardCell.TextAndMedia(variant=small)": return .textAndMedia(.small)
        case "PostCardCell.TextAndMedia(variant=large)": return .textAndMedia(.large)
        case "PostCardCell.MediaOnly(variant=hidden)": return .mediaOnly(.hidden)
        case "PostCardCell.MediaOnly(variant=small)": return .mediaOnly(.small)
        case "PostCardCell.MediaOnly(variant=large)": return .mediaOnly(.large)
        default:
            log.error("PostCardCell fallback to .textOnly")
            return .textOnly
        }
    }
    
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
        
        var mediaVariant: PostCardMediaVariant {
            switch self {
            case .detail: return .large
            case .mentions: return .small
            default: return GlobalStruct.mediaSize
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
    
    enum PostCardVariant: Equatable {
        case textOnly
        case textAndMedia(PostCardMediaVariant)
        case mediaOnly(PostCardMediaVariant)

        static func cellVariant(for postCard: PostCardModel, cellType: PostCardCellType) -> Self? {
            let hasText = !postCard.postText.isEmpty
            
            if postCard.containsPoll || postCard.hasQuotePost || postCard.hasLink || postCard.hasMediaAttachment {
                let mediaVariant = cellType.mediaVariant

//                UNCOMMENT TO SUPPORT DYNAMIC MEDIA SIZE MODE
//                if mediaVariant == .auto {
//                    if let firstImage = postCard.mediaAttachments.first,
//                        let original = firstImage.meta?.original,
//                        (original.width ?? 0) < 200 && (original.height ?? 0) < 200 {
//                        mediaVariant = .small
//                    } else {
//                        mediaVariant = .large
//                    }
//                }
                
                // NOTE: when a post has only media in thumbnail-mode we do display a text label as well
                return hasText || [.small, .hidden].contains(mediaVariant) ? .textAndMedia(mediaVariant) : .mediaOnly(mediaVariant)
            }
            
            return .textOnly
        }
        
        var hasText: Bool {
            if self == .textOnly { return true }
            if case .textAndMedia = self { return true }
            return  false
        }
        
        var hasMedia: Bool  {
            if case .mediaOnly = self { return true }
            if case .textAndMedia = self { return true }
            return false
        }
        
        var mediaVariant: PostCardMediaVariant {
            if case .textAndMedia(let mediaVariant) = self {
                return mediaVariant
            }
            if case .mediaOnly(let mediaVariant) = self {
                return mediaVariant
            }
            return .hidden
        }
    }
    
    // MARK: - Properties
    
    static let paragraphSpacing = 12.0
    
    // Includes the header extension and the rest of the cell
    private var wrapperStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
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
        stackView.isOpaque = true
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
        stackView.spacing = 0.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        return stackView
    }()
    
    // Includes header, text, media and footer
    private var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 2
        stackView.isOpaque = true
        stackView.layoutMargins = .init(top: 0, left: 12, bottom: 0, right: 0)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        stackView.isLayoutMarginsRelativeArrangement = true
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
        button.isUserInteractionEnabled = false

        button.isOpaque = true
        return button
    }()
    private var deletedWarningConstraints: [NSLayoutConstraint] = []

    private var postTextView: MetaLabel = {
        let metaText = MetaLabel()
        metaText.isOpaque = true
        metaText.backgroundColor = .custom.background
        metaText.translatesAutoresizingMaskIntoConstraints = false
        metaText.textContainer.lineFragmentPadding = 0
        metaText.numberOfLines = 0
        metaText.textContainer.maximumNumberOfLines = 0
        metaText.textContainer.lineBreakMode = .byTruncatingTail
        
        metaText.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
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
            style.paragraphSpacing = 12
            style.alignment = .natural
            return style
        }()

        return metaText
    }()
    
    private var hiddenImageIndicator: UILabel = {
        let label = UILabel()
        label.isOpaque = true
        label.backgroundColor = .custom.background
        label.textColor = .custom.highContrast
        label.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()
    
    private var postTextTrailingConstraint: NSLayoutConstraint?
    
    // Contains image attachment, poll, and/or link preview if needed
    private var mediaContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.layoutMargins = .zero
        stackView.preservesSuperviewLayoutMargins = false
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
    
    private var mediaGallery: PostCardMediaGallery?
    private var mediaGalleryTrailingConstraint: NSLayoutConstraint? = nil
    
    private var mediaStack: PostCardMediaStack?
    private var mediaStackTrailingConstraint: NSLayoutConstraint? = nil
    
    private var linkPreview: PostCardLinkPreview?
    private var linkPreviewTrailingConstraint: NSLayoutConstraint? = nil
    
    private var quotePost: PostCardQuotePost?
    private var quotePostTrailingConstraint: NSLayoutConstraint? = nil
    
    private var postCard: PostCardModel?
    private var type: PostCardCellType?
    private var onButtonPress: PostCardButtonCallback?
    private var headerExtension: PostCardHeaderExtension?
    private var metadata: PostCardMetadata?
    
//    private var readMoreButton: ReadMoreButton?
    
    private var cellVariant: PostCardVariant {
        if let reuseIdentifier = self.reuseIdentifier {
            return Self.variant(for: reuseIdentifier)
        }
        
        return .textOnly
    }
    
    private let parentThread: UIView = {
        let view = UIView()
        view.isOpaque = true
        view.layer.shouldRasterize = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .custom.feintContrast
        view.isHidden = true
        return view
    }()
    
    private let childThread: UIView = {
        let view = UIView()
        view.isOpaque = true
        view.layer.shouldRasterize = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .custom.feintContrast
        view.isHidden = true
        return view
    }()
    
    private var textLongPressGesture: UILongPressGestureRecognizer?
    private var isPrivateMention: Bool = false
    
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
        self.postTextView.reset()
        self.profilePic.prepareForReuse()
        self.footer.onButtonPress = nil
        self.separatorInset = .zero
        
//        self.readMoreButton?.isHidden = true
        
        self.hiddenImageIndicator.isHidden = true
        
        self.contentStackView.setCustomSpacing(self.contentStackView.spacing, after: self.header)
        
        self.contentWarningButton.isHidden = true
        self.contentWarningButton.isUserInteractionEnabled = false
        NSLayoutConstraint.deactivate(self.contentWarningConstraints)
        
        self.deletedWarningButton.isHidden = true
        NSLayoutConstraint.deactivate(self.deletedWarningConstraints)
        
        self.header.prepareForReuse()
        
        self.parentThread.isHidden = true
        self.childThread.isHidden = true
        
        self.metadata?.prepareForReuse()
        
        if self.quotePost?.isHidden == false {
            self.quotePost?.prepareForReuse()
            self.quotePost?.isHidden = true
        }
        
        self.image?.prepareForReuse()
        self.video?.prepareForReuse()
        self.poll?.prepareForReuse()
        self.linkPreview?.prepareForReuse()
        self.mediaStack?.prepareForReuse()
        self.mediaGallery?.prepareForReuse()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }
        if let mediaGallery = self.mediaGallery,
            self.postCard?.mediaDisplayType == .carousel,
            mediaGallery.isHidden == false,
            mediaGallery.alpha == 1 {
            let convertedPoint = mediaGallery.convert(point, from: self)
            return mediaGallery.hitTest(convertedPoint, with: event) ?? hitView
        }
        
        return hitView
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
        
        headerExtension = PostCardHeaderExtension()
        wrapperStackView.addArrangedSubview(headerExtension!)
        wrapperStackView.addArrangedSubview(mainStackView)
        
        if self.headerExtension == nil {
            self.headerExtension = PostCardHeaderExtension()
        }
                
        NSLayoutConstraint.activate([
            wrapperStackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            wrapperStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            wrapperStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            wrapperStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            
            // Force main stack view to fill the parent width
            mainStackView.trailingAnchor.constraint(equalTo: wrapperStackView.layoutMarginsGuide.trailingAnchor),
        ])
        
        mainStackView.addSubview(parentThread)
        mainStackView.addSubview(childThread)

        mainStackView.addArrangedSubview(profilePic)
        profilePic.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        mainStackView.addArrangedSubview(contentStackView)
        
        contentStackView.addArrangedSubview(header)
        contentStackView.addArrangedSubview(textAndSmallMediaStackView)
        
        NSLayoutConstraint.activate([
            parentThread.widthAnchor.constraint(equalToConstant: 1),
            parentThread.topAnchor.constraint(equalTo: self.topAnchor),
            parentThread.bottomAnchor.constraint(equalTo: profilePic.topAnchor),
            parentThread.centerXAnchor.constraint(equalTo: profilePic.centerXAnchor),
            
            childThread.widthAnchor.constraint(equalToConstant: 1),
            childThread.topAnchor.constraint(equalTo: self.profilePic.bottomAnchor),
            childThread.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            childThread.centerXAnchor.constraint(equalTo: profilePic.centerXAnchor),
            
            contentStackView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),
            textAndSmallMediaStackView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor)
        ])
        
        
        // insert a text label if there's a post text
        if self.cellVariant.hasText || [.small, .hidden].contains(self.cellVariant.mediaVariant) {
            textAndSmallMediaStackView.addArrangedSubview(postTextView)
            
            postTextView.linkDelegate = self

            if self.cellVariant.hasMedia {
                if self.cellVariant.mediaVariant == .large {
                    self.contentStackView.setCustomSpacing(12.0, after: self.textAndSmallMediaStackView)
                } else if self.cellVariant.mediaVariant == .small {
                    self.contentStackView.setCustomSpacing(4.0, after: self.textAndSmallMediaStackView)
                }
            }
            
            // Force post text to fill the parent width
            self.postTextTrailingConstraint = postTextView.trailingAnchor.constraint(equalTo: textAndSmallMediaStackView.layoutMarginsGuide.trailingAnchor)
            postTextTrailingConstraint!.priority = .defaultHigh
            postTextTrailingConstraint!.isActive = true
            
//            self.readMoreButton = ReadMoreButton()
//            self.readMoreButton?.isHidden = true
//            contentStackView.addArrangedSubview(readMoreButton!)
//            self.readMoreButton?.addTarget(self, action: #selector(self.onReadMorePress), for: .touchUpInside)
        }
        
        if self.cellVariant.hasMedia {
            
            if self.cellVariant.mediaVariant == .hidden {
                self.contentStackView.addArrangedSubview(self.hiddenImageIndicator)
                
                let height = ceil("1 Image".height(width: 300, font: self.hiddenImageIndicator.font))
                NSLayoutConstraint.activate([
                    self.hiddenImageIndicator.heightAnchor.constraint(equalToConstant: height)
                ])
            }
            
            self.contentStackView.addArrangedSubview(self.mediaContainer)
            
            if UIDevice.current.userInterfaceIdiom == .phone {
                let c = self.mediaContainer.trailingAnchor.constraint(equalTo: self.contentStackView.trailingAnchor)
                c.isActive = true
                self.mediaContainerConstraints = [c]
            } else {
                // Force media container to fill the parent width - with max width for big displays
                self.mediaContainerConstraints = self.mediaContainer.addHorizontalFillConstraints(withParent: self.contentStackView, andMaxWidth: 320)
            }
            
            // Setup Image
            switch self.cellVariant.mediaVariant {
            case .small:
                self.image = PostCardImage(variant: .thumbnail)
                self.image!.translatesAutoresizingMaskIntoConstraints = false
                self.textAndSmallMediaStackView.addArrangedSubview(self.image!)
                self.imageTrailingConstraint = self.image!.widthAnchor.constraint(equalToConstant: 60)
            case .large:
                self.image = PostCardImage(variant: .fullSize)
                self.image!.translatesAutoresizingMaskIntoConstraints = false
                self.mediaContainer.addArrangedSubview(self.image!)
                self.imageTrailingConstraint = self.image!.trailingAnchor.constraint(equalTo: self.mediaContainer.trailingAnchor)
            default: break
            }
            
            // Setup Video
            switch self.cellVariant.mediaVariant {
            case .small:
                self.video = PostCardVideo(variant: .thumbnail)
                self.video!.translatesAutoresizingMaskIntoConstraints = false
                self.textAndSmallMediaStackView.addArrangedSubview(self.video!)
                self.videoTrailingConstraint = self.video!.widthAnchor.constraint(equalToConstant: 60)
            case .large:
                self.video = PostCardVideo(variant: .fullSize)
                self.video!.translatesAutoresizingMaskIntoConstraints = false
                self.mediaContainer.addArrangedSubview(self.video!)
                self.videoTrailingConstraint = self.video!.trailingAnchor.constraint(equalTo: self.mediaContainer.trailingAnchor)
            default: break
            }
            
            
            // Setup Media Carousel
            switch self.cellVariant.mediaVariant {
            case .small:
                self.mediaStack = PostCardMediaStack(variant: .thumbnail)
                self.mediaStack?.translatesAutoresizingMaskIntoConstraints = false
                self.textAndSmallMediaStackView.addArrangedSubview(self.mediaStack!)
                self.mediaStackTrailingConstraint = self.mediaStack!.widthAnchor.constraint(equalToConstant: 60)
            case .large:
                self.mediaGallery = PostCardMediaGallery()
                self.mediaGallery?.translatesAutoresizingMaskIntoConstraints = false
                self.mediaContainer.addArrangedSubview(self.mediaGallery!)
                self.mediaGalleryTrailingConstraint = self.mediaGallery!.trailingAnchor.constraint(equalTo: self.mediaContainer.trailingAnchor)
            default: break
            }
            
            // Setup Poll
            self.poll = PostCardPoll()
            self.poll?.translatesAutoresizingMaskIntoConstraints = false
            self.mediaContainer.addArrangedSubview(self.poll!)
            self.pollTrailingConstraint = self.poll!.trailingAnchor.constraint(equalTo: self.mediaContainer.layoutMarginsGuide.trailingAnchor)
            self.pollTrailingConstraint?.isActive = true
            
            // Setup Quote Post
            self.quotePost = PostCardQuotePost(mediaVariant: self.cellVariant.mediaVariant)
            self.quotePost?.translatesAutoresizingMaskIntoConstraints = false
            self.mediaContainer.addArrangedSubview(self.quotePost!)
            self.quotePostTrailingConstraint = self.quotePost!.trailingAnchor.constraint(equalTo: self.mediaContainer.layoutMarginsGuide.trailingAnchor)
            
            // Setup Link Preview
            self.linkPreview = PostCardLinkPreview()
            self.linkPreview?.translatesAutoresizingMaskIntoConstraints = false
            self.mediaContainer.addArrangedSubview(self.linkPreview!)
            self.linkPreviewTrailingConstraint = self.linkPreview!.trailingAnchor.constraint(equalTo: self.mediaContainer.layoutMarginsGuide.trailingAnchor)
        }
        
        contentStackView.addArrangedSubview(footer)
        
        // Make sure the contentWarning covers the post text, image, link (just not the header, footer)
        contentStackView.addSubview(contentWarningButton)
        contentWarningButton.isHidden = true
        contentWarningButton.addTarget(self, action: #selector(self.contentWarningButtonTapped), for: .touchUpInside)
        contentWarningConstraints = [
            contentWarningButton.topAnchor.constraint(equalTo: header.bottomAnchor, constant: -1),
            contentWarningButton.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: -48),
            contentWarningButton.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor, constant: 6),
            contentWarningButton.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: 3),
        ]
        
        // Make sure the deleted warning covers entire post text, image, link (just not the header, footer)
        self.addSubview(deletedWarningButton)
        deletedWarningButton.isHidden = true
        deletedWarningButton.setTitle("Post removed", for: .normal)
        deletedWarningConstraints = [
            deletedWarningButton.topAnchor.constraint(equalTo: wrapperStackView.topAnchor, constant: -1),
            deletedWarningButton.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: -8),
            deletedWarningButton.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor, constant: 6),
            deletedWarningButton.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: 3),
        ]

        NSLayoutConstraint.activate([
            // Force header to fill the parent width
            header.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
        ])
        
        // Setup Metadata
        self.metadata = PostCardMetadata()
        self.contentStackView.insertArrangedSubview(self.metadata!, at: self.contentStackView.arrangedSubviews.firstIndex(of: self.footer) ?? 0)
        
        self.setupUIFromSettings()
        self.onThemeChange()
    }
    
    @objc func setupUIFromSettings() {
        
        deletedWarningButton.titleLabel?.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)

        self.postTextView.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]
        
        self.postTextView.linkAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold),
            .foregroundColor: UIColor.custom.highContrast,
        ]

        self.postTextView.paragraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = DeviceHelpers.isiOSAppOnMac() ? 1 : 0
            style.paragraphSpacing = PostCardCell.paragraphSpacing
            style.alignment = .natural
            return style
        }()

        if footer.isHidden {
            contentView.layoutMargins = .init(top: 16, left: 13, bottom: 10, right: 13)
        } else {
            let newMargins = UIEdgeInsets.init(top: 16, left: 13, bottom: 0, right: 13)
            if contentView.layoutMargins != newMargins {
                contentView.layoutMargins = newMargins
            }
        }
        
        self.header.setupUIFromSettings()
        self.linkPreview?.setupUIFromSettings()
        self.quotePost?.setupUIFromSettings()
        self.headerExtension?.setupUIFromSettings()
        self.metadata?.setupUIFromSettings()
    }
}

// MARK: - Estimated height
extension PostCardCell {
    static func estimatedHeight(width: CGFloat, postCard: PostCardModel, cellType: PostCardCell.PostCardCellType) -> CGFloat {
        
        let variant = PostCardCell.PostCardVariant.cellVariant(for: postCard, cellType: cellType)
        let contentMarginTop = 13.0
        let contentMarginBottom = 0.0
        let contentMarginLeft = 13.0
        let contentMarginRight = 13.0
        let contentColumnSpacing = 12.0
        let contentSpacing = 2.0
        
        var linkBoxHeight = 0.0
        
        var height = contentMarginTop
        let contentWidth = width - PostCardProfilePic.ProfilePicSize.regular.width() - contentMarginLeft - contentMarginRight - contentColumnSpacing
        
        let textWidth: CGFloat = {
            if let variant, variant.hasMedia, variant.mediaVariant == .small {
                let thumbnailSize = 60.0
                return contentWidth - thumbnailSize - 12.0
            }
            
            return contentWidth
        }()
        
        var textHeight = 0.0
        
        if let variant, variant.hasText {
            let contentFont = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
            let maxHeight = contentFont.lineHeight * Double(cellType.numberOfLines == 0 ? 100 : cellType.numberOfLines)
            let minHeight = variant.mediaVariant == .small ? 60.0 : 0.0
            textHeight = max(ceil(postCard.richPostText?.string.height(width: textWidth, font: contentFont, maxHeight: maxHeight) ?? 0.0), minHeight)
            
            let numberOfParagraphs = postCard.postText.string.numberOfParagraphs()
            if numberOfParagraphs > 1 {
                if cellType.numberOfLines == 0 {
                    for _ in 1...numberOfParagraphs-1 {
                        textHeight += PostCardCell.paragraphSpacing
                    }
                } else {
                    // if text is trimmed and we find > 1 <p> tag, assume there are 2 paragraphs visible
                    textHeight += PostCardCell.paragraphSpacing
                }
            }
            
            height += textHeight
        }
        
        if postCard.hasLink {
            height += PostCardLinkPreview.estimatedHeight(width: contentWidth, postCard: postCard)
            height += contentSpacing
            height += 12
            
            linkBoxHeight += PostCardLinkPreview.estimatedHeight(width: contentWidth, postCard: postCard)
        }
        
        if let variant, variant.hasMedia {
            if variant.mediaVariant == .large {
                height += 12
            } else if variant.mediaVariant == .small {
                if variant.hasText {
                    height += 14
                } else {
                    height += 4
                }
            } else if variant.mediaVariant == .hidden {
                if cellType != .detail && postCard.hasMediaAttachment && !postCard.mediaAttachmentDescription.isEmpty {
                    let hiddenMediaIndicatorHeight = ceil("1 Image".height(width: 300, font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)))
                    height += hiddenMediaIndicatorHeight
                }
            }
        }
        
        if postCard.isReblogged {
            height += PostCardHeaderExtension.estimatedHeight()
            height += 8
        }
        
        height += PostCardHeader.estimatedHeight()
        height += contentSpacing
        height += PostCardMetadata.estimatedHeight()
        height += contentSpacing
        height += PostCardFooter.estimatedHeight()
        height += contentMarginBottom
        height += 1

        return height
    }
}

// MARK: - Configuration
extension PostCardCell {
    func configure(postCard: PostCardModel, type: PostCardCellType = .regular, hasParent: Bool = false, hasChild: Bool = false, onButtonPress: @escaping PostCardButtonCallback) {        
        let mediaHasChanged = postCard.mediaAttachments != self.postCard?.mediaAttachments
        
        let shouldUpdateTheme = self.isPrivateMention != postCard.isPrivateMention
        self.isPrivateMention = postCard.isPrivateMention
        
        self.postCard = postCard
        self.type = type
        self.onButtonPress = onButtonPress
        
        // Display header extension (reblogged or hashtagged indicator)
        if ((postCard.isReblogged && type != .detail) || postCard.isHashtagged || postCard.isPrivateMention) && type != .forYou {
            self.headerExtension?.onPress = onButtonPress
            self.headerExtension!.configure(postCard: postCard)
            self.headerExtension?.isHidden = false
        } else {
            self.headerExtension?.isHidden = true
        }
        
        if let user = postCard.user, !postCard.isDeleted, !postCard.isMuted, !postCard.isBlocked {
            if case .hide(_) = postCard.filterType {} else {
                self.profilePic.configure(user: user, isPrivateMention: postCard.isPrivateMention)
                self.profilePic.onPress = onButtonPress
            }
        }
        
        let isVerticallyCentered = postCard.mediaDisplayType == .carousel
                                    && postCard.postText.isEmpty
                                    && type.headerType != .quotePost
                                    && self.cellVariant.mediaVariant == .large
        
        self.header.configure(postCard: postCard, headerType: type.headerType, isVerticallyCentered: isVerticallyCentered)
        self.header.onPress = onButtonPress
        
        self.configureMetaTextContent()
        
        if self.cellVariant.hasMedia {
            
            if type != .detail && postCard.hasMediaAttachment && !postCard.mediaAttachmentDescription.isEmpty {
                self.hiddenImageIndicator.text = "(\(postCard.mediaAttachmentDescription))"
                self.hiddenImageIndicator.isHidden = false
            } else {
                self.hiddenImageIndicator.isHidden = true
            }
            
            // Display poll if needed
            if postCard.containsPoll {
                self.poll?.prepareForReuse()
                self.poll?.configure(postCard: postCard)
                self.poll?.isHidden = false
            } else {
                self.poll?.isHidden = true
            }
            
            // Display the quote post preview if needed
            if postCard.hasQuotePost {
                self.quotePost?.configure(postCard: postCard)
                self.quotePost?.onPress = onButtonPress
                self.quotePost?.isHidden = false
            } else {
                self.quotePost?.isHidden = true
            }
            
            // Display the link preview if needed
            if postCard.hasLink && !postCard.hasQuotePost {
                self.linkPreview?.configure(postCard: postCard)
                self.linkPreview?.onPress = onButtonPress
                self.linkPreview?.isHidden = false
            } else {
                self.linkPreview?.isHidden = true
            }
            
            // Display single image if needed
            if postCard.hasMediaAttachment && postCard.mediaDisplayType == .singleImage {
                self.image?.configure(postCard: postCard)
                self.image?.isHidden = false
            } else {
                self.image?.isHidden = true
            }
            
            // Display single video/gif if needed
            if postCard.hasMediaAttachment && [.singleVideo, .singleGIF].contains(postCard.mediaDisplayType) {
                if mediaHasChanged {
                    self.video?.configure(postCard: postCard)
                    
                    // Do not auto-play videos in thumbnail-mode
                    if [.small, .hidden].contains(self.cellVariant.mediaVariant) {
                        self.video?.pause()
                    }
                    
                    // Auto-play videos in detail mode (unless auto-play is disabled)
                    if type == .detail && GlobalStruct.autoPlayVideos {
                        self.video?.play()
                    }
                    
                    self.video?.isHidden = false
                }
            } else {
                self.video?.isHidden = true
            }
            
            // Display the image carousel if needed
            if postCard.hasMediaAttachment && postCard.mediaDisplayType == .carousel {
                if self.cellVariant.mediaVariant == .small {
                    self.mediaStack?.configure(postCard: postCard)
                    self.mediaStack?.isHidden = false
                    self.mediaGallery?.isHidden = true
                } else {
                    self.mediaGallery?.configure(postCard: postCard)
                    self.mediaGallery?.isHidden = false
                    self.mediaStack?.isHidden = true
                }
                
            } else {
                self.mediaGallery?.isHidden = true
                self.mediaStack?.isHidden = true
            }
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
        
        // Hide media gallery (carousel) if covered with content warning / deleted overlay
        if self.contentWarningButton.isHidden == false || self.deletedWarningButton.isHidden == false {
            self.mediaGallery?.alpha = 0
            self.textAndSmallMediaStackView.alpha = 0
            self.mediaStack?.alpha = 0
            self.metadata?.alpha = 0
        } else {
            self.mediaGallery?.alpha = 1
            self.textAndSmallMediaStackView.alpha = 1
            self.mediaStack?.alpha = 1
            self.metadata?.alpha = 1
        }
        
        self.footer.configure(postCard: postCard, includeMetrics: false)
        self.footer.onButtonPress = onButtonPress
        
        self.childThread.isHidden = !hasChild
        self.parentThread.isHidden = !hasParent
        
        if type.shouldShowDetailedMetrics {
            self.metadata?.isHidden = false
            self.metadata?.configure(postCard: postCard, type: type, onButtonPress: onButtonPress)
            
            // add custom spacing above the post details ("via Mammoth, public", and metrics)
            if self.contentStackView.arrangedSubviews.contains(self.mediaContainer) {
                self.contentStackView.setCustomSpacing(12, after: self.mediaContainer)
            } else if self.contentStackView.arrangedSubviews.contains(self.postTextView) {
                self.contentStackView.setCustomSpacing(10, after: self.postTextView)
            }
        } else {
            // remove the detailStack when not needed
            if self.metadata?.isHidden == false {
                self.metadata?.isHidden = true
            }
        }
        
        // set detail-specific UI
        if type == .detail {
            // long press to copy the post text
            self.textLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.onTextLongPress))
            self.postTextView.addGestureRecognizer(self.textLongPressGesture!)
            
            // make sure the thread lines are behind all the other elements
            self.mainStackView.sendSubviewToBack(self.childThread)
            self.mainStackView.sendSubviewToBack(self.parentThread)
        } else if let gesture = self.textLongPressGesture, (self.postTextView.gestureRecognizers?.contains(gesture) as? Bool) == true {
            self.postTextView.removeGestureRecognizer(gesture)
        }
        
        // Make sure all views are underneath the contentWarningButton and the deletedWarningButton
        if self.contentWarningButton.isHidden == false {
            self.contentStackView.bringSubviewToFront(self.contentWarningButton)
        }
        if self.deletedWarningButton.isHidden == false {
            self.contentStackView.bringSubviewToFront(self.deletedWarningButton)
        }
        
        if CommandLine.arguments.contains("-M_DEBUG_TIMELINES") {
            // Configure for debugging
            self.configureForDebugging(postCard: postCard)
        }
        
        self.configureContraints()
        
        if shouldUpdateTheme {
            self.onThemeChange()
        }
    }
    
    func configureMetaTextContent() {
        if self.cellVariant.hasText {
            if self.postTextView.textContainer.maximumNumberOfLines != type!.numberOfLines {
                self.postTextView.textContainer.maximumNumberOfLines = type!.numberOfLines
                self.postTextView.numberOfLines = type!.numberOfLines
            }
            
            if let postTextContent = postCard?.metaPostText, !postTextContent.original.isEmpty {
                self.postTextView.configure(content: postTextContent)
                self.postCard?.richPostText = self.postTextView.attributedText
            } else if [.small].contains(self.cellVariant.mediaVariant) {
                // If there's no post text, but a media attachment,
                // set the post text to either:
                //  - ([type])
                //  - ([type] description: [meta description])
                if let type = postCard?.mediaDisplayType.captializedDisplayName  {
                    if let desc = postCard?.mediaAttachments.first?.description {
                        let content = MastodonMetaContent.convert(text: MastodonContent(content: "(\(type) description: \(desc))", emojis: [:]))
                        self.postTextView.configure(content: content)
                        self.postTextView.isHidden = false
                    } else {
                        let content = MastodonMetaContent.convert(text: MastodonContent(content: "(\(type))", emojis: [:]))
                        self.postTextView.configure(content: content)
                        self.postTextView.isHidden = false
                    }
                } else {
                    self.postTextView.isHidden = true
                }
            } else {
                self.postTextView.isHidden = true
            }
            
//            self.readMoreButton?.isHidden = true
//            contentStackView.setCustomSpacing(2, after: textAndSmallMediaStackView)
//            let processingPostUniqueId = postCard?.uniqueId
//            DispatchQueue.main.async { [weak self] in
//                guard let self else { return }
//                guard self.postCard?.uniqueId == processingPostUniqueId else { return }
//                if self.postTextView.isTruncated && self.type != .detail {
//                    self.readMoreButton?.isHidden = false
//                } else if self.readMoreButton?.isHidden == false {
//                    self.readMoreButton?.isHidden = true
//                }
//            }
        }
    }
    
    private func configureContraints() {
        if let postCard = self.postCard {
            // Display poll if needed
            if postCard.containsPoll {
                if let constraint = self.pollTrailingConstraint, !constraint.isActive {
                    NSLayoutConstraint.activate([self.pollTrailingConstraint!])
                }
            } else {
                if let constraint = self.pollTrailingConstraint, constraint.isActive {
                    NSLayoutConstraint.deactivate([constraint])
                }
            }
            
            // Display the quote post preview if needed
            if postCard.hasQuotePost {
                if let constraint = self.quotePostTrailingConstraint, !constraint.isActive {
                    NSLayoutConstraint.activate([self.quotePostTrailingConstraint!])
                }
            } else {
                if let constraint = self.quotePostTrailingConstraint, constraint.isActive {
                    NSLayoutConstraint.deactivate([constraint])
                }
            }
            
            // Display the link preview if needed
            if postCard.hasLink && !postCard.hasQuotePost {
                if let constraint = self.linkPreviewTrailingConstraint, !constraint.isActive {
                    NSLayoutConstraint.activate([constraint])
                }
            } else {
                if let constraint = self.linkPreviewTrailingConstraint, constraint.isActive {
                    NSLayoutConstraint.deactivate([constraint])
                }
            }
            
            // Display single image if needed
            if postCard.hasMediaAttachment && postCard.mediaDisplayType == .singleImage {
                if let constraint = self.imageTrailingConstraint, !constraint.isActive {
                    NSLayoutConstraint.activate([self.imageTrailingConstraint!])
                }
            } else {
                if let constraint = self.imageTrailingConstraint, constraint.isActive {
                    NSLayoutConstraint.deactivate([constraint])
                }
            }
            
            // Display single video/gif if needed
            if postCard.hasMediaAttachment && [.singleVideo, .singleGIF].contains(postCard.mediaDisplayType) {
                if let constraint = self.videoTrailingConstraint, !constraint.isActive {
                    NSLayoutConstraint.activate([self.videoTrailingConstraint!])
                }
            } else {
                if let constraint = self.videoTrailingConstraint, constraint.isActive {
                    NSLayoutConstraint.deactivate([constraint])
                }
            }
            
            // Display the image carousel if needed
            if postCard.hasMediaAttachment && postCard.mediaDisplayType == .carousel {
                switch self.cellVariant.mediaVariant {
                case .small:
                    if let constraint = self.mediaStackTrailingConstraint, !constraint.isActive {
                        NSLayoutConstraint.activate([self.mediaStackTrailingConstraint!])
                    }
                    NSLayoutConstraint.deactivate([
                        self.mediaGalleryTrailingConstraint,
                    ].compactMap({$0}))
                case .large:
                    if let constraint = self.mediaGalleryTrailingConstraint, !constraint.isActive {
                        NSLayoutConstraint.activate([
                            self.mediaGalleryTrailingConstraint!
                        ])
                    }
                    if let constraints = self.mediaStackTrailingConstraint {
                        NSLayoutConstraint.deactivate([constraints])
                    }
                default: break
                }
                
            } else {
                NSLayoutConstraint.deactivate([
                    self.mediaGalleryTrailingConstraint,
                ].compactMap({$0}))
            }
        }
    }
    
    /// the cell will be displayed in the tableview
    public func willDisplay() {
        if let postCard = self.postCard, 
            postCard.hasMediaAttachment && [.singleVideo, .singleGIF].contains(postCard.mediaDisplayType),
           ![.small, .hidden].contains(self.cellVariant.mediaVariant) {
            if GlobalStruct.autoPlayVideos {
                self.video?.play()
            }
        }
        
        if let postCard = self.postCard, postCard.hasQuotePost, ![.small, .hidden].contains(self.cellVariant.mediaVariant) {
            postCard.preloadQuotePost()
        }
        
        self.header.startTimeUpdates()
        self.profilePic.willDisplay()
        self.quotePost?.willDisplay()
    }
    
    // the cell will end being displayed in the tableview
    public func didEndDisplay() {
        if let postCard = self.postCard, 
            postCard.hasMediaAttachment && [.singleVideo, .singleGIF].contains(postCard.mediaDisplayType) {
            self.video?.pause()
        }
        
        if let postCard = self.postCard, postCard.hasQuotePost,
            let quotePostCard = postCard.quotePostData,
            let video = quotePostCard.videoPlayer {
            video.pause()
        }
        
        self.header.stopTimeUpdates()
    }
    
    @objc private func onTextLongPress(recognizer: UIGestureRecognizer) {
        if let view = recognizer.view, let superview = recognizer.view?.superview {
            view.becomeFirstResponder()
            let menuController = UIMenuController.shared
                    
            let copyItem = UIMenuItem(title: NSLocalizedString("generic.copy", comment: ""), action: #selector(self.copyText))
            menuController.menuItems = [copyItem]
            
            menuController.showMenu(from: superview, rect: view.frame)
        }
    }
    
    @objc private func onMetricPress(recognizer: UIGestureRecognizer) {
        if recognizer.view?.tag == MetricButtons.likes.rawValue {
            self.onButtonPress?(.likes, false, nil)
        }
        
        if recognizer.view?.tag == MetricButtons.reposts.rawValue {
            self.onButtonPress?(.reposts, false, nil)
        }
        
        if recognizer.view?.tag == MetricButtons.replies.rawValue {
            self.onButtonPress?(.replies, false, nil)
        }
    }
    
    @objc private func copyText() {
        UIPasteboard.general.setValue(self.postCard?.metaPostText?.original ?? "", forPasteboardType: "public.utf8-plain-text")
    }
    
    private func configureForDebugging(postCard: PostCardModel) {
        if let batchId = postCard.batchId, let batchItemIndex = postCard.batchItemIndex {
            self.postTextView.text = "\(batchId) - \(batchItemIndex)"
            
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
        var backgroundColor = UIColor.custom.background
        if let postCard = self.postCard, postCard.isPrivateMention {
            backgroundColor = .custom.OVRLYSoftContrast
        }
        
        self.backgroundColor = backgroundColor
        self.contentView.backgroundColor = backgroundColor
        self.postTextView.backgroundColor = backgroundColor
        self.wrapperStackView.backgroundColor = backgroundColor
        self.mainStackView.backgroundColor = backgroundColor
        self.contentStackView.backgroundColor = backgroundColor
        self.mediaStack?.backgroundColor = backgroundColor
        self.mediaContainer.backgroundColor = backgroundColor
        self.textAndSmallMediaStackView.backgroundColor = backgroundColor
        
        self.profilePic.onThemeChange()
        self.header.onThemeChange()
        self.poll?.onThemeChange()
        self.linkPreview?.onThemeChange()
        self.quotePost?.onThemeChange()
        self.image?.onThemeChange()
        self.metadata?.onThemeChange()
        self.footer.onThemeChange()
        self.footer.backgroundColor = self.contentView.backgroundColor
        
//        self.readMoreButton?.configure(backgroundColor: backgroundColor)
        
        // Update all items that use .custom colors
        contentWarningButton.backgroundColor = .custom.OVRLYSoftContrast
        deletedWarningButton.backgroundColor = .custom.OVRLYSoftContrast
        postTextView.textColor = .custom.mediumContrast
        parentThread.backgroundColor = .custom.feintContrast
        childThread.backgroundColor = .custom.feintContrast
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupUIFromSettings()
        configureMetaTextContent()
        onThemeChange()
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
        self.mediaGallery?.alpha = 1
        self.textAndSmallMediaStackView.alpha = 1
        self.mediaStack?.alpha = 1
        self.metadata?.alpha = 1
    }
    
    @objc func onReadMorePress() {
        if let postCard = self.postCard {
            self.onButtonPress?(.postDetails, true, .post(postCard))
        }
    }
}

// MARK: - MetaTextViewDelegate
extension PostCardCell: MetaLabelDelegate {
    
    func metaLabel(_ metaLabel: MetaLabel, didSelectMeta meta: Meta) {
        switch meta {
        case .url(_, _, let urlString, _):
            if let url = URL(string: urlString) {
                self.onButtonPress?(.link, true, .url(url))
            }
        case .mention(_, let mention, _):
            if case .mastodon(let status) = self.postCard?.data {
                self.onButtonPress?(.link, true, .mention((mention, status)))
            }
        case .hashtag(_, let hashtag, _):
            self.onButtonPress?(.link, true, .hashtag(hashtag))
        default:
            guard let postCard = self.postCard, self.type != .detail else { return }
            self.onButtonPress?(.postDetails, true, .post(postCard))
        }
    }
}

// MARK: - Context menu creators
extension PostCardCell {
    private func createContextMenuAction(_ title: String, _ buttonType: PostCardButtonType, isActive: Bool, onPress: @escaping PostCardButtonCallback, attributes:  UIMenuElement.Attributes = []) -> UIAction {
        
        var color: UIColor = .black
        if GlobalStruct.overrideTheme == 1 || self.traitCollection.userInterfaceStyle == .light {
            color = .black
        } else if GlobalStruct.overrideTheme == 2 || self.traitCollection.userInterfaceStyle == .dark  {
            color = .white
        }
        
        if attributes.contains(.destructive) {
            color = UIColor.systemRed
        }
        
        let action = UIAction(title: title,
                              image: isActive
                              ? buttonType.activeIcon(symbolConfig: postCardSymbolConfig)?.withTintColor(color).withRenderingMode(.alwaysTemplate)
                              : buttonType.icon(symbolConfig: postCardSymbolConfig)?.withTintColor(color).withRenderingMode(.alwaysTemplate),
                                  identifier: nil) { _ in
            onPress(buttonType, isActive, nil)
        }
        action.accessibilityLabel = title
        action.attributes = attributes
  
        return action
    }
    
    // General cell context menu
    func createContextMenu(postCard: PostCardModel, onButtonPress: @escaping PostCardButtonCallback) -> UIMenu {
        let options = [
            createContextMenuAction(NSLocalizedString("post.reply", comment: ""), .reply, isActive: false, onPress: onButtonPress),
            
            (postCard.isReposted
             ? createContextMenuAction(NSLocalizedString("post.repost.undo", comment: ""), .repost, isActive: true, onPress: onButtonPress)
             : createContextMenuAction(NSLocalizedString("post.repost", comment: ""), .repost, isActive: false, onPress: onButtonPress)),
            
            (postCard.isLiked
             ? createContextMenuAction(NSLocalizedString("post.like.undo", comment: ""), .like, isActive: true, onPress: onButtonPress)
             : createContextMenuAction(NSLocalizedString("post.like", comment: ""), .like, isActive: false, onPress: onButtonPress)),
            
            (postCard.isBookmarked
                ? createContextMenuAction(NSLocalizedString("post.bookmark.undo", comment: ""), .unbookmark, isActive: false, onPress: onButtonPress)
                : createContextMenuAction(NSLocalizedString("post.bookmark", comment: ""), .bookmark, isActive: false, onPress: onButtonPress)),
            
            createContextMenuAction(NSLocalizedString("post.translatePost", comment: ""), .translate, isActive: false, onPress: onButtonPress),
            createContextMenuAction(NSLocalizedString("post.viewInBrowser", comment: ""), .viewInBrowser, isActive: false, onPress: onButtonPress),
            
            ( !postCard.isOwn ? createContextMenuAction(NSLocalizedString("post.report", comment: ""), .reportPost, isActive: false, onPress: onButtonPress, attributes: .destructive) : nil),
            
            createContextMenuAction(NSLocalizedString("post.sharePost", comment: ""), .share, isActive: false, onPress: onButtonPress),
            (postCard.isOwn
             ? UIMenu(title: NSLocalizedString("post.modify", comment: ""), options: [], children: [
                
                (postCard.isPinned
                    ? createContextMenuAction(NSLocalizedString("post.pin.undo", comment: ""), .pinPost, isActive: true, onPress: onButtonPress)
                    : createContextMenuAction(NSLocalizedString("post.pin", comment: ""), .pinPost, isActive: false, onPress: onButtonPress)),
                
                createContextMenuAction(NSLocalizedString("post.edit", comment: ""), .editPost, isActive: false, onPress: onButtonPress),
                createContextMenuAction(NSLocalizedString("post.delete", comment: ""), .deletePost, isActive: false, onPress: onButtonPress, attributes: .destructive),
             ])
             : nil)
        ].compactMap({$0})
        
        return UIMenu(title: "", options: [.displayInline], children: options)
    }
}

