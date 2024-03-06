//
//  DetailImageView.swift
//  Mammoth
//
//  Created by Benoit Nolens on 09/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit
import Vision
import Photos
import NaturalLanguage
import LinkPresentation

class DetailImageView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, SKPhotoBrowserDelegate, AVPlayerViewControllerDelegate, UICollectionViewDragDelegate, UIActivityItemSource {
    
    var collectionView1: UICollectionView!
    let playButton = UIButton()
    var altText: [String] = []
    var postText: String = ""
    var tmpIndex: Int = 0
    var isSensitive: Bool = false
    let countButton2 = UIButton()
    var isQuotedPostPreview: Bool = false
    
    init(isQuotedPostPreview: Bool) {
        super.init(frame: CGRectZero)
        self.isQuotedPostPreview = isQuotedPostPreview
        self.player.isMuted = true
        self.commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.player.isMuted = true
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        self.accessibilityIdentifier = "DetailImagView"
        let layout = ColumnFlowLayoutD(
            cellsPerRow: 4,
            minimumInteritemSpacing: 0,
            minimumLineSpacing: 0,
            sectionInset: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )
        layout.itemSize = CGSize(width: self.bounds.width, height: self.bounds.width)
        layout.scrollDirection = .horizontal
        
        let windowFrame = UIApplication.shared.connectedScenes
                        .compactMap({ scene -> UIWindow? in
                            (scene as? UIWindowScene)?.windows.first
                        }).first?.frame
        
        var fullWidth = UIScreen.main.bounds.size.width - 87
        #if targetEnvironment(macCatalyst)
        fullWidth = windowFrame?.size.width ?? 0
        #endif
        
#if targetEnvironment(macCatalyst)
        if GlobalStruct.singleColumn {
            collectionView1 = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(fullWidth), height: CGFloat(400)), collectionViewLayout: layout)
        } else {
            collectionView1 = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(GlobalStruct.padColWidth), height: CGFloat(280)), collectionViewLayout: layout)
        }
#elseif !targetEnvironment(macCatalyst)
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            collectionView1 = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(GlobalStruct.padColWidth), height: CGFloat(400)), collectionViewLayout: layout)
        } else {
            collectionView1 = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(GlobalStruct.padColWidth), height: CGFloat(280)), collectionViewLayout: layout)
        }
        
#endif
        collectionView1.translatesAutoresizingMaskIntoConstraints = false
        collectionView1.backgroundColor = .custom.quoteTint
        collectionView1.delegate = self
        collectionView1.dataSource = self
        collectionView1.showsHorizontalScrollIndicator = false
        collectionView1.isPagingEnabled = true
        collectionView1.register(CollectionImageCellD.self, forCellWithReuseIdentifier: "CollectionImageCellD")
        collectionView1.dragDelegate = self
        self.addSubview(collectionView1)
        
        if self.isQuotedPostPreview {
            collectionView1.layer.cornerRadius = 6
            collectionView1.layer.masksToBounds = true
        }

        
        NSLayoutConstraint.activate([
            collectionView1.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            collectionView1.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            collectionView1.topAnchor.constraint(equalTo: self.topAnchor),
            collectionView1.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        
#if targetEnvironment(macCatalyst)
        if GlobalStruct.singleColumn {
            collectionView1.heightAnchor.constraint(equalToConstant: 400).isActive = true
        } else {
            collectionView1.heightAnchor.constraint(equalToConstant: 280).isActive = true
        }
#elseif !targetEnvironment(macCatalyst)
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            collectionView1.heightAnchor.constraint(equalToConstant: 400).isActive = true
        } else {
            collectionView1.heightAnchor.constraint(equalToConstant: 280).isActive = true
        }
#endif
    }
    
    func prepareForReuse() {
        self.player.isMuted = true
        self.videoUrl = ""
        self.playButton.removeFromSuperview()
        self.player.pause()
        self.playerController.player?.pause()
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        self.player.isMuted = true
        NotificationCenter.default.removeObserver(self)
    }
    
    // images
    
    var imagesFull: [Attachment] = []
    var images: [String] = []
    var images2: [UIImageView] = []
    var images3: [String] = []
    let countButtonBG = UIButton()
    let countButton = UIButton()
    var allCounts: Int = 0
    var currentIndex: Int = 0
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        var image1: UIImage = UIImage()
        if let cell = collectionView1.cellForItem(at: indexPath) as? CollectionImageCell {
            image1 = cell.image.image ?? UIImage()
        }
        if let cell = collectionView1.cellForItem(at: indexPath) as? CollectionImageCell2 {
            image1 = cell.image.image ?? UIImage()
        }
        if let cell = collectionView1.cellForItem(at: indexPath) as? CollectionImageCell3 {
            image1 = cell.image.image ?? UIImage()
        }
        let itemProvider = NSItemProvider(object: image1)
        return [UIDragItem(itemProvider: itemProvider)]
    }
    
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let previewParameters = UIDragPreviewParameters()
        previewParameters.backgroundColor = UIColor.clear
        return previewParameters
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionImageCellD", for: indexPath) as! CollectionImageCellD
        if self.images.isEmpty {
            
        } else {
            // Hack to force the cell to use a size width equal to this views width
            // instead of full width
            cell.preferredWidth = self.bounds.width

            cell.configure()
            if indexPath.item == 0 {
                if self.altText.count > 0 && !self.altText[0].isEmpty {
                    cell.altTextButton.alpha = 1
                    cell.image.accessibilityLabel = self.altText[0]
                }
            }
            if indexPath.item == 1 {
                if self.altText.count > 1 && !self.altText[1].isEmpty {
                    cell.altTextButton.alpha = 1
                    cell.image.accessibilityLabel = self.altText[1]
                }
            }
            if indexPath.item == 2 {
                if self.altText.count > 2 && !self.altText[2].isEmpty {
                    cell.altTextButton.alpha = 1
                    cell.image.accessibilityLabel = self.altText[2]
                }
            }
            if indexPath.item == 3 {
                if self.altText.count > 3 && !self.altText[3].isEmpty {
                    cell.altTextButton.alpha = 1
                    cell.image.accessibilityLabel = self.altText[3]
                }
            }
            cell.altTextButton.tag = indexPath.item
            cell.altTextButton.addTarget(self, action: #selector(self.altTextTap), for: .touchUpInside)
            cell.image.contentMode = .scaleAspectFill
            
            if let ur = URL(string: self.images[indexPath.item]) {
                cell.image.sd_setImage(with: ur)
                
                // Hack to force the Flow Layout to use an item size width equal to this views width
                // instead of full width
                if let layout = collectionView.collectionViewLayout as? ColumnFlowLayoutD {
                    layout.preferredWidth = self.bounds.width
                    layout.prepare()
                    layout.invalidateLayout()
                }
            }
            cell.image.layer.masksToBounds = true
            
            for x in cell.image.subviews {
                x.removeFromSuperview()
            }
            if self.isSensitive && GlobalStruct.blurSensitiveContent {
                let blurEffect = UIBlurEffect(style: .regular)
                var blurredEffectView = UIVisualEffectView()
                blurredEffectView = UIVisualEffectView(effect: blurEffect)
                blurredEffectView.frame = cell.image.bounds
                blurredEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.image.addSubview(blurredEffectView)
            }
        }
        cell.backgroundColor = .custom.quoteTint
        return cell
    }
    
    func setupImages(url1: String, url2: String?, url3: String?, url4: String?, isVideo: Bool? = false, videoUrl: String? = "www.google.com", altText: [String] = [], fullImages: [Attachment] = [], isSensitive: Bool = false) {
        self.isSensitive = isSensitive
        self.imagesFull = fullImages
        images = []
        images.append(url1)
        self.altText = altText
        if url2 != nil {
            images.append(url2 ?? "")
        }
        if url3 != nil {
            images.append(url3 ?? "")
        }
        if url4 != nil {
            images.append(url4 ?? "")
        }
        collectionView1.reloadData()
        
        if url2 != nil {
            // show count
            allCounts = images.count
            countButtonBG.frame = CGRect(x: 10, y: 10, width: 40, height: 25)
            countButtonBG.layer.cornerCurve = .continuous
            countButtonBG.layer.cornerRadius = 10
            countButtonBG.backgroundColor = .clear
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = countButtonBG.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blurEffectView.removeFromSuperview()
            countButtonBG.addSubview(blurEffectView)
            countButtonBG.layer.masksToBounds = true
            countButtonBG.removeFromSuperview()
            collectionView1.superview?.addSubview(countButtonBG)
            
            countButton.frame = CGRect(x: 0, y: 0, width: 40, height: 25)
            countButton.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption2).pointSize + GlobalStruct.customTextSize, weight: .bold)
            countButton.setTitle("1/\(allCounts)", for: .normal)
            countButton.sizeToFit()
            countButtonBG.bounds.size.width = countButton.bounds.size.width
            countButtonBG.bounds.size.height = countButton.bounds.size.height
            countButtonBG.frame.origin.x = 10
            countButtonBG.frame.origin.y = 10
            countButton.setTitleColor(UIColor.white, for: .normal)
            countButton.backgroundColor = .clear
            countButtonBG.addSubview(countButton)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let center = CGPoint(x: scrollView.contentOffset.x + (scrollView.frame.width / 2), y: (scrollView.frame.height / 2))
        if let ip = self.collectionView1.indexPathForItem(at: center) {
            currentIndex = ip.row
            countButton.alpha = 1
            countButton.setTitle("\(ip.row + 1)/\(allCounts)", for: .normal)
        }
    }
    
    var isVideo: Bool = false
    var videoUrl: String = ""
    var player = AVPlayer()
    var playerController = CustomVideoPlayer()
    
    func setupPlayButton(_ videoUrl: String, isAudio: Bool = false) {
        self.playButton.isUserInteractionEnabled = false
        if videoUrl != "" {
            self.videoUrl = videoUrl
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .semibold)
            
            if let cell = self.collectionView1.cellForItem(at: (IndexPath(item: 0, section: 0))) as? CollectionImageCellD {
                self.playButton.frame = CGRect(x: cell.image.bounds.width/2 - 35, y: cell.image.bounds.height/2 - 35, width: 70, height: 70)
                self.collectionView1.addSubview(self.playButton)
            }
            self.playButton.alpha = 1
            self.playButton.layer.cornerRadius = 35
            self.playButton.backgroundColor = UIColor.white
            
            countButton2.removeFromSuperview()
            countButton2.frame.size.width = 70
            countButton2.frame.size.height = 70
            countButton2.isUserInteractionEnabled = false
            countButton2.backgroundColor = UIColor.clear
            if isAudio {
                countButton2.setImage(UIImage(systemName: "waveform.path", withConfiguration: symbolConfig)?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
            } else {
                countButton2.setImage(UIImage(systemName: "play.fill", withConfiguration: symbolConfig)?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
            }
            self.playButton.addSubview(countButton2)
        } else {
            self.playButton.removeFromSuperview()
        }
    }
    
    func setupVideoUrl(_ videoUrl: String) {
        DispatchQueue.global(qos: .background).async {
            self.videoUrl = videoUrl
            if let fileURL = URL(string: videoUrl) {
                let assetForCache = AVAsset(url: fileURL)
                let playerItem = AVPlayerItem(asset: assetForCache)
                let keys = ["playable", "tracks", "duration"]
                assetForCache.loadValuesAsynchronously(forKeys: keys, completionHandler: {
                    self.player.replaceCurrentItem(with: playerItem)
                    self.player.isMuted = true
                    
                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: nil) { (_) in
                        self.player.seek(to: CMTime.zero)
                        self.player.play()
                    }
                    
                    DispatchQueue.main.async {
                        self.playerController.view.isHidden = false
                        self.playerController.player = self.player
                        if let vi = self.playerController.view {
                            if let cell = self.collectionView1.cellForItem(at: (IndexPath(item: 0, section: 0))) as? CollectionImageCellD {
                                vi.backgroundColor = .black
                                vi.layer.masksToBounds = true
                                vi.frame = cell.image.frame
                                self.inputViewController?.addChild(self.playerController)
                                self.collectionView1.addSubview(vi)
                                
                                self.player.play()
                                self.playerController.player?.play()
                            }
                        }
                    }
                })
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.videoUrl != "" {
            if let ur = URL(string: self.videoUrl) {
                let player = AVPlayer(url: ur)
                let vc = CustomVideoPlayer()
                vc.delegate = self
                vc.allowsPictureInPicturePlayback = true
                
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { (_) in
                    player.seek(to: CMTime.zero)
                    player.play()
                }
                
                vc.player = player
                GlobalStruct.inVideoPlayer = true
                getTopMostViewController()?.present(vc, animated: true) {
                    vc.player?.play()
                }
            }
        } else {
            if isVideo {
                let player = AVPlayer(url: URL(string: self.videoUrl)!)
                let vc = CustomVideoPlayer()
                vc.delegate = self
                vc.allowsPictureInPicturePlayback = true
                
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { (_) in
                    player.seek(to: CMTime.zero)
                    player.play()
                }
                
                vc.player = player
                GlobalStruct.inVideoPlayer = true
                getTopMostViewController()?.present(vc, animated: true) {
                    vc.player?.play()
                }
            } else {
                var images = [SKPhoto]()
                if let cell = self.collectionView1.cellForItem(at: indexPath) as? CollectionImageCellD {
                    if let originImage = cell.image.image {
                        for x in self.imagesFull {
                            let photo = SKPhoto.photoWithImageURL(x.url)
                            photo.shouldCachePhotoURLImage = true
                            images.append(photo)
                        }
                        let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: cell.image, imageText: self.postText, imageText2: 0, imageText3: 0, imageText4: "")
                        browser.delegate = self
                        SKPhotoBrowserOptions.enableSingleTapDismiss = false
                        SKPhotoBrowserOptions.displayCounterLabel = false
                        SKPhotoBrowserOptions.displayBackAndForwardButton = false
                        SKPhotoBrowserOptions.displayAction = false
                        SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
                        SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
                        SKPhotoBrowserOptions.displayCloseButton = false
                        SKPhotoBrowserOptions.displayStatusbar = false
                        browser.initializePageIndex(currentIndex)
                        getTopMostViewController()?.present(browser, animated: true, completion: {})
                    }
                }
            }
        }
    }
    
    @objc func altTextTap(_ sender: UIButton) {
        triggerHapticImpact(style: .light)
        let altTextPopup = self.altText[sender.tag]
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
    
    func makePreviewV() -> UIViewController {
        let viewController = UIViewController()
        let asset = AVAsset(url: URL(string: self.videoUrl)!)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        player.play()
        let playerLayer = AVPlayerLayer(player: player)
        let size = asset.videoSize ?? .zero
        var ratioS: CGFloat = 1
        if size.height == 0 {} else {
            ratioS = size.width/size.height
        }
        if size.height >= (size.width * 2) {
            playerLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.width/2, height: self.bounds.width/2/ratioS)
        } else {
            playerLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.width/ratioS)
        }
        playerLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(playerLayer)
        viewController.preferredContentSize = playerLayer.frame.size
        return viewController
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if self.videoUrl != "" {
            return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: {
                return self.makePreviewV()
            }, actionProvider: { suggestedActions in
                return self.makeContextMenuV(indexPath.row)
            })
        } else {
            return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: {
                return self.makePreview(indexPath.row)
            }, actionProvider: { suggestedActions in
                return self.makeContextMenu(indexPath.row)
            })
        }
    }
    
    func makePreview(_ index: Int) -> UIViewController {
        if let cell = collectionView1.cellForItem(at: IndexPath(row: index, section: 0)) as? CollectionImageCellD {
            let theImage = cell.image.image ?? UIImage()
            let viewController = UIViewController()
            let imageView = UIImageView(image: theImage)
            viewController.view = imageView
            var ratioS: CGFloat = 1
            if theImage.size.height == 0 {} else {
                ratioS = theImage.size.width/theImage.size.height
            }
            if theImage == UIImage() {
                imageView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            } else {
                imageView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.width/ratioS)
            }
            imageView.contentMode = .scaleAspectFit
            viewController.preferredContentSize = imageView.frame.size
            return viewController
        } else {
            return UIViewController()
        }
    }
    
    func makeContextMenuV(_ index: Int) -> UIMenu {
        let share = UIAction(title: NSLocalizedString("generic.share", comment: ""), image: UIImage(systemName: "square.and.arrow.up"), identifier: nil) { action in
            DispatchQueue.global(qos: .background).async {
                if let url = URL(string: self.videoUrl) {
                    guard let urlData = NSData(contentsOf: url) else { return }
                    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                    let filePath = "\(documentsPath)/Video.mov"
                    DispatchQueue.main.async {
                        urlData.write(toFile: filePath, atomically: true)
                        let activityViewController = UIActivityViewController(activityItems: [NSURL(fileURLWithPath: filePath)], applicationActivities: nil)
                        activityViewController.excludedActivityTypes = [.addToReadingList, .assignToContact]
                        if let cell = self.collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCellD {
                            activityViewController.popoverPresentationController?.sourceView = cell.image
                        }
                        getTopMostViewController()?.present(activityViewController, animated: true, completion: nil)
                    }
                }
            }
        }
        let save = UIAction(title: NSLocalizedString("generic.save", comment: ""), image: UIImage(systemName: "square.and.arrow.down"), identifier: nil) { action in
            DispatchQueue.global(qos: .background).async {
                if let url = URL(string: self.videoUrl) {
                    guard let urlData = NSData(contentsOf: url) else { return }
                    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                    let filePath = "\(documentsPath)/Video.mov"
                    DispatchQueue.main.async {
                        urlData.write(toFile: filePath, atomically: true)
                        if let urlToYourVideo = URL(string: filePath) {
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: urlToYourVideo)
                            }) { saved, error in
                                if saved {
                                    print("saved video")
                                }
                            }
                        }
                    }
                }
            }
        }
        return UIMenu(title: "", image: nil, identifier: nil, children: [share, save])
    }
    
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }

    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return nil
    }

    public func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        var image1: UIImage = UIImage()
        if let cell = collectionView1.cellForItem(at: IndexPath(item: self.tmpIndex, section: 0)) as? CollectionImageCellD {
            image1 = cell.image.image ?? UIImage()
        }
        let image = image1
        let imageProvider = NSItemProvider(object: image)
        let metadata = LPLinkMetadata()
        metadata.imageProvider = imageProvider
        return metadata
    }
    
    func makeContextMenu(_ index: Int) -> UIMenu {
        var image1: UIImage = UIImage()
        if self.videoUrl != "" {
            let share = UIAction(title: NSLocalizedString("generic.share", comment: ""), image: UIImage(systemName: "square.and.arrow.up"), identifier: nil) { action in
                if let videoURL = URL(string: self.videoUrl) {
                    let imageToShare = [videoURL]
                    let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
                    activityViewController.excludedActivityTypes = [.addToReadingList, .assignToContact]
                    if let cell = self.collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCellD {
                        activityViewController.popoverPresentationController?.sourceView = cell.image
                    }
                    getTopMostViewController()?.present(activityViewController, animated: true, completion: nil)
                }
            }
            let save = UIAction(title: NSLocalizedString("generic.save", comment: ""), image: UIImage(systemName: "square.and.arrow.down"), identifier: nil) { action in
                if let videoURL = URL(string: self.videoUrl) {
                    DispatchQueue.global(qos: .background).async {
                        if let urlData = NSData(contentsOf: videoURL) {
                            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                            let filePath="\(documentsPath)/tempFile.mp4"
                            DispatchQueue.main.async {
                                urlData.write(toFile: filePath, atomically: true)
                                PHPhotoLibrary.shared().performChanges({
                                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
                                }) { completed, error in
                                    if completed {
                                        print("Video is saved!")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return UIMenu(title: "", image: nil, identifier: nil, children: [share, save])
        } else {
            if let cell = collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCellD {
                image1 = cell.image.image ?? UIImage()
            }
            let copy = UIAction(title: NSLocalizedString("generic.copy", comment: ""), image: UIImage(systemName: "doc.on.doc"), identifier: nil) { action in
                UIPasteboard.general.image = image1
            }
            let share = UIAction(title: NSLocalizedString("generic.share", comment: ""), image: UIImage(systemName: "square.and.arrow.up"), identifier: nil) { action in
                self.tmpIndex = index
                let imToShare = [image1, self]
                let activityViewController = UIActivityViewController(activityItems: imToShare,  applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self
                activityViewController.popoverPresentationController?.sourceRect = self.bounds
                getTopMostViewController()?.present(activityViewController, animated: true, completion: nil)
            }
            let save = UIAction(title: NSLocalizedString("generic.save", comment: ""), image: UIImage(systemName: "square.and.arrow.down"), identifier: nil) { action in
                UIImageWriteToSavedPhotosAlbum(image1, nil, nil, nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "savedImage"), object: nil)
            }
            let actMenu = UIMenu(title: "", options: [.displayInline], children: [copy, share, save])
            if #available(iOS 16.0, *) {
                actMenu.preferredElementSize = .small
            }
            var alt = ""
            if index < self.altText.count {
                alt = self.altText[index]
            }
            return UIMenu(title: alt, image: nil, identifier: nil, children: [actMenu])
        }
    }
    
    public static func willDisplayContentForStat(_ stat: Status?) -> Bool {
        return stat?.reblog?.mediaAttachments.count ?? stat?.mediaAttachments.count ?? 0 > 0
    }
    
    public func updateFromStat(_ stat: Status) {
        var alt: [String] = []
        let z = stat.reblog?.mediaAttachments ?? stat.mediaAttachments
        var isVideo: Bool = false
        let mediaItems = z[0].previewURL

        alt = z.map({ attachment in
            if let alt = attachment.description {
                return alt
            }
            return ""
        })
        
        if z.first?.type == .video || z.first?.type == .gifv || z.first?.type == .audio {
            isVideo = true
            self.playerController.view.isHidden = false
            if z.first?.type == .audio {
                self.setupPlayButton(z.first?.url ?? "", isAudio: true)
            } else {
                self.setupPlayButton(z.first?.url ?? "")
            }
        } else {
            self.playerController.view.isHidden = true
            self.setupPlayButton("")
        }
        
        var mediaItems1: String?
        if z.count > 1 {
            mediaItems1 = z[1].previewURL
        }
        
        var mediaItems2: String?
        if z.count > 2 {
            mediaItems2 = z[2].previewURL
        }
        
        var mediaItems3: String?
        if z.count > 3 {
            mediaItems3 = z[3].previewURL
        }
        
        self.setupImages(url1: mediaItems ?? "", url2: mediaItems1, url3: mediaItems2, url4: mediaItems3, isVideo: isVideo, videoUrl: nil, altText: alt, fullImages: z, isSensitive: stat.reblog?.sensitive ?? stat.sensitive ?? false)
    }
    
}
