//
//  PostCardImage.swift
//  Mammoth
//
//  Created by Benoit Nolens on 28/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import SDWebImage

final class PostCardImage: UIView {
    
    static var transformer: SDImageTransformer {
        return ScaleDownTransformer()
    }
    
    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        imageView.backgroundColor = .custom.OVRLYSoftContrast
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
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
        
    private var imageWidthConstraint: NSLayoutConstraint?
    private var imageHeightConstraint: NSLayoutConstraint?
    private var maxHeightConstraint: NSLayoutConstraint?
    private var minHeightConstraint: NSLayoutConstraint?
    
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
    
    private var media: Attachment?
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        
        self.media = nil
        self.dismissedSensitiveOverlay = false
        
//        self.resetVariableConstraints()
    }
    
    private func resetVariableConstraints() {
        [imageWidthConstraint, imageHeightConstraint, maxHeightConstraint, minHeightConstraint].compactMap({$0}).forEach({
            $0.isActive = false
//            imageView.removeConstraint($0)
        })
    }
    
    private func setupUI() {
        self.isOpaque = true
        self.backgroundColor = .custom.background
        self.layoutMargins = .init(top: 3, left: 0, bottom: 0, right: 0)

        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.layer.cornerCurve = .continuous
        self.addSubview(imageView)
        self.addSubview(altButton)
        self.imageView.addSubview(sensitiveContentOverlay)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            altButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
            altButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
        ])
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.onPress))
        self.addGestureRecognizer(gesture)
                
        let altPress = UITapGestureRecognizer(target: self, action: #selector(self.altPress))
        self.altButton.addGestureRecognizer(altPress)
        
        self.sensitiveContentOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.sensitiveContentOverlay.alpha = 1
    }
    
    override func updateConstraints() {
        self.resetVariableConstraints()
        
        // the aspect value might be nil
        if self.media?.meta?.original?.aspect == nil {
            self.media?.meta?.original?.aspect = Double(self.media?.meta?.original?.width ?? 10) / Double(self.media?.meta?.original?.height ?? 10)
        }
        
        if let ratio = self.media?.meta?.original?.aspect {
            // square
            if fabs(ratio - 1.0) < 0.01 {
                imageWidthConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
                imageWidthConstraint!.priority = .required
                imageWidthConstraint!.isActive = true
                
                imageHeightConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
                imageHeightConstraint!.priority = .required
                imageHeightConstraint!.isActive = true
                
                self.translatesAutoresizingMaskIntoConstraints = false
            }
            
            // landscape
            else if ratio > 1 {
                imageWidthConstraint = imageView.widthAnchor.constraint(equalTo: self.widthAnchor)
                imageWidthConstraint!.priority = .defaultHigh
                imageWidthConstraint!.isActive = true
                
                imageHeightConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1 / ratio)
                imageHeightConstraint!.priority = .defaultHigh
                imageHeightConstraint!.isActive = true
                
                minHeightConstraint = imageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
                minHeightConstraint!.priority = .required
                minHeightConstraint!.isActive = true
            }
            
            // portrait
            else if ratio < 1 {
                if ratio < 0.44 {
                    // extremely tall (more than the iPhone 14 Pro Max ratio)
                    imageWidthConstraint = imageView.widthAnchor.constraint(equalTo: self.widthAnchor)
                    imageWidthConstraint!.priority = .defaultHigh
                    imageWidthConstraint!.isActive = true
                    
                    imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 420)
                    imageHeightConstraint!.priority = .defaultHigh
                    imageHeightConstraint!.isActive = true
                    
                } else {
                    // most portrait images
                    imageWidthConstraint = imageView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor)
                    imageWidthConstraint!.priority = .required
                    imageWidthConstraint!.isActive = true
                    
                    imageHeightConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1 / ratio)
                    imageHeightConstraint!.priority = .defaultHigh
                    imageHeightConstraint!.isActive = true
                    
                    maxHeightConstraint = imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 420)
                    maxHeightConstraint!.priority = .required
                    maxHeightConstraint!.isActive = true
                }
            }
        }
        
        super.updateConstraints()
    }
    
    public func configure(postCard: PostCardModel) {
        let shouldUpdate = self.media == nil || postCard.mediaAttachments.first != self.media!
        
        if let media = postCard.mediaAttachments.first {
            self.media = media
            if let previewURL = media.previewURL, let imageURL = URL(string: previewURL) {
                
                self.imageView.ma_setImage(with: imageURL,
                                                  cachedImage: postCard.decodedImages[previewURL] as? UIImage,
                                                  imageTransformer: PostCardImage.transformer) { image in
                    postCard.decodedImages[previewURL] = image
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
            self.setNeedsUpdateConstraints()
        }
    }
    
    @objc func onPress() {
        if let originImage = imageView.image {
            
            let photo: SKPhoto = {
                if let url = media?.previewURL {
                    let photo = SKPhoto.photoWithImageURL(url)
                    photo.shouldCachePhotoURLImage = true
                    return photo
                }
                return SKPhoto()
            }()
            
            let browser = SKPhotoBrowser(originImage: originImage, photos: [photo], animatedFromView: imageView, imageText: media?.description ?? "", imageText2: 0, imageText3: 0, imageText4: "")
            SKPhotoBrowserOptions.enableSingleTapDismiss = false
            SKPhotoBrowserOptions.displayCounterLabel = false
            SKPhotoBrowserOptions.displayBackAndForwardButton = false
            SKPhotoBrowserOptions.displayAction = false
            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
            SKPhotoBrowserOptions.displayCloseButton = false
            SKPhotoBrowserOptions.displayStatusbar = false
            browser.initializePageIndex(0)
            getTopMostViewController()?.present(browser, animated: true, completion: {})
        }
    }
    
    @objc func altPress() {
        if let altTextPopup = self.media?.description {
            triggerHapticImpact(style: .light)
            let alert = UIAlertController(title: nil, message: altTextPopup, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Copy", style: .default , handler:{ (UIAlertAction) in
                let pasteboard = UIPasteboard.general
                pasteboard.string = altTextPopup
            }))
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel , handler:{ (UIAlertAction) in

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
