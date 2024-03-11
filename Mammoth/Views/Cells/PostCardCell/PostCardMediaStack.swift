//
//  PostCardMediaStack.swift
//  Mammoth
//
//  Created by Benoit Nolens on 12/01/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit
import SDWebImage
import UnifiedBlurHash
import AVFoundation

final class PostCardMediaStack: UIView {
    
    enum PostCardImageStackVariant {
        case fullSize
        case thumbnail
    }
    
    private var imageView = PostCardImage(variant: .thumbnail)
    private var videoView = PostCardVideo(variant: .thumbnail)
    private var backgroundCard = {
        let view = UIImageView()
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        view.layer.shouldRasterize = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.transform = CGAffineTransformConcat(
            .init(rotationAngle: CGFloat((Float.pi / 180.0)) * 9),
            .init(translationX: 3, y: 0)
            )
        
        let overlay = UIView()
        overlay.backgroundColor = UIColor(red: 86.0/255.0, green: 86.0/255.0, blue: 86.0/255.0, alpha: 0.20)
        view.addSubview(overlay)
        overlay.pinEdges()
        
        return view
    }()
    
    private var media: Attachment?
    private var postCard: PostCardModel?
    private let variant: PostCardImageStackVariant
    
    init(variant: PostCardImageStackVariant = .thumbnail) {
        self.variant = variant
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        self.media = nil
        self.postCard = nil
        self.imageView.prepareForReuse()
        self.videoView.prepareForReuse()
        self.backgroundCard.sd_cancelCurrentImageLoad()
        self.backgroundCard.image = nil
        self.backgroundCard.isHidden = false
    }
    
    private func setupUI() {
        self.isOpaque = true
        self.layoutMargins = .zero
        self.isUserInteractionEnabled = true
        
        self.addSubview(self.backgroundCard)
        self.addSubview(self.imageView)
        self.addSubview(self.videoView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.onPress))
        self.addGestureRecognizer(tapGesture)
        
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.videoView.translatesAutoresizingMaskIntoConstraints = false
                
        self.imageView.layer.shadowColor = UIColor.black.cgColor
        self.imageView.layer.shadowPath = UIBezierPath(roundedRect: .init(origin: .zero, size: .init(width: 56, height: 56)), cornerRadius: 6).cgPath
        self.imageView.layer.shadowOpacity = 0.4
        self.imageView.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        self.imageView.layer.shadowRadius = 2
        self.imageView.backgroundColor = .clear
        self.imageView.isUserInteractionEnabled = false

        self.videoView.layer.shadowColor = UIColor.black.cgColor
        self.videoView.layer.shadowPath = UIBezierPath(roundedRect: .init(origin: .zero, size: .init(width: 56, height: 56)), cornerRadius: 6).cgPath
        self.videoView.layer.shadowOpacity = 0.4
        self.videoView.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        self.videoView.layer.shadowRadius = 2
        self.videoView.backgroundColor = .clear
        self.videoView.isUserInteractionEnabled = false

        NSLayoutConstraint.activate([
            self.imageView.widthAnchor.constraint(equalToConstant: 56),
            self.imageView.heightAnchor.constraint(equalToConstant: 56),
            self.imageView.topAnchor.constraint(equalTo: self.topAnchor),
            self.imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            
            self.videoView.widthAnchor.constraint(equalToConstant: 56),
            self.videoView.heightAnchor.constraint(equalToConstant: 56),
            self.videoView.topAnchor.constraint(equalTo: self.topAnchor),
            self.videoView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            
            self.backgroundCard.widthAnchor.constraint(equalToConstant: 56),
            self.backgroundCard.heightAnchor.constraint(equalToConstant: 56),
            self.backgroundCard.topAnchor.constraint(equalTo: self.topAnchor),
            self.backgroundCard.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.backgroundCard.leadingAnchor.constraint(equalTo: self.leadingAnchor),
        ])
    }
    
    public func configure(postCard: PostCardModel) {
        let shouldUpdate = self.media == nil || postCard.mediaAttachments.first != self.media!
        self.media = postCard.mediaAttachments.first
        self.postCard = postCard
        
        if postCard.isPrivateMention {
            self.backgroundColor = .custom.OVRLYSoftContrast
        } else {
            self.backgroundColor = .custom.background
        }
        
        if shouldUpdate {
            if let media = self.media {
                if media.type == .image {
                    self.imageView.configure(postCard: postCard)
                    self.imageView.isHidden = false
                    self.videoView.isHidden = true
                }
                
                if media.type == .video || media.type == .gifv || media.type == .audio {
                    self.videoView.configure(postCard: postCard)
                    self.videoView.isHidden = false
                    self.imageView.isHidden = true
                    
                    self.videoView.pause()
                    
                    // Audio is currenlty using a carousel view in large-mode.
                    // To make this work in small-mode using this image stack
                    // we hide the backgroundCard if it's an audio track alone.
                    // FIX: when audio has it's own view
                    if media.type == .audio && postCard.mediaAttachments.count == 1 {
                        self.backgroundCard.isHidden = true
                    }
                }
                
                if let second = (postCard.mediaAttachments.count > 1 ? postCard.mediaAttachments[1] : nil), let blurHash = second.blurhash {
                    let blurImage = UnifiedImage(blurHash: blurHash, size: .init(width: 32, height: 32))
                    self.backgroundCard.image = blurImage
                }
            }
        }
    }
    
    @objc func onPress() {
        if let originImage = imageView.image {

            // Open fullscreen image preview
            let images = self.postCard?.mediaAttachments.compactMap { attachment in
                guard attachment.type == .image else { return SKPhoto() }
                let photo = SKPhoto.photoWithImageURL(attachment.url)
                photo.shouldCachePhotoURLImage = false
                
                let imageFromCache = SDImageCache.shared.imageFromCache(forKey: attachment.url)
                let previewFromCache = SDImageCache.shared.imageFromCache(forKey: attachment.previewURL)
                
                var blurImage: UIImage? = nil
                if let blurhash = attachment.blurhash, imageFromCache == nil, let currentMedia = self.media, attachment.url != currentMedia.url {
                    let blurWidth = attachment.meta?.original?.width != nil ? attachment.meta!.original!.width! / 20 : 32
                    let blurHeight = attachment.meta?.original?.height != nil ? attachment.meta!.original!.height! / 20 : 32
                    blurImage = UnifiedImage(blurHash: blurhash, size: .init(width: blurWidth, height: blurHeight))
                }
                photo.underlyingImage = imageFromCache ?? previewFromCache ?? blurImage
                return photo
            } ?? [SKPhoto()]
            
            let descriptions = self.postCard?.mediaAttachments.map { $0.description ?? "" } ?? []
            
            let browser = SKPhotoBrowser(originImage: originImage,
                                         photos: images,
                                         animatedFromView: self.imageView,
                                         descriptions: descriptions,
                                         currentIndex: 0)
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
            
            // Preload other images
            PostCardModel.imageDecodeQueue.async { [weak self] in
                guard let self else { return }
                let prefetcher = SDWebImagePrefetcher.shared
                let urls = self.postCard?.mediaAttachments.compactMap { URL(string: $0.url) }
                prefetcher.prefetchURLs(urls, progress: nil) { _, _ in
                    let images = self.postCard?.mediaAttachments.compactMap { attachment in
                        guard attachment.type == .image else { return nil }
                        let photo = SKPhoto.photoWithImageURL(attachment.url)
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
            
        } else {
            
            // Open fullscreen video player
            if let mediaURLString = self.media?.url {
                if let mediaURL = URL(string: mediaURLString) {
                    let player = AVPlayer(url: mediaURL)
                    
                    let vc = CustomVideoPlayer()
                    vc.allowsPictureInPicturePlayback = true
                    vc.player = player
                    vc.altText = self.media?.description ?? ""
                    GlobalStruct.inVideoPlayer = true
                    getTopMostViewController()?.present(vc, animated: true) {
                        vc.player?.play()
                    }
                }
            }
        }
    }
}
