//
//  PostCardVideo.swift
//  Mammoth
//
//  Created by Benoit Nolens on 02/10/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import AVFoundation

final class PostCardVideo: UIView {
    
    enum PostCardVideoVariant {
        case fullSize
        case thumbnail
    }
    
    private var videoView: UIView = {
        let videoView = UIView()
        videoView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        videoView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        videoView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        videoView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        videoView.backgroundColor = .custom.OVRLYSoftContrast
        videoView.translatesAutoresizingMaskIntoConstraints = false
        return videoView
    }()
    
    private var sensitiveContentOverlay: UIButton = {
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
    private var onPressGesture: UITapGestureRecognizer!
    
    private var muteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.isHidden = true
        button.accessibilityElementsHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = .zero
        button.imageView?.contentMode = .center
        
        let bg = BlurredBackground(dimmed: false)
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.layer.cornerCurve = .continuous
        bg.layer.cornerRadius = 12
        bg.clipsToBounds = true
        button.insertSubview(bg, belowSubview: button.imageView!)
        
        NSLayoutConstraint.activate([
            bg.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            bg.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            bg.widthAnchor.constraint(equalToConstant: 24),
            bg.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return button
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
    
    private var previewImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private let loadingIndicator = UIActivityIndicatorView()
    private var playerStatusObserver: NSKeyValueObservation?
    private var playerRateObserver: NSKeyValueObservation?
    private var playerMuteObserver: NSKeyValueObservation?
    private var playerLoopObserver: NSObjectProtocol?
    
    private var loopCount: Int = 0
    private let maxLoopCount: Int = 8
    
    private var systemPausedOverlayLarge: UIButton = {
        
        let button = UIButton(type: .custom)
        button.isHidden = true
        button.setTitle("", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        let icon = UIImageView(image: FontAwesome.image(fromChar: "\u{f04b}", color: .custom.linkText, size: 16, weight: .bold).withRenderingMode(.alwaysTemplate))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .center
        iconView.addSubview(icon)
        
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconView.centerXAnchor, constant: 1),
            icon.centerYAnchor.constraint(equalTo: iconView.centerYAnchor)
        ])

        let bg = UIView()
        bg.backgroundColor = .custom.OVRLYSoftContrast.withAlphaComponent(0.3)
        button.insertSubview(bg, belowSubview: button.imageView!)
        bg.pinEdges()
        
        return button

    }()
    
    private var systemPausedOverlayThumbnail: UIButton = {
        
        let button = UIButton(type: .custom)
        button.isHidden = true
        button.setTitle("", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = BlurredBackground(dimmed: false)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 4
        iconView.clipsToBounds = true
        
        button.insertSubview(iconView, aboveSubview: button.imageView!)
        
        NSLayoutConstraint.activate([
            iconView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -3),
            iconView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -3),
            iconView.widthAnchor.constraint(equalToConstant: 15),
            iconView.heightAnchor.constraint(equalToConstant: 15),
        ])
        
        let icon = UIImageView(image: FontAwesome.image(fromChar: "\u{f04b}", color: .custom.linkText, size: 8, weight: .bold).withRenderingMode(.alwaysTemplate))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .center
        iconView.addSubview(icon)
        
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconView.centerXAnchor, constant: 0.5),
            icon.centerYAnchor.constraint(equalTo: iconView.centerYAnchor, constant: 0.25)
        ])
        
        return button

    }()
    
    private lazy var systemPausedOverlay: (_ variant: PostCardVideoVariant) -> UIButton = { variant in
        switch variant {
        case .fullSize:
            return self.systemPausedOverlayLarge
        case .thumbnail:
            return self.systemPausedOverlayThumbnail
        }
    }
    
    private var isSystemPaused: Bool = false
        
    private var postCard: PostCardModel?
    private var media: Attachment?
    private var isSensitive: Bool = false
    private let variant: PostCardVideoVariant
    
    // A dynamic width is used when the view has a fixed height (as in the gallery)
    private var dynamicWidthConstraint: NSLayoutConstraint?
    // A dynamic height is used when the view has a max width (as in standalone image in post card cell)
    private var dynamicHeightConstraint: NSLayoutConstraint?
    
    private let tallAspectRatio = 0.44
    
    private lazy var squareConstraints: [NSLayoutConstraint] = {
        let c1 = videoView.widthAnchor.constraint(equalTo: videoView.heightAnchor)
        c1.priority = .defaultHigh

        let c2 = videoView.heightAnchor.constraint(equalTo: videoView.widthAnchor)
        c2.priority = .defaultHigh
        
        let c3 = videoView.heightAnchor.constraint(equalTo: self.heightAnchor)
        c3.priority = .required
        
        return [c1, c2, c3]
    }()
    
    private lazy var portraitConstraints: [NSLayoutConstraint] = {
        // most landscape images
        if self.inGallery {
            let c1 = videoView.heightAnchor.constraint(equalTo: self.heightAnchor)
            c1.priority = .defaultLow

            let c2 = videoView.widthAnchor.constraint(lessThanOrEqualTo: self.heightAnchor, multiplier: tallAspectRatio)
            c2.priority = .defaultHigh
            
            return [c1, c2]
        } else {
            let c1 = videoView.widthAnchor.constraint(equalTo: self.widthAnchor)
            c1.priority = .defaultHigh

            let c2 = videoView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
            c2.priority = .required
            
            return [c1, c2]
        }
    }()
    
    private lazy var tallPortraitConstraints: [NSLayoutConstraint] = {
        if self.inGallery {
            // extremely tall (more than the iPhone 14 Pro Max ratio)
            let c1 = videoView.heightAnchor.constraint(equalTo: self.heightAnchor)
            c1.priority = .defaultLow
            
            let c2 = videoView.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: 9.0/16.0)
            c2.priority = .required
            
            return [c1, c2]
        } else {
            // extremely tall (more than the iPhone 14 Pro Max ratio)
            let c1 = videoView.widthAnchor.constraint(equalTo: self.widthAnchor)
            c1.priority = .defaultHigh
            
            let c2 = videoView.heightAnchor.constraint(equalToConstant: 420)
            c2.priority = .defaultHigh
            
            return [c1, c2]
        }
    }()
    
    private lazy var landscapeConstraints: [NSLayoutConstraint] = {
        if self.inGallery {
            let c1 = videoView.heightAnchor.constraint(equalTo: self.heightAnchor)
            c1.priority = .required
            
            let c2 = videoView.widthAnchor.constraint(lessThanOrEqualTo: self.heightAnchor, multiplier: 16.0/9.0)
            c2.priority = .required
            
            return [c1, c2]
        } else {
            let c1 = videoView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor)
            c1.priority = .required
            
            let c2 = videoView.heightAnchor.constraint(lessThanOrEqualToConstant: 420)
            c2.priority = .required
            
            return [c1, c2]
        }
    }()
    
    private let inGallery: Bool
    
    init(variant: PostCardVideoVariant = .fullSize, inGallery: Bool = false) {
        self.variant = variant
        self.inGallery = inGallery
        super.init(frame: .zero)
        self.setupUI()
        
        NotificationCenter.default.addObserver(self, 
                                               selector: #selector(self.stoppedBySystem),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
    }
    
    deinit {
        self.removeLoopObserver()
        NotificationCenter.default.removeObserver(self)
        playerStatusObserver?.invalidate()
        playerRateObserver?.invalidate()
        playerMuteObserver?.invalidate()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        self.postCard = nil
        self.media = nil
        self.isSensitive = false
        self.dismissedSensitiveOverlay = false
        self.onPressGesture.isEnabled = true
        self.isSystemPaused = false
        self.systemPausedOverlay(self.variant).isHidden = true
        
        playerRateObserver?.invalidate()
        playerStatusObserver?.invalidate()
        playerMuteObserver?.invalidate()

        self.removeLoopObserver()
        loopCount = 0

        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
  
        previewImage.sd_cancelCurrentImageLoad()
        previewImage.image = nil
        
        
        if let _ = self.videoView.subviews.firstIndex(of: self.sensitiveContentOverlay) {
            self.sensitiveContentOverlay.removeFromSuperview()
        }
    }
    
    private func setupUI() {
        self.isOpaque = true
        self.layoutMargins = .init(top: 3, left: 0, bottom: 0, right: 0)

        videoView.clipsToBounds = true
        videoView.layer.cornerRadius = 6
        videoView.layer.cornerCurve = .continuous
        videoView.layoutMargins = .zero
        videoView.isUserInteractionEnabled = true
        self.addSubview(videoView)
                
        videoView.addSubview(previewImage)
        videoView.addSubview(loadingIndicator)
        videoView.addSubview(systemPausedOverlay(self.variant))

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        loadingIndicator.hidesWhenStopped = true
        
        self.addSubview(muteButton)
        self.addSubview(altButton)
        
        switch self.variant {
        case .fullSize:
            self.altButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            self.altButton.contentEdgeInsets = .init(top: 3, left: 5, bottom: 2, right: 5)
        case .thumbnail:
            self.altButton.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
            self.altButton.contentEdgeInsets = .init(top: 3, left: 5, bottom: 2, right: 5)
        }
        
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: self.topAnchor),
            videoView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            videoView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            previewImage.topAnchor.constraint(equalTo: videoView.topAnchor),
            previewImage.bottomAnchor.constraint(equalTo: videoView.bottomAnchor),
            previewImage.leadingAnchor.constraint(equalTo: videoView.leadingAnchor),
            previewImage.trailingAnchor.constraint(equalTo: videoView.trailingAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: videoView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: videoView.centerYAnchor),
            
            systemPausedOverlay(self.variant).topAnchor.constraint(equalTo: videoView.topAnchor),
            systemPausedOverlay(self.variant).bottomAnchor.constraint(equalTo: videoView.bottomAnchor),
            systemPausedOverlay(self.variant).leadingAnchor.constraint(equalTo: videoView.leadingAnchor),
            systemPausedOverlay(self.variant).trailingAnchor.constraint(equalTo: videoView.trailingAnchor),
            altButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: self.variant == .fullSize ? -10 : -2),
            altButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: self.variant == .fullSize ? -10 : -2),
        ])
        
        if self.variant == .thumbnail {
            altButton.isHidden = true
            NSLayoutConstraint.activate([
                muteButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                muteButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                muteButton.widthAnchor.constraint(equalToConstant: 40),
                muteButton.heightAnchor.constraint(equalToConstant: 40),
            ])
        } else {
            altButton.isHidden = false
            NSLayoutConstraint.activate([
                muteButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -2),
                muteButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 2),
                muteButton.widthAnchor.constraint(equalToConstant: 40),
                muteButton.heightAnchor.constraint(equalToConstant: 40),
            ])
        }
                
        self.onPressGesture = UITapGestureRecognizer(target: self, action: #selector(self.onPress))
        self.addGestureRecognizer(self.onPressGesture)
        
        let mutePress = UITapGestureRecognizer(target: self, action: #selector(self.mutePress))
        self.muteButton.addGestureRecognizer(mutePress)
        
        let altPress = UITapGestureRecognizer(target: self, action: #selector(self.altPress))
        self.altButton.addGestureRecognizer(altPress)
        
        let systemPausedPress = UITapGestureRecognizer(target: self, action: #selector(self.systemPausedPress))
        self.systemPausedOverlay(self.variant).addGestureRecognizer(systemPausedPress)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = videoView.bounds
    }
    
    public func configure(video: Attachment?, postCard: PostCardModel, cachedPlayer: AVPlayer? = nil) {
        let shouldUpdate = self.media == nil || video != self.media!
        self.isSensitive = postCard.isSensitive
        self.postCard = postCard
        
        if let media = video {
            guard self.media != media else { return }
            
            self.media = media
            if let videoURL = URL(string: media.remoteURL ?? media.url), let previewImageURL = URL(string: media.previewURL ?? "") {
                
                loadingIndicator.startAnimating()
                previewImage.sd_setImage(with: previewImageURL)
                
                if let cachedPlayer = cachedPlayer {
                    // if the player is preloaded
                    player = cachedPlayer
                    
                    if let currentItem = player?.currentItem {
                        if currentItem.status == .readyToPlay {
                            if cachedPlayer.isPlaying() {
                                self.play()
                            } else if !self.isSensitive && !self.isSystemPaused && GlobalStruct.autoPlayVideos {
                                self.play()
                            }
                        } else if !self.isSensitive && GlobalStruct.autoPlayVideos {
                            self.observePlayerStatus(currentItem)
                        }
                    }
      
                    if loadingIndicator.isAnimating {
                        loadingIndicator.stopAnimating()
                    }
                } else {
                    // if no player is preloaded
                    let item = AVPlayerItem(url: videoURL)
                    player = AVPlayer(playerItem: item)
                    player?.isMuted = true
                    self.observePlayerStatus(item)
                    postCard.videoPlayer = player
                }
                
                // if the player is not already playing - make sure it doesn't auto-plays
                // if the sensitive overlay is visible or auto-play is enabled
                if !player!.isPlaying() && ((self.isSensitive && !self.dismissedSensitiveOverlay) || !GlobalStruct.autoPlayVideos) {
                    self.pause()
                }
                
                if playerLayer != nil {
                    if let _ = videoView.layer.sublayers?.firstIndex(of: playerLayer!) {
                        playerLayer?.removeFromSuperlayer()
                    }
                }
                
                self.playerRateObserver?.invalidate()
                self.observePlayerRate(player!)
                self.playerMuteObserver?.invalidate()
                self.observePlayerMuteState(player!)
                
                // sync mute button state
                if self.player!.isMuted {
                    self.muteButton.setImage(FontAwesome.image(fromChar: "\u{f6a9}", color: .custom.linkText, size: 11, weight: .bold).withRenderingMode(.alwaysTemplate), for: .normal)
                } else {
                    self.muteButton.setImage(FontAwesome.image(fromChar: "\u{f6a8}", color: .custom.linkText, size: 11, weight: .bold).withRenderingMode(.alwaysTemplate), for: .normal)
                }
                
                playerLayer = AVPlayerLayer(player: player)
                playerLayer?.videoGravity = .resizeAspectFill
                playerLayer?.frame = videoView.bounds
                
                videoView.layer.addSublayer(playerLayer!)

                self.videoView.bringSubviewToFront(self.systemPausedOverlay(self.variant))
                self.videoView.bringSubviewToFront(self.sensitiveContentOverlay)
            }
            
            if shouldUpdate {
                // the aspect value might be nil
                if self.media?.meta?.original?.aspect == nil {
                    self.media?.meta?.original?.aspect = Double(self.media?.meta?.original?.width ?? 10) / Double(self.media?.meta?.original?.height ?? 10)
                }
        
                if let ratio = self.media?.meta?.original?.aspect {
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
                                self.dynamicWidthConstraint = videoView.widthAnchor.constraint(equalTo: videoView.heightAnchor, multiplier: ratio)
                                self.dynamicWidthConstraint!.priority = .defaultHigh + 1
                                self.dynamicWidthConstraint!.isActive = true
                            }
                        } else {
                            self.dynamicHeightConstraint = videoView.heightAnchor.constraint(equalTo: videoView.widthAnchor, multiplier: 1.0 / ratio)
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
                                self.dynamicWidthConstraint = videoView.widthAnchor.constraint(equalTo: videoView.heightAnchor, multiplier: ratio)
                                self.dynamicWidthConstraint!.priority = .defaultHigh
                                self.dynamicWidthConstraint!.isActive = true
                            } else {
                                self.dynamicHeightConstraint = videoView.heightAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1.0 / ratio)
                                self.dynamicHeightConstraint!.priority = .defaultHigh
                                self.dynamicHeightConstraint!.isActive = true
                            }
                            
                            NSLayoutConstraint.activate(self.portraitConstraints)
                        }
                    }
                }
                
                if GlobalStruct.blurSensitiveContent && self.isSensitive && !self.dismissedSensitiveOverlay {
                    self.sensitiveContentOverlay.frame = self.videoView.bounds
                    self.sensitiveContentOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    self.sensitiveContentOverlay.alpha = 1
                    
                    if self.hideSensitiveOverlayGesture == nil {
                        self.hideSensitiveOverlayGesture = UITapGestureRecognizer(target: self, action: #selector(self.hideSensitiveOverlay))
                        self.sensitiveContentOverlay.addGestureRecognizer(self.hideSensitiveOverlayGesture!)
                    }
                    
                    self.videoView.addSubview(self.sensitiveContentOverlay)
                }
                
                if let description = media.description, !description.isEmpty, media.type == .gifv {
                    self.altButton.isHidden = false
                    self.bringSubviewToFront(self.altButton)
                } else {
                    self.altButton.isHidden = true
                }
            }
        }
    }
    
    public func configure(postCard: PostCardModel) {
        if let firstVideo = postCard.mediaAttachments.first, [.video, .gifv].contains(firstVideo.type) {
            self.configure(video: firstVideo, postCard: postCard, cachedPlayer: postCard.videoPlayer)
        }
    }
    
    private func deactivateAllImageConstraints() {
        NSLayoutConstraint.deactivate(self.squareConstraints
                                      + self.portraitConstraints
                                      + self.tallPortraitConstraints
                                      + self.landscapeConstraints
                                      + [self.dynamicHeightConstraint, self.dynamicWidthConstraint].compactMap({$0})
        )
    }
    
    @objc public func play() {
        self.systemPausedOverlay(self.variant).isHidden = true
        self.isSystemPaused = false
        self.loopCount = 0
        self.showMuteButton()
        
        self.addLoopObserver()
        
        if let player, !player.isPlaying(), (!self.isSensitive || self.dismissedSensitiveOverlay) {
            player.play()
        }
        
        if loadingIndicator.isAnimating {
            loadingIndicator.stopAnimating()
        }
    }
    
    public func pause() {
        self.isSystemPaused = true
        self.systemPausedOverlay(self.variant).isHidden = false
        self.hideMuteButton()
        if let player = self.player, player.isPlaying() {
            player.pause()
        }
    }
    
    @objc public func stoppedBySystem() {
        self.isSystemPaused = true
        self.systemPausedOverlay(self.variant).isHidden = false
        self.hideMuteButton()
        
        self.loopCount = 0
        self.player?.seek(to: CMTime.zero)
        self.player?.pause()
    }
    
    private func addLoopObserver() {
        if let observer = self.playerLoopObserver {
            NotificationCenter.default.removeObserver(observer)
            self.playerLoopObserver = nil
        }
        
        self.playerLoopObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { [weak self] _ in
            guard let self else { return }

            if UIApplication.shared.applicationState == .active {
                if let media = self.media, media.type == .video, self.loopCount >= self.maxLoopCount {
                    self.stoppedBySystem()
                } else if !self.isSystemPaused {
                    self.loopCount += 1
                    self.player?.seek(to: CMTime.zero)
                    self.player?.play()
                }
            } else {
                self.stoppedBySystem()
            }
        }
    }
    
    private func removeLoopObserver() {
        if let observer = self.playerLoopObserver {
            NotificationCenter.default.removeObserver(observer)
            self.playerLoopObserver = nil
        }
    }
    
    private func observePlayerStatus(_ playerItem: AVPlayerItem) {
        playerStatusObserver = playerItem.observe(\AVPlayerItem.status) { [weak self] (playerItem, _) in
            guard let self else { return }
            if playerItem.status == .readyToPlay {
                if let player, !player.isPlaying(), !self.isSensitive, !self.isSystemPaused {
                    player.play()
                }
                
                if self.loadingIndicator.isAnimating {
                    self.loadingIndicator.stopAnimating()
                }
            }
        }
    }
    
    private func observePlayerRate(_ player: AVPlayer) {
        playerRateObserver = player.observe(\AVPlayer.rate) { [weak self] (player, _) in
            guard let self else { return }
            if player.rate.isZero {
                // Paused
                // When looping - rates switch from paused to playing at the end of each cycle.
                // To prevent the overlay to flash on each cycle we add this delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let player = self.player, !player.isPlaying() && self.systemPausedOverlay(self.variant).isHidden {
                        self.systemPausedOverlay(self.variant).isHidden = false
                        self.hideMuteButton()
                    }
                }
            } else {
                // Playing
                if !self.systemPausedOverlay(self.variant).isHidden {
                    self.systemPausedOverlay(self.variant).isHidden = true
                    self.showMuteButton()
                }
            }
        }
    }
    
    private func observePlayerMuteState(_ player: AVPlayer) {
        playerMuteObserver = player.observe(\AVPlayer.isMuted) { [weak self] (player, _) in
            guard let self else { return }
            if player.isMuted {
                self.muteButton.setImage(FontAwesome.image(fromChar: "\u{f6a9}", color: .custom.linkText, size: 11, weight: .bold).withRenderingMode(.alwaysTemplate), for: .normal)
            } else {
                self.muteButton.setImage(FontAwesome.image(fromChar: "\u{f6a8}", color: .custom.linkText, size: 11, weight: .bold).withRenderingMode(.alwaysTemplate), for: .normal)
            }
        }
    }
    
    @objc func onPress() {
        if let player = self.player, let media = self.media, [.video, .gifv].contains(media.type) {
            let vc = CustomVideoPlayer()
            vc.allowsPictureInPicturePlayback = true
            vc.player = player
            vc.altText = media.description ?? ""
            GlobalStruct.inVideoPlayer = true
            getTopMostViewController()?.present(vc, animated: true) {
                vc.player?.play()
            }
        }
    }
    
    private func showMuteButton() {
        if let media = self.media {
            if media.type == .video {
                self.muteButton.isHidden = false
            } else if media.type == .gifv {
                self.muteButton.isHidden = true
            }
        }
    }
    
    private func hideMuteButton() {
        self.muteButton.isHidden = true
    }
    
    private func mute(_ player: AVPlayer) {
        player.isMuted = true
    }
    
    private func unmute(_ player: AVPlayer) {
        player.isMuted = false
    }
    
    @objc func systemPausedPress() {
        if self.variant == .thumbnail {
            self.onPress()
        } else {
            if let player = self.player {
                self.play()
                AVManager.shared.currentPlayer = player
                self.unmute(player)
            }
        }
    }
    
    @objc func mutePress() {
        if let player = self.player {
            
            if player.isMuted && player.currentItem?.tracks.first(where: { $0.assetTrack?.mediaType == .audio}) == nil {
                let alertController = UIAlertController(title: "This video has no sound", message: nil, preferredStyle: .alert)
                let okAction = UIAlertAction(title: NSLocalizedString("generic.ok", comment: ""), style: .default)
                alertController.addAction(okAction)
                getTopMostViewController()?.present(alertController, animated: true, completion: nil)
                return
            }
            
            if player.isMuted {
                self.unmute(player)
                AVManager.shared.currentPlayer = player
            } else {
                self.mute(player)
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
        UIView.animate(withDuration: 0.13) { [weak self] in
            self?.sensitiveContentOverlay.alpha = 0
        } completion: { [weak self] _ in
            self?.sensitiveContentOverlay.removeFromSuperview()
        }
        
        self.play()
    }
}
