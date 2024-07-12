//
//  PostCardImageAttachment.swift
//  Mammoth
//
//  Created by Benoit Nolens on 26/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit

class PostCardImageAttachment: UIView, AVPlayerViewControllerDelegate {
    
    static let largeImageHeight = 220.0
    // largeImageWidth determined by self.view.bounds.width
    static let gapBetweenLargeImages = 20.0

    // Keep a cache of the current image index
    static var URLToCurrentIndexCache: [String:Int] = [:]
    
    // MARK: - Properties
    private var cellHeightConstraint: NSLayoutConstraint?
    private var standardLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0 // horizontal gap between cells
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 1.0, height: largeImageHeight)
        return layout
    }()
    private var imageCollectionView: UICollectionView = {
        var imageCollectionView: UICollectionView
        var placeholderLayout = UICollectionViewLayout()
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            imageCollectionView = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(GlobalStruct.padColWidth), height: largeImageHeight), collectionViewLayout: placeholderLayout)
        } else {
            imageCollectionView = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: 50.0 /*CGFloat(UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) */, height: largeImageHeight), collectionViewLayout: placeholderLayout)
        }
        imageCollectionView.translatesAutoresizingMaskIntoConstraints = false
        imageCollectionView.showsHorizontalScrollIndicator = false
        imageCollectionView.isPagingEnabled = true
        imageCollectionView.register(PostCardImageCollectionCell.self, forCellWithReuseIdentifier: "PostCardImageCollectionCell")
        imageCollectionView.register(PostCardImageCollectionCellSmall.self, forCellWithReuseIdentifier: "PostCardImageCollectionCellSmall")
        imageCollectionView.accessibilityIdentifier = "imageCollectionView"
//        imageCollectionView.dragDelegate = self
        imageCollectionView.backgroundColor = .clear
        imageCollectionView.layer.masksToBounds = false
        return imageCollectionView
    }()
    
    private var countButton: UIButton = {
        let countButton = UIButton()
        countButton.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption2).pointSize + GlobalStruct.customTextSize, weight: .bold)
        countButton.setTitleColor(.custom.active, for: .normal)
        countButton.sizeToFit()
        countButton.translatesAutoresizingMaskIntoConstraints = false
        countButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        countButton.heightAnchor.constraint(equalToConstant: 23).isActive = true
        countButton.layer.cornerCurve = .continuous
        countButton.layer.cornerRadius = 7
        countButton.clipsToBounds = true
        
        let bg = BlurredBackground(dimmed: false)
        countButton.insertSubview(bg, belowSubview: countButton.titleLabel!)
        bg.pinEdges()
        
        countButton.clipsToBounds = true
        
        return countButton
    }()
    
    // Data from the postCard
    var mediaAttachments: [Attachment] = []
    var isSensitive = false
    var collectionCellModels: [PostCardImageCollectionCellModel] = []
    var statusURI: String = ""
    var currentImageIndex: Int = 0
    var configuringCell = false
    
    var hasRoundedCorners = true
    
    override init(frame: CGRect) {
       super.init(frame: frame)
       self.setupUI()
   }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // In setupUI(), imageCollectionView.bounds.width is not known yet, and so
        // setting the layout.itemSize is done here.
        cellHeightConstraint?.constant = PostCardImageAttachment.largeImageHeight
        standardLayout.itemSize = CGSize(width: imageCollectionView.bounds.width, height: PostCardImageAttachment.largeImageHeight)
        imageCollectionView.collectionViewLayout = standardLayout
    }
    
}

// MARK: - Setup UI
private extension PostCardImageAttachment {
    func setupUI() {
        self.isOpaque = true
        self.backgroundColor = .custom.background
        self.addSubview(imageCollectionView)
        imageCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageCollectionView.topAnchor.constraint(equalTo: self.topAnchor, constant: 4),
            imageCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: -PostCardImageAttachment.gapBetweenLargeImages),
            imageCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])

        let height = PostCardImageAttachment.largeImageHeight
        cellHeightConstraint = imageCollectionView.heightAnchor.constraint(equalToConstant: height)
        cellHeightConstraint?.priority = UILayoutPriority(rawValue: 999)
        cellHeightConstraint?.isActive = true
        imageCollectionView.delegate = self
        imageCollectionView.dataSource = self
        
        self.addSubview(countButton)
        countButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            countButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
            countButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 10)
        ])
    }
    
}

// MARK: - Configuration
extension PostCardImageAttachment {
    func configure(postCard: PostCardModel, withRoundedCorners: Bool = true) {
        self.hasRoundedCorners = withRoundedCorners
        
        let status: Status?
        if case .mastodon(let s) = postCard.data {
            status = s
        } else {
            status = nil
        }
        
        configuringCell = true
        // Collect relevant info from the postCard
        isSensitive = status?.reblog?.sensitive ?? status?.sensitive ?? false
        mediaAttachments = postCard.mediaAttachments
        
        collectionCellModels = []
        for attachment in mediaAttachments {
            if attachment.previewURL != nil || attachment.type == .audio {
                let usesMediaPlayer = attachment.type == .video ||
                                      attachment.type == .gifv ||
                                      attachment.type == .audio
                // For every image, assure some alt text, even if a placeholder
                let desc = attachment.description ?? ""
                let model = PostCardImageCollectionCellModel(altText: desc, mediaAttachment: attachment, isSensitive: isSensitive, usesMediaPlayer: usesMediaPlayer, postCard: postCard)
                collectionCellModels.append(model)
            }
        }
        let showImageCount = collectionCellModels.count > 1
        countButton.alpha = showImageCount ? 1.0 : 0.0
        countButton.isUserInteractionEnabled = showImageCount
        if showImageCount {
            statusURI = status?.uri ?? ""
            currentImageIndex = PostCardImageAttachment.URLToCurrentIndexCache[statusURI] ?? 0
            countButton.setTitle("\(currentImageIndex + 1)/\(collectionCellModels.count)", for: .normal)
        } else {
            statusURI = ""
            currentImageIndex = 0
        }
        setNeedsLayout()
        imageCollectionView.reloadData()
        
        // Scroll to the relevant image
        imageCollectionView.scrollToItem(at: IndexPath(row: currentImageIndex, section: 0), at: .left, animated: false)

        configuringCell = false
    }
}

extension PostCardImageAttachment: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaAttachments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCardImageCollectionCell", for: indexPath) as! PostCardImageCollectionCell
        if !self.collectionCellModels.isEmpty {
            cell.configure(model: collectionCellModels[indexPath.item], withRoundedCorners: self.hasRoundedCorners)
            cell.altButton.tag = indexPath.item
            cell.altButton.addTarget(self, action: #selector(self.altTextTap), for: .touchUpInside)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = collectionCellModels[indexPath.item]
        
        if model.usesMediaPlayer {
            // Open fullscreen video player
            let mediaURLString = model.mediaAttachment.url ?? model.mediaAttachment.previewURL!
            
            if let mediaURL = URL(string: mediaURLString) {
                let player = AVPlayer(url: mediaURL)
                let vc = CustomVideoPlayer()
                vc.allowsPictureInPicturePlayback = true
                vc.player = player
                vc.altText = model.mediaAttachment.description ?? ""
                GlobalStruct.inVideoPlayer = true
                getTopMostViewController()?.present(vc, animated: true) {
                    vc.player?.play()
                }
            }
        } else {
            // Open fullscreen image preview
            let images = self.mediaAttachments.map { attachment in
                let photo = SKPhoto.photoWithImageURL(attachment.url ?? attachment.previewURL!)
                photo.shouldCachePhotoURLImage = true
                return photo
            }
            
            let descriptions = self.mediaAttachments.map { $0.description }
            
            if let cell = collectionView.cellForItem(at: indexPath) as? PostCardImageCollectionCell ??
                collectionView.cellForItem(at: indexPath) as? PostCardImageCollectionCellSmall,
                let originImage = cell.imageView.image {
                
                let browser = SKPhotoBrowser(originImage: originImage,
                                             photos: images,
                                             animatedFromView: cell.imageView,
                                             descriptions: descriptions,
                                             currentIndex: indexPath.item)
                SKPhotoBrowserOptions.enableSingleTapDismiss = false
                SKPhotoBrowserOptions.displayCounterLabel = false
                SKPhotoBrowserOptions.displayBackAndForwardButton = false
                SKPhotoBrowserOptions.displayAction = false
                SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
                SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
                SKPhotoBrowserOptions.displayCloseButton = false
                SKPhotoBrowserOptions.displayStatusbar = false
                browser.initializePageIndex(indexPath.row)
                getTopMostViewController()?.present(browser, animated: true, completion: {})
            }
        }
    }
    
    @objc func altTextTap(_ sender: UIButton) {
        triggerHapticImpact(style: .light)
        let altTextPopup = self.collectionCellModels[sender.tag].altText
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


extension PostCardImageAttachment: UICollectionViewDelegate {
    
    
//    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
//        return false
//    }

//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//
//        if collectionView == self.imageCollectionView {
//            // Handle video/audio player
//            if usesPlayer() {
//                showMediaPlayer()
//            }
//
//            // If this was an image, display it full screen
//
//
//            /*
//
//            else {
//                if dataImages.isEmpty {
//                    var images = [SKPhoto]()
//                    if let cell = self.imageCollectionView.cellForItem(at: indexPath) as? PostCardImageCollectionCell {
//                        if let originImage = cell.image.image {
//                            for x in self.imagesFull {
//                                let photo = SKPhoto.photoWithImageURL(x.url)
//                                photo.shouldCachePhotoURLImage = true
//                                images.append(photo)
//                            }
//                            var alt = ""
//                            if indexPath.item < self.altText.count {
//                                alt = self.altText[indexPath.item]
//                            }
//                            let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: cell.image, imageText: self.postText.text ?? "", imageText2: 0, imageText3: 0, imageText4: alt)
//                            browser.delegate = self
//                            SKPhotoBrowserOptions.enableSingleTapDismiss = false
//                            SKPhotoBrowserOptions.displayCounterLabel = false
//                            SKPhotoBrowserOptions.displayBackAndForwardButton = false
//                            SKPhotoBrowserOptions.displayAction = false
//                            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
//                            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
//                            SKPhotoBrowserOptions.displayCloseButton = false
//                            SKPhotoBrowserOptions.displayStatusbar = false
//                            browser.initializePageIndex(currentIndex)
//                            getTopMostViewController()?.present(browser, animated: true, completion: {})
//                        }
//                    }
//        } else {
//            if GlobalStruct.inlineVideos == false && self.videoUrlQ != "" && self.lpImage == UIImage() {
//                if let ur = URL(string: self.videoUrlQ) {
//                    let player = AVPlayer(url: ur)
//                    let vc = CustomVideoPlayer()
//                    vc.delegate = self
//                    vc.allowsPictureInPicturePlayback = true
//                    if GlobalStruct.loopVideos {
//                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { (_) in
//                            if UIApplication.shared.applicationState == .active {
//                                player.seek(to: CMTime.zero)
//                                player.play()
//                            }
//                        }
//                    }
//                    vc.player = player
//                    GlobalStruct.inVideoPlayer = true
//                    getTopMostViewController()?.present(vc, animated: true) {
//                        vc.player?.play()
//                    }
//                }
//            } else {
//                if linkDataImages.isEmpty {
//                    var images = [SKPhoto]()
//                    if let cell = self.linkCollectionView1.cellForItem(at: indexPath) as? PostCardImageCollectionCell {
//                        if let originImage = cell.image.image {
//                            for x in self.linkImages {
//                                let photo = SKPhoto.photoWithImageURL(x)
//                                photo.shouldCachePhotoURLImage = true
//                                images.append(photo)
//                            }
//                            var alt = ""
//                            if indexPath.item < self.altText.count {
//                                alt = self.altText[indexPath.item]
//                            }
//                            let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: cell.image, imageText: self.linkPost.text ?? "", imageText2: 0, imageText3: 0, imageText4: alt)
//                            browser.delegate = self
//                            SKPhotoBrowserOptions.enableSingleTapDismiss = false
//                            SKPhotoBrowserOptions.displayCounterLabel = false
//                            SKPhotoBrowserOptions.displayBackAndForwardButton = false
//                            SKPhotoBrowserOptions.displayAction = false
//                            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
//                            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
//                            SKPhotoBrowserOptions.displayCloseButton = false
//                            SKPhotoBrowserOptions.displayStatusbar = false
//                            browser.initializePageIndex(linkCurrentIndex)
//                            getTopMostViewController()?.present(browser, animated: true, completion: {})
//                        }
//                    }
//                    if let cell = self.linkCollectionView1.cellForItem(at: indexPath) as? CollectionImageCellActivity {
//                        if let originImage = cell.image.image {
//                            for x in self.linkImages {
//                                let photo = SKPhoto.photoWithImageURL(x)
//                                photo.shouldCachePhotoURLImage = true
//                                images.append(photo)
//                            }
//                            var alt = ""
//                            if indexPath.item < self.altText.count {
//                                alt = self.altText[indexPath.item]
//                            }
//                            let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: cell.image, imageText: self.linkPost.text ?? "", imageText2: 0, imageText3: 0, imageText4: alt)
//                            browser.delegate = self
//                            SKPhotoBrowserOptions.enableSingleTapDismiss = false
//                            SKPhotoBrowserOptions.displayCounterLabel = false
//                            SKPhotoBrowserOptions.displayBackAndForwardButton = false
//                            SKPhotoBrowserOptions.displayAction = false
//                            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
//                            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
//                            SKPhotoBrowserOptions.displayCloseButton = false
//                            SKPhotoBrowserOptions.displayStatusbar = false
//                            browser.initializePageIndex(linkCurrentIndex)
//                            getTopMostViewController()?.present(browser, animated: true, completion: {})
//                        }
//                    }
//                    if let cell = self.linkCollectionView1.cellForItem(at: indexPath) as? CollectionImageCell3 {
//                        if let originImage = cell.image.image {
//                            for x in self.linkImages {
//                                let photo = SKPhoto.photoWithImageURL(x)
//                                photo.shouldCachePhotoURLImage = true
//                                images.append(photo)
//                            }
//                            var alt = ""
//                            if indexPath.item < self.altText.count {
//                                alt = self.altText[indexPath.item]
//                            }
//                            let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: cell.image, imageText: self.linkPost.text ?? "", imageText2: 0, imageText3: 0, imageText4: alt)
//                            browser.delegate = self
//                            SKPhotoBrowserOptions.enableSingleTapDismiss = false
//                            SKPhotoBrowserOptions.displayCounterLabel = false
//                            SKPhotoBrowserOptions.displayBackAndForwardButton = false
//                            SKPhotoBrowserOptions.displayAction = false
//                            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
//                            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
//                            SKPhotoBrowserOptions.displayCloseButton = false
//                            SKPhotoBrowserOptions.displayStatusbar = false
//                            browser.initializePageIndex(linkCurrentIndex)
//                            getTopMostViewController()?.present(browser, animated: true, completion: {})
//                        }
//                    }
//                }
//            }
//             */
//        }
//    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let center = CGPoint(x: scrollView.contentOffset.x + (scrollView.frame.width / 2), y: (scrollView.frame.height / 2))
        if let ip = self.imageCollectionView.indexPathForItem(at: center) {
            currentImageIndex = ip.row
            countButton.setTitle("\(currentImageIndex + 1)/\(collectionCellModels.count)", for: .normal)
            if !statusURI.isEmpty && !configuringCell {
                PostCardImageAttachment.URLToCurrentIndexCache[statusURI] = currentImageIndex
            }
        }
    }

}
