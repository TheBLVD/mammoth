//
//  ChatViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 18/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation
import SafariServices
import Photos
import PhotosUI
import MobileCoreServices
import SDWebImage
import MessageKit
import InputBarAccessoryView

class ChatMessagesViewController: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, MessageCellDelegate, MessageLabelDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVPlayerViewControllerDelegate, SKPhotoBrowserDelegate, UIDocumentPickerDelegate, UITextFieldDelegate, PHPickerViewControllerDelegate {
    
    var currentSender: MessageKit.SenderType = MockUser(senderId: "1", displayName: "\(AccountsManager.shared.currentUser()?.id ?? "")")
    
    static var currentVC: ChatMessagesViewController? = nil
    var currentUserID: String? = nil
    var client: Client? = nil
    var scrollDownButton = UIButton()
    var keyHeight: CGFloat = 0
    var imageDict2: [String: String] = [:]
    var otherUser: String = ""
    var currentUser: String = ""
    var currentStatus: [Status] = []
    var allCurrentMessages: [Status] = []
    var messages: [MessageType] = []
    var messagesMedia: [UIImage] = []
    var allCurrentMessagesImages: [UIImage] = []
    let btn0 = UIButton(type: .custom)
    var index: Int = 0
    var mediaIdString: String = ""
    let playerViewController = AVPlayerViewController()
    var player = AVPlayer()
    var safariVC: SFSafariViewController?
    var lastUser = ""
    let imag = UIImagePickerController()
    var theUser = ""
    var hasSent: Bool = false
    var videoURL: URL = URL(string: "https://www.google.com")!
    var cc: [Int] = []
    let sendB = UIButton()
    var photoPickerView: PHPickerViewController!
    var photoPickerView2 = UIImagePickerController()
    var currentImage = UIImage()
    var image1 = UIButton()
    var canPost: Bool = false
    var fromDMLink: String = ""
    var dm: Bool = true
    var mButton = InputBarButtonItem()
    var fromNew: Bool = false
    var currentAccounts: [Account] = []
    
    @objc func reloadAll() {
        DispatchQueue.main.async {
            // tints
            

            let hcText = UserDefaults.standard.value(forKey: "hcText") as? Bool ?? true
            if hcText == true {
                UIColor.custom.mainTextColor = .label
            } else {
                UIColor.custom.mainTextColor = .secondaryLabel
            }
            self.scrollDownButton.backgroundColor = .custom.quoteTint
            self.setupCol()
            self.messagesCollectionView.reloadData()
            
            // update various elements
            self.view.backgroundColor = .custom.backgroundTint
            let navApp = UINavigationBarAppearance()
            navApp.configureWithOpaqueBackground()
            navApp.backgroundColor = .custom.backgroundTint
            navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
            self.navigationController?.navigationBar.standardAppearance = navApp
            self.navigationController?.navigationBar.scrollEdgeAppearance = navApp
            self.navigationController?.navigationBar.compactAppearance = navApp
            if #available(iOS 15.0, *) {
                self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
            }
            if GlobalStruct.hideNavBars2 {
                self.extendedLayoutIncludesOpaqueBars = true
            } else {
                self.extendedLayoutIncludesOpaqueBars = false
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
       if #available(iOS 13.0, *) {
           if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
               messagesCollectionView.reloadData()
               scrollDownButton.backgroundColor = .custom.quoteTint
               scrollDownButton.layer.borderColor = UIColor.systemGray3.cgColor
           }
       }
    }
    
    @objc func cameraTapped() {
        triggerHapticSelectionChanged()
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
                    DispatchQueue.main.async {
                        self.photoPickerView2.delegate = self
                        self.photoPickerView2.sourceType = .camera
                        self.photoPickerView2.mediaTypes = [kUTTypeImage as String]
                        self.photoPickerView2.allowsEditing = false
                        self.present(self.photoPickerView2, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    @objc func galleryTapped() {
        triggerHapticSelectionChanged()
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            DispatchQueue.main.async {
                var configuration = PHPickerConfiguration()
                configuration.selectionLimit = 1
                configuration.filter = .any(of: [.videos, .images])
                self.photoPickerView = PHPickerViewController(configuration: configuration)
                self.photoPickerView.modalPresentationStyle = .popover
                self.photoPickerView.delegate = self
                if let presenter = self.photoPickerView.popoverPresentationController {
                    presenter.sourceView = self.view
                    presenter.sourceRect = self.view.bounds
                }
                if #available(iOS 15.0, *) {
                    if let sheet = self.photoPickerView.popoverPresentationController?.adaptiveSheetPresentationController {
                        sheet.detents = [.medium(), .large()]
                    }
                }
                self.present(self.photoPickerView, animated: true, completion: nil)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.fromDMLink != "" {
            messageInputBar.inputTextView.text = self.fromDMLink
            messageInputBar.sendButton.isEnabled = true
            self.canPost = true
            UIView.animate(withDuration: 0.3, animations: {
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
                self.messageInputBar.sendButton.image = UIImage(systemName: "arrow.up.circle.fill", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
            })
        }
        messageInputBar.inputTextView.becomeFirstResponder()
        self.messagesCollectionView.scrollToLastItem(animated: true)

        setupImages()
    }
    
    func setupImages() {
        image1.frame = CGRect(x: 20, y: view.bounds.height - keyHeight - messageInputBar.bounds.height - 41, width: 50, height: 50)
        image1.backgroundColor = .clear
        image1.layer.cornerRadius = 6
        image1.layer.cornerCurve = .continuous
        image1.imageView?.contentMode = .scaleAspectFill
        image1.layer.masksToBounds = true
        image1.alpha = 0
        view.addSubview(image1)
        
        let remove1 = UIAction(title: "Remove", image: UIImage(systemName: "xmark"), identifier: nil) { action in
            self.image1.setImage(UIImage(), for: .normal)
            self.mediaIdString = ""
        }
        remove1.accessibilityLabel = "Remove"
        remove1.attributes = .destructive
        let itemMenu1 = UIMenu(title: "", options: [], children: [remove1])
        image1.menu = itemMenu1
        image1.showsMenuAsPrimaryAction = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.scrollDownButton.alpha = 0
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        if indexPath.section < self.messages.count {
            if self.messages[indexPath.section].sender.displayName == AccountsManager.shared.currentUser()?.avatar ?? "" {
                let profileIcon = AccountsManager.shared.currentUser()?.avatar ?? ""
                if let ur = URL(string: profileIcon) {
                    DispatchQueue.global(qos: .utility).async {
                        if let data = try? Data(contentsOf: ur) {
                            DispatchQueue.main.async {
                                let image = UIImage(data: data)
                                let avatar = Avatar(image: image, initials: "")
                                avatarView.set(avatar: avatar)
                            }
                        }
                    }
                }
            } else {
                let profileIcon = self.messages[indexPath.section].sender.displayName
                if let ur = URL(string: profileIcon) {
                    DispatchQueue.global(qos: .utility).async {
                        if let data = try? Data(contentsOf: ur) {
                            DispatchQueue.main.async {
                                let image = UIImage(data: data)
                                let avatar = Avatar(image: image, initials: "")
                                avatarView.set(avatar: avatar)
                            }
                        }
                    }
                }
            }
        }
    }

    func didTapAvatar(in cell: MessageCollectionViewCell) {
        triggerHapticImpact(style: .light)
        let ind = self.messagesCollectionView.indexPath(for: cell)
        
        if let account = self.allCurrentMessages[ind?.section ?? 0].account {
            let vc = ProfileViewController(user: UserCardModel(account: account), screenType: .others)
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    @objc func keyboardWillChange(notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) - 4
            self.keyHeight = CGFloat(keyboardHeight)
            self.setupScrollDownButton()
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let insets = scrollView.contentInset
        
        let y = offset.y + bounds.size.height - insets.bottom
        let h = size.height
        
        if y < h {
            UIView.animate(withDuration: 0.1, delay: 0, options: [.curveLinear]) {
                self.scrollDownButton.alpha = 1
            } completion: { x in
                
            }
        } else {
            UIView.animate(withDuration: 0.1, delay: 0, options: [.curveLinear]) {
                self.scrollDownButton.alpha = 0
            } completion: { x in
                
            }
        }
    }
    
    func setupScrollDownButton() {
        if self.keyHeight <= 200 {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveLinear]) {
                self.scrollDownButton.frame = CGRect(x: self.view.bounds.width - 46, y: self.view.bounds.height - 56 - self.messageInputBar.bounds.height - 20, width: 36, height: 36)
            } completion: { x in
                
            }
        } else {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveLinear]) {
                self.scrollDownButton.frame = CGRect(x: self.view.bounds.width - 46, y: self.view.bounds.height - 26 - self.messageInputBar.bounds.height - 20 - self.keyHeight, width: 36, height: 36)
            } completion: { x in
                
            }
        }
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        scrollDownButton.setImage(UIImage(systemName: "chevron.down", withConfiguration: symbolConfig)?.withTintColor(.label, renderingMode: .alwaysOriginal), for: .normal)
        scrollDownButton.imageEdgeInsets = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        scrollDownButton.layer.cornerRadius = 18
        scrollDownButton.backgroundColor = .custom.quoteTint
        scrollDownButton.layer.borderColor = UIColor.systemGray3.cgColor
        scrollDownButton.layer.borderWidth = 0.7
        scrollDownButton.layer.shadowColor = UIColor.black.cgColor
        scrollDownButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        scrollDownButton.layer.shadowRadius = 6
        scrollDownButton.layer.shadowOpacity = 0.1
        scrollDownButton.alpha = 0
        scrollDownButton.addTarget(self, action: #selector(self.scrollDown), for: .touchUpInside)
        getTopMostViewController()?.view.addSubview(scrollDownButton)
    }
    
    @objc func scrollDown() {
        triggerHapticImpact(style: .light)
        self.messagesCollectionView.scrollToLastItem(animated: true)
    }
    
    @objc func updateMessageList2() {
        self.loadMessages()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if type(of: self).currentVC != nil {
            NotificationCenter.default.removeObserver(type(of: self).currentVC!)
        }
        type(of: self).currentVC = self
        self.currentUserID = AccountsManager.shared.currentUser()?.id
        self.client = AccountsManager.shared.currentAccountClient
        self.view.backgroundColor = .custom.backgroundTint
        if self.currentAccounts.count > 1 {
            self.title = "Group Message"
        } else {
            self.title = "Private Message"
        }
        
        NotificationCenter.default.addObserver(self,selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateMessageList2), name: NSNotification.Name(rawValue: "updateMessageList2"), object: nil)
        
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        let symbolConfig2 = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        
        // set up nav bar
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        self.navigationController?.navigationBar.standardAppearance = navApp
        self.navigationController?.navigationBar.scrollEdgeAppearance = navApp
        self.navigationController?.navigationBar.compactAppearance = navApp
        if #available(iOS 15.0, *) {
            self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
        }
        
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        if #available(iOS 15.0, *) {
            self.messagesCollectionView.allowsFocus = true
        }
        
        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.setMessageOutgoingAvatarSize(.zero)
        layout?.setMessageIncomingAvatarSize(.zero)
        
        self.messageInputBar.inputTextView.placeholderLabel.text = "  Message..."
        
        self.setupCol()
        messageInputBar.separatorLine.isHidden = false
        messageInputBar.separatorLine.height = 0.7
        messageInputBar.inputTextView.layer.cornerRadius = 12
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 11, left: 10, bottom: 4, right: 10)
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 9, left: 2, bottom: 5, right: 5)
        messageInputBar.setRightStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setLeftStackViewWidthConstant(to: 38, animated: false)
        messageInputBar.sendButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        messageInputBar.sendButton.setSize(CGSize(width: 40, height: 40), animated: false)
        messageInputBar.sendButton.image = UIImage(systemName: "arrow.up.circle.fill", withConfiguration: symbolConfig)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal)
        messageInputBar.sendButton.title = nil
        messageInputBar.sendButton.imageView?.layer.cornerRadius = 0
        messageInputBar.sendButton.addTarget(self, action: #selector(self.didTouchSend), for: .touchUpInside)
        messageInputBar.sendButton
            .onEnabled { item in
                if self.image1.alpha == 1 && self.mediaIdString.isEmpty {
                    self.canPost = false
                    UIView.animate(withDuration: 0.3, animations: {
                        self.messageInputBar.sendButton.image = UIImage(systemName: "arrow.up.circle.fill", withConfiguration: symbolConfig)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal)
                    })
                } else {
                    if self.dm {
                        self.canPost = true
                        UIView.animate(withDuration: 0.3, animations: {
                            self.messageInputBar.sendButton.image = UIImage(systemName: "arrow.up.circle.fill", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
                        })
                    }
                }
            }.onDisabled { item in
                self.canPost = false
                UIView.animate(withDuration: 0.3, animations: {
                    self.messageInputBar.sendButton.image = UIImage(systemName: "arrow.up.circle.fill", withConfiguration: symbolConfig)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal)
                })
        }
        
        mButton = InputBarButtonItem()
            .configure {
                $0.spacing = .fixed(0)
                $0.image = UIImage(systemName: "plus", withConfiguration: symbolConfig2)?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
                $0.setSize(CGSize(width: 40, height: 40), animated: false)
                $0.tintColor = UIColor.label
            }.onSelected {
                $0.tintColor = UIColor.label
            }.onDeselected {
                $0.tintColor = UIColor.label
            }
        
        let comp = UIAction(title: "Expanded Composer", image: UIImage(systemName: "square.and.pencil"), identifier: nil) { action in
            self.expandedComposer()
        }
        let gal = UIAction(title: "Gallery", image: UIImage(systemName: "photo"), identifier: nil) { action in
            self.galleryTapped()
        }
        let cam = UIAction(title: "Camera", image: UIImage(systemName: "camera"), identifier: nil) { action in
            self.cameraTapped()
        }
        let newMenu = UIMenu(title: "", options: [], children: [comp, gal, cam])
        mButton.menu = newMenu
        mButton.showsMenuAsPrimaryAction = true
        
        let leftItems = [mButton]
        messageInputBar.setStackViewItems(leftItems, forStack: .left, animated: false)
        
        let name = self.currentAccounts.first?.displayName ?? ""
        
        if self.currentAccounts.count == 1 {
            let containView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            let imageview = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            let profileIcon = self.currentAccounts.first?.avatar ?? "www.google.com"
            if let x = URL(string: profileIcon) {
                imageview.sd_setImage(with: x, for: .normal, completed: nil)
            }
            imageview.addTarget(self, action: #selector(self.proButtonTap), for: .touchUpInside)
            imageview.contentMode = .scaleAspectFit
            imageview.layer.cornerRadius = 15
            imageview.layer.masksToBounds = true
            containView.addSubview(imageview)
            let rightBarButton = UIBarButtonItem(customView: containView)
            self.navigationItem.setRightBarButtonItems([rightBarButton], animated: true)
            
            self.messageInputBar.inputTextView.placeholderLabel.text = "  Message \(name)..."
            
            layout?.setMessageOutgoingAvatarSize(.zero)
            layout?.setMessageIncomingAvatarSize(.zero)
        } else {
            self.messageInputBar.inputTextView.placeholderLabel.text = "  Group message..."
            
            layout?.setMessageOutgoingAvatarSize(.zero)
            layout?.setMessageIncomingAvatarSize(CGSize(width: 30, height: 30))
        }
        
        loadMessages()
    }
    
    func expandedComposer() {
        let vc = NewPostViewController()
        vc.isModalInPresentation = true
        vc.fromNewDM = true
        vc.fromExpanded = self.currentStatus.last?.account?.acct ?? ""
        vc.inReplyId = self.currentStatus.last?.id ?? ""
        vc.whoCanReply = .direct
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    func setupCol() {
        messagesCollectionView.backgroundColor = .custom.backgroundTint
        messageInputBar.backgroundColor = .custom.backgroundTint
        messageInputBar.separatorLine.backgroundColor = .custom.quoteTint
        messageInputBar.separatorLine.tintColor = .custom.quoteTint
        messageInputBar.backgroundView.backgroundColor = .custom.backgroundTint
        messageInputBar.contentView.backgroundColor = .custom.backgroundTint
        messageInputBar.inputTextView.backgroundColor = .custom.quoteTint
        messageInputBar.inputTextView.placeholderTextColor = UIColor.secondaryLabel
        messageInputBar.inputTextView.tintColor = .custom.baseTint
        messageInputBar.inputTextView.textColor = UIColor.label
        messageInputBar.inputTextView.layer.borderColor = UIColor.custom.quoteTint.cgColor
        messageInputBar.sendButton.imageView?.backgroundColor = UIColor.clear
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        let symbolConfig3 = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        if textField.text?.count == 0 {
            sendB.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: symbolConfig3)?.withTintColor(UIColor.systemGray5, renderingMode: .alwaysOriginal), for: .normal)
        } else {
            sendB.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: symbolConfig3)?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal), for: .normal)
        }
    }
    
    @objc func moreTap() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let op0 = UIAlertAction(title: "Gallery", style: .default , handler:{ (UIAlertAction) in
            self.galleryTapped()
        })
        op0.setValue(UIImage(systemName: "photo")!, forKey: "image")
        op0.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        alert.addAction(op0)
        let op1 = UIAlertAction(title: "Camera", style: .default , handler:{ (UIAlertAction) in
            self.cameraTapped()
        })
        op1.setValue(UIImage(systemName: "camera")!, forKey: "image")
        op1.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        alert.addAction(op1)
        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
            
        }))
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = self.view
            presenter.sourceRect = self.view.bounds
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func proButtonTap() {
        triggerHapticImpact(style: .light)
        let x = self.allCurrentMessages.last { x in
            (x.account?.id ?? "") != (self.currentUserID ?? "")
        }
        if let account = x?.account ?? self.currentStatus.last?.account {
            let vc = ProfileViewController(user: UserCardModel(account: account), screenType: .others)
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.photoPickerView2.dismiss(animated: true, completion: {
            
        })
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true, completion: nil)
        guard !results.isEmpty else { return }
        _ = results.map({ x in
            if x.itemProvider.hasItemConformingToTypeIdentifier(kUTTypeGIF as String) {
                x.itemProvider.loadDataRepresentation(forTypeIdentifier: kUTTypeGIF as String) { data, error in
                    DispatchQueue.main.async {
                        // attach gif
                        self.image1.alpha = 1
                        self.image1.setImage(self.createThumbnailOfVideoFromFileURL(self.videoURL.absoluteString) ?? UIImage(), for: .normal)
                        self.currentImage = self.createThumbnailOfVideoFromFileURL(self.videoURL.absoluteString) ?? UIImage()
                        let mediaData = data ?? Data()
                        self.attachGIF(mediaData)
                    }
                }
            } else {
                if x.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    x.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        DispatchQueue.main.async {
                            if let photoToAttach = image as? UIImage {
                                // attach photo
                                self.image1.alpha = 1
                                self.image1.setImage(photoToAttach, for: .normal)
                                self.currentImage = photoToAttach
                                let mediaData = photoToAttach.jpegData(compressionQuality: 0.7) ?? Data()
                                self.attachPhoto(mediaData)
                            }
                        }
                    }
                }
                x.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.movie") { data, error in
                    if let _ = data {
                        DispatchQueue.main.async {
                            // attach video
                            self.image1.alpha = 1
                            self.image1.setImage(self.createThumbnailOfVideoFromFileURL(self.videoURL.absoluteString) ?? UIImage(), for: .normal)
                            self.currentImage = self.createThumbnailOfVideoFromFileURL(self.videoURL.absoluteString) ?? UIImage()
                            if let vid = data {
                                DispatchQueue.main.async {
                                    // attach video
                                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                                    let videoURL = documentsURL?.appendingPathComponent("video.mp4")
                                    if let url = videoURL {
                                        do {
                                            try vid.write(to: url)
                                        } catch {
                                            log.error("error - \(error)")
                                        }
                                    }
                                    let mediaData = vid
                                    self.attachVideo(mediaData)
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
    func createThumbnailOfVideoFromFileURL2(_ strVideoURL: URL) -> UIImage? {
        let asset = AVAsset(url: strVideoURL)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        let time = CMTimeMakeWithSeconds(Float64(0.0), preferredTimescale: 600)
        do {
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: img)
            return thumbnail
        } catch {
            log.error("err creating thumbnail - \(error)")
            return nil
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let moreButton0 = UIBarButtonItem(customView: btn0)
        self.navigationItem.setLeftBarButton(moreButton0, animated: true)
        if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String {
            if mediaType == "public.movie" {
                
            } else if mediaType == kUTTypeGIF as String {
                
            } else {
                if let photoToAttach = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                    // send image
                    self.image1.alpha = 1
                    self.image1.setImage(photoToAttach, for: .normal)
                    self.currentImage = photoToAttach
                    let mediaData = photoToAttach.jpegData(compressionQuality: 1) ?? Data()
                    self.attachPhoto(mediaData)
                }
            }
        }
        self.photoPickerView2.dismiss(animated: true, completion: nil)
    }
    
    func attachPhoto(_ mediaData: Data) {
        self.canPost = false
        if self.image1.alpha == 1 {
            let request = Media.upload(media: .jpeg(mediaData))
            self.client!.run(request) { (statuses) in
                if let err = (statuses.error) {
                    log.error("error attaching photo - \(err)")
                    // remove image
                    self.canPost = true
                }
                if let stat = (statuses.value) {
                    DispatchQueue.main.async {
                        self.mediaIdString = stat.id
                        self.canPost = true
                        print("attached photo")
                        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
                        UIView.animate(withDuration: 0.3, animations: {
                            self.messageInputBar.sendButton.isEnabled = true
                            self.messageInputBar.sendButton.image = UIImage(systemName: "arrow.up.circle.fill", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
                        })
                    }
                }
            }
        }
    }
    
    func attachVideo(_ mediaData: Data) {
        self.canPost = false
        let request = Media.upload(media: .video(mediaData))
        self.client!.run(request) { (statuses) in
            if let err = (statuses.error) {
                print("error attaching video - \(err)")
                self.canPost = true
            }
            if let stat = (statuses.value) {
                DispatchQueue.main.async {
                    self.mediaIdString = stat.id
                    self.canPost = true
                    print("attached video")
                    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
                    UIView.animate(withDuration: 0.3, animations: {
                        self.messageInputBar.sendButton.isEnabled = true
                        self.messageInputBar.sendButton.image = UIImage(systemName: "arrow.up.circle.fill", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
                    })
                }
            }
        }
    }
    
    func attachGIF(_ mediaData: Data) {
        self.canPost = false
        let request = Media.upload(media: .video(mediaData))
        self.client!.run(request) { (statuses) in
            if let err = (statuses.error) {
                log.error("error attaching video - \(err)")
                self.canPost = true
            }
            if let stat = (statuses.value) {
                DispatchQueue.main.async {
                    self.mediaIdString = stat.id
                    self.canPost = true
                    print("attached video")
                    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
                    UIView.animate(withDuration: 0.3, animations: {
                        self.messageInputBar.sendButton.isEnabled = true
                        self.messageInputBar.sendButton.image = UIImage(systemName: "arrow.up.circle.fill", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
                    })
                }
            }
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let fileURL = urls.first!
        let ext = fileURL.pathExtension
        let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil)
        if UTTypeConformsTo((uti?.takeRetainedValue())!, kUTTypeMPEG) || UTTypeConformsTo((uti?.takeRetainedValue())!, kUTTypeMPEG4) || UTTypeConformsTo((uti?.takeRetainedValue())!, kUTTypeVideo) || UTTypeConformsTo((uti?.takeRetainedValue())!, kUTTypeMovie) || UTTypeConformsTo((uti?.takeRetainedValue())!, kUTTypeAVIMovie) || UTTypeConformsTo((uti?.takeRetainedValue())!, kUTTypeMPEG2Video) {
            let videoURL = fileURL
            // send video
            self.videoURL = videoURL
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func createThumbnailOfVideoFromFileURL(_ strVideoURL: String) -> UIImage? {
        if strVideoURL.isEmpty {} else {
            let asset = AVAsset(url: URL(string: strVideoURL)!)
            let assetImgGenerate = AVAssetImageGenerator(asset: asset)
            assetImgGenerate.appliesPreferredTrackTransform = true
            let time = CMTimeMakeWithSeconds(Float64(1), preferredTimescale: 100)
            do {
                let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                let thumbnail = UIImage(cgImage: img)
                return thumbnail
            } catch {
                print("err")
            }
        }
        return nil
    }
    
    func loadMessages() {
        let request = Statuses.context(id: self.currentStatus.first?.id ?? "")
        self.client!.run(request) { (statuses) in
            if let value = statuses.value {
                DispatchQueue.main.async {
                    self.allCurrentMessages = value.ancestors + self.currentStatus + value.descendants
                    
                    var canDo: Bool = true
                    
                    let _ = self.allCurrentMessages.enumerated().map ({ (c,x) in
                        var theType = "0"
                        if x.account?.id == (self.currentUserID ?? "") {
                            theType = "1"
                        }
                        let sender = MockUser(senderId: theType, displayName: x.account?.avatar ?? "")
                        let theDate = x.createdAt
                        var tex = x.content.stripHTML()
                        
                        let _ = x.mentions.map({ x in
                            tex = tex.replacingOccurrences(of: "@\(x.username) ", with: "")
                            if tex.hasPrefix("\n\n") {
                                tex = String(tex.dropFirst(2))
                            }
                            if tex.hasPrefix(" \n\n") {
                                tex = String(tex.dropFirst(3))
                            }
                            if tex.hasPrefix(" \n") {
                                tex = String(tex.dropFirst(2))
                            }
                            if tex.hasPrefix("\n") {
                                tex = String(tex.dropFirst(1))
                            }
                            if tex == "@\(x.username)" {
                                canDo = false
                            }
                        })
                        
                        if x.mediaAttachments.isEmpty {
                            if canDo {
                                if tex == "" || tex == " " {} else {
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = GlobalStruct.dateFormat
                                    let time = dateFormatter.date(from: theDate) ?? Date()
                                    let y = MockMessage.init(text: tex, sender: sender, messageId: x.account?.acct ?? "", date: time, account: x.account)
                                    if c <= self.messages.count {
                                        self.messages.insert(y, at: c)
                                        self.messagesMedia.insert(UIImage(), at: c)
                                    }
                                }
                            } else {
                                canDo = true
                            }
                        } else {
                            _ = x.mediaAttachments.reversed().map({ y in
                                if let z = y.previewURL {
                                    if let url = URL(string: z) {
                                        URLSession.shared.dataTask(with: url) { data, response, error in
                                            guard
                                                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                                                let data = data, error == nil,
                                                let _ = UIImage(data: data)
                                            else { return }
                                            DispatchQueue.main.async() { [weak self] in
                                                let image = UIImage(data: data)!
                                                let dateFormatter = DateFormatter()
                                                dateFormatter.dateFormat = GlobalStruct.dateFormat
                                                let time = dateFormatter.date(from: theDate) ?? Date()
                                                let y2 = MockMessage.init(image: image, sender: sender, messageId: x.account?.acct ?? "", date: time, account: x.account)
                                                if c <= (self?.messages.count ?? 0) {
                                                    self?.messages.insert(y2, at: c)
                                                    self?.messagesMedia.insert(image, at: c)
                                                }
                                            }
                                        }.resume()
                                    }
                                }
                            })
                            if canDo {
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = GlobalStruct.dateFormat
                                let time = dateFormatter.date(from: theDate) ?? Date()
                                let y = MockMessage.init(text: tex, sender: sender, messageId: x.account?.acct ?? "", date: time, account: x.account)
                                if c <= self.messages.count {
                                    self.messages.insert(y, at: c)
                                    self.messagesMedia.insert(UIImage(), at: c)
                                }
                            } else {
                                canDo = true
                            }
                        }
                    })
                    
                    self.messages = self.messages.sorted(by: { x, y in
                        x.sentDate < y.sentDate
                    })
                    
                    self.messagesCollectionView.reloadData()
                    self.messagesCollectionView.scrollToLastItem(animated: true)
                }
            }
        }
    }
    
    func didSelectURL(_ url: URL) {
        triggerHapticSelectionChanged()
        PostActions.openLink(url)
    }

    func didSelectHashtag(_ hashtag: String) {
        
    }

    func didSelectMention(_ mention2: String) {
        
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        switch detector {
        case .hashtag, .mention, .url: return isFromCurrentSender(message: message) ? [.foregroundColor: UIColor.white.withAlphaComponent(0.75), .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)] : [.foregroundColor: UIColor.label.withAlphaComponent(0.75), .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)]
        default: return MessageLabel.defaultAttributes
        }
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .mention, .hashtag]
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        
    }
    
    @objc func didTouchSend(sender: UIButton) {
        let theText = messageInputBar.inputTextView.text ?? ""
        if self.canPost {
            triggerHapticImpact(style: .light)
            let theText2 = NSMutableAttributedString(string: theText)
            theText2.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.9), NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)], range: theText2.mutableString.range(of: theText2.string))
            let sender = MockUser(senderId: "1", displayName: "\(AccountsManager.shared.currentUser()?.displayName ?? "")")
            if self.currentImage == UIImage() {
                let x = MockMessage.init(attributedText: theText2, sender: sender, messageId: "18982", date: Date())
                messages.append(x)
            } else {
                let x = MockMessage.init(image: self.currentImage, sender: sender, messageId: "18982", date: Date())
                messages.append(x)
                self.currentImage = UIImage()
                if theText != "" {
                    let x2 = MockMessage.init(attributedText: theText2, sender: sender, messageId: "18982", date: Date())
                    messages.append(x2)
                }
            }
            self.image1.alpha = 0
            messagesCollectionView.reloadData()
            self.messagesCollectionView.scrollToLastItem(animated: true)
            messageInputBar.inputTextView.text = ""
            postDirectMessage(to: self.currentStatus.last?.id ?? "", message: theText)
        }
    }
    
    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < messages.count else { return false }
        return messages[indexPath.section].sender.displayName == messages[indexPath.section + 1].sender.displayName
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(tail, .curved)
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor.white : UIColor.label
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .custom.baseTint : .custom.quoteTint
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if !isPreviousMessageSameSender(at: indexPath) {
            return 34
        }
        return 0
    }
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return messages[indexPath.section].sender.displayName == messages[indexPath.section - 1].sender.displayName
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateString = MessageKitDateFormatter.shared.string(from: message.sentDate)
        if !isPreviousMessageSameSender(at: indexPath) {
            return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        }
        return nil
    }
    
   func postDirectMessage(to recipientUserId: String, message: String) {
       var z = self.currentStatus.last { x in
           (x.account?.id ?? "") != (self.currentUserID ?? "")
       }
       if z == nil {
           z = self.currentStatus.first
       }
       let x = self.allCurrentMessages.last { x in
           (x.account?.id ?? "") != (self.currentUserID ?? "")
       }
       var mess = "@\(x?.account?.acct ?? self.currentAccounts.first?.acct ?? "") \(message)"
       if self.currentAccounts.count > 1 {
           var allAccounts = ""
           for (c,x) in self.currentAccounts.enumerated() {
               if c == 0 {
                   allAccounts = "@\(x.acct)"
               } else {
                   allAccounts = "\(allAccounts) @\(x.acct)"
               }
           }
           mess = "\(allAccounts) \(message)"
       }
       let request = Statuses.create(status: mess, replyToID: z?.id ?? "", mediaIDs: [self.mediaIdString], spoilerText: nil, scheduledAt: nil, poll: GlobalStruct.newPollPost, visibility: .direct)
       self.client!.run(request) { (statuses) in
           print("new message sent - \(statuses)")
           if let stat = statuses.value {
               DispatchQueue.main.async {
                   self.currentStatus = [stat]
               }
           }
       }
   }
    
}

struct MockMessage: MessageType {
    var messageId: String
    var sender: SenderType
    var sentDate: Date
    var kind: MessageKind
    var account: Account? = nil
    
    private init(kind: MessageKind, sender: SenderType, messageId: String, date: Date, account: Account? = nil) {
        self.kind = kind
        self.sender = sender
        self.messageId = messageId
        self.sentDate = date
        self.account = account
    }
    
    init(custom: Any?, sender: SenderType, messageId: String, date: Date) {
        self.init(kind: .custom(custom), sender: sender, messageId: messageId, date: date)
    }
    
    init(text: String, sender: SenderType, messageId: String, date: Date, account: Account? = nil) {
        self.init(kind: .text(text), sender: sender, messageId: messageId, date: date, account: account)
    }
    
    init(attributedText: NSAttributedString, sender: SenderType, messageId: String, date: Date) {
        self.init(kind: .attributedText(attributedText), sender: sender, messageId: messageId, date: date)
    }
    
    init(image: UIImage, sender: SenderType, messageId: String, date: Date, account: Account? = nil) {
        let mediaItem = ImageMediaItem(image: image)
        self.init(kind: .photo(mediaItem), sender: sender, messageId: messageId, date: date, account: account)
    }
}

struct MockUser: SenderType {
    var senderId: String
    var displayName: String
    
    init(senderId: String, displayName: String) {
        self.senderId = senderId
        self.displayName = displayName
    }
}

struct ImageMediaItem: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(image: UIImage) {
        self.image = image
        self.size = CGSize(width: 240, height: 160)
        self.placeholderImage = UIImage()
    }
}

extension ChatMessagesViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        guard let data = try? Data(contentsOf: outputFileURL) else {
            return
        }
        print("File size before compression: \(Double(data.count / 1048576)) mb")
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + UUID().uuidString + ".mp4")
        compressVideo(inputURL: outputFileURL as URL,
                      outputURL: compressedURL) { exportSession in
            guard let session = exportSession else {
                return
            }
            switch session.status {
            case .unknown:
                break
            case .waiting:
                break
            case .exporting:
                break
            case .completed:
                guard let compressedData = try? Data(contentsOf: compressedURL) else {
                    return
                }
                print("File size after compression: \(Double(compressedData.count / 1048576)) mb")
            case .failed:
                break
            case .cancelled:
                break
            @unknown default:
                log.error("Failed to handle files")
                break
            }
        }
    }

    func compressVideo(inputURL: URL,
                       outputURL: URL,
                       handler:@escaping (_ exportSession: AVAssetExportSession?) -> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPreset3840x2160) else {
            handler(nil)
            return
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.exportAsynchronously {
            handler(exportSession)
        }
    }
}




