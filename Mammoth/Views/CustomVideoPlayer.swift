//
//  CustomVideoPlayer.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 02/03/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import AVKit
import Photos

class CustomVideoPlayer: AVPlayerViewController, UIContextMenuInteractionDelegate, AVPlayerViewControllerDelegate {
    var scrubbingBeginTime: CMTime?
    var showShare: Bool = true
    private var keepPlayingOnClose: Bool = false
    public var altText: String = ""
    
    //autorotate
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let interaction0 = UIContextMenuInteraction(delegate: self)
        self.view.addInteraction(interaction0)
        self.videoGravity = .resizeAspect
        self.requiresLinearPlayback = false
        self.showsPlaybackControls = false
        
        self.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.player?.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.keepPlayingOnClose = self.player?.isPlaying() ?? false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        GlobalStruct.inVideoPlayer = false
    }
    
    deinit {
        if self.keepPlayingOnClose {
            self.player?.play()
        }
    }
    
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        let pg = self.view
        if UIDevice.current.userInterfaceIdiom == .phone {
            pg?.backgroundColor = .clear
        }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: pg ?? UIView(), parameters: parameters)
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
            return self.makeContextMenu()
        })
    }
    
    func makeContextMenu() -> UIMenu {
        let op1 = UIAction(title: "0.25x", image: UIImage(systemName: "speedometer"), identifier: nil) { action in
            self.player?.rate = 0.25
        }
        let op2 = UIAction(title: "0.5x", image: UIImage(systemName: "speedometer"), identifier: nil) { action in
            self.player?.rate = 0.5
        }
        let op3 = UIAction(title: "Normal", image: UIImage(systemName: "speedometer"), identifier: nil) { action in
            self.player?.rate = 1
        }
        let op4 = UIAction(title: "1.5x", image: UIImage(systemName: "speedometer"), identifier: nil) { action in
            self.player?.rate = 1.5
        }
        let op5 = UIAction(title: "2x", image: UIImage(systemName: "speedometer"), identifier: nil) { action in
            self.player?.rate = 2
        }
        let op6 = UIAction(title: "Skip to Beginning", image: UIImage(systemName: "backward.end"), identifier: nil) { action in
            self.player?.seek(to: .zero)
        }

        let newMenu0 = UIMenu(title: "", options: [.displayInline], children: [op6])
        
        let alt = UIAction(title: "Show ALT text", image: FontAwesome.image(fromChar: "\u{f05a}"), identifier: nil) { action in
            triggerHapticImpact(style: .light)
            let alert = UIAlertController(title: nil, message: self.altText, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.copy", comment: ""), style: .default , handler:{ (UIAlertAction) in
                let pasteboard = UIPasteboard.general
                pasteboard.string = self.altText
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in

            }))
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = self.view
                presenter.sourceRect = self.view.bounds
            }
            getTopMostViewController()?.present(alert, animated: true, completion: nil)
        }
        
        let share = UIAction(title: NSLocalizedString("generic.share", comment: ""), image: FontAwesome.image(fromChar: "\u{e09a}"), identifier: nil) { action in
            if let x = ((self.player?.currentItem?.asset) as? AVURLAsset)?.url {
                let imageToShare = [x]
                let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view
                self.present(activityViewController, animated: true, completion: nil)
            }
        }
        let save = UIAction(title: NSLocalizedString("generic.save", comment: ""), image: UIImage(systemName: "square.and.arrow.down"), identifier: nil) { action in
            DispatchQueue.global(qos: .background).async {
                if let x = ((self.player?.currentItem?.asset) as? AVURLAsset)?.url {
                    if let urlData = NSData(contentsOf: x) {
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
        let newMenu00 = UIMenu(title: "", options: [.displayInline], children: [self.altText.isEmpty ? nil : alt, share, save].compactMap({$0}))
        if self.showShare {
            let newMenu = UIMenu(title: "", options: [], children: [op1, op2, op3, op4, op5, newMenu0, newMenu00])
            return newMenu
        } else {
            let newMenu = UIMenu(title: "", options: [], children: [op1, op2, op3, op4, op5, newMenu0])
            return newMenu
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.showsPlaybackControls = true
        super.touchesBegan(touches, with: event)
    }
}
