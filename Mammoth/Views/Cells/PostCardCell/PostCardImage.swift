//
//  PostCardImage.swift
//  Mammoth
//
//  Created by Benoit Nolens on 28/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import SDWebImage

// swiftlint:disable:next type_body_length
final class PostCardImage: UIView {
    
    enum PostCardImageVariant {
        case fullSize
        case thumbnail
    }
    
    static var transformer: SDImageTransformer {
        return ScaleDownTransformer()
    }
    
    private(set) var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .custom.OVRLYSoftContrast
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    public var image: UIImage? {
        return self.imageView.image
    }
    
    private lazy var sensitiveContentOverlay: UIButton = {
        let button = UIButton(type: .custom)
        
        let iconView = BlurredBackground(dimmed: false)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 18
        iconView.clipsToBounds = true
        
        button.insertSubview(iconView, aboveSubview: button.imageView!)
        
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),
        ])
        
        let icon = UIImageView(image: FontAwesome.image(fromChar: "\u{f070}", color: .custom.linkText, size: 16, weight: .bold).withRenderingMode(.alwaysTemplate))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .center
        iconView.addSubview(icon)
        icon.pinCenter()

        let bg = BlurredBackground(dimmed: true, underlayAlpha: 0.11)
        button.insertSubview(bg, belowSubview: button.imageView!)
        bg.pinEdges()
        
        return button
    }()
    
    private var hideSensitiveOverlayGesture: UITapGestureRecognizer?
    private var dismissedSensitiveOverlay: Bool = false

    // A dynamic width is used when the view has a fixed height (as in the gallery)
    private var dynamicWidthConstraint: NSLayoutConstraint?
    // A dynamic height is used when the view has a max width (as in standalone image in post card cell)
    private var dynamicHeightConstraint: NSLayoutConstraint?
    
    private let tallAspectRatio = 0.44
    
    private lazy var squareConstraints: [NSLayoutConstraint] = {
        let c1 = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
        c1.priority = .defaultHigh

        let c2 = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        c2.priority = .defaultHigh
        
        let c3 = imageView.heightAnchor.constraint(equalTo: self.heightAnchor)
        c3.priority = .required
        
        return [c1, c2, c3]
    }()
    
    private lazy var portraitConstraints: [NSLayoutConstraint] = {
        // most landscape images
        if self.inGallery {
            let c1 = imageView.heightAnchor.constraint(equalTo: self.heightAnchor)
            c1.priority = .defaultLow

            let c2 = imageView.widthAnchor.constraint(lessThanOrEqualTo: self.heightAnchor, multiplier: tallAspectRatio)
            c2.priority = .defaultHigh
            
            return [c1, c2]
        } else {
            let c1 = imageView.widthAnchor.constraint(equalTo: self.widthAnchor)
            c1.priority = .defaultHigh

            let c2 = imageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
            c2.priority = .defaultHigh
            
            return [c1, c2]
        }
    }()
    
    private lazy var tallPortraitConstraints: [NSLayoutConstraint] = {
        if self.inGallery {
            // extremely tall (more than the iPhone 14 Pro Max ratio)
            let c1 = imageView.heightAnchor.constraint(equalTo: self.heightAnchor)
            c1.priority = .defaultLow
            
            let c2 = imageView.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: 9.0/16.0)
            c2.priority = .required
            
            return [c1, c2]
        } else {
            // extremely tall (more than the iPhone 14 Pro Max ratio)
            let c1 = imageView.widthAnchor.constraint(equalTo: self.widthAnchor)
            c1.priority = .defaultHigh
            
            let c2 = imageView.heightAnchor.constraint(equalToConstant: 420)
            c2.priority = .defaultHigh
            
            return [c1, c2]
        }
    }()
    
    private lazy var landscapeConstraints: [NSLayoutConstraint] = {
        if self.inGallery {
            let c1 = imageView.heightAnchor.constraint(equalTo: self.heightAnchor)
            c1.priority = .required
            
            let c2 = imageView.widthAnchor.constraint(lessThanOrEqualTo: self.heightAnchor, multiplier: 16.0/9.0)
            c2.priority = .required
            
            return [c1, c2]
        } else {
            let c1 = imageView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor)
            c1.priority = .defaultHigh
            
            let c2 = imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 420)
            c2.priority = .required
            
            return [c1, c2]
        }
    }()
    
    private var altButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("ALT", for: .normal)
        button.setTitleColor(.custom.active, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        button.layer.cornerCurve = .continuous
        button.layer.cornerRadius = 7
        button.clipsToBounds = true
        button.isHidden = true
        button.accessibilityElementsHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = .init(top: 3, left: 5, bottom: 2, right: 5)
        
        let bg = BlurredBackground(dimmed: false)
        button.insertSubview(bg, belowSubview: button.titleLabel!)
        bg.pinEdges()
        
        return button
    }()
    
    private var ownGalleryIndex: Int?
    
    private var postCard: PostCardModel?
    private var media: Attachment?
    private let variant: PostCardImageVariant
    private let inGallery: Bool
    
    weak var galleryDelegate: PostCardMediaGalleryDelegate?
    
    init(variant: PostCardImageVariant = .fullSize, inGallery: Bool = false) {
        self.variant = variant
        self.inGallery = inGallery
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        self.postCard = nil
        self.media = nil
        self.galleryDelegate = nil
        self.dismissedSensitiveOverlay = false
        self.imageView.sd_cancelCurrentImageLoad()
    }
    
    private func setupUI() {
        self.isOpaque = true
        self.translatesAutoresizingMaskIntoConstraints = false
        self.layoutMargins = .init(top: 3, left: 0, bottom: 0, right: 0)

        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.layer.cornerCurve = .continuous
        self.addSubview(imageView)
        self.addSubview(altButton)
        self.imageView.addSubview(sensitiveContentOverlay)
        
        switch self.variant {
        case .fullSize:
            self.altButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            self.altButton.contentEdgeInsets = .init(top: 3, left: 5, bottom: 2, right: 5)
        case .thumbnail:
            self.altButton.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
            self.altButton.contentEdgeInsets = .init(top: 3, left: 5, bottom: 2, right: 5)
        }
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            altButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: self.variant == .fullSize ? -10 : -2),
            altButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: self.variant == .fullSize ? -10 : -2),
        ])
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.onPress))
        self.addGestureRecognizer(gesture)
                
        let altPress = UITapGestureRecognizer(target: self, action: #selector(self.altPress))
        self.altButton.addGestureRecognizer(altPress)
        
        self.sensitiveContentOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.sensitiveContentOverlay.alpha = 1
    }
    
    public func configure(image: Attachment?, postCard: PostCardModel) {
        let shouldUpdate = self.media == nil || image != self.media!
        self.postCard = postCard
        self.media = image
        
        if let media = image {
            if let previewURL = media.previewURL, let imageURL = URL(string: previewURL) {
                var placeholder: UIImage?
                if let blurhash = media.blurhash, let blurImage = postCard.decodedBlurhashes[blurhash] {
                    placeholder = blurImage
                }
                let decodedImage = (media.previewURL != nil) ? postCard.decodedImages[media.previewURL!] as? UIImage : nil
                self.imageView.ma_setImage(with: imageURL,
                                           cachedImage: decodedImage,
                                           placeholder: placeholder,
                                                  imageTransformer: PostCardImage.transformer) { [weak self] image in
                    if self?.media == media, let image = image {
                        if let key = media.previewURL {
                            postCard.decodedImages[key] = image
                        }
                    }
                }
            }
            
            if GlobalStruct.blurSensitiveContent && postCard.isSensitive && !self.dismissedSensitiveOverlay {
                self.sensitiveContentOverlay.frame = self.imageView.bounds
                
                if self.hideSensitiveOverlayGesture == nil {
                    self.hideSensitiveOverlayGesture = UITapGestureRecognizer(target: self, action: #selector(self.hideSensitiveOverlay))
                    self.sensitiveContentOverlay.addGestureRecognizer(self.hideSensitiveOverlayGesture!)
                }
                
                self.sensitiveContentOverlay.isHidden = false
            } else {
                self.sensitiveContentOverlay.isHidden = true
            }
            
            if let description = media.description, !description.isEmpty {
                self.altButton.isHidden = false
                self.bringSubviewToFront(self.altButton)
            } else {
                self.altButton.isHidden = true
            }
        }
        
        if shouldUpdate {
            // meta itself might be nil
            var aspect: Double? = nil
            if let width = self.media?.meta?.original?.width, let height = self.media?.meta?.original?.height {
                aspect = Double(width) / Double(height)
            } else {
                imageView.contentMode = .scaleAspectFit
            }
            let ratio = self.media?.meta?.original?.aspect ?? aspect ?? 16.0 / 9.0
    
            // square
            if self.variant == .thumbnail || fabs(ratio - 1.0) < 0.01 {
                self.deactivateAllImageConstraints()
                NSLayoutConstraint.activate(self.squareConstraints)
            }

            // landscape
            else if ratio > 1 {
                self.deactivateAllImageConstraints()
                
                if self.inGallery {
                    if ratio < 16.0/9.0 {
                        self.dynamicWidthConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: ratio)
                        self.dynamicWidthConstraint!.priority = .defaultHigh + 1
                        self.dynamicWidthConstraint!.isActive = true
                    }
                } else {
                    self.dynamicHeightConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.0 / ratio)
                    self.dynamicHeightConstraint!.priority = .defaultHigh + 1
                    self.dynamicHeightConstraint!.isActive = true
                }
                
                NSLayoutConstraint.activate(self.landscapeConstraints)
            }

            // portrait
            else if ratio < 1 {
                if ratio < tallAspectRatio {
                    self.deactivateAllImageConstraints()
                    NSLayoutConstraint.activate(self.tallPortraitConstraints)
                } else {
                    self.deactivateAllImageConstraints()
                    
                    if self.inGallery {
                        self.dynamicWidthConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: ratio)
                        self.dynamicWidthConstraint!.priority = .defaultHigh
                        self.dynamicWidthConstraint!.isActive = true
                    } else {
                        self.dynamicHeightConstraint = imageView.heightAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1.0 / ratio)
                        self.dynamicHeightConstraint!.priority = .defaultHigh
                        self.dynamicHeightConstraint!.isActive = true
                    }
                    
                    NSLayoutConstraint.activate(self.portraitConstraints)
                }
            }
            
            self.onThemeChange()
        }
    }
    
    public func configure(postCard: PostCardModel) {
        if let firstImage = postCard.mediaAttachments.first {
            self.configure(image: firstImage, postCard: postCard)
        }
    }
    
    public func onThemeChange() {
        let backgroundColor: UIColor = (self.postCard?.isPrivateMention ?? false) ? .custom.OVRLYSoftContrast : .custom.background
        self.backgroundColor = backgroundColor
    }
    
    private func deactivateAllImageConstraints() {
        NSLayoutConstraint.deactivate(self.squareConstraints
                                      + self.portraitConstraints
                                      + self.tallPortraitConstraints
                                      + self.landscapeConstraints
                                      + [self.dynamicHeightConstraint, self.dynamicWidthConstraint].compactMap({$0})
        )
    }
    
    @objc func onPress() {
        if let originImage = imageView.image {

            // Open fullscreen image preview
            let images = self.postCard?.mediaAttachments.compactMap { attachment in
                guard attachment.type == .image else { return SKPhoto() }
                let photo = SKPhoto.photoWithImageURL(attachment.url)
                photo.contentMode = imageView.contentMode
                photo.shouldCachePhotoURLImage = false
                
                let imageFromCache = SDImageCache.shared.imageFromCache(forKey: attachment.url)
                let previewFromCache = SDImageCache.shared.imageFromCache(forKey: attachment.previewURL)
                
                var blurImage: UIImage? = nil
                if let blurhash = attachment.blurhash, imageFromCache == nil, let currentMedia = self.media, attachment.url != currentMedia.url, let decodedBlurImage = self.postCard?.decodedBlurhashes[blurhash] {
                    blurImage = decodedBlurImage
                }
                photo.underlyingImage = imageFromCache ?? previewFromCache ?? blurImage
                return photo
            } ?? [SKPhoto()]
            
            let descriptions = self.postCard?.mediaAttachments.map { $0.description ?? "" } ?? []
            self.ownGalleryIndex = self.postCard?.mediaAttachments.firstIndex(where: {$0.id == self.media?.id}) ?? 0
            
            let browser = SKPhotoBrowser(originImage: originImage,
                                         photos: images,
                                         animatedFromView: self.imageView,
                                         descriptions: descriptions,
                                         currentIndex: self.ownGalleryIndex ?? 0)
            SKPhotoBrowserOptions.enableSingleTapDismiss = false
            SKPhotoBrowserOptions.displayCounterLabel = false
            SKPhotoBrowserOptions.displayBackAndForwardButton = false
            SKPhotoBrowserOptions.displayAction = false
            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
            SKPhotoBrowserOptions.displayCloseButton = false
            SKPhotoBrowserOptions.displayStatusbar = false
            browser.initializePageIndex(self.ownGalleryIndex ?? 0)
            browser.delegate = self
            getTopMostViewController()?.present(browser, animated: true, completion: {})
            
            // Preload other images
            PostCardModel.imageDecodeQueue.async { [weak self] in
                guard let self else { return }
                let prefetcher = SDWebImagePrefetcher.shared
                let urls = self.postCard?.mediaAttachments.compactMap { URL(string: $0.url) }
                prefetcher.prefetchURLs(urls, progress: nil) { _, _ in
                    let images = self.postCard?.mediaAttachments.compactMap { attachment in
                        guard attachment.type == .image else { return nil }
                        let photo = SKPhoto.photoWithImageURL(attachment.url)
                        photo.contentMode = self.imageView.contentMode
                        photo.shouldCachePhotoURLImage = false
                        photo.underlyingImage = SDImageCache.shared.imageFromCache(forKey: attachment.url)
                        return photo
                    } ?? [SKPhoto()]
                    
                    DispatchQueue.main.async {
                        browser.photos = images
                        browser.reloadData()
                    }
                }
            }
        }
    }
    
    @objc func altPress() {
        if let altTextPopup = self.media?.description {
            triggerHapticImpact(style: .light)
            let alert = UIAlertController(title: nil, message: altTextPopup, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.copy", comment: ""), style: .default , handler:{ (UIAlertAction) in
                let pasteboard = UIPasteboard.general
                pasteboard.string = altTextPopup
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in

            }))
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = self
                presenter.sourceRect = self.bounds
            }
            getTopMostViewController()?.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func hideSensitiveOverlay() {
        self.dismissedSensitiveOverlay = true
        triggerHapticImpact(style: .light)
        UIView.animate(withDuration: 0.18) {
            self.sensitiveContentOverlay.alpha = 0
        } completion: { _ in
            self.sensitiveContentOverlay.removeFromSuperview()
        }
    }
}

extension PostCardImage: SKPhotoBrowserDelegate {
    func viewForPhoto(_ browser: SKPhotoBrowser, index: Int) -> UIView? {
        if self.ownGalleryIndex != index {
            return self.galleryDelegate?.galleryItemForPhoto(withIndex: index)?.imageView
        }
        
        return self.imageView
    }
    
    func willDismissAtPageIndex(_ index: Int) {
        if self.ownGalleryIndex != index {
            self.imageView.alpha = 1
            self.imageView.isHidden = false
            if let targetImage = self.galleryDelegate?.galleryItemForPhoto(withIndex: index) {
                targetImage.imageView.alpha = 0
                targetImage.imageView.isHidden = true
            }
            self.galleryDelegate?.scrollGalleryToItem(atIndex: index, animated: false)
        }
    }
}
