//
//  NewPostViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 07/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import PhotosUI
import MobileCoreServices
import UniformTypeIdentifiers
import AVFoundation
import NaturalLanguage
import AVKit
import LinkPresentation
#if canImport(ActivityKit)
import ActivityKit
#endif

// swiftlint:disable:next type_body_length
class NewPostViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UITextFieldDelegate, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SKPhotoBrowserDelegate, AVPlayerViewControllerDelegate, UIDocumentPickerDelegate, SwiftyGiphyViewControllerDelegate, UIDropInteractionDelegate {
    
    let kButtonSide = 70.0
    let kButtonToKeyboardGap = 20.0 // between the image buttons and keyboard
    let kCellLowerMargin = 20.0     // between image/visiblity buttons, and the cell content
    var keyboardRect: CGRect = CGRectZero
    let maxVideoSize: Int = 40      // in MB - Mastodon rejects videos > 40MB
    
    // top of the keyboard, in self.view coordinates
    var topOfKeyboard: CGFloat {
        if CGRectIsEmpty(self.keyboardRect) {
            return CGRectGetMaxY(self.view.bounds)
        } else {
            let keyboardInLocal = self.view.convert(self.keyboardRect.origin, from: nil)
            return keyboardInLocal.y
        }
    }
    
    var pickerController: UIDocumentPickerViewController?
    
    private var pendingRequestWorkItem: DispatchWorkItem?
    
    var visibImages = 0
    var spoilerText: String = ""
    let btn1 = UIButton(type: .custom)
    let btn2 = UIButton(type: .custom)
    var tableView = UITableView()
    var inReplyId: String = ""
    var currentFullName: String = ""
    var fromShare: Bool = false
    var fromShareV: Bool = false
    var fromShare2: Bool = false
    var fromNewDM: Bool = false
    var fromExpanded: String = ""
    var fromEdit: Status? = nil
    var postCharacterCount: Int = 500   // characters remaining in this post
    var postCharacterCount2: Int = 500  // max characters allowed per post
    var formatToolbar = UIToolbar()
    var formatToolbar2 = UIToolbar()
    var scrollViewM = UIScrollView()
    var trimmedAtString: String = ""
    var canPost: Bool = false
    var whoCanReply: Visibility? = .public
    var whoCanReplyPill = UIButton()
    var allStatuses: [Status] = []
    var quoteString: String = ""
    var photoPickerView: PHPickerViewController!
    let photoPickerView2 = UIImagePickerController()
    var mediaData: Data = Data()
    var mediaIdStrings: [String] = []
    var mediaAttached: Bool = false // Looks like this is never cleared (?)
    var hasEditedText = false
    var hasEditedMedia = false
    var hasEditedMetadata = false // CW, Sensitive, Post Language
    var hasEditedPoll = false
    let numImages = 4
    var imageButton = [UIButton(), UIButton(), UIButton(), UIButton()]
    var audioAttached: Bool = false
    var videoAttached: Bool = false
    var videoAttachedCheckForAttachingImages: Bool = false // check whether videos have been attached when attempting to add images
    var doneOnce: Bool = false
    var currentAcct = AccountsManager.shared.currentAccount
    var currentUser: Account? {
        return (currentAcct as? MastodonAcctData)?.account
    }
    var itemLast = UIBarButtonItem()
    var fromPro: Bool = false
    var placeCursorAtEndOfText = true
    var proText: String = ""
    var cellPostText: String = ""           // storage for the cell post text
    var cellPostTextView: UITextView? = nil // reference to the cell post UITextView
    // quote post
    var followedByQuotedAccount : FollowManager.FollowStatus = .unknown
    var quotedAccountPublicSocialGraph = false
    var isQuotePost = false
    var quotedAccount: Account? = nil
    var haveUpdatedPostWithQuoteURL = false
    var quotePostCell = ComposeQuotePostCell()
    // view
    var scrollView = UIScrollView()
    var cwHeight: CGFloat = 0
    let dateViewBG = UIButton()
    let dateView = UIView()
    let datePicker = UIDatePicker()
    var tempDate = Date()
    var scheduledTime: String? = nil
    var userItemsAll: [Account] = []
    var tagsAll: [Tag] = []
    var keyboardSizeView = UIView()          // tracks the keyboard view size
    var keyboardSizeHeightConstraint: NSLayoutConstraint? = nil
    // video
    var assetWriter: AVAssetWriter!
    var assetWriterVideoInput: AVAssetWriterInput!
    var audioMicInput: AVAssetWriterInput!
    var videoURL: URL!
    var audioAppInput: AVAssetWriterInput!
    var channelLayout = AudioChannelLayout()
    var assetReader: AVAssetReader?
    let bitrate: NSNumber = NSNumber(value: 1500000)
    var vUrl: URL!
    var doneImagesOnce: Bool = false
    private lazy var progressRing = [ALProgressRing(), ALProgressRing(), ALProgressRing(), ALProgressRing()]
    var visibleImages: Int = 0
    var uploaded = [false, false, false, false]
    var fromAction: Bool = false
    var otherInstance: String = ""
    var isSensitive: Bool = false
    var fromDetailReply: Bool = false
    var detailReplyToEdit: String = ""
    var gifAttached: Bool = false
    var mediaItemsDisabled: Bool = false
    var thumbnailAttempt: Int = 0
    var fromCamera: Bool = false
    var hasUpdatedReplyingTo: Bool = false
    var instanceCanEditAltText: Bool = true
    
    var isProcessingVideo: Bool = false
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileCell {
            cell.profileIcon.layer.borderColor = UIColor.custom.baseTint.cgColor
        }
        for cell in self.tableView.visibleCells {
            if let cell = cell as? PostCell {
                let cell = cell.p
                cell.postText.textColor = .custom.mainTextColor
                cell.linkPost.textColor = .custom.mainTextColor2
            }
        }
        self.dateViewBG.frame = self.view.frame
        
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
        self.updateCharacterCounts()
        self.updateSubviewFrames()
    }

    @objc func keyboardWillShowNotification(notification: Notification) {
        self.createToolbar()
    }
    
    @objc func keyboardDidHideOrShowNotification(notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            self.keyboardRect = keyboardFrame.cgRectValue
            if GlobalStruct.inVideoPlayer {
                self.keyboardRect = CGRectZero
            }
            self.updateSubviewFrames()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateReplyingToIfNecessary()
        self.tableView.reloadData()
        self.updateCharacterCounts()
    }
    
    private func updateReplyingToIfNecessary() {
        log.error("--- THINKING about DOING IT")
        // Only do this once, when first loading the view
        if !hasUpdatedReplyingTo && self.cellPostTextView != nil {
            self.hasUpdatedReplyingTo = true
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                if !GlobalStruct.inVideoPlayer {
                    self.updateReplyingTo()
                }
            }
        }
    }
    
    // who can reply, reply people
    @objc func updateReplyingTo() {
        if self.fromNewDM {
            if self.fromExpanded != "" {
                cellPostText = "@\(self.fromExpanded) "
                self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
            } else {
                cellPostText = "@"
                self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
            }
        } else {
            if self.fromPro {} else {
                let serverPostVisibility = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.defaultPostVisibility
                self.whoCanReply = self.allStatuses.first?.reblog?.visibility ?? self.allStatuses.first?.visibility ?? serverPostVisibility ?? .public
            }
        }
        
        // create toolbar
        self.createToolbar()
        self.createToolbar2()
        
        
        if self.cellPostTextView != nil && self.cellPostTextView!.isFirstResponder {
            log.warning("toggling FR")
            cellPostTextView?.resignFirstResponder()
        }

        self.cellPostTextView?.becomeFirstResponder()

        if self.fromPro {
            cellPostText = self.proText
            self.updateQuotePostURL()
            self.tableView.beginUpdates()
            if self.isQuotePost {
                self.tableView.reloadSections(IndexSet(2...2), with: .none)
            }
            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
            self.tableView.endUpdates()
        }
        
        var allMentions: [Mention] = []
        if let x = self.allStatuses.first?.reblog?.mentions ?? self.allStatuses.first?.mentions {
            allMentions = x
        }
        // Filter out certain accounts
        let mainReplyAccount = self.allStatuses.first?.reblog?.account ?? self.allStatuses.first?.account
        allMentions = allMentions.filter({ x in
            let duplicateMention = x.acct == mainReplyAccount?.acct // make sure we aren't duplicating mentions if someone pings themself
            let pingingSelf = x.url == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.account.url //make sure we aren't pinging ourself
            return !(duplicateMention || pingingSelf)
        })
        allMentions = allMentions.filter({ x in
            if GlobalStruct.excludeUsers.contains(x.id) {
                return false
            } else {
                return true
            }
        })

        if self.allStatuses.isEmpty {} else {
            // change placeholder text
            if let _ = self.allStatuses.first?.reblog?.id ?? self.allStatuses.first?.id {
                if self.quoteString.isEmpty {
                    var moreUsers: String = ""
                    _ = allMentions.map({ x in
                        if x.acct.contains("@") {
                            moreUsers = "\(moreUsers) @\(x.acct)"
                        } else {
                            if self.otherInstance != "" {
                                moreUsers = "\(moreUsers) @\(x.acct)@\(self.otherInstance)"
                            } else {
                                moreUsers = "\(moreUsers) @\(x.acct)"
                            }
                        }
                    })
                    if mainReplyAccount?.url == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.account.url ?? "" {
                        if moreUsers == "" {} else {
                            cellPostText = "\(moreUsers) "
                            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                        }
                    } else {
                        var mainReplyString = ""
                        if mainReplyAccount?.acct.contains("@") ?? false {
                            cellPostText = "@\(mainReplyAccount!.acct)\(moreUsers) "
                            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                        } else {
                            if mainReplyAccount?.server != (AccountsManager.shared.currentAccount as? MastodonAcctData)?.account.server {
                                cellPostText = "@\(mainReplyAccount?.fullAcct ?? "")\(moreUsers) "
                                mainReplyString = "\(mainReplyAccount?.fullAcct ?? "")"
                                self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                            } else {
                                cellPostText = "@\(mainReplyAccount?.acct ?? "")\(moreUsers) "
                                self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                            }
                        }
                        
                        // select moreUsers text with cursor
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let cellPostTextView = self.cellPostTextView {
                                if let startPos = cellPostTextView.position(from: cellPostTextView.beginningOfDocument, offset: mainReplyString.count + 2) {
                                    if let endPos = cellPostTextView.position(from: cellPostTextView.beginningOfDocument, offset: mainReplyString.count + 2 + moreUsers.count) {
                                        cellPostTextView.selectedTextRange = cellPostTextView.textRange(from: startPos, to: endPos)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            self.spoilerText = self.allStatuses.first?.spoilerText ?? ""
            if self.spoilerText != "" {
                self.cwHeight = UITableView.automaticDimension
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
                self.createToolbar()
                if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AltTextCell2 {
                    cell.altText.placeholder = "Content warning..."
                    cell.altText.becomeFirstResponder()
                    cell.altText.text = self.spoilerText
                    cell.altText.isHidden = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
                }
            }
        }
        
        // display media from Share Extension
        if self.fromShare {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.addMediaFromShare()
            }
        }
        // display videos from Share Extension
        if self.fromShareV {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.addVideosFromShare()
            }
        }
        // display text from Share Extension
        if self.fromShare2 {
            self.addTextFromShare()
        }
        
        // fill in edit post details
        if let stat = self.fromEdit {
            // Edited posts can't modify their visibility
            self.whoCanReplyPill.removeFromSuperview()
            self.whoCanReply = stat.visibility
            cellPostText = stat.content.stripHTML()
            let _ = stat.mentions.map({ x in
                cellPostText = cellPostText.replacingOccurrences(of: x.username, with: x.acct)
            })
            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
            if let pollOptions = stat.poll?.options {
                let date1 = stat.poll?.expiresAt ?? ""
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = GlobalStruct.dateFormat
                let date = dateFormatter.date(from: date1)
                
                let expiresIn = date ?? Date()
                let diff = Calendar.current.dateComponents([.second], from: Date(), to: expiresIn).second ?? 0
                var str: [String] = []
                _ = pollOptions.map({ x in
                    str.append(x.title)
                })
                let a: [Any] = [str, diff, stat.poll?.multiple ?? false, false]
                GlobalStruct.newPollPost = a
                self.createToolbar()
            }
            self.spoilerText = stat.spoilerText.stripHTML()
            if self.spoilerText != "" {
                self.cwHeight = UITableView.automaticDimension
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
                self.createToolbar()
                if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AltTextCell2 {
                    cell.altText.placeholder = "Content warning..."
                    cell.altText.becomeFirstResponder()
                    cell.altText.text = self.spoilerText
                    cell.altText.isHidden = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
                }
            }
            
            // media
            if !stat.mediaAttachments.isEmpty {
                self.isSensitive = stat.sensitive ?? false
                
                
                for mainIndex in 0..<numImages {
                    if stat.mediaAttachments.count == mainIndex+1 {
                        
                        for index in 0...mainIndex {

                            self.mediaIdStrings.append(stat.mediaAttachments[index].id)
                            if stat.mediaAttachments[index].type == .video || stat.mediaAttachments[index].type == .gifv {
                                if let ur = URL(string: stat.mediaAttachments[index].url) {
                                    self.videoAttached = true
                                    self.vUrl = ur
                                    self.tryDisplayThumbnail(url: self.vUrl)
                                }
                            } else if index == 0 && stat.mediaAttachments[0].type == .audio {
                                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
                                let photoToAttach = UIImage(systemName: "waveform.path", withConfiguration: symbolConfig)?.withTintColor(UIColor.black.withAlphaComponent(0.2), renderingMode: .alwaysOriginal)
                                self.imageButton[0].backgroundColor = .custom.baseTint
                                self.imageButton[0].setImage(photoToAttach, for: .normal)
                                self.imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                                UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                                    self.imageButton[0].alpha = 1
                                    self.imageButton[0].transform = CGAffineTransform.identity
                                }, completion: { x in
                                    
                                })
                                if let ur = URL(string: stat.mediaAttachments[0].url) {
                                    self.audioAttached = true
                                    self.videoAttached = false
                                    self.vUrl = ur
                                    self.createToolbar()
                                }
                            } else {
                                self.imageButton[index].sd_setImage(with: URL(string: stat.mediaAttachments[index].url), for: .normal)
                            }
                            if stat.mediaAttachments[index].type == .gifv {
                                self.videoAttached = false
                                self.gifAttached = true
                            }
                            self.imageButton[index].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                            self.imageButton[index].backgroundColor = .custom.baseTint
                            UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                                self.imageButton[index].alpha = 1
                                self.imageButton[index].transform = CGAffineTransform.identity
                            }, completion: { x in
                                
                            })
                        }
                        
                        // Disable remaining buttons
                        for index in mainIndex+1..<numImages {
                            self.imageButton[index].isUserInteractionEnabled = false
                        }
                    }
                }
            } else {
                for index in 0..<numImages {
                    self.imageButton[index].alpha = 0
                }
            }
        }
        
        self.parseText()
        self.updateCharacterCounts()
        if isQuotePost {
            self.moveCursorToBeginning()
        }
        // Handle the @ DM case
        if self.fromNewDM && self.fromExpanded == "" {
            self.moveCursorToEnd()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.cellPostTextView?.resignFirstResponder()
        }
    }
    
    @objc func updateToolbar() {
        self.createToolbar()
        self.updatePostButton()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let z = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PostCell {
            if scrollView.contentOffset.y + 1 < (z.bounds.size.height - (self.navigationController?.navigationBar.bounds.size.height ?? 0)) {
                for index in 0..<numImages {
                    // Delays: .06, .04, .02, .00
                    UIView.animate(withDuration: 0.65, delay: 0.02 * Double(numImages-index-1), usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                        self.imageButton[index].alpha = 0
                        self.imageButton[index].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                    }, completion: { x in
                        
                    })
                }
            } else {
                for index in 0..<numImages {
                    if self.imageButton[index].currentImage != nil {
                        // Delays: .00, .02, .04, .06
                        UIView.animate(withDuration: 0.65, delay: 0.02 * Double(index), usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                            self.imageButton[index].alpha = 1
                            self.imageButton[index].transform = CGAffineTransform.identity
                        }, completion: { x in
                            
                        })
                    }
                }
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if GlobalStruct.isCompact || UIDevice.current.userInterfaceIdiom == .phone {
            view.backgroundColor = .custom.backgroundTint
            self.setupNavBar(.custom.backgroundTint)
        } else {
            switch traitCollection.userInterfaceStyle {
            case .light, .unspecified:
                view.backgroundColor = .custom.backgroundTint
                self.setupNavBar(.custom.backgroundTint)
            case .dark:
                view.backgroundColor = .secondarySystemBackground
                self.setupNavBar(.secondarySystemBackground)
            @unknown default:
                log.error("Failed to determine userInterfaceStyle")
                view.backgroundColor = .custom.backgroundTint
                self.setupNavBar(.custom.backgroundTint)
            }
        }
    }
    
    func setupNavBar(_ col: UIColor) {
        // set up nav bar
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = col
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
    
    override var keyCommands: [UIKeyCommand]? {
        let sendPost = UIKeyCommand(input: "\r", modifierFlags: [.command], action: #selector(sendTap))
        sendPost.discoverabilityTitle = "Post Post"
        if #available(iOS 15, *) {
            sendPost.wantsPriorityOverSystemBehavior = true
        }
        let closeWindow = UIKeyCommand(input: "w", modifierFlags: [.command], action: #selector(dismissTap))
        closeWindow.discoverabilityTitle = NSLocalizedString("generic.dismiss", comment: "")
        if #available(iOS 15, *) {
            closeWindow.wantsPriorityOverSystemBehavior = true
        }
        return [sendPost, closeWindow]
    }
    
    @objc func translateAdded() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.cellPostText = GlobalStruct.tempPostTranslate
            GlobalStruct.tempPostTranslate = ""
            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
//        self.saveDraft()
    }
    
    func addMediaFromShare() {
        let sharedGroupContainerDirectory = FileManager().containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.theblvd.mammoth.wormhole")
        guard let fileURL = sharedGroupContainerDirectory?.appendingPathComponent("savedMedia.json") else { return }
        guard let fileContent = try? Data(contentsOf: fileURL) else { return }
        
        let photoToAttach = UIImage(data: fileContent) ?? UIImage()
        
        self.setupImages()
        
        for index in 1..<numImages { // All but the first
            self.imageButton[index].alpha = 0
        }
        self.imageButton[0].setImage(photoToAttach, for: .normal)
        self.imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
            self.imageButton[0].alpha = 1
            self.imageButton[0].transform = CGAffineTransform.identity
        }, completion: { x in
            
        })
        
        self.mediaData = photoToAttach.jpegData(compressionQuality: 0.7) ?? Data()
        self.videoAttached = false
        self.gifAttached = false
        self.attachPhoto()
        self.cellPostTextView?.resignFirstResponder()
        self.cellPostTextView?.becomeFirstResponder()
    }
    
    func addVideosFromShare() {
        let sharedGroupContainerDirectory = FileManager().containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.theblvd.mammoth.wormhole")
        guard let fileURL = sharedGroupContainerDirectory?.appendingPathComponent("savedMedia.json") else { return }
        guard let fileContent = try? Data(contentsOf: fileURL) else { return }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videoURL = documentsURL.appendingPathComponent("video.mp4")
        try? fileContent.write(to: videoURL)
        
        self.setupImages()
        
        self.vUrl = videoURL
        self.tryDisplayThumbnail(url: videoURL)
        for index in 1..<numImages { // All but the first
            self.imageButton[index].alpha = 0
        }
        self.imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
            self.imageButton[0].alpha = 1
            self.imageButton[0].transform = CGAffineTransform.identity
        }, completion: { x in
            
        })
        
        self.videoAttached = true
        self.mediaData = fileContent
        Task {
            await self.attachVideo()
        }
        
        self.cellPostTextView?.resignFirstResponder()
        self.cellPostTextView?.becomeFirstResponder()
    }
    
    func addTextFromShare() {
        let userDefaults = UserDefaults(suiteName: "group.com.theblvd.mammoth.wormhole")
        if let theData = userDefaults?.value(forKey: "shareExtensionText") as? String {
            self.cellPostText = theData
            self.cellPostTextView?.resignFirstResponder()
            self.cellPostTextView?.becomeFirstResponder()
            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
            self.hasEditedText = true
            updatePostButton()
        }
    }
    
    override func paste(_ sender: Any?) {
        let pasteboard = UIPasteboard.general
        if pasteboard.hasImages {
            triggerHapticImpact(style: .light)
            let photoToAttach = pasteboard.image ?? UIImage()
            
            // attach photo
            if self.videoAttached {
                self.imageButton[0].alpha = 0
            }
            for index in 0..<numImages {
                if self.imageButton[index].alpha == 0 {
                    self.imageButton[index].setImage(photoToAttach, for: .normal)
                    self.imageButton[index].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                        self.imageButton[index].alpha = 1
                        self.imageButton[index].transform = CGAffineTransform.identity
                    }, completion: { x in
                        
                    })
                    break
                }
            }
            self.mediaData = photoToAttach.jpegData(compressionQuality: 0.7) ?? Data()
            self.videoAttached = false
            self.gifAttached = false
            self.attachPhoto()
            self.cellPostTextView?.resignFirstResponder()
            self.cellPostTextView?.becomeFirstResponder()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if GlobalStruct.isCompact || UIDevice.current.userInterfaceIdiom == .phone {
            view.backgroundColor = .custom.backgroundTint
            self.setupNavBar(.custom.backgroundTint)
        } else {
            switch traitCollection.userInterfaceStyle {
            case .light, .unspecified:
                view.backgroundColor = .custom.backgroundTint
                self.setupNavBar(.custom.backgroundTint)
            case .dark:
                view.backgroundColor = .secondarySystemBackground
                self.setupNavBar(.secondarySystemBackground)
            @unknown default:
                log.error("Failed to determine userInterfaceStyle")
                view.backgroundColor = .custom.backgroundTint
                self.setupNavBar(.custom.backgroundTint)
            }
        }
        
        let dropInteraction = UIDropInteraction(delegate: self)
        self.view.addInteraction(dropInteraction)
        
        GlobalStruct.altAdded = [:]
        GlobalStruct.whichImagesAltText = []
        GlobalStruct.excludeUsers = []
        GlobalStruct.showingNewPostComposer = true
        GlobalStruct.placeID = ""
        GlobalStruct.mediaEditID = ""
        GlobalStruct.mediaEditDescription = ""
        
        self.view.addSubview(keyboardSizeView)
        keyboardSizeView.backgroundColor = .clear
        keyboardSizeView.translatesAutoresizingMaskIntoConstraints = false
        keyboardSizeView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        keyboardSizeView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        keyboardSizeView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        keyboardSizeHeightConstraint = keyboardSizeView.heightAnchor.constraint(equalToConstant: 0)
        keyboardSizeHeightConstraint?.isActive = true
        
        self.whoCanReplyPill.backgroundColor = .custom.quoteTint
        self.whoCanReplyPill.layer.cornerCurve = .continuous
        self.whoCanReplyPill.layer.cornerRadius = 10
        self.whoCanReplyPill.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        self.whoCanReplyPill.layer.shadowOffset = CGSize(width: 3, height: 3)
        self.whoCanReplyPill.layer.shadowOpacity = 1.0
        self.whoCanReplyPill.layer.shadowRadius = 10.0
        let existingInsets = self.whoCanReplyPill.titleEdgeInsets
        self.whoCanReplyPill.contentEdgeInsets = UIEdgeInsets(top: existingInsets.top, left: 10, bottom: existingInsets.bottom, right: 10)
        self.view.addSubview(self.whoCanReplyPill)
        self.whoCanReplyPill.translatesAutoresizingMaskIntoConstraints = false
        self.whoCanReplyPill.heightAnchor.constraint(equalToConstant: 46).isActive = true
        self.whoCanReplyPill.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20).isActive = true
        self.whoCanReplyPill.bottomAnchor.constraint(equalTo: keyboardSizeView.topAnchor, constant: -kButtonToKeyboardGap).isActive = true
        
        self.refreshDrafts()
        
        NotificationCenter.default.addObserver(self,selector: #selector(keyboardWillShowNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(keyboardDidHideOrShowNotification), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(keyboardDidHideOrShowNotification), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.saveDraft), name: NSNotification.Name(rawValue: "saveDraft"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateToolbar), name: NSNotification.Name(rawValue: "updateToolbar"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.restoreFromDrafts), name: NSNotification.Name(rawValue: "restoreFromDrafts"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.restoreFromTemplate), name: NSNotification.Name(rawValue: "restoreFromTemplate"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.canvasAdded), name: NSNotification.Name(rawValue: "canvasAdded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.translateAdded), name: NSNotification.Name(rawValue: "translateAdded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.createToolbar), name: NSNotification.Name(rawValue: "createToolbar"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.addEmoji), name: NSNotification.Name(rawValue: "addEmoji"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updatePostButton), name: NSNotification.Name(rawValue: "updatePostButton"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.quotePostDidUpdate), name: didUpdateQuotePostNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(self.followStatusNotification), name: didChangeFollowStatusNotification, object: nil)
        
        InstanceFeatures.supportsFeature(.editingAltText) { supported, instanceInfo in
            DispatchQueue.main.async {
                self.postCharacterCount = instanceInfo?.configuration?.statuses?.maxCharacters ?? 500
                self.postCharacterCount2 = self.postCharacterCount
                self.navigationItem.title = "\(self.postCharacterCount)"
                self.navigationItem.accessibilityLabel = "\(self.postCharacterCount) characters remaining"
                self.instanceCanEditAltText = supported
                if !self.instanceCanEditAltText {
                    self.setupImages2()
                }
                self.updateCharacterCounts()
            }
        }
        
        GlobalStruct.canPostPost = true
        
        // set up nav
        setupNav()
        
        // set up table
        setupTable()
        
        // update quoted account relationship to currentAccount
        if self.isQuotePost {
            Task.detached(priority: .userInitiated) { [weak self] in
                await self?.fetchQuotePostMetaData()
            }
        }
        
        self.updateCharacterCounts()
    }
    
    @objc func addEmoji() {
        if cellPostText == "" {
            cellPostText = ":\(GlobalStruct.emoticonToAdd):"
        } else if cellPostText.last == " " {
            cellPostText = "\(cellPostText):\(GlobalStruct.emoticonToAdd):"
        } else {
            cellPostText = "\(cellPostText) :\(GlobalStruct.emoticonToAdd):"
        }
        if let textRange = cellPostTextView?.selectedTextRange {
            cellPostTextView!.replace(textRange, withText: ":\(GlobalStruct.emoticonToAdd): ")
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
        
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        var dropProposal = UITableViewDropProposal(operation: .cancel)
        guard session.items.count <= 4 else { return dropProposal }
        dropProposal = UITableViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
        return dropProposal
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        // disable posting
        self.updatePostButton()
        
        _ = session.items.map({ x in
            if x.itemProvider.hasItemConformingToTypeIdentifier(kUTTypeGIF as String) {
                x.itemProvider.loadDataRepresentation(forTypeIdentifier: kUTTypeGIF as String) { data, error in
                    DispatchQueue.main.async {
                        triggerHapticImpact(style: .light)
                        // attach gif
                        self.imageButton[0].setImage(UIImage(data: data ?? Data()), for: .normal)
                        for index in 1..<self.numImages {
                            self.imageButton[index].alpha = 0
                        }
                        self.imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                            self.imageButton[0].alpha = 1
                            self.imageButton[0].transform = CGAffineTransform.identity
                        }, completion: { x in
                            
                        })
                        
                        self.mediaData = data ?? Data()
                        self.videoAttached = false
                        self.gifAttached = true
                        self.attachPhoto()
                        self.cellPostTextView?.resignFirstResponder()
                        self.cellPostTextView?.becomeFirstResponder()
                    }
                }
            } else {
                if x.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    x.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        DispatchQueue.main.async {
                            if let photoToAttach = image as? UIImage {
                                triggerHaptic3Impact()
                                // attach photo
                                if self.videoAttached {
                                    self.imageButton[0].alpha = 0
                                }
                                
                                if let index = self.imageButton.firstIndex(where: { imageButton in
                                    imageButton.alpha == 0
                                }) {
                                    self.imageButton[index].setImage(photoToAttach, for: .normal)
                                    self.imageButton[index].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                                    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                                        self.imageButton[index].alpha = 1
                                        self.imageButton[index].transform = CGAffineTransform.identity
                                    }, completion: { x in
                                        
                                    })
                                }
                                
                                self.mediaData = photoToAttach.jpegData(compressionQuality: 0.7) ?? Data()
                                self.videoAttached = false
                                self.gifAttached = false
                                self.attachPhoto()
                                self.cellPostTextView?.resignFirstResponder()
                                self.cellPostTextView?.becomeFirstResponder()
                            }
                        }
                    }
                }
                if x.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    x.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.movie") { data, error in
                        DispatchQueue.main.async {
                            // attach video
                            self.videoAttached = true
                            self.mediaData = data ?? Data()
                            Task {
                                await self.attachVideo()
                            }
                        }
                    }
                    x.itemProvider.loadItem(forTypeIdentifier: UTType.movie.identifier, options: [:]) { [self] (videoURL, error) in
                        DispatchQueue.main.async {
                            if let url = videoURL as? URL {
                                triggerHaptic3Impact()
                                self.setupImages2()
                                
                                self.cellPostTextView?.resignFirstResponder()
                                self.cellPostTextView?.becomeFirstResponder()

                                self.vUrl = url
                                self.tryDisplayThumbnail(url: url)
                                for index in 1..<self.numImages { // All but the first
                                    self.imageButton[index].alpha = 0
                                }
                                self.imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                                UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                                    self.imageButton[0].alpha = 1
                                    self.imageButton[0].transform = CGAffineTransform.identity
                                }, completion: { x in
                                    
                                })
                                
                            }
                        }
                    }
                }
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.fromCamera {
            self.fromCamera = false
        } else {
            NotificationCenter.default.removeObserver(self)
        }
        GlobalStruct.showingNewPostComposer = false
        GlobalStruct.newPollPost = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // set footer, so that the view scrolls to the main composer area
        let footerHe = tableView.bounds.height - tableView.rectForRow(at: IndexPath(row: 1, section: 1)).height - view.safeAreaInsets.bottom - view.safeAreaInsets.top
        let customViewFooter = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: footerHe))
        customViewFooter.isUserInteractionEnabled = false
        self.tableView.tableFooterView = customViewFooter
        self.tableView.scrollToRow(at: IndexPath(row: 1, section: 1), at: .top, animated: true)
        
        if doneOnce == false {
            // set up images
            setupImages()
            doneOnce = true
        }
        
        if doneImagesOnce == false {
            self.updateSubviewFrames()
            doneImagesOnce = true
        }
        
        if self.isQuotePost {
            self.tableView.beginUpdates()
            self.tableView.reloadSections(IndexSet(2...2), with: .none)
            self.tableView.endUpdates()
        }

        // menu items
        let lowercaseMenuItem = UIMenuItem(title: "Lower Case", action: #selector(lowercaseTapped))
        let uppercaseMenuItem = UIMenuItem(title: "Upper Case", action: #selector(uppercaseTapped))
        let randomcaseMenuItem = UIMenuItem(title: "Random Case", action: #selector(randomcaseTapped))
        UIMenuController.shared.menuItems = [lowercaseMenuItem, uppercaseMenuItem, randomcaseMenuItem]
        
        if let cellPostTextView {
            cellPostTextView.becomeFirstResponder()
            
            if placeCursorAtEndOfText {
                cellPostTextView.selectedTextRange = cellPostTextView.textRange(
                    from: cellPostTextView.endOfDocument,
                    to: cellPostTextView.endOfDocument)
            }
        }
        
        self.createToolbar()
    }
    
    @objc func lowercaseTapped() {
        if let cellPostTextView {
            if let textRange = cellPostTextView.selectedTextRange {
                let selectedText = cellPostTextView.text(in: textRange)
                cellPostTextView.text = cellPostTextView.text.replacingOccurrences(of: selectedText ?? "", with: selectedText?.lowercased() ?? selectedText ?? "")
                cellPostTextView.selectedTextRange = textRange
            }
        }
    }
    
    @objc func uppercaseTapped() {
        if let cellPostTextView {
            if let textRange = cellPostTextView.selectedTextRange {
                let selectedText = cellPostTextView.text(in: textRange)
                cellPostTextView.text = cellPostTextView.text.replacingOccurrences(of: selectedText ?? "", with: selectedText?.uppercased() ?? selectedText ?? "")
                cellPostTextView.selectedTextRange = textRange
            }
        }
    }
    
    @objc func randomcaseTapped() {
        if let cellPostTextView {
            if let textRange = cellPostTextView.selectedTextRange {
                let selectedText = cellPostTextView.text(in: textRange)
                let result = (selectedText ?? "").map {
                    if Int.random(in: 0...1) == 0 {
                        return String($0).lowercased()
                    }
                    return String($0).uppercased()
                }.joined(separator: "")
                cellPostTextView.text = cellPostTextView.text.replacingOccurrences(of: selectedText ?? "", with: result)
                cellPostTextView.selectedTextRange = textRange
            }
        }
    }
    
    func updateSubviewFrames() {
#if targetEnvironment(macCatalyst)
        for index in 0..<numImages {
            // x position is 20, 100, 180, 260
            imageButton[index].frame = CGRect(x: 20 + CGFloat(index * 80), y: view.bounds.height - 55 - 90, width: kButtonSide, height: kButtonSide)
        }
#elseif !targetEnvironment(macCatalyst)
        if UIDevice.current.userInterfaceIdiom == .pad {
            for index in 0..<numImages {
                // x position is 20, 100, 180, 260
                imageButton[index].frame = CGRect(x: 20 + CGFloat(index * 80), y: CGRectGetMaxY(tableView.frame) - kButtonSide - kButtonToKeyboardGap, width: kButtonSide, height: kButtonSide)
            }
        } else {
            for index in 0..<numImages {
                // x position is 20, 100, 180, 260
                imageButton[index].frame = CGRect(x: 20 + CGFloat(index * 80), y: CGRectGetMaxY(tableView.frame) - kButtonSide - kButtonToKeyboardGap, width: kButtonSide, height: kButtonSide)
            }
        }
#endif
        // Update the tableView height constraint
        keyboardSizeHeightConstraint?.constant = CGRectGetMaxY(keyboardSizeView.frame) - self.topOfKeyboard
    }
    
    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        self.dismiss(animated: true, completion: nil)
    }
    
    func setupNav() {
        let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        btn1.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysTemplate), for: .normal)
        btn1.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        btn1.layer.cornerRadius = 14
        btn1.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        btn1.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        btn1.addTarget(self, action: #selector(self.dismissTap), for: .touchUpInside)
        btn1.accessibilityLabel = NSLocalizedString("generic.dismiss", comment: "")
        let moreButton0 = UIBarButtonItem(customView: btn1)
        self.navigationItem.setLeftBarButton(moreButton0, animated: true)
        
        btn2.setImage(UIImage(systemName: "arrow.up", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysTemplate), for: .normal)
        btn2.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        btn2.layer.cornerRadius = 14
        btn2.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        btn2.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        btn2.addTarget(self, action: #selector(self.sendTap), for: .touchUpInside)
        btn2.accessibilityLabel = NSLocalizedString("composer.post", comment: "")
        let moreButton1 = UIBarButtonItem(customView: btn2)
        self.navigationItem.setRightBarButton(moreButton1, animated: true)
    }
    
    func setupTable() {
        tableView.register(PostCell.self, forCellReuseIdentifier: "PostCell")
        tableView.register(AltTextCell2.self, forCellReuseIdentifier: "AltTextCell2")
        tableView.register(ComposeCell.self, forCellReuseIdentifier: "ComposeCell")
        tableView.alpha = 1
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.layer.masksToBounds = true
        tableView.estimatedRowHeight = 89
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        view.sendSubviewToBack(tableView)
        
#if targetEnvironment(macCatalyst)
        self.view.addSubview(self.formatToolbar)
        self.view.addSubview(self.scrollView)
#endif
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: keyboardSizeView.topAnchor).isActive = true
    }
    
    func setupImages() {
        self.updateSubviewFrames()
        if self.fromShare || self.fromShareV {} else {
            if self.fromEdit == nil {
                for index in 0..<numImages {
                    self.imageButton[index].alpha = 0
                }
            }
        }
        self.setupImages2()
    }
    
    func setupImages2() {
        DispatchQueue.main.async {
            // check whether there is existing media from an edit
            var mediaCount: Int = 0
            if let fromEditMediaCount = self.fromEdit?.mediaAttachments.count {
                mediaCount = fromEditMediaCount
            }
            
            if !self.audioAttached {
                self.imageButton[0].backgroundColor = .clear
            }
            self.imageButton[0].layer.cornerRadius = 10
            self.imageButton[0].layer.cornerCurve = .continuous
            self.imageButton[0].imageView?.contentMode = .scaleAspectFill
            self.imageButton[0].layer.masksToBounds = true
            self.view.addSubview(self.imageButton[0])

            let image_string = NSLocalizedString("composer.media.image", comment: "")
            let view_media = NSLocalizedString("composer.media.viewMedia", comment: "")
            let add_media_description = NSLocalizedString("composer.media.altText", comment: "")
            var mediaType: String = NSLocalizedString("composer.media.video", comment: "")
            if self.gifAttached {
                mediaType = NSLocalizedString("composer.media.gif", comment: "")
            }
            let vie0 = UIAction(title: String.localizedStringWithFormat(view_media, mediaType), image: UIImage(systemName: "eye"), identifier: nil) { action in
                self.viewVideo()
            }
            vie0.accessibilityLabel = String.localizedStringWithFormat(view_media, mediaType)
            let vie1 = UIAction(title: String.localizedStringWithFormat(view_media, image_string), image: UIImage(systemName: "eye"), identifier: nil) { action in
                self.viewImages(self.imageButton[0])
            }
            vie1.accessibilityLabel = String.localizedStringWithFormat(view_media, image_string)
            let alt1 = UIAction(title: String.localizedStringWithFormat(add_media_description, image_string), image: UIImage(systemName: "character.cursor.ibeam"), identifier: nil) { action in
                self.hasEditedMetadata = true
                let vc = AltTextViewController()
                vc.currentImage = self.imageButton[0].currentImage ?? UIImage()
                if let x = GlobalStruct.altAdded[0] {
                    vc.theAltText = x
                }
                if let stat = self.fromEdit {
                    if stat.mediaAttachments.count >= 1 {
                        vc.theAltText = stat.mediaAttachments[0].description ?? ""
                    }
                }
                if self.mediaIdStrings.count > 0 {
                    vc.id = self.mediaIdStrings[0]
                    vc.whichImagesAltText = 0
                    self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
                }
            }
            alt1.accessibilityLabel = String.localizedStringWithFormat(add_media_description, image_string)
            if (self.instanceCanEditAltText == false && self.fromEdit != nil && mediaCount >= 1) || (self.mediaIdStrings.count < 1) {
                alt1.attributes = .hidden
            }
            let remove1 = UIAction(title: NSLocalizedString("generic.remove", comment: ""), image: UIImage(systemName: "trash"), identifier: nil) { action in
                triggerHapticImpact(style: .light)
                
                GlobalStruct.whichImagesAltText = GlobalStruct.whichImagesAltText.filter({ x in
                    x != 0
                })
                self.hasEditedMedia = true
                self.updatePostButton()
                self.uploaded[0] = false
                self.isProcessingVideo = false
                
                // Move all other images down by one since this one was deleted
                for indexToMove in 0..<self.numImages-1 {
                    self.imageButton[indexToMove].setImage(self.imageButton[indexToMove+1].currentImage, for: .normal)
                }
                
                // Clear alpha of any empty images
                for indexToClear in 0..<self.numImages-1 {
                    if self.imageButton[indexToClear].currentImage == nil {
                        self.imageButton[indexToClear].alpha = 0
                    }
                }
                // Clear out the last button
                self.imageButton[self.numImages-1].alpha = 0
                self.imageButton[self.numImages-1].setImage(nil, for: .normal)
                
                if self.mediaIdStrings.count > 0 {
                    self.mediaIdStrings[0] = ""
                }
                self.updatePostButton()
                self.videoAttached = false
                if self.audioAttached {
                    self.audioAttached = false
                    self.visibleImages -= 1
                    self.mediaIdStrings = []
                }
                self.createToolbar()
                self.setupImages2()
            }
            remove1.accessibilityLabel = NSLocalizedString("generic.remove", comment: "")
            remove1.attributes = .destructive
            
            if self.canPost || self.fromEdit != nil {
                if self.audioAttached {
                    let itemMenu1 = UIMenu(title: "", options: [], children: [remove1])
                    self.imageButton[0].menu = itemMenu1
                } else {
                    if self.videoAttached {
                        let itemMenu1 = UIMenu(title: "", options: [], children: [vie0, remove1])
                        self.imageButton[0].menu = itemMenu1
                    } else if self.gifAttached {
                        let itemMenu1 = UIMenu(title: "", options: [], children: [vie0, alt1, remove1])
                        self.imageButton[0].menu = itemMenu1
                    } else {
                        let itemMenu1 = UIMenu(title: "", options: [], children: [vie1, alt1, remove1])
                        self.imageButton[0].menu = itemMenu1
                    }
                }
                self.imageButton[0].showsMenuAsPrimaryAction = true
            }
            
            
            // Skip the first cell (was taken care of above in custom code)
            for index in 1..<self.numImages {
                
                self.imageButton[index].backgroundColor = .clear
                self.imageButton[index].layer.cornerRadius = 10
                self.imageButton[index].layer.cornerCurve = .continuous
                self.imageButton[index].imageView?.contentMode = .scaleAspectFill
                self.imageButton[index].layer.masksToBounds = true
                self.view.addSubview(self.imageButton[index])
                
                let vie2 = UIAction(title: String.localizedStringWithFormat(view_media, image_string), image: UIImage(systemName: "eye"), identifier: nil) { action in
                    self.viewImages(self.imageButton[index])
                }
                vie2.accessibilityLabel = String.localizedStringWithFormat(view_media, image_string)
                let alt2 = UIAction(title: String.localizedStringWithFormat(add_media_description, image_string), image: UIImage(systemName: "character.cursor.ibeam"), identifier: nil) { action in
                    self.hasEditedMetadata = true
                    let vc = AltTextViewController()
                    vc.currentImage = self.imageButton[index].currentImage ?? UIImage()
                    if let x = GlobalStruct.altAdded[index] {
                        vc.theAltText = x
                    }
                    if let stat = self.fromEdit {
                        if stat.mediaAttachments.count >= index+1 {
                            vc.theAltText = stat.mediaAttachments[index].description ?? ""
                        }
                    }
                    if self.mediaIdStrings.count > index {
                        vc.id = self.mediaIdStrings[index]
                        vc.whichImagesAltText = index
                        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
                    }
                }
                alt2.accessibilityLabel = String.localizedStringWithFormat(add_media_description, image_string)
                // Disable this if (1) editing from an instance that doesn't support it and there's media to edit, OR
                //                 (3) there's no text placeholder - it should have been added in attachPhoto()/similar
                if (self.instanceCanEditAltText == false && self.fromEdit != nil && mediaCount >= index+1) ||
                    (self.mediaIdStrings.count < index+1) {
                    alt2.attributes = .hidden
                }
                let remove2 = UIAction(title: NSLocalizedString("generic.remove", comment: ""), image: UIImage(systemName: "trash"), identifier: nil) { action in
                    triggerHapticImpact(style: .light)
                    GlobalStruct.whichImagesAltText = GlobalStruct.whichImagesAltText.filter({ x in
                        x != index
                    })
                    self.hasEditedMedia = true
                    self.updatePostButton()
                    self.uploaded[index] = false
                    
                    
                    // Move all other images down by one since this one was deleted
                    for indexToMove in index..<self.numImages-1 {
                        self.imageButton[indexToMove].setImage(self.imageButton[indexToMove+1].currentImage, for: .normal)
                    }
                    // Clear alpha of any empty images
                    for indexToClear in 0..<self.numImages {
                        if self.imageButton[indexToClear].currentImage == nil {
                            self.imageButton[indexToClear].alpha = 0
                        }
                    }
                    // Clear out the last button
                    self.imageButton[self.numImages-1].alpha = 0
                    self.imageButton[self.numImages-1].setImage(nil, for: .normal)
                    
                    if self.mediaIdStrings.count > index {
                        self.mediaIdStrings[index] = ""
                    }
                    
                    self.updatePostButton()
                }
                remove2.accessibilityLabel = NSLocalizedString("generic.remove", comment: "")
                remove2.attributes = .destructive
                let itemMenu2 = UIMenu(title: "", options: [], children: [vie2, alt2, remove2])
                if self.canPost || self.fromEdit != nil {
                    self.imageButton[index].menu = itemMenu2
                    self.imageButton[index].showsMenuAsPrimaryAction = true
                }
            }
        }
    }
    
    func viewVideo() {
        if self.vUrl == nil {
            let tempUrl = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("temp.mp4")
            GIF2MP4(data: self.mediaData)?.convertAndExport(to: tempUrl, completion: {
                self.vUrl = tempUrl
                self.viewVideo()
            })
        } else {
            let player = AVPlayer(url: self.vUrl)
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
    }
    
    func viewImages(_ image: UIButton) {
        var images = [SKPhoto]()
        let photo = SKPhoto.photoWithImage(image.currentImage ?? UIImage())
        photo.shouldCachePhotoURLImage = true
        images.append(photo)
        let originImage = image.currentImage ?? UIImage()
        let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: image, imageText: "", imageText2: 0, imageText3: 0, imageText4: "")
        browser.delegate = self
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
    
    @objc func createToolbar() {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
        formatToolbar.tintColor = .custom.baseTint
        formatToolbar.barStyle = UIBarStyle.default
        formatToolbar.isTranslucent = false
        formatToolbar.barTintColor = .custom.quoteTint
        
        let fixedSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.fixedSpace, target: nil, action: nil)
        fixedSpacer.width = 10
        let flexibleSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        // items
        let photoButtonImage = FontAwesome.image(fromChar: "\u{f03e}", weight: .bold).withConfiguration(symbolConfig).withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
        let photoButton = UIBarButtonItem(image: photoButtonImage, style: .plain, target: self, action: #selector(self.galleryTapped))
        photoButton.accessibilityLabel = NSLocalizedString("composer.media.fromGallery", comment: "")
        let cameraButton = UIBarButtonItem(image: UIImage(systemName: "camera", withConfiguration: symbolConfig)!.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(self.cameraTapped))
        cameraButton.accessibilityLabel = NSLocalizedString("composer.media.camera", comment: "")
        let gifButtonImage = FontAwesome.image(fromChar: "\u{e190}", weight: .bold).withConfiguration(symbolConfig).withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
        let gifButton = UIBarButtonItem(image: gifButtonImage, style: .plain, target: self, action: #selector(self.gifTapped))
        gifButton.accessibilityLabel = NSLocalizedString("composer.media.gif", comment: "")
        let customEmojiButtonImage = FontAwesome.image(fromChar: "\u{e409}", weight: .bold).withConfiguration(symbolConfig).withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
        let customEmojiButton = UIBarButtonItem(image: customEmojiButtonImage, style: .plain, target: self, action: #selector(self.customEmojiTapped))
        customEmojiButton.accessibilityLabel = NSLocalizedString("composer.media.customEmoji", comment: "")
        let pollButtonImage = FontAwesome.image(fromChar: "\u{f828}", weight: .regular).withConfiguration(symbolConfig).withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
        var pollButton = UIBarButtonItem(image: pollButtonImage, style: .plain, target: self, action: #selector(self.pollTapped))
        if GlobalStruct.newPollPost != nil {
            // contains a poll, tap to edit or delete
            let pollButtonImage = FontAwesome.image(fromChar: "\u{f828}", weight: .bold).withConfiguration(symbolConfig).withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
            pollButton = UIBarButtonItem(image: pollButtonImage, style: .plain, target: self, action: nil)
            
            let edit_poll = NSLocalizedString("composer.poll.edit", comment: "")
            let view31 = UIAction(title: edit_poll, image: UIImage(systemName: "pencil"), identifier: nil) { action in
                self.pollTapped(true)
            }
            view31.accessibilityLabel = edit_poll
            let remove_poll = NSLocalizedString("composer.poll.remove", comment: "")
            let view32 = UIAction(title: remove_poll, image: UIImage(systemName: "trash"), identifier: nil) { action in
                self.hasEditedPoll = true
                GlobalStruct.newPollPost = nil
                self.createToolbar()
            }
            view32.accessibilityLabel = remove_poll
            view32.attributes = .destructive
            
            let itemMenu1 = UIMenu(title: "", options: [], children: [view31, view32])
            pollButton.menu = itemMenu1
        }
        pollButton.accessibilityLabel = NSLocalizedString("composer.poll", comment: "")
        
        let imageWeight: UIFont.Weight = self.cwHeight != 0 ? .bold : .regular
        let itemCWImage = FontAwesome.image(fromChar: "\u{f321}", weight: imageWeight).withConfiguration(symbolConfig).withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
        let itemCW = UIBarButtonItem(image: itemCWImage, style: .plain, target: self, action: #selector(self.cwTapped))
        itemCW.accessibilityLabel = NSLocalizedString("composer.contentWarning", comment: "")
        
        let languageButton = toolbarLanguageButton()
        
        let itemDrafts = UIBarButtonItem(image: UIImage(systemName: "doc.text", withConfiguration: symbolConfig)!.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(self.draftsTapped))
        itemDrafts.accessibilityLabel = NSLocalizedString("composer.drafts", comment: "")
        
        itemLast = UIBarButtonItem(image: UIImage(systemName: "ellipsis", withConfiguration: symbolConfig)!.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal), style: .plain, target: self, action: nil)
        itemLast.accessibilityLabel = NSLocalizedString("generic.more", comment: "")
        itemLastMenu()
        
        if self.audioAttached {
            photoButton.isEnabled = false
            cameraButton.isEnabled = false
            gifButton.isEnabled = false
            pollButton.isEnabled = false
            photoButton.image = UIImage(systemName: "photo.on.rectangle.angled", withConfiguration: symbolConfig)!.withTintColor(.custom.baseTint.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
            cameraButton.image = UIImage(systemName: "camera", withConfiguration: symbolConfig)!.withTintColor(.custom.baseTint.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
            gifButton.image = UIImage(named: "gif.rectangle", in: nil, with: symbolConfig)!.withTintColor(.custom.baseTint.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
            pollButton.image = UIImage(systemName: "chart.pie", withConfiguration: symbolConfig)!.withTintColor(.custom.baseTint.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
        }
        if self.mediaItemsDisabled || GlobalStruct.newPollPost != nil {
            photoButton.isEnabled = false
            cameraButton.isEnabled = false
            gifButton.isEnabled = false
            photoButton.image = UIImage(systemName: "photo.on.rectangle.angled", withConfiguration: symbolConfig)!.withTintColor(.custom.baseTint.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
            cameraButton.image = UIImage(systemName: "camera", withConfiguration: symbolConfig)!.withTintColor(.custom.baseTint.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
            gifButton.image = UIImage(named: "gif.rectangle", in: nil, with: symbolConfig)!.withTintColor(.custom.baseTint.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
        }
        
        var toolbarItems = [
            photoButton,
            fixedSpacer,
            gifButton,
            fixedSpacer,
            customEmojiButton,
            fixedSpacer,
            pollButton,
            fixedSpacer,
            itemCW,
            fixedSpacer,
            languageButton,
            flexibleSpacer,
            itemLast
        ]
        if !GlobalStruct.drafts.isEmpty {
            toolbarItems.insert(contentsOf: [fixedSpacer, itemDrafts], at: toolbarItems.count-2)
        }
        formatToolbar.items = toolbarItems
        formatToolbar.sizeToFit()
        formatToolbar.frame = CGRect(x: 0, y: 0, width: 3000, height: formatToolbar.frame.size.height)
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AltTextCell2 {
            cell.altText.inputAccessoryView = self.formatToolbar
        } else {
            log.warning("expected cell at (0, 2) for toolbar")
        }
        // Only set it if needed. If the input field is already the first responder,
        // need to call reloadInputViews().
        if cellPostTextView == nil {
            log.warning("expected cellPostTextView for toolbar")
        }

        if self.cellPostTextView != nil && self.cellPostTextView!.inputAccessoryView == nil {
            self.cellPostTextView!.inputAccessoryView = self.formatToolbar
            if self.cellPostTextView!.isFirstResponder {
                self.cellPostTextView?.reloadInputViews()
            }
        }
#if targetEnvironment(macCatalyst)
        formatToolbar.frame = CGRect(x: 0, y: self.view.bounds.height - formatToolbar.bounds.size.height - 5, width: self.view.bounds.width, height: formatToolbar.frame.size.height)
#endif
        
        let everyone_string = NSLocalizedString("composer.visibility.everyone", comment: "")
        let private_string = NSLocalizedString("composer.visibility.private", comment: "")
        let followers_string = NSLocalizedString("composer.visibility.followers", comment: "")
        let unlisted_string = NSLocalizedString("composer.visibility.unlisted", comment: "")

        var visibilityText = everyone_string
        var visibilityImage = "globe"
        if self.whoCanReply == .direct {
            visibilityText = private_string
            visibilityImage = "tray.full"
        }
        if self.whoCanReply == .private {
            visibilityText = followers_string
            visibilityImage = "person.2"
        }
        if self.whoCanReply == .unlisted {
            visibilityText = unlisted_string
            visibilityImage = "lock.open"
        }
        self.whoCanReplyPill.setTitle(visibilityText, for: .normal)
        let attachment1 = NSTextAttachment()
        let symbolConfig1 = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let downImage1 = UIImage(systemName: visibilityImage, withConfiguration: symbolConfig1) ?? UIImage()
        attachment1.image = downImage1.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
        let attStringNewLine000 = NSMutableAttributedString()
        let attStringNewLine00 = NSMutableAttributedString(string: "  \(visibilityText)", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16, weight: .semibold), NSAttributedString.Key.foregroundColor : UIColor.custom.baseTint])
        let attString00 = NSAttributedString(attachment: attachment1)
        attStringNewLine000.append(attString00)
        attStringNewLine000.append(attStringNewLine00)
        self.whoCanReplyPill.setAttributedTitle(attStringNewLine000, for: .normal)
        
        let view01 = UIAction(title: everyone_string, image: UIImage(systemName: "globe"), identifier: nil) { action in
            self.whoCanReply = .public
            self.createToolbar()
        }
        view01.accessibilityLabel = everyone_string
        if self.whoCanReply == .public {
            view01.state = .on
        }
        let view21 = UIAction(title: private_string, image: UIImage(systemName: "tray.full"), identifier: nil) { action in
            self.whoCanReply = .direct
            self.createToolbar()
        }
        view21.accessibilityLabel = private_string
        if self.whoCanReply == .direct {
            view21.state = .on
        }
        let view11 = UIAction(title: followers_string, image: UIImage(systemName: "person.2"), identifier: nil) { action in
            self.whoCanReply = .private
            self.createToolbar()
        }
        view11.accessibilityLabel = followers_string
        if self.whoCanReply == .private {
            view11.state = .on
        }
        let view12 = UIAction(title: unlisted_string, image: UIImage(systemName: "lock.open"), identifier: nil) { action in
            self.whoCanReply = .unlisted
            self.createToolbar()
        }
        view12.accessibilityLabel = unlisted_string
        if self.whoCanReply == .unlisted {
            view12.state = .on
        }
        
        let post_visibility = NSLocalizedString("composer.visibility", comment: "")
        let itemMenu1 = UIMenu(title: post_visibility, options: [], children: [view01, view21, view11, view12])
        itemMenu1.accessibilityLabel = post_visibility
        self.whoCanReplyPill.menu = itemMenu1
        self.whoCanReplyPill.showsMenuAsPrimaryAction = true
    }
    
    @objc func createToolbar2() {
        formatToolbar2.tintColor = UIColor.label
        formatToolbar2.barStyle = UIBarStyle.default
        formatToolbar2.isTranslucent = false
        formatToolbar2.barTintColor = .custom.quoteTint
    }
    
    @objc func cwTapped() {
        self.hasEditedMetadata = true
        if self.cwHeight == 0 {
            self.cwHeight = UITableView.automaticDimension
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .bottom)
            self.createToolbar()
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AltTextCell2 {
                cell.altText.placeholder = NSLocalizedString("composer.contentWarning.placeholder", comment: "")
                cell.altText.becomeFirstResponder()
                cell.altText.text = self.spoilerText
                cell.altText.isHidden = false
            }
        } else {
            self.cwHeight = 0
            self.cellPostTextView?.becomeFirstResponder()
            self.createToolbar()
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .top)
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AltTextCell2 {
                cell.altText.isHidden = true
                self.spoilerText = ""
            }
        }
        self.itemLastMenu()
        self.updateCharacterCounts()
    }
    
    @objc func canvasAdded() {
        triggerHapticImpact(style: .light)
        for index in 0..<numImages {
            if self.imageButton[index].currentImage == nil || self.imageButton[index].currentImage == UIImage() {
                self.imageButton[index].backgroundColor = UIColor.white
                self.imageButton[index].setImage(GlobalStruct.canvasImage, for: .normal)
                self.imageButton[index].alpha = 1
            }
        }
        self.mediaData = GlobalStruct.canvasImage.jpegData(compressionQuality: 0.7) ?? Data()
        self.videoAttached = false
        self.gifAttached = false
        self.attachPhoto()
    }
    
    @objc func translatePostTapped() {
        let vc = TranslationComposeViewController()
        vc.postText = self.cellPostText
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    func itemLastMenu() {
        var sensitiveText: String = NSLocalizedString("composer.sensitive.add", comment: "")
        var sensitiveImage: String = "exclamationmark.triangle"
        if self.isSensitive {
            sensitiveText = NSLocalizedString("composer.sensitive.remove", comment: "")
            sensitiveImage = "exclamationmark.triangle.fill"
        }
        let viewSensitive = UIAction(title: sensitiveText, image: UIImage(systemName: sensitiveImage), identifier: nil) { action in
            self.hasEditedMetadata = true
            self.isSensitive = !self.isSensitive
            self.itemLastMenu()
            self.updatePostButton()
        }
        viewSensitive.accessibilityLabel = sensitiveText
        if self.spoilerText != "" {
            viewSensitive.attributes = .disabled
        }
        
        let translate_post_string = NSLocalizedString("post.translatePost", comment: "")
        let translatePost = UIAction(title: translate_post_string, image: UIImage(systemName: "arrow.triangle.2.circlepath"), identifier: nil) { action in
            self.translatePostTapped()
        }
        translatePost.accessibilityLabel = translate_post_string
                
        if self.imageButton[0].alpha == 1 {
            let itemMenu = UIMenu(title: "", options: [], children: [viewSensitive, translatePost])
            itemLast.menu = itemMenu
        } else {
            let itemMenu = UIMenu(title: "", options: [], children: [translatePost])
            itemLast.menu = itemMenu
        }
    }
        
    @objc func galleryTapped() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            DispatchQueue.main.async {
                var configuration = PHPickerConfiguration()
                configuration.selectionLimit = 4
                if #available(iOS 16.0, *) {
                    configuration.filter = .any(of: [.images, .screenshots, .depthEffectPhotos, .videos, .screenRecordings, .cinematicVideos, .slomoVideos, .timelapseVideos])
                } else {
                    configuration.filter = .any(of: [.videos, .images, .livePhotos])
                }
                self.photoPickerView = PHPickerViewController(configuration: configuration)
                self.photoPickerView.modalPresentationStyle = .automatic
                self.photoPickerView.view.tintColor = .custom.gold
                self.photoPickerView.delegate = self
                self.present(self.photoPickerView, animated: true, completion: nil)
            }
        }
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        // Only allow a single video, or multiple images;
        // note that the 'if / else' structure here mirrors
        // the code below.
        var videoCount = 0
        var imageCount = 0
        for result in results {
            if result.itemProvider.hasItemConformingToTypeIdentifier(kUTTypeGIF as String) {
                videoCount += 1
            } else {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    imageCount += 1
                }
                if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    videoCount += 1
                }
            }
        }
        let completion: (() -> Void)?
        if (videoCount == 1 && imageCount == 0) || (videoCount == 0) {
            // Valid selection
            completion = nil
        } else {
            // Invalid selection
            completion = {
                self.mediaFailure(title: NSLocalizedString("error.pleaseTryAgain", comment: ""), message: NSLocalizedString("composer.error.mediaLimit", comment: ""))
            }
        }
        
        dismiss(animated: true, completion: completion)
        guard completion == nil else { return }

        // disable posting
        self.updatePostButton()
        
        _ = results.map({ x in
            if x.itemProvider.hasItemConformingToTypeIdentifier(kUTTypeGIF as String) {
                x.itemProvider.loadDataRepresentation(forTypeIdentifier: kUTTypeGIF as String) { data, error in
                    DispatchQueue.main.async {
                        triggerHapticImpact(style: .light)
                        // attach gif
                        self.imageButton[0].setImage(UIImage(data: data ?? Data()), for: .normal)
                        for index in 1..<self.numImages {
                            self.imageButton[index].alpha = 0
                        }
                        self.imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                            self.imageButton[0].alpha = 1
                            self.imageButton[0].transform = CGAffineTransform.identity
                        }, completion: { x in
                            
                        })
                        
                        self.mediaData = data ?? Data()
                        self.videoAttached = false
                        self.gifAttached = true
                        self.attachPhoto()
                        self.cellPostTextView?.resignFirstResponder()
                        self.cellPostTextView?.becomeFirstResponder()
                    }
                }
            } else {
                if x.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    x.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        DispatchQueue.main.async {
                            if let photoToAttach = image as? UIImage {
                                triggerHapticImpact(style: .light)
                                // attach photo
                                if self.videoAttached {
                                    self.imageButton[0].alpha = 0
                                }
                                
                                if let index = self.imageButton.firstIndex(where: { imageButton in
                                    imageButton.alpha == 0
                                }) {
                                    self.imageButton[index].setImage(photoToAttach, for: .normal)
                                    self.imageButton[index].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                                    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                                        self.imageButton[index].alpha = 1
                                        self.imageButton[index].transform = CGAffineTransform.identity
                                    }, completion: { x in
                                        
                                    })
                                }
                                
                                self.mediaData = photoToAttach.jpegData(compressionQuality: 0.7) ?? Data()
                                self.videoAttached = false
                                self.gifAttached = false
                                self.attachPhoto()
                                self.cellPostTextView?.resignFirstResponder()
                                self.cellPostTextView?.becomeFirstResponder()
                            }
                        }
                    }
                }
                if x.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    x.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.movie") { data, error in
                        DispatchQueue.main.async {
                            // attach video
                            self.videoAttached = true
                            self.mediaData = data ?? Data()
                            Task {
                                await self.attachVideo()
                            }
                        }
                    }
                    x.itemProvider.loadItem(forTypeIdentifier: UTType.movie.identifier, options: [:]) { [self] (videoURL, error) in
                        DispatchQueue.main.async {
                            if let url = videoURL as? URL {
                                triggerHapticImpact(style: .light)
                                
                                self.setupImages2()
                                
                                self.cellPostTextView?.resignFirstResponder()
                                self.cellPostTextView?.becomeFirstResponder()

                                self.vUrl = url
                                self.tryDisplayThumbnail(itemProvider: x.itemProvider)
                                for index in 1..<self.numImages { // All but the first
                                    self.imageButton[index].alpha = 0
                                }
                                self.imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                                UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                                    self.imageButton[0].alpha = 1
                                    self.imageButton[0].transform = CGAffineTransform.identity
                                }, completion: { x in
                                    
                                })
                                
                            }
                        }
                    }
                }
            }
        })
    }
    
    func tryDisplayThumbnail(itemProvider: NSItemProvider) {
        self.imageButton[0].setImage(UIImage(), for: .normal)
        self.thumbnailAttempt = 0
        self.getThumbnailImageFromItemProvider(itemProvider: itemProvider)
    }

    func tryDisplayThumbnail(url: URL) {
        self.imageButton[0].setImage(UIImage(), for: .normal)
        self.thumbnailAttempt = 0
        self.getThumbnailImageFromVideoUrl(url: url)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // enable posting
//        updatePostButton()
        if let _ = info[UIImagePickerController.InfoKey.mediaType] as? String {
            if let photoToAttach = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                DispatchQueue.main.async {
                    triggerHapticImpact(style: .light)
                    // attach photo
                    if self.videoAttached {
                        self.imageButton[0].alpha = 0
                    }
                    
                    if let index = self.imageButton.firstIndex(where: { imageButton in
                        imageButton.alpha == 0
                    }) {
                        self.imageButton[index].setImage(photoToAttach, for: .normal)
                        self.imageButton[index].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                            self.imageButton[index].alpha = 1
                            self.imageButton[index].transform = CGAffineTransform.identity
                        }, completion: { x in
                            
                        })
                    }
                    
                    self.mediaData = photoToAttach.jpegData(compressionQuality: 0.7) ?? Data()
                    self.videoAttached = false
                    self.gifAttached = false
                    self.attachPhoto()
                    self.cellPostTextView?.resignFirstResponder()
                    self.cellPostTextView?.becomeFirstResponder()
                }
            } else {
                if let url = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL {
                    DispatchQueue.main.async {
                        // attach video
                        self.videoAttached = true
                        do {
                            let videoData = try NSData(contentsOf: url as URL, options: .mappedIfSafe)
                            self.mediaData = videoData as Data
                            Task {
                                await self.attachVideo()
                            }
                        } catch {
                            return
                        }
                    }
                    DispatchQueue.main.async {
                        triggerHapticImpact(style: .light)
                        
                        self.setupImages2()
                        
                        self.cellPostTextView?.resignFirstResponder()
                        self.cellPostTextView?.becomeFirstResponder()

                        self.vUrl = url as URL
                        self.tryDisplayThumbnail(url: url as URL)
                        for index in 1..<self.numImages { // All but the first
                            self.imageButton[index].alpha = 0
                        }
                        self.imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                            self.imageButton[0].alpha = 1
                            self.imageButton[0].transform = CGAffineTransform.identity
                        }, completion: { x in
                            
                        })
                    }
                }
            }
        }
        photoPickerView2.dismiss(animated: true, completion: nil)
    }
    
    @objc func gifTapped() {
        let vc = SwiftyGiphyViewController()
        vc.delegate = self
        let nvc = UINavigationController(rootViewController: vc)
        nvc.modalPresentationStyle = .automatic
        self.present(nvc, animated: true, completion: nil)
    }
    
    @objc func customEmojiTapped() {
        let vc = EmoticonPickerViewController(emoticons: (self.currentAcct as? MastodonAcctData)?.emoticons)
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    func giphyControllerDidSelectGif(controller: SwiftyGiphyViewController, item: GiphyItem) {
        controller.dismiss(animated: true, completion: nil)
        if let x = item.originalImage?.url {
            DispatchQueue.main.async {
                // attach gif
                self.videoAttached = true
                self.gifAttached = true
                
                if let ur = item.originalImage?.mp4URL {
                    self.vUrl = ur
                }
                
                DispatchQueue.global(qos: .utility).async {
                    do {
                        self.mediaData = try Data(contentsOf: x)
                        DispatchQueue.main.async {
                            self.imageButton[0].setImage(UIImage(data: self.mediaData), for: .normal)
                            for index in 1..<self.numImages { // All but the first
                                self.imageButton[index].alpha = 0
                            }
                            triggerHapticImpact(style: .light)
                            self.imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                            UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                                self.imageButton[0].alpha = 1
                                self.imageButton[0].transform = CGAffineTransform.identity
                            }, completion: { x in
                                
                            })
                            
                            self.attachPhoto()
                            self.cellPostTextView?.resignFirstResponder()
                            self.cellPostTextView?.becomeFirstResponder()
                        }
                    } catch {
                        log.error("Error fetching GIF from URL.")
                    }
                }
            }
        }
    }
    
    func giphyControllerDidCancel(controller: SwiftyGiphyViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func getThumbnailImageFromItemProvider(itemProvider: NSItemProvider) {
        // Put in a gray square placeholder
        let placeholder = UIImage.makeColorTile(size: CGSize(width: 100, height: 100), color: .darkGray)
        DispatchQueue.main.async {
            self.imageButton[0].setImage(placeholder, for: .normal)
            
            self.imageButton[0].addSubview(self.progressRing[0])
            self.progressRing[0].translatesAutoresizingMaskIntoConstraints = false
            self.progressRing[0].centerXAnchor.constraint(equalTo: self.imageButton[0].centerXAnchor).isActive = true
            self.progressRing[0].centerYAnchor.constraint(equalTo: self.imageButton[0].centerYAnchor).isActive = true
            self.progressRing[0].widthAnchor.constraint(equalToConstant: 50).isActive = true
            self.progressRing[0].heightAnchor.constraint(equalToConstant: 50).isActive = true
            self.progressRing[0].setProgress(0.005, animated: true)
            self.progressRing[0].startColor = .custom.baseTint
            self.progressRing[0].endColor = .custom.baseTint
            self.progressRing[0].grooveColor = .custom.backgroundTint.withAlphaComponent(0.25)
            self.progressRing[0].lineWidth = 5
            self.progressRing[0].rotate360Degrees()
        }
        let _ = itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { fileURL, error in
            guard error == nil else {
                log.error("Unable to make thumbnail from video")
                return
            }
            guard let fileURL else {
                log.error("Unable to use fileURL")
                return
            }
            let asset = AVAsset(url: fileURL)
            let avAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            avAssetImageGenerator.appliesPreferredTrackTransform = true
            let thumnailTime = CMTimeMake(value: 1, timescale: 60)
            if let cgThumbImage = try? avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil) {
                let thumbImage = UIImage(cgImage: cgThumbImage)
                DispatchQueue.main.async {
                    self.imageButton[0].setImage(thumbImage, for: .normal)
                }
            } else {
                log.error("unable to create thumbimage")
            }
        }
    }
    
    func getThumbnailImageFromVideoUrl(url: URL) {
        if self.thumbnailAttempt < 10 {
            DispatchQueue.global().async {
                let asset = AVAsset(url: url)
                let avAssetImageGenerator = AVAssetImageGenerator(asset: asset)
                avAssetImageGenerator.appliesPreferredTrackTransform = true
                let thumnailTime = CMTimeMake(value: 1, timescale: 60)
                do {
                    let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil)
                    let thumbImage = UIImage(cgImage: cgThumbImage)
                    DispatchQueue.main.async {
                        self.imageButton[0].setImage(thumbImage, for: .normal)
                    }
                } catch {
                    log.error("Error fetching thumbnail. Trying again. - \(error)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.thumbnailAttempt += 1
                        self.getThumbnailImageFromVideoUrl(url: url)
                    }
                }
            }
        }
    }
    
    
    // This will re-upload media when the user switches accounts
    // using the account picker in the avatar button.
    func reuploadMedia() {
        if !videoAttached && gifAttached {
            // This is a gif
            self.visibleImages = 0
            self.attachPhoto() // should use existing mediaData
        } else if videoAttached {
            // This is a video
            Task {
                await self.attachVideo()
            }
        } else if audioAttached {
            // This is audio
            Task {
                await self.attachAudio()
            }
        } else if self.visibleImages > 0 {
            // This is one or more photos
            //
            // Store the current images
            var imagesToAttach: [UIImage] = []
            for index in 0..<self.visibleImages {
                if let buttonImage = self.imageButton[index].imageView?.image {
                    imagesToAttach.append(buttonImage)
                }
            }
            // Reset settings
            self.videoAttached = false
            self.gifAttached = false
            self.visibleImages = 0
            for index in 0..<numImages {
                self.uploaded[index] = false
            }
            // Re-attach each photo
            for index in 0..<imagesToAttach.count {
                self.mediaData = imagesToAttach[index].jpegData(compressionQuality: 0.7) ?? Data()
                self.attachPhoto()
            }
        }
    }

    
    func attachPhoto() {
        self.hasEditedMedia = true
        if self.videoAttachedCheckForAttachingImages || self.gifAttached {
            self.videoAttached = false
            self.visibleImages = 0
            self.mediaIdStrings = []
            for index in 0..<numImages {
                self.uploaded[index] = false
            }
        }
        
        // Find a slot to use
        var index = 0
        for imageIndex in 0..<numImages {
            if self.imageButton[imageIndex].alpha == 1 && self.uploaded[imageIndex] == false {
                index = imageIndex
                break
            }
        }

        self.uploaded[index] = true
        self.visibleImages += 1
        imageButton[index].addSubview(progressRing[index])
        progressRing[index].translatesAutoresizingMaskIntoConstraints = false
        progressRing[index].centerXAnchor.constraint(equalTo: imageButton[index].centerXAnchor).isActive = true
        progressRing[index].centerYAnchor.constraint(equalTo: imageButton[index].centerYAnchor).isActive = true
        progressRing[index].widthAnchor.constraint(equalToConstant: 50).isActive = true
        progressRing[index].heightAnchor.constraint(equalToConstant: 50).isActive = true
        progressRing[index].setProgress(0.005, animated: true)
        progressRing[index].startColor = .custom.baseTint
        progressRing[index].endColor = .custom.baseTint
        progressRing[index].grooveColor = .custom.backgroundTint.withAlphaComponent(0.25)
        progressRing[index].lineWidth = 5
        progressRing[index].rotate360Degrees()
        
        self.updatePostButton()
        if imageButton[index].alpha == 1 {
            self.setToolBarMediaItemStates(disabled: true)
            let request = Media.upload(media: .jpeg(self.mediaData))
            (self.currentAcct as? MastodonAcctData)?.client.run(request) { (statuses) in
                if let err = (statuses.error) {
                    log.error("error attaching photo - \(err)")
                    DispatchQueue.main.async {
                        self.setToolBarMediaItemStates(disabled: false)
                        
                        
                        // Move all other images down by one since this one failed to upload
                        for indexToMove in index..<self.numImages-1 {
                            self.imageButton[indexToMove].setImage(self.imageButton[indexToMove+1].currentImage, for: .normal)
                        }
                        // Any image buttons that have no button should have no alpha
                        for indexToClear in index..<self.numImages-1 {
                            if self.imageButton[indexToClear].currentImage == nil {
                                self.imageButton[indexToClear].alpha = 0
                            }
                        }
                        // Clear the last image
                        self.imageButton[self.numImages-1].alpha = 0
                        self.imageButton[self.numImages-1].setImage(nil, for: .normal)

                        self.setupImages2()
                        self.uploaded[index] = false
                        self.visibleImages -= 1
                        self.updatePostButton()
                        self.mediaFailure(message: err.localizedDescription)
                    }
                }
                if let stat = (statuses.value) {
                    // Ensure there is a slot for this string in the array
                    while self.mediaIdStrings.count < index+1 {
                        self.mediaIdStrings.append("")
                    }
                    // Now, replace the one in our slot
                    self.mediaIdStrings.remove(at: index)
                    self.mediaIdStrings.insert(stat.id, at: index)

                    self.setToolBarMediaItemStates(disabled: false)
                    self.mediaAttached = true
                    
                    DispatchQueue.main.async {
                        self.progressRing[index].layer.removeAllAnimations()
                        self.progressRing[index].removeFromSuperview()
                        
                        if self.mediaIdStrings.count == self.visibleImages {
                            self.updatePostButton()
                        }
                        log.debug("attached photo")
                    }
                }
            }
        }
    }
    
    func attachAudio() async {
        self.hasEditedMedia = true
        self.imageButton[0].addSubview(progressRing[0])
        self.visibleImages += 1
        progressRing[0].translatesAutoresizingMaskIntoConstraints = false
        progressRing[0].centerXAnchor.constraint(equalTo: self.imageButton[0].centerXAnchor).isActive = true
        progressRing[0].centerYAnchor.constraint(equalTo: self.imageButton[0].centerYAnchor).isActive = true
        progressRing[0].widthAnchor.constraint(equalToConstant: 50).isActive = true
        progressRing[0].heightAnchor.constraint(equalToConstant: 50).isActive = true
        progressRing[0].setProgress(0.005, animated: true)
        progressRing[0].startColor = .custom.baseTint
        progressRing[0].endColor = .custom.baseTint
        progressRing[0].grooveColor = .custom.backgroundTint.withAlphaComponent(0.25)
        progressRing[0].lineWidth = 5
        progressRing[0].rotate360Degrees()
        
        self.updatePostButton()
        self.setToolBarMediaItemStates(disabled: true)
        let request = Media.upload(media: .mp3(mediaData))
        (self.currentAcct as? MastodonAcctData)?.client.run(request) { (statuses) in
            if let err = (statuses.error) {
                log.error("error attaching audio - \(err.localizedDescription)")
                DispatchQueue.main.async {
                    self.setToolBarMediaItemStates(disabled: false)
                    self.imageButton[0].alpha = 0
                    self.imageButton[0].setImage(UIImage(), for: .normal)
                    self.visibleImages -= 1
                    self.updatePostButton()
                    self.mediaFailure(message: err.localizedDescription)
                }
            }
            if let stat = (statuses.value) {
                self.setToolBarMediaItemStates(disabled: false)
                self.mediaIdStrings.append(stat.id)
                
                DispatchQueue.main.async {
                    self.progressRing[0].layer.removeAllAnimations()
                    self.progressRing[0].setProgress(1, animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.progressRing[0].removeFromSuperview()
                    }
                    self.mediaAttached = true
                    if self.imageButton[0].alpha == 1 {
                        self.updatePostButton()
                    }
                }
            }
        }
    }
    
    func attachVideo() async {
        self.hasEditedMedia = true
        self.isProcessingVideo = true
        self.imageButton[0].addSubview(progressRing[0])
        self.visibleImages = 1
        self.mediaIdStrings = []
        self.videoAttachedCheckForAttachingImages = true
        progressRing[0].translatesAutoresizingMaskIntoConstraints = false
        progressRing[0].centerXAnchor.constraint(equalTo: self.imageButton[0].centerXAnchor).isActive = true
        progressRing[0].centerYAnchor.constraint(equalTo: self.imageButton[0].centerYAnchor).isActive = true
        progressRing[0].widthAnchor.constraint(equalToConstant: 50).isActive = true
        progressRing[0].heightAnchor.constraint(equalToConstant: 50).isActive = true
        progressRing[0].setProgress(0.005, animated: true)
        progressRing[0].startColor = .custom.baseTint
        progressRing[0].endColor = .custom.baseTint
        progressRing[0].grooveColor = .custom.backgroundTint.withAlphaComponent(0.25)
        progressRing[0].lineWidth = 5
        progressRing[0].rotate360Degrees()
        
        self.updatePostButton()
        self.setToolBarMediaItemStates(disabled: true)
        
        do {
            let request: Request<Attachment>
            do {
                if try VideoProcessor.shouldBeCompressed(url: self.vUrl, maxResolution: 1920, maxSizeInMB: maxVideoSize) {
                    let (compressedVideo, compressedVideoUrl) = try await VideoProcessor.compressVideo(videoUrl: self.vUrl, outputSize: CGSize(width: 960, height: 960), outputFileType: .mp4, compressionPreset: AVAssetExportPreset960x540)
                    try VideoProcessor.checkVideoSize(url: compressedVideoUrl, maxSizeInMB: maxVideoSize)
                    request = Media.upload(media: .video(compressedVideo))
                } else {
                    request = Media.upload(media: .video(mediaData))
                }
            } catch {
                log.error("unable to check if compressable: \(error)")
                request = Media.upload(media: .video(mediaData))
            }
            
            (self.currentAcct as? MastodonAcctData)?.client.run(request) { (statuses) in
                if let err = (statuses.error) {
                    log.error("error attaching video - \(err.localizedDescription)")
                    DispatchQueue.main.async {
                        self.setToolBarMediaItemStates(disabled: false)
                        self.imageButton[0].alpha = 0
                        self.imageButton[0].setImage(UIImage(), for: .normal)
                        self.visibleImages = 0
                        self.updatePostButton()
                        self.mediaFailure(message: err.localizedDescription)
                    }
                }
                if let stat = (statuses.value) {
                    self.setToolBarMediaItemStates(disabled: false)
                    self.mediaIdStrings = [stat.id]
                    
                    DispatchQueue.main.async {
                        self.progressRing[0].layer.removeAllAnimations()
                        self.progressRing[0].setProgress(1, animated: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.progressRing[0].removeFromSuperview()
                        }
                        self.mediaAttached = true
                        self.isProcessingVideo = false
                        if self.imageButton[0].alpha == 1 {
                            self.updatePostButton()
                        }
                    }
                }
            }
        }
    }
    
    func setToolBarMediaItemStates(disabled: Bool) {
        DispatchQueue.main.async {
            if disabled {
                self.mediaItemsDisabled = true
                self.createToolbar()
            } else {
                self.mediaItemsDisabled = false
                self.createToolbar()
            }
        }
    }
    
    func mediaFailure(title: String = NSLocalizedString("error.composer.mediaFailed", comment: ""), message: String) {
        let alert = UIAlertController(title: title, message: "\(message)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Done", style: .cancel , handler:{ (UIAlertAction) in
        }))
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = getTopMostViewController()?.view
            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
        }
        getTopMostViewController()?.present(alert, animated: true, completion: nil)
    }
    
    func setPostFailure() {
        let alert = UIAlertController(title: NSLocalizedString("error.composer.postFailed", comment: ""), message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("composer.retry", comment: ""), style: .default , handler:{ [weak self] (UIAlertAction) in
            self?.sendData()
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("composer.drafts.save", comment: ""), style: .default , handler:{ [weak self] (UIAlertAction) in
            self?.saveDraft()
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("composer.drafts.discard", comment: ""), style: .destructive , handler:{ (UIAlertAction) in
        }))
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = getTopMostViewController()?.view
            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
        }
        getTopMostViewController()?.present(alert, animated: true, completion: nil)
    }
    
    @objc func schedulePost() {
        self.cellPostTextView?.resignFirstResponder()

        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: { () -> Void in
            self.whoCanReplyPill.alpha = 0
        })
        
        self.dateViewBG.alpha = 1
        self.dateViewBG.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        self.dateViewBG.addTarget(self, action: #selector(self.dismissDateView), for: .touchUpInside)
        self.navigationController?.view.addSubview(self.dateViewBG)
        
#if targetEnvironment(macCatalyst)
        var dWidth: CGFloat = self.view.bounds.width - 140
        var dX: CGFloat = 70
        if (self.view.bounds.width - 140) > 188 {
            dWidth = 188
            dX = (self.view.bounds.width - dWidth)/2
        }
        self.dateView.frame = CGRect(x: dX, y: self.view.bounds.height/2 + 150, width: dWidth, height: 125)
#elseif !targetEnvironment(macCatalyst)
        var dWidth: CGFloat = self.view.bounds.width - 140
        var dX: CGFloat = 70
        if (self.view.bounds.width - 140) > 230 {
            dWidth = 230
            dX = (self.view.bounds.width - dWidth)/2
        }
        self.dateView.frame = CGRect(x: dX, y: self.view.bounds.height/2 + 150, width: dWidth, height: 140)
#endif
        self.dateView.backgroundColor = UIColor.secondarySystemBackground
        self.dateView.layer.cornerCurve = .continuous
        self.dateView.layer.cornerRadius = 16
        self.dateViewBG.addSubview(self.dateView)
        
        self.dateView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: { () -> Void in
            self.dateView.transform = CGAffineTransform.identity
            self.dateView.frame.origin.y = self.view.bounds.height/2 - 70
        })
        
#if targetEnvironment(macCatalyst)
        self.datePicker.frame = CGRect(x: 15, y: 15, width: self.dateView.bounds.size.width - 30, height: 100)
#elseif !targetEnvironment(macCatalyst)
        self.datePicker.frame = CGRect(x: 15, y: -15, width: self.dateView.bounds.size.width - 30, height: 100)
#endif
        self.datePicker.contentHorizontalAlignment = .center
        self.datePicker.minimumDate = Date().adjust(.minute, offset: 10)
        self.datePicker.date = Date().adjust(.minute, offset: 10)
        self.datePicker.locale = .current
        self.datePicker.preferredDatePickerStyle = .compact
        self.datePicker.addTarget(self, action: #selector(self.handleDateSelection), for: .valueChanged)
        self.dateView.addSubview(self.datePicker)
        
        self.tempDate = Date().adjust(.minute, offset: 10)
        
        let dateDone = UIButton()
        dateDone.frame = CGRect(x: 20, y: self.dateView.bounds.size.height - 70, width: self.dateView.bounds.size.width - 40, height: 50)
        dateDone.backgroundColor = .custom.baseTint
        dateDone.layer.cornerCurve = .continuous
        dateDone.layer.cornerRadius = 12
        dateDone.setTitle("Schedule", for: .normal)
        dateDone.setTitleColor(UIColor.white, for: .normal)
        dateDone.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        dateDone.addTarget(self, action: #selector(self.doneDateView), for: .touchUpInside)
        dateDone.tag = 999
        dateDone.layer.shadowColor = UIColor.black.cgColor
        dateDone.layer.shadowOffset = CGSize(width: 0, height: 15)
        dateDone.layer.shadowRadius = 15
        dateDone.layer.shadowOpacity = 0.24
        for x in self.dateView.subviews {
            if x.tag == 999 {
                x.removeFromSuperview()
            }
        }
        self.dateView.addSubview(dateDone)
    }
    
    @objc func doneDateView() {
        triggerHapticImpact()
        self.dismissDateView()
        self.scheduledTime = self.tempDate.iso8601String
    }
    
    @objc func handleDateSelection(_ sender: UIDatePicker) {
        self.tempDate = sender.date
    }
    
    @objc func dismissDateView() {
        self.scheduledTime = nil
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: { () -> Void in
            self.whoCanReplyPill.alpha = 1
        })
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: { () -> Void in
            self.dateView.frame.origin.y = self.view.bounds.height/2 - 105
        })
        UIView.animate(withDuration: 0.29, delay: 0.16, options: [.curveEaseOut], animations: { () -> Void in
            self.dateViewBG.alpha = 0
            self.dateView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            self.dateView.frame.origin.y = self.view.bounds.height/2 + 150
        }) { x in
            self.cellPostTextView?.becomeFirstResponder()
            self.dateViewBG.removeFromSuperview()
            self.dateView.removeFromSuperview()
            self.datePicker.removeFromSuperview()
            self.dateView.transform = CGAffineTransform.identity
        }
    }
    
    func goToPollView(_ edit: Bool = false) {
        let vc = PollViewController()
        if edit {
            vc.fromEdit = true
        }
        self.hasEditedPoll = true
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    @objc func pollTapped(_ edit: Bool = false) {
        if self.imageButton[0].alpha == 0 {
            if let _ = self.fromEdit, GlobalStruct.newPollPost != nil {
                let alert = UIAlertController(title: nil, message: NSLocalizedString("poll.editNotice", comment: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("generic.continue", comment: ""), style: .default , handler:{ (UIAlertAction) in
                    self.goToPollView(edit)
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("generic.cancel", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
                    
                }))
                if let presenter = alert.popoverPresentationController {
                    presenter.sourceView = getTopMostViewController()?.view
                    presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                }
                getTopMostViewController()?.present(alert, animated: true, completion: nil)
            } else {
                self.goToPollView(edit)
            }
        } else {
            let alert = UIAlertController(title: nil, message: NSLocalizedString("error.pollMedia", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
                
            }))
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = getTopMostViewController()?.view
                presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
            }
            getTopMostViewController()?.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func cameraTapped() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
                    DispatchQueue.main.async {
                        self.fromCamera = true
                        self.photoPickerView2.delegate = self
                        self.photoPickerView2.sourceType = .camera
                        self.photoPickerView2.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
                        self.photoPickerView2.allowsEditing = false
                        self.present(self.photoPickerView2, animated: true, completion: nil)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: NSLocalizedString("generic.oops", comment: ""), message: NSLocalizedString("error.cameraDenied", comment: ""), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("generic.cancel", comment: ""), style: .cancel))
                    alert.addAction(UIAlertAction(title: NSLocalizedString("title.settings", comment: ""), style: .default) { _ in
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                                
                            })
                        }
                    })
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @objc func draftsTapped() {
        let vc = ScheduledPostsViewController()
        vc.drafts = GlobalStruct.drafts
        vc.currentUser = self.currentUser
        let nvc = UINavigationController(rootViewController: vc)
        self.present(nvc, animated: true, completion: nil)
    }
    
    @objc func restoreFromDrafts() {
        updatePostButton()
        createToolbar()
        if self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
            cellPostText = GlobalStruct.currentDraft?.contents.content.stripHTML() ?? ""
            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
            if cellPostText.isEmpty {
                self.btn1.showsMenuAsPrimaryAction = false
            } else {
                // present drafts option
                let draft = UIAction(title: NSLocalizedString("composer.drafts.save", comment: ""), image: UIImage(systemName: "doc.text"), identifier: nil) { action in
                    self.saveDraft()
                }
                let dismiss = UIAction(title: NSLocalizedString("generic.dismiss", comment: ""), image: UIImage(systemName: "xmark"), identifier: nil) { action in
                    self.dismiss(animated: true, completion: nil)
                }
                dismiss.attributes = .destructive
                
                let newMenu = UIMenu(title: "", options: [], children: [draft, dismiss])
                self.btn1.menu = newMenu
                self.btn1.showsMenuAsPrimaryAction = true
            }
        }
        self.spoilerText = GlobalStruct.currentDraft?.contents.spoilerText.stripHTML() ?? ""
        if self.spoilerText != "" {
            self.cwHeight = UITableView.automaticDimension
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
            self.createToolbar()
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AltTextCell2 {
                cell.altText.placeholder = NSLocalizedString("composer.contentWarning.placeholder", comment: "")
                cell.altText.becomeFirstResponder()
                cell.altText.text = self.spoilerText
                cell.altText.isHidden = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
            }
        }
        if let poll = GlobalStruct.currentDraft?.contents.poll {
            let date1 = poll.expiresAt ?? ""
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = GlobalStruct.dateFormat
            let date = dateFormatter.date(from: date1)
            
            let expiresIn = date ?? Date()
            let diff = Calendar.current.dateComponents([.second], from: Date(), to: expiresIn).second ?? 0
            var str: [String] = []
            _ = poll.options.map({ x in
                str.append(x.title)
            })
            let a: [Any] = [str, diff, poll.multiple, false]
            GlobalStruct.newPollPost = a
            self.createToolbar()
        }
        if let z = GlobalStruct.currentDraft?.contents.visibility {
            self.whoCanReply = z
            self.createToolbar()
        }
        if let rep = GlobalStruct.currentDraft?.replyPost {
            self.allStatuses = rep
            self.tableView.reloadData()
            self.cellPostTextView?.becomeFirstResponder()
        }
        self.mediaIdStrings = GlobalStruct.currentDraft?.imagesIds ?? []
        if let im = GlobalStruct.currentDraft?.images {
            for index in 0..<numImages {
                if index < im.count, let imageData = im[index] {
                    self.imageButton[index].setImage(UIImage(data: imageData), for: .normal)
                    self.imageButton[index].alpha = 1
                } else {
                    self.imageButton[index].alpha = 0
                }
            }
        }
        
        parseText()
        self.updateCharacterCounts()
                
        if self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
            if cellPostText.isEmpty || cellPostText.count > self.postCharacterCount2 {
                self.updatePostButton()
                // show default toolbar
                if let cellPostTextView {
                    cellPostTextView.inputAccessoryView = self.formatToolbar
                    cellPostTextView.reloadInputViews()
                }
#if targetEnvironment(macCatalyst)
                self.formatToolbar.removeFromSuperview()
                self.scrollView.removeFromSuperview()
                self.view.addSubview(self.formatToolbar)
#endif
            } else {
                updatePostButton()
            }
        }
        self.updateCharacterCounts()
    }
    
    @objc func restoreFromTemplate() {
        // first launch composer preview template
        updatePostButton()
        if self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
            if self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) is AltTextCell2 {
                cellPostText = "I just started trying out #Mammoth for Mastodon and I'm loving it!"
                self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                self.updateCharacterCounts()
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.isQuotePost {
            return 3
        } else {
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // The post being replied to, if any
            if allStatuses.isEmpty {
                return 0
            } else {
                return 1
            }
        } else if section == 1 {
            // The post being composed
            return 2
        } else {
            // The post being quoted, if any
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 0 {
            // Content warning
            return self.cwHeight
        } else {
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let newCell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
            let cell = newCell.p
            
            // default
            let stat = self.allStatuses[indexPath.row].reblog ?? self.allStatuses[indexPath.row]
            if let ur = URL(string: stat.account?.avatar ?? "") {
                cell.profileIcon.sd_setImage(with: ur, for: .normal)
            }
            
            let text = stat.content.stripHTML()
            cell.postText.commitUpdates {
                cell.postText.textColor = .custom.mainTextColor
                cell.linkPost.textColor = .custom.mainTextColor2
                cell.postText.text = text
                cell.postText.mentionColor = .custom.baseTint
                cell.postText.hashtagColor = .custom.baseTint
                cell.postText.URLColor = .custom.baseTint
                cell.postText.emailColor = .custom.baseTint
                
                let userName = stat.account?.displayName ?? ""
                cell.userName.text = userName
                
                let userTag = stat.account?.acct ?? ""
                cell.userTag.text = "@\(userTag)"
                
                let time1 = stat.createdAt
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = GlobalStruct.dateFormat
                var time = dateFormatter.date(from: time1)?.toStringWithRelativeTime() ?? ""
                if GlobalStruct.timeStampStyle == 1 {
                    let time1 = stat.createdAt
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = GlobalStruct.dateFormat
                    time = dateFormatter.date(from: time1)?.toString(dateStyle: .short, timeStyle: .short) ?? ""
                } else if GlobalStruct.timeStampStyle == 2 {
                    time = ""
                }
                cell.dateTime.text = time
                
                cell.indicator.alpha = 0
                
                var containsPoll: Bool = false
                if let _ = stat.poll {
                    containsPoll = true
                }
                // images
                if stat.mediaAttachments.count > 0 {
                    let z = stat.mediaAttachments
                    var isVideo: Bool = false
                    let mediaItems = z[0].previewURL
                    
                    if z.first?.type == .video || z.first?.type == .gifv || z.first?.type == .audio {
                        isVideo = true
                        cell.playerController.view.isHidden = false
                        if z.first?.type == .audio {
                            cell.setupPlayButton(z.first?.url ?? "", isAudio: true)
                        } else {
                            cell.setupPlayButton(z.first?.url ?? "")
                        }
                    } else {
                        cell.playerController.view.isHidden = true
                        cell.setupPlayButton("")
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
                    
                    cell.setupImages(url1: mediaItems ?? "", url2: mediaItems1, url3: mediaItems2, url4: mediaItems3, isVideo: isVideo, fullImages: z)
                    cell.setupConstraints(containsImages: true, quotePostCard: nil, containsRepost: false, containsPoll: containsPoll, pollOptions: stat.poll, stat: stat)
                } else {
                    cell.setupConstraints(containsImages: false, quotePostCard: nil, containsRepost: false, containsPoll: containsPoll, pollOptions: stat.poll, stat: stat)
                }
            }
            
            // tap items
            cell.postText.handleMentionTap { (str) in
                
            }
            cell.postText.handleHashtagTap { (str) in
                
            }
            cell.postText.handleURLTap { (str) in
                triggerHapticImpact(style: .light)
                PostActions.openLink(str)
            }
            cell.postText.handleEmailTap { (str) in
                
            }
            
            cell.stackViewB.isHidden = true
            for sub in cell.stackViewB.arrangedSubviews {
                sub.removeFromSuperview()
            }
            
            cell.topThreadLine.alpha = 0
            cell.bottomThreadLine.alpha = 1
            
            newCell.separatorInset = UIEdgeInsets(top: 0, left: 78, bottom: 0, right: 0)
            let bgColorView = UIView()
            bgColorView.backgroundColor = .clear
            newCell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .clear
            return newCell
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AltTextCell2", for: indexPath) as! AltTextCell2
                cell.altText.placeholder = ""
                cell.altText.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
                let bgColorView = UIView()
                bgColorView.backgroundColor = .clear
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                cell.separatorInset = UIEdgeInsets(top: 0, left: self.view.bounds.width, bottom: 0, right: 0)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ComposeCell", for: indexPath) as! ComposeCell
                
                if let ur = URL(string: self.currentUser?.avatar ?? "") {
                    cell.profileIcon.sd_setImage(with: ur, for: .normal)
                }
                
                var items: [UIAction] = []
                for acct in AccountsManager.shared.allAccounts {
                    let im = UIImage(systemName: "person.crop.circle")
                    let imV = UIImageView()
                    imV.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
                    imV.layer.cornerRadius = 10
                    imV.layer.masksToBounds = true
                    if let ur = URL(string: acct.avatar) {
                        imV.sd_setImage(with: ur)
                    }
                    let instanceAndAccount = "@\(acct.fullAcct)"
                    let op1 = UIAction(title: instanceAndAccount, image: imV.image?.withRoundedCorners()?.resize(targetSize: CGSize(width: 20, height: 20)) ?? im, identifier: nil) { action in
                        // switch account
                        DispatchQueue.main.async {
                            self.currentFullName = "@\(instanceAndAccount)"
                            self.currentAcct = acct
                            self.tableView.reloadData()
                            self.refreshDrafts()
                            self.cellPostTextView?.becomeFirstResponder()
                            self.reuploadMedia()
                        }
                    }
                    op1.state = (self.currentAcct?.uniqueID == acct.uniqueID) ? .on : .off
                    items.append(op1)
                }
                let profileMenu = UIMenu(title: "Post from...", image: nil, identifier: nil, children: items)
                if AccountsManager.shared.allAccounts.count > 1 && self.fromEdit == nil {
                    cell.profileIcon.menu = profileMenu
                    cell.profileIcon.showsMenuAsPrimaryAction = true
                }
                
                // If this is the first time through here, be sure to update the content of
                // cellPostTextView, and run through again.
                if self.cellPostTextView == nil {
                    DispatchQueue.main.async {
                        self.updateReplyingToIfNecessary()
                    }
                }
                cellPostTextView = cell.post

                // Record and restore the firstResponder state, and
                // the selection before/after setting cell.post.text.
                let wasFirstResponder = cellPostTextView?.isFirstResponder
                let currentSelection = cellPostTextView?.selectedTextRange
                cell.post.text = cellPostText
                if currentSelection != nil {
                    cellPostTextView?.selectedTextRange = currentSelection!
                }
                if wasFirstResponder ?? false {
                    cellPostTextView?.becomeFirstResponder()
                }
                
                if GlobalStruct.keyboardType == 0 {
                    cell.post.keyboardType = .twitter
                } else {
                    cell.post.keyboardType = .default
                }
                cell.post.delegate = self
                
                if self.allStatuses.isEmpty {
                    cell.topThreadLine.alpha = 0
                } else {
                    cell.topThreadLine.alpha = 1
                }
                
                let bgColorView = UIView()
                bgColorView.backgroundColor = .clear
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = UIColor.clear
                return cell
            }
        } else {
            // Section 2: the quoted post
            let cell = quotePostCell
            let quotePostURL = self.quotePostURL()
            log.debug("updating quote post URL to: \(quotePostURL?.absoluteString ?? "nil")")
            cell.updateForQuotePost(quotePostURL)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func updateCharacterCounts() {
        // Count the content warning
        let contentWarning = self.spoilerText
        
        // Break down the post if necessary
        let postPieces = self.postPiecesFromPost(cellPostText, contentWarning: contentWarning)

        // Compose the string
        if postPieces.count == 1 {
            // Show the # of characters used
            self.postCharacterCount = self.postCharacterCount2 - countWithURL(postPieces[0]) - contentWarning.count
            self.navigationItem.title = "\(postCharacterCount)"
            self.navigationItem.accessibilityLabel = String.localizedStringWithFormat(NSLocalizedString("composer.characterCount", comment: ""), postCharacterCount)
        } else {
            // Show the current number of posts, and the character space *remaining*
            self.postCharacterCount = self.postCharacterCount2 - countWithURL(postPieces.last!)
            
            self.navigationItem.title = String.localizedStringWithFormat(NSLocalizedString("composer.characterCount.thread", comment: ""), postPieces.count, postCharacterCount)
            self.navigationItem.accessibilityLabel = String.localizedStringWithFormat(NSLocalizedString("composer.characterCount.thread.description", comment: ""), postPieces.count, postCharacterCount)

        }
        
        if self.threadingAllowed() {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .custom.backgroundTint
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
            self.navigationItem.standardAppearance = appearance
            self.navigationItem.scrollEdgeAppearance = appearance
        } else {
            if postCharacterCount > 30 {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .custom.backgroundTint
                appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
                self.navigationItem.standardAppearance = appearance
                self.navigationItem.scrollEdgeAppearance = appearance
            } else if postCharacterCount > 15 {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .custom.backgroundTint
                appearance.titleTextAttributes = [.foregroundColor: UIColor.systemYellow]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemYellow]
                self.navigationItem.standardAppearance = appearance
                self.navigationItem.scrollEdgeAppearance = appearance
            } else if postCharacterCount > 0 {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .custom.backgroundTint
                appearance.titleTextAttributes = [.foregroundColor: UIColor.systemOrange]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemOrange]
                self.navigationItem.standardAppearance = appearance
                self.navigationItem.scrollEdgeAppearance = appearance
            } else {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .custom.backgroundTint
                appearance.titleTextAttributes = [.foregroundColor: UIColor.systemRed]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemRed]
                self.navigationItem.standardAppearance = appearance
                self.navigationItem.scrollEdgeAppearance = appearance
            }
        }

        self.updatePostButton()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        self.hasEditedMetadata = true
        self.updateCharacterCounts()
        if let cell2 = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AltTextCell2 {
            self.spoilerText = cell2.altText.text ?? ""
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.cellPostText = textView.text
        
        self.hasEditedText = true
        self.updateCharacterCounts()
        
        var isEmoji = false
        if let x = textView.text.last {
            if "\(x)".containsEmoji {
                isEmoji = true
            }
        }
        
        if textView.text.isEmpty || ((textView.text.count > self.postCharacterCount2) && !self.threadingAllowed()) {
            self.updatePostButton()
            if isEmoji {} else {
                // show default toolbar
                cellPostTextView?.inputAccessoryView = self.formatToolbar
                cellPostTextView?.reloadInputViews()
#if targetEnvironment(macCatalyst)
                self.formatToolbar.removeFromSuperview()
                self.scrollView.removeFromSuperview()
                self.view.addSubview(self.formatToolbar)
#endif
            }
        } else {
            updatePostButton()
        }
        
        var inSearch1: Bool = false
        var inSearch2: Bool = false
        
        if isEmoji {} else {
            // find @ mentions
            let trimmedToCursor = textView.text[..<(textView.cursorIndex ?? textView.text.endIndex)]
            var trimSpot = trimmedToCursor.firstIndex(of: "@") ?? textView.text.endIndex
            //find most recent match of a non-alphanumeric character which is followed by an @
            do {
                let regex = try NSRegularExpression(pattern: "[^a-zA-Z0-9]@")
                let matches = regex.matches(in: String(trimmedToCursor), range: NSRange(trimmedToCursor.startIndex..., in: trimmedToCursor))
                if let lastMatch = matches.last {
                    trimSpot = trimmedToCursor.utf16.index(trimmedToCursor.startIndex, offsetBy: lastMatch.range.location + lastMatch.range.length - 1)
                }
            } catch {
                log.error("Regex error: \(error.localizedDescription)")
            }
            if trimSpot <= (textView.cursorIndex ?? textView.text.endIndex) {
                let trimmed = trimmedToCursor[trimSpot..<(textView.cursorIndex ?? textView.text.endIndex)]
                if !trimmed.contains(" ") && (trimmed.contains("@") && trimmed.count > 1) {
                    inSearch1 = true
                    // search for users
                    self.trimmedAtString = String(trimmed.dropFirst())
                    self.pendingRequestWorkItem?.cancel()
                    let requestWorkItem = DispatchWorkItem { [weak self] in
                        self?.searchForUsers(self?.trimmedAtString ?? "")
                    }
                    self.pendingRequestWorkItem = requestWorkItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: requestWorkItem)
                } else {
                    inSearch1 = false
                    // show default toolbar
                    if inSearch1 == false && inSearch2 == false {
                        self.pendingRequestWorkItem?.cancel()
                        cellPostTextView?.inputAccessoryView = self.formatToolbar
                        cellPostTextView?.reloadInputViews()
#if targetEnvironment(macCatalyst)
                        self.formatToolbar.removeFromSuperview()
                        self.scrollView.removeFromSuperview()
                        self.view.addSubview(self.formatToolbar)
#endif
                    }
                }
            } else {
                inSearch1 = false
                // show default toolbar
                if inSearch1 == false && inSearch2 == false {
                    self.pendingRequestWorkItem?.cancel()
                    cellPostTextView?.inputAccessoryView = self.formatToolbar
                    cellPostTextView?.reloadInputViews()
#if targetEnvironment(macCatalyst)
                    self.formatToolbar.removeFromSuperview()
                    self.scrollView.removeFromSuperview()
                    self.view.addSubview(self.formatToolbar)
#endif
                }
            }
            
            // find # tags
            let trimSpot2 = trimmedToCursor.lastIndex(of: "#") ?? textView.text.endIndex
            if trimSpot2 <= (textView.cursorIndex ?? textView.text.endIndex) {
                let trimmed = trimmedToCursor[trimSpot2..<(textView.cursorIndex ?? textView.text.endIndex)]
                if !trimmed.contains(" ") && (trimmed.contains("#")) {
                    inSearch2 = true
                    // search for tags
                    self.trimmedAtString = String(trimmed.dropFirst())
                    self.pendingRequestWorkItem?.cancel()
                    let requestWorkItem = DispatchWorkItem { [weak self] in
                        self?.searchForTags(self?.trimmedAtString ?? "")
                    }
                    self.pendingRequestWorkItem = requestWorkItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: requestWorkItem)
                } else {
                    inSearch2 = false
                    // show default toolbar
                    if inSearch1 == false && inSearch2 == false {
                        self.pendingRequestWorkItem?.cancel()
                        cellPostTextView?.inputAccessoryView = self.formatToolbar
                        cellPostTextView?.reloadInputViews()
#if targetEnvironment(macCatalyst)
                        self.formatToolbar.removeFromSuperview()
                        self.scrollView.removeFromSuperview()
                        self.view.addSubview(self.formatToolbar)
#endif
                    }
                }
            } else {
                inSearch2 = false
                // show default toolbar
                if inSearch1 == false && inSearch2 == false {
                    self.pendingRequestWorkItem?.cancel()
                    cellPostTextView?.inputAccessoryView = self.formatToolbar
                    cellPostTextView?.reloadInputViews()
#if targetEnvironment(macCatalyst)
                    self.formatToolbar.removeFromSuperview()
                    self.scrollView.removeFromSuperview()
                    self.view.addSubview(self.formatToolbar)
#endif
                }
            }
        }
        
        if self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
            if cellPostText.isEmpty {
                self.btn1.showsMenuAsPrimaryAction = false
            } else {
                // present drafts option
                let draft = UIAction(title: NSLocalizedString("composer.drafts.save", comment: ""), image: UIImage(systemName: "doc.text"), identifier: nil) { action in
                    self.saveDraft()
                }
                let dismiss = UIAction(title: NSLocalizedString("generic.dismiss", comment: ""), image: UIImage(systemName: "xmark"), identifier: nil) { action in
                    self.dismiss(animated: true, completion: nil)
                }
                dismiss.attributes = .destructive
                
                let newMenu = UIMenu(title: "", options: [], children: [draft, dismiss])
                self.btn1.menu = newMenu
                self.btn1.showsMenuAsPrimaryAction = true
            }
        }

        // These are needed to force the textView to recalculate its height, and update.
        textView.sizeToFit()
        let areAnimationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        UIView.setAnimationsEnabled(areAnimationsEnabled)

        parseText()
    }
    
    func parseText() {
        if self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
            // get cursor position
            var cursorPosition: Int = 0
            if let selectedRange = cellPostTextView?.selectedTextRange {
                cursorPosition = cellPostTextView!.offset(from: cellPostTextView!.beginningOfDocument, to: selectedRange.start)
            }
            
            let pattern = "(?:|$)#[\\p{L}0-9_]*|\\B\\@([a-zA-Z0-9_.-]*)([\\w@a-zA-Z0-9_.-]+)|\\@|(https?:\\/\\/(?:www\\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|www\\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|https?:\\/\\/(?:www\\.|(?!www))[a-zA-Z0-9]+\\.[^\\s]{2,}|www\\.[a-zA-Z0-9]+\\.[^\\s]{2,})"
            let inString = cellPostText
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let range = NSMakeRange(0, inString.count)
            let matches = (regex?.matches(in: inString, options: [], range: range))!
            let attrs = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular), NSAttributedString.Key.foregroundColor : UIColor.label]
            let attrString = NSMutableAttributedString(string: inString, attributes: attrs)
            for match in matches.reversed() {
                attrString.addAttribute(NSAttributedString.Key.foregroundColor , value: UIColor.custom.baseTint, range: match.range(at: 0))
            }
            if !matches.isEmpty {
                cellPostTextView?.attributedText = attrString
            }
            
            // set cursor position
            if let newPosition = cellPostTextView?.position(from: cellPostTextView!.beginningOfDocument, offset: cursorPosition) {
                cellPostTextView!.selectedTextRange = cellPostTextView!.textRange(from: newPosition, to: newPosition)
            }
        } else {
            log.error("parseText called with no cell")
        }
    }
    
    func moveCursorToBeginning() {
        if self.cellPostTextView != nil {
            let startPosition = cellPostTextView!.position(from: cellPostTextView!.beginningOfDocument, offset: 0)!
            cellPostTextView?.selectedTextRange = cellPostTextView?.textRange(from: startPosition, to: startPosition)
        } else {
            log.error("expected cellPostTextView to be valid")
        }
    }
    
    func moveCursorToEnd() {
        if self.cellPostTextView != nil {
            let endPosition = cellPostTextView!.position(from: cellPostTextView!.endOfDocument, offset: 0)!
            cellPostTextView?.selectedTextRange = cellPostTextView?.textRange(from: endPosition, to: endPosition)
        } else {
            log.error("expected cellPostTextView to be valid")
        }
    }
    
    @objc func saveDraft() {
        let postText: String = cellPostText
        var reply: String? = nil
        if self.allStatuses.isEmpty && self.quoteString.isEmpty {} else {
            // replying to
            reply = self.allStatuses.first?.reblog?.inReplyToID ?? self.allStatuses.first?.inReplyToID ?? ""
        }
        var replyA: String? = nil
        if self.allStatuses.isEmpty && self.quoteString.isEmpty {} else {
            // replying to
            replyA = self.allStatuses.first?.reblog?.inReplyToAccountID ?? self.allStatuses.first?.inReplyToAccountID ?? ""
        }
        if self.mediaAttached {
            self.mediaIdStrings = self.mediaIdStrings.filter({ x in
                x != ""
            })
            var images: [Data] = []
            for index in 0..<numImages {
                if let a1 = self.imageButton[index].currentImage?.pngData() {
                    images.append(a1)
                }
            }
            var poll: Poll? = nil
            if let x = GlobalStruct.newPollPost {
                var pOpt: [PollOptions] = []
                let a = x[0] as? [String] ?? []
                for z in a {
                    pOpt.append(PollOptions(title: z, votesCount: nil))
                }
                let pp = Poll(id: "0", expired: false, multiple: false, votesCount: 0, options: pOpt)
                poll = pp
            }
            let draftPost = Status(id: "\(Int.random(in: 0 ... 1000000))", uri: "", url: nil, account: self.currentUser!, inReplyToID: reply, inReplyToAccountID: replyA, content: postText, createdAt: "", emojis: [], repliesCount: 0, reblogsCount: 0, favouritesCount: 0, reblogged: nil, favourited: nil, bookmarked: nil, sensitive: nil, spoilerText: self.spoilerText, visibility: self.whoCanReply ?? .public, mediaAttachments: [], mentions: [], tags: [], card: nil, application: nil, language: nil, reblog: nil, pinned: nil, poll: poll, editedAt: nil)
            let dr1 = Draft(id: Int.random(in: 0 ... 1000000), contents: draftPost, images: images, imagesIds: self.mediaIdStrings, replyPost: self.allStatuses)
            GlobalStruct.drafts.insert(dr1, at: 0)
            do {
                try Disk.save(GlobalStruct.drafts, to: .documents, as: "\(AccountsManager.shared.currentAccount?.diskFolderName() ?? "")/drafts.json")
                self.dismiss(animated: true, completion: nil)
            } catch {
                log.error("error saving drafts to Disk")
            }
        } else {
            var poll: Poll? = nil
            if let x = GlobalStruct.newPollPost {
                var pOpt: [PollOptions] = []
                let a = x[0] as? [String] ?? []
                for z in a {
                    pOpt.append(PollOptions(title: z, votesCount: nil))
                }
                let pp = Poll(id: "0", expired: false, multiple: false, votesCount: 0, options: pOpt)
                poll = pp
            }
            let draftPost = Status(id: "\(Int.random(in: 0 ... 1000000))", uri: "", url: nil, account: self.currentUser!, inReplyToID: reply, inReplyToAccountID: replyA, content: postText, createdAt: "", emojis: [], repliesCount: 0, reblogsCount: 0, favouritesCount: 0, reblogged: nil, favourited: nil, bookmarked: nil, sensitive: nil, spoilerText: self.spoilerText, visibility: self.whoCanReply ?? .public, mediaAttachments: [], mentions: [], tags: [], card: nil, application: nil, language: nil, reblog: nil, pinned: nil, poll: poll, editedAt: nil)
            let dr1 = Draft(id: Int.random(in: 0 ... 1000000), contents: draftPost, images: [], imagesIds: nil, replyPost: self.allStatuses)
            GlobalStruct.drafts.insert(dr1, at: 0)
            do {
                try Disk.save(GlobalStruct.drafts, to: .documents, as: "\(AccountsManager.shared.currentAccount?.diskFolderName() ?? "")/drafts.json")
                self.dismiss(animated: true, completion: nil)
            } catch {
                log.error("error saving drafts to Disk")
            }
        }
    }
    
    func fetchQuotePostMetaData() async {
        if let quotedAccount = self.quotedAccount{
            log.debug("Fetching quoted account info for \(quotedAccount.fullAcct)")
            self.quotedAccountPublicSocialGraph = await FollowManager.shared.publicSocialGraphForAccount(quotedAccount)
            self.followedByQuotedAccount = FollowManager.shared.followedByStatusForAccount(quotedAccount, requestUpdate: .force)
        }
    }
    
    func updateQuotePostURL() {
        // This can get called multiple times based on timing;
        // only do it successfully once.
//        if self.haveUpdatedPostWithQuoteURL {
//            return
//        }
//        if self.followedByQuotedAccount == FollowManager.FollowStatus.unknown {
//            return
//        }
//
//        log.debug("Followed by Quote Account: \(String(self.followedByQuotedAccount.rawValue))")
//        log.debug("Quote Account SocialGraph: \(String(self.quotedAccountPublicSocialGraph))")
//
//        var enabledQuotePost = false
//
//        // user must be followed by quoted account and quoted account must have following publicly available
//        enabledQuotePost = self.followedByQuotedAccount == FollowManager.FollowStatus.following && self.quotedAccountPublicSocialGraph
//
//        // quote post is the current user's own account
//        if let currentUser = AccountsManager.shared.currentUser(), let quotedAccount = self.quotedAccount{
//            if(quotedAccount.acct == currentUser.acct){
//                enabledQuotePost = true
//            }
//        }
        // Disable any animations while we update the cell content
        self.tableView.beginUpdates()
        UIView.setAnimationsEnabled(false)

//        if cellPostText.count > 0 {
//            let rg = NSRange(cellPostText.endIndex..., in: cellPostText)
//            if let stringRange = Range(rg, in: cellPostText) {
//                let urlSuffix = "?public_follow=\(String(enabledQuotePost))"
//                cellPostText.replaceSubrange(stringRange, with: urlSuffix)
//                self.haveUpdatedPostWithQuoteURL = true
//                log.debug("text after updating URL: \(cellPostText)")
//                parseText()
//            }
//        }
    
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
        UIView.setAnimationsEnabled(true)
        self.tableView.endUpdates()
    }
    
    
    private func quotePostURL() -> URL? {
        // See if the last part of the text is a URL; if so, use it
        var quotePostURL: URL? = nil
        let postText = cellPostText
        // Look backward for "https://"
        if let urlStart = postText.range(of:"https://", options:.backwards) {
            // Take everything from "https://" forward and try to make a URL
            let urlString = postText.suffix(from: urlStart.lowerBound)
            quotePostURL = URL(string: String(urlString))
        }
        return quotePostURL
    }
    
    @objc func followStatusNotification(notification: Notification) {
        // Originally , we only observe the notification if it's tied to the current user,
        // and otherUser matches the quoted account.
        // However, this isn't always the case (see MAM-1538).
        //
        // Since this just an update, and the proabability and downside of updating
        // this twice is insignificant, go ahead and do the udpate based on just checking
        // the current account.
    
        log.debug("followStatusNotification: \(notification.userInfo)")
        if (notification.userInfo!["currentUserFullAcct"] as! String) == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.account.fullAcct {
            self.followedByQuotedAccount = FollowManager.FollowStatus(rawValue: notification.userInfo!["followedByStatus"] as! String)!
            self.updateQuotePostURL()
        } else {
            log.warning("unexpected notification")
        }
    }
    
    func searchForUsers(_ user0: String) {
        let request = Search.search(query: user0, resolve: true)
        self.formatToolbar2.sizeToFit()
        (self.currentAcct as? MastodonAcctData)?.client.run(request) { (statuses) in
            if let stat = (statuses.value) {
                DispatchQueue.main.async {
                    self.formatToolbar2.items = []
                    var allWidths: CGFloat = 0
                    var zz = stat.accounts
                    zz = zz.removingDuplicates()
                    self.userItemsAll = zz
                    for (c,_) in zz.enumerated() {
                        let view = UIButton()
                        
                        let im = UIButton()
                        im.isUserInteractionEnabled = false
                        im.frame = CGRect(x: 0, y: 10, width: (self.formatToolbar2.frame.size.height) - 20, height: (self.formatToolbar2.frame.size.height) - 20)
                        im.layer.cornerRadius = ((self.formatToolbar2.frame.size.height) - 20)/2
                        im.imageView?.contentMode = .scaleAspectFill
                        if let ur = URL(string: zz[c].avatar) {
                            im.sd_setImage(with: ur, for: .normal)
                        }
                        im.layer.masksToBounds = true
                        view.addSubview(im)
                        
                        let titl = UILabel()
                        titl.text = "@\(zz[c].acct)"
                        titl.textColor = .custom.baseTint
                        titl.frame = CGRect(x: (self.formatToolbar2.frame.size.height) - 10, y: 0, width: (self.view.bounds.width) - (self.formatToolbar2.frame.size.height), height: (self.formatToolbar2.frame.size.height))
                        titl.sizeToFit()
                        titl.frame.size.height = self.formatToolbar2.frame.size.height
                        titl.frame.origin.x = (self.formatToolbar2.frame.size.height) - 10
                        view.addSubview(titl)
                        
                        let wid = im.frame.size.width + titl.frame.size.width + 30
                        view.frame = CGRect(x: 0, y: 0, width: wid, height: (self.formatToolbar2.frame.size.height))
                        view.tag = c
                        view.addTarget(self, action: #selector(self.tapAccount(_:)), for: .touchUpInside)
                        let x0 = UIBarButtonItem(customView: view)
                        x0.width = wid
                        allWidths += wid
                        x0.accessibilityLabel = "@\(zz[c].acct)"
                        
                        self.formatToolbar2.items?.append(x0)
                    }
                    
                    self.formatToolbar2.sizeToFit()
                    if (allWidths + 40) < self.view.bounds.width {
                        self.formatToolbar2.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: (self.formatToolbar2.frame.size.height))
                    } else {
                        self.formatToolbar2.frame = CGRect(x: 0, y: 0, width: allWidths + 40, height: (self.formatToolbar2.frame.size.height))
                    }
                    if self.cellPostTextView != nil {
                        self.scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: (self.view.frame.width), height: (self.formatToolbar2.frame.size.height)))
                        self.scrollView.backgroundColor = .custom.quoteTint
                        self.scrollView.showsVerticalScrollIndicator = false
                        self.scrollView.showsHorizontalScrollIndicator = false
                        self.scrollView.contentSize = self.formatToolbar2.frame.size
                        self.scrollView.addSubview(self.formatToolbar2)
                        self.cellPostTextView!.inputAccessoryView = self.scrollView
                        self.cellPostTextView!.reloadInputViews()
#if targetEnvironment(macCatalyst)
                        self.scrollView.frame.origin.y = self.view.bounds.height - self.formatToolbar2.bounds.size.height - 5
                        self.formatToolbar.removeFromSuperview()
                        self.scrollView.removeFromSuperview()
                        self.view.addSubview(self.scrollView)
#endif
                    }
                    
                }
            }
        }
    }
    
    @objc func tapAccount(_ sender: UIButton) {
        triggerHapticImpact(style: .light)
        self.pendingRequestWorkItem?.cancel()
        let searchItem1 = self.userItemsAll[sender.tag].acct
        if let cellPostTextView = self.cellPostTextView {
            if let selectedRange = cellPostTextView.selectedTextRange {
                let cursorPosition = cellPostTextView.offset(from: cellPostTextView.beginningOfDocument, to: selectedRange.start)
                if let currPosition = cellPostTextView.position(from: cellPostTextView.beginningOfDocument, offset: cursorPosition) {
                    let tag = self.getCurrentTagOrUser(isTag: false) ?? ""
                    if let currTagPosition = cellPostTextView.position(from: cellPostTextView.beginningOfDocument, offset: cursorPosition - tag.count) {
                        if let textRange = cellPostTextView.textRange(from: currTagPosition, to: currPosition) {
                            if let range = cellPostText.rangeFromNSRange(nsRange: self.rangeFromTextRange(textRange: textRange, textView: cellPostTextView)) {
                                cellPostText.replaceSubrange(range, with: "\(searchItem1) ")
                                self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                            }
                        }
                    }
                    self.parseText()
                }
                let cursorDiff = Array(searchItem1).count - Array(self.trimmedAtString).count + 1
                if let newPosition = cellPostTextView.position(from: cellPostTextView.beginningOfDocument, offset: cursorPosition + cursorDiff) {
                    if newPosition != cellPostTextView.endOfDocument {
                        cellPostTextView.selectedTextRange = cellPostTextView.textRange(from: newPosition, to: newPosition)
                    }
                }
            }
            // show default toolbar
            if self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
                cellPostTextView.inputAccessoryView = self.formatToolbar
                cellPostTextView.reloadInputViews()
            }
#if targetEnvironment(macCatalyst)
            self.formatToolbar.removeFromSuperview()
            self.scrollView.removeFromSuperview()
            self.view.addSubview(self.formatToolbar)
#endif
        }
    }
    
    func searchForTags(_ tag0: String) {
        let request = Search.search(query: tag0, resolve: true)
        (self.currentAcct as? MastodonAcctData)?.client.run(request) { (statuses) in
            if let stat = (statuses.value) {
                DispatchQueue.main.async {
                    self.formatToolbar2.items = []
                    var allWidths: CGFloat = 0
                    let zz = stat.hashtags
                    self.tagsAll = zz
                    for (c,_) in zz.enumerated() {
                        let view = UIButton()
                        
                        let titl = UILabel()
                        titl.text = "#\(zz[c].name)"
                        titl.textColor = .custom.baseTint
                        titl.frame = CGRect(x: 0, y: 0, width: (self.view.bounds.width) - (self.formatToolbar2.frame.size.height) + ((self.formatToolbar2.frame.size.height) - 10), height: (self.formatToolbar2.frame.size.height))
                        titl.sizeToFit()
                        titl.frame.size.height = self.formatToolbar2.frame.size.height
                        titl.frame.origin.x = 0
                        view.addSubview(titl)
                        
                        let wid = titl.frame.size.width + 30
                        view.frame = CGRect(x: 0, y: 0, width: wid, height: (self.formatToolbar2.frame.size.height))
                        view.tag = c
                        view.addTarget(self, action: #selector(self.tapTag(_:)), for: .touchUpInside)
                        let x0 = UIBarButtonItem(customView: view)
                        x0.width = wid
                        allWidths += wid
                        x0.accessibilityLabel = "@\(zz[c].name)"
                        
                        self.formatToolbar2.items?.append(x0)
                    }
                    
                    self.formatToolbar2.sizeToFit()
                    if (allWidths + 40) < self.view.bounds.width {
                        self.formatToolbar2.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: (self.formatToolbar2.frame.size.height))
                    } else {
                        self.formatToolbar2.frame = CGRect(x: 0, y: 0, width: allWidths + 40, height: (self.formatToolbar2.frame.size.height))
                    }
                    if self.cellPostTextView != nil {
                        self.scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: (self.view.frame.width), height: (self.formatToolbar2.frame.size.height)))
                        self.scrollView.backgroundColor = .custom.quoteTint
                        self.scrollView.showsVerticalScrollIndicator = false
                        self.scrollView.showsHorizontalScrollIndicator = false
                        self.scrollView.contentSize = self.formatToolbar2.frame.size
                        self.scrollView.addSubview(self.formatToolbar2)
                        self.cellPostTextView!.inputAccessoryView = self.scrollView
                        self.cellPostTextView!.reloadInputViews()
#if targetEnvironment(macCatalyst)
                        self.scrollView.frame.origin.y = self.view.bounds.height - self.formatToolbar2.bounds.size.height - 5
                        self.formatToolbar.removeFromSuperview()
                        self.scrollView.removeFromSuperview()
                        self.view.addSubview(self.scrollView)
#endif
                    }
                    
                }
            }
        }
    }
    
    @objc func tapTag(_ sender: UIButton) {
        triggerHapticImpact(style: .light)
        self.pendingRequestWorkItem?.cancel()
        let searchItem1 = self.tagsAll[sender.tag].name
        if let cellPostTextView {
            if let selectedRange = cellPostTextView.selectedTextRange {
                let cursorPosition = cellPostTextView.offset(from: cellPostTextView.beginningOfDocument, to: selectedRange.start)
                if let currPosition = cellPostTextView.position(from: cellPostTextView.beginningOfDocument, offset: cursorPosition) {
                    let tag = self.getCurrentTagOrUser(isTag: true) ?? ""
                    if let currTagPosition = cellPostTextView.position(from: cellPostTextView.beginningOfDocument, offset: cursorPosition - tag.count) {
                        if let textRange = cellPostTextView.textRange(from: currTagPosition, to: currPosition) {
                            if let range = cellPostText.rangeFromNSRange(nsRange: self.rangeFromTextRange(textRange: textRange, textView: cellPostTextView)) {
                                cellPostText.replaceSubrange(range, with: "\(searchItem1) ")
                                self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                            }
                        }
                    }
                    self.parseText()
                }
                let cursorDiff = Array(searchItem1).count - Array(self.trimmedAtString).count + 1
                if let newPosition = cellPostTextView.position(from: cellPostTextView.beginningOfDocument, offset: cursorPosition + cursorDiff) {
                    if newPosition != cellPostTextView.endOfDocument {
                        cellPostTextView.selectedTextRange = cellPostTextView.textRange(from: newPosition, to: newPosition)
                    }
                }
            }
            // show default toolbar
            if self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
                cellPostTextView.inputAccessoryView = self.formatToolbar
                cellPostTextView.reloadInputViews()
            }
#if targetEnvironment(macCatalyst)
            self.formatToolbar.removeFromSuperview()
            self.scrollView.removeFromSuperview()
            self.view.addSubview(self.formatToolbar)
#endif
        }
    }
    
    func getCurrentTagOrUser(isTag: Bool) -> String? {
        if let cellPostTextView = self.cellPostTextView {
            let selectedRange: UITextRange? = cellPostTextView.selectedTextRange
            var cursorOffset: Int? = nil
            if let aStart = selectedRange?.start {
                cursorOffset = cellPostTextView.offset(from: cellPostTextView.beginningOfDocument, to: aStart)
            }
            let text = cellPostText
            let substring = (text as NSString?)?.substring(to: cursorOffset!)
            if isTag {
                let tag = substring?.components(separatedBy: "#").last
                return tag
            } else {
                var user = substring?.components(separatedBy: "@").last
                // Handle the case where the user has typed '@aaa@bbb' before tapping the button
                if user != nil {
                    if let lastWord = substring?.components(separatedBy: " ").last,
                       lastWord.hasPrefix("@"),
                       lastWord.contains(user!) {
                        let index = lastWord.index(lastWord.startIndex, offsetBy: 1)
                        user = String(lastWord[index...])
                    }
                }
                return user
            }
        } else {
            return nil
        }
    }
    
    func rangeFromTextRange(textRange: UITextRange, textView: UITextView) -> NSRange {
        let location: Int = textView.offset(from: textView.beginningOfDocument, to: textRange.start)
        let length: Int = textView.offset(from: textRange.start, to: textRange.end)
        return NSMakeRange(location, length)
    }
    
    @objc func updatePostButton() {
        DispatchQueue.main.async {
            
            // Is the text valid?
            var hasValidText = false
            if self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
                let textCount = self.cellPostText.count
                hasValidText = (textCount > 0) &&
                    ((textCount <= self.postCharacterCount2) || self.threadingAllowed())
            }
            
            // Is there any media at all?
            let hasAnyMedia = self.imageButton[0].alpha == 1

            
            let hasAnyValidContent = hasValidText || hasAnyMedia
            
            // Enable if (1) there is any valid content, AND
            //           (2) any editing has happened
            let canSend = hasAnyValidContent &&
                            (self.hasEditedText || self.hasEditedMedia || self.hasEditedMetadata || self.hasEditedPoll)
            if canSend {
                let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
                self.canPost = true
                self.btn2.setImage(UIImage(systemName: "arrow.up", withConfiguration: symbolConfig0)?.withTintColor(UIColor.custom.activeInverted, renderingMode: .alwaysOriginal), for: .normal)
                self.btn2.backgroundColor = .custom.active
                self.setupImages2()
            } else {
                let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
                self.canPost = false
                self.btn2.setImage(UIImage(systemName: "arrow.up", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
                self.btn2.backgroundColor = UIColor.label.withAlphaComponent(0.08)
            }
        }
    }
    
    @objc func quotePostDidUpdate() {
        if self.isQuotePost {
            self.tableView.reloadSections(IndexSet(2...2), with: .none)
        } else {
            log.warning("unexpectedly got an update for a quote post")
        }
    }
    
    func sendDataIfCanPost() {
        self.stopActivity()
        if GlobalStruct.canPostPost {
            self.sendData()
        }
    }
    
    @objc func sendTap() {
        DispatchQueue.main.async {
            var canP = true
            if GlobalStruct.altText {
                if (GlobalStruct.whichImagesAltText.count >= self.mediaIdStrings.count) {
                    canP = true
                    print("has image description")
                } else {
                    canP = false
                    print("missing image description")
                    self.postMissingAltText()
                    return
                }
            }
            if let _ = self.fromEdit {
                if GlobalStruct.canPostPost {
                    self.sendEditData()
                }
                self.dismissTap()
            } else {
                if self.canPost && canP {
                    for index in 0..<self.numImages {
                        if self.imageButton[index].alpha == 1 {
                            self.visibImages += 1
                        }
                    }
                    // send post
                    if ((self.visibImages == self.mediaIdStrings.count) || self.audioAttached || self.videoAttached) && !self.isProcessingVideo {
                        // all media attached, post it
                        self.startActivity()
                        self.sendDataIfCanPost()
                        self.dismissTap()
                        GlobalStruct.currentlyPosting = true
                    } else {
                        self.visibImages = 0
                        // all media not attached, reconsider
                        let alert = UIAlertController(title: NSLocalizedString("composer.media.progress", comment: ""), message: NSLocalizedString("composer.media.progress.confirm", comment: ""), preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("composer.media.progress.giveUp", comment: ""), style: .destructive , handler:{ (UIAlertAction) in
                            self.startActivity()
                            self.sendDataIfCanPost()
                        }))
                        alert.addAction(UIAlertAction(title: NSLocalizedString("composer.media.progress.wait", comment: "As in 'to wait'"), style: .cancel , handler:{ (UIAlertAction) in
                            
                        }))
                        if let presenter = alert.popoverPresentationController {
                            presenter.sourceView = getTopMostViewController()?.view
                            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                        }
                        getTopMostViewController()?.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func startActivity() {
    }
    
    func stopActivity() {
#if !targetEnvironment(macCatalyst)
#if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            if UIDevice.current.userInterfaceIdiom == .phone {
                Task {
                    for activity in Activity<UndoStruct>.activities {
                        await activity.end(using: nil, dismissalPolicy: .immediate)
                        print("Stopped activity")
                    }
                }
            }
        }
#endif
#endif
    }
    
    private func countWithURL(_ postText: String) -> Int {
        var newString: String
        // for mastodon. urls always have 23 characters
        // content warnings don't have the url rule.
        let urlRegex = try! NSRegularExpression(pattern: #"https?://[^ ]+\.[^ ][^ ]+"#, options: .caseInsensitive)
        let urlRange = NSMakeRange(0, postText.count)
        // replace with 23 characters
        newString = urlRegex.stringByReplacingMatches(in: postText, options: [], range: urlRange, withTemplate: ".......................")
        
        // the composer ignores the domain name in mentions when counting.
        // closest regex i derived from mastodon's:
        let mentionRegex = try! NSRegularExpression(pattern: #"(@[^ \n]+)@\.*[a-zA-Z0-9](\.*[a-zA-Z0-9]+)+"#, options: .caseInsensitive)
        let mentionRange = NSMakeRange(0, newString.count)
        newString = mentionRegex.stringByReplacingMatches(in: newString, range: mentionRange, withTemplate: "$1")
        return newString.count
    }
    
    func postThread(_ postText: String, contentWarning: String) {
        let postPieces = self.postPiecesFromPost(postText, contentWarning: contentWarning)
        
        // Start posting the thread
        self.postNextThreadPiece(postPieces, inReplyTo:self.inReplyId, isFirstPiece: true)
    }
    
    // Break down the full thread into it's smaller pieces based on the current
    // threading settings. If threading is off, it will always return an array
    // with a single item.
    //
    // It will also take the content warning into account when breaking down
    // into threads.
    private func postPiecesFromPost(_ postText: String, contentWarning: String) -> [String] {
        
        // If no threader mode, just return the one post
        if !self.threadingAllowed() {
            return [postText]
        }
        
        // If threader mode, but text is short, return one item
        if self.threadingAllowed() && self.postCharacterCount2 > countWithURL(postText) + contentWarning.count {
            return [postText]
        }
        
        // First, break this down into the sub posts
        let threadFooterSize = " (xx/xx)".count // max chars for thread footer text
        let numUserCharsPerPost = postCharacterCount2 - threadFooterSize   // number of chars of the user's text per post
        
        // Split the post into various pieces
        var postPieces: [String] = []
        var currentPiece: String = ""
        var pieceSize: Int = 0
        // separate post per word.
        let allWords = postText.split(separator: " ", omittingEmptySubsequences: false)
        for word in allWords {
            let regex = try! NSRegularExpression(pattern: "https?://[^ ]+\\.[^ ][^ ]+", options: .caseInsensitive)
            let wordSize: Int
            
            // links are always 23 characters
            if regex.firstMatch(in: String(word), range: NSMakeRange(0, word.count)) != nil {
                // account for space
                wordSize = 23 + 1
            } else {
                // account for space
                wordSize = word.count + 1
            }
            
            // if this word makes the post too big!
            if pieceSize + wordSize > numUserCharsPerPost {
                postPieces.append(currentPiece)
                currentPiece = String(word) + " "
                pieceSize = wordSize + 1
            }
            // if not!!!
            else {
                currentPiece += word + " "
                pieceSize += wordSize
            }
        }
        // append our final part
        postPieces.append(currentPiece)
        
        // Append footer to each thread piece
        for index in 0..<postPieces.count {
            var threadSuffix: String
            switch GlobalStruct.threaderStyle {
            case 0: // no suffix
                threadSuffix = ""
            case 1: // ellipsis - no ellipsis on the last piece though
                threadSuffix = (index < postPieces.count-1) ? " …" : ""
            case 2: // (x/y)
                threadSuffix = " (\(index+1)/\(postPieces.count))"
            case 3: // x 🧵
                threadSuffix = " \(index+1) 🧵"
            case 4: // x 🪡
                threadSuffix = " \(index+1) 🪡"
            default:
                threadSuffix = ""
                log.error("Unexpected threading style")
            }
            postPieces[index] += threadSuffix
        }
        return postPieces
    }
    
    // Post the first item in the postPieces array
    private func postNextThreadPiece(_ postPieces: [String], inReplyTo: String? = nil, isFirstPiece: Bool = false) {
        log.debug("postNextThreadPiece inReplyTo: \(inReplyTo ?? "<no id>") ifFirstPiece:\(isFirstPiece)")
        let thisPostPiece = postPieces[0]
        let remainingPostPieces = Array(postPieces.dropFirst())
        
        var repId: String? = nil
        if inReplyTo != nil {
            repId = inReplyTo
        }
        var whoCanRep = self.whoCanReply ?? .public
        // Only move public subsequent posts to .unlisted
        if !isFirstPiece && whoCanRep == .public {
            whoCanRep = .unlisted
        }

        var spoilerText: String? = nil
        if self.spoilerText != "" {
            spoilerText = self.spoilerText
        }
        log.debug("posting thread piece reply to: \(repId ?? "<no id>"), visiblity: \(whoCanRep)")
        // First, if necessary, do a search of the post to get it onto
        // the authenticated user's server.
        if inReplyTo == "ID Requires Search" {
            // Get the local post ID, and try again
            // Checking for url as reblog or original.
            if let statURL = self.allStatuses.first?.reblog?.url ?? self.allStatuses.first?.url {
                let request = Search.search(query: statURL, resolve: true)
                (self.currentAcct as? MastodonAcctData)?.client.run(request) { [weak self] (statuses) in
                    var successGettingPostID = false
                    if let error = statuses.error {
                        log.error("error from Search.search(): \(error)")
                        // I have seen 500, 503 errors returned when the serer is very busy
                    }
                    if let results = statuses.value {
                        let statuses = results.statuses
                        if let statID = statuses.first?.id {
                            successGettingPostID = true
                            DispatchQueue.main.async {
                                // Try again
                                self?.postNextThreadPiece(postPieces, inReplyTo: statID)
                            }
                        } else {
                            log.error("Expected a status")
                        }
                    }
                    // Put an alert to retry if needed.
                    if !successGettingPostID {
                        DispatchQueue.main.async { [weak self] in
                            self?.setPostFailure()
                        }
                    }
                }
            } else {
                log.error("unable to get a stat url")
            }
            return
        }
        let request = Statuses.create(status: thisPostPiece, replyToID: repId, mediaIDs: self.mediaIdStrings, sensitive: self.isSensitive, spoilerText: spoilerText, scheduledAt: self.scheduledTime, language: PostLanguages.shared.postLanguage, poll: GlobalStruct.newPollPost, visibility: whoCanRep)
        (self.currentAcct as? MastodonAcctData)?.client.run(request) { (statuses) in
            if let error = statuses.error {
                log.error("Unable to post thread piece; error: \(error)")
            }
            if let stat = statuses.value {
                DispatchQueue.main.async {
                    if remainingPostPieces.count > 0 {
                        self.postNextThreadPiece(remainingPostPieces, inReplyTo: stat.id)
                    } else {
                        self.dismiss(animated: true, completion: nil)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "postPosted"), object: nil)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateFeed"), object: nil)
                    }
                }
            }
        }
    }
    
    func sendDataBluesky() {
        let record = Model.Feed.Post(
            createdAt: Date(),
            text: cellPostText,
            facets: [],
            reply: nil,
            embed: nil)
        
        Task {
            guard let account = AccountsManager.shared.currentAccount as? BlueskyAcctData
            else { return }
            
            _ = try await account.api.createRecord(
                repo: account.userID,
                record: record)
            
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "postPosted"),
                object: nil)
        }
    }
    
    func sendData() {
        let postText: String = cellPostText
        let contentWarning = self.spoilerText
        let postPieces = self.postPiecesFromPost(postText, contentWarning: contentWarning)
        if postPieces.count > 1 {
            self.postThread(postText, contentWarning: contentWarning)
        } else {
            // First, if necessary, do a search of the post to get it onto
            // the authenticated user's server.
            if self.inReplyId == "ID Requires Search" {
                // Get the local post ID, and try again
                // Checking for url as reblog or original.
                if let statURL = self.allStatuses.first?.reblog?.url ?? self.allStatuses.first?.url {
                    let request = Search.search(query: statURL, resolve: true)
                    (self.currentAcct as? MastodonAcctData)?.client.run(request) { (statuses) in
                        var successGettingPostID = false
                        if let error = statuses.error {
                            log.error("error from Search.search(): \(error)")
                            AnalyticsManager.track(event: self.inReplyId.isEmpty ? .newPostFailed : .newReplyFailed, props: ["isQuotePost": self.isQuotePost])
                            AnalyticsManager.reportError(error)
                            // I have seen 500, 503 errors returned when the serer is very busy
                        }
                        if let results = statuses.value {
                            let statuses = results.statuses
                            if let statID = statuses.first?.id {
                                successGettingPostID = true
                                DispatchQueue.main.async {
                                    self.inReplyId = statID
                                    // Try again
                                    self.sendData()
                                }
                            } else {
                                log.error("Expected a status")
                            }
                        }
                        // Put an alert to retry if needed.
                        if !successGettingPostID {
                            DispatchQueue.main.async { [weak self] in
                                self?.setPostFailure()
                            }
                        }
                    }
                } else {
                    log.error("unable to get a stat url")
                }
                return
            }
            
            var successSendingPost = false
            var repId: String? = nil
            if self.inReplyId != "" {
                repId = self.inReplyId
            }
            var spoilerText: String? = nil
            if self.spoilerText != "" {
                spoilerText = self.spoilerText
            }
            let request = Statuses.create(status: postText, replyToID: repId, mediaIDs: self.mediaIdStrings, sensitive: self.isSensitive, spoilerText: spoilerText, scheduledAt: self.scheduledTime, language: PostLanguages.shared.postLanguage, poll: GlobalStruct.newPollPost, visibility: self.whoCanReply ?? .public)
            (self.currentAcct as? MastodonAcctData)?.client.run(request) { (statuses) in
                print("new post - \(statuses)")
                if let error = statuses.error {
                    log.error("Unable to post; error: \(error)")
                    AnalyticsManager.track(event: self.inReplyId.isEmpty ? .newPostFailed : .newReplyFailed)
                    AnalyticsManager.reportError(error)
                }
                if let _ = statuses.value {
                    AnalyticsManager.track(event: .newPost, props:
                                            [
                                                "postLanguage": PostLanguages.shared.postLanguage,
                                                "poll": (GlobalStruct.newPollPost?.isEmpty as? Bool) ?? false,
                                                "hasMedia": self.mediaIdStrings.count > 0,
                                                "numberOfMedia": self.mediaIdStrings.count,
                                                "visibility": (self.whoCanReply ?? .public).rawValue,
                                                "isQuotePost": self.isQuotePost,
                                                "isReply": !self.inReplyId.isEmpty
                                            ])
                    successSendingPost = true
                    DispatchQueue.main.async {
                        if self.scheduledTime == nil {
                            if self.whoCanReply == .direct {
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "postSentMessage"), object: nil)
                            } else {
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "postPosted"), object: nil)
                            }
                        } else {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "postScheduled"), object: nil)
                        }
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateFeed"), object: nil)
                        
                        if self.fromExpanded != "" {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "updateMessageList"), object: nil)
                        }

                        self.dismissTap()
                    }
                }
                
                // Put an alert to retry if needed.
                if !successSendingPost {
                    DispatchQueue.main.async { [weak self] in
                        self?.setPostFailure()
                    }
                }
            }
        }
    }
    
    func sendEditData() {
        if self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
            let postText: String = cellPostText
            var spoilerText: String? = nil
            if self.spoilerText != "" {
                spoilerText = self.spoilerText
            }
            let id = "\((self.fromEdit?.uri ?? "").split(separator: "/").last ?? "")"
            var mediaAttributes: [String] = []
            if GlobalStruct.mediaEditID != "" {
                mediaAttributes = [GlobalStruct.mediaEditID, GlobalStruct.mediaEditDescription]
            }
            let request = Statuses.edit(id: id, status: postText, mediaIDs: self.mediaIdStrings, sensitive: self.isSensitive, spoilerText: spoilerText, poll: GlobalStruct.newPollPost, mediaAttributes: mediaAttributes)
            (self.currentAcct as? MastodonAcctData)?.client.run(request) { (statuses) in
                print("updated post - \(statuses)")
                if let error = statuses.error {
                    log.error("Unable to post; error: \(error)")
                }
                if let status = statuses.value {
                    DispatchQueue.main.async {
                        if self.fromDetailReply {
                            let object: [String: String] = [
                                "detailReplyToEdit" : self.detailReplyToEdit,
                                "detailReplyTextToEdit": status.content.stripHTML()
                            ]
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDetailReplyFromEdit"), object: object)
                        } else {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "postUpdated"), object: nil)
                        }
                        GlobalStruct.tempUpdateMetrics = [status]
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateMetrics"), object: nil)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateFeed"), object: nil)
                        
                        // Consolidate list data with updated post card data and request a cell refresh
                        let newPost = PostCardModel(status: status)
                        newPost.preloadQuotePost()
                        NotificationCenter.default.post(name: PostActions.didUpdatePostCardNotification, object: nil, userInfo: ["postCard": newPost])
                    }
                }
            }
        }
    }
        
    func refreshDrafts() {
        do {
            GlobalStruct.drafts = try Disk.retrieve("\(AccountsManager.shared.currentAccount?.diskFolderName() ?? "")/drafts.json", from: .documents, as: [Draft].self)
            self.createToolbar()
        } catch {
            GlobalStruct.drafts = []
            self.createToolbar()
            log.warning("error fetching drafts from Disk - \(error)")
        }
    }
    
    @objc func postMissingAltText() {
        triggerHapticNotification()
        
        for index in 0..<numImages {
            if self.imageButton[index].alpha == 1 && !GlobalStruct.whichImagesAltText.contains(index) {
                let vc = AltTextViewController()
                vc.currentImage = self.imageButton[index].currentImage ?? UIImage()
                if self.mediaIdStrings.count > index {
                    vc.id = self.mediaIdStrings[index]
                    vc.whichImagesAltText = index
                    self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
                }
                break
            }
        }
    }
    
    private func threadingAllowed() -> Bool {
        // Threading only allowed if threader mode is enabled,
        // and this is NOT a private message.
        return GlobalStruct.threaderMode && (self.whoCanReply != .direct)
    }
    
}


// Toolbar language extension
extension NewPostViewController: TranslationComposeViewControllerDelegate {
    private func toolbarLanguageButton() -> UIBarButtonItem {
        let choose_language = NSLocalizedString("composer.chooseLanguage", comment: "")
        // Create the button menu
        var menuItems: [UIAction] = []
        let showLanguagePickerAction = UIAction(title: choose_language, image: nil, identifier: nil) { [weak self] _ in
            self?.menuShowLanguagePicker()
        }
        menuItems.append(showLanguagePickerAction)
        for language in PostLanguages.shared.postLanguages {
            let languageName = Locale.current.localizedString(forLanguageCode: language) ?? language
            let pickLanguageAction = UIAction(title:languageName, image: nil, identifier: nil) { [weak self] _ in
                self?.menuSelectLanguage(language)
            }
            menuItems.append(pickLanguageAction)
        }
        let buttonMenu = UIMenu(title: "", image: nil, identifier: nil, options: [], children: menuItems)

        // Create the button
        let buttonImage = buttonImage()
        let toolbarLanguageButton = UIBarButtonItem(image: buttonImage, style: .plain, target: self, action: nil)
        toolbarLanguageButton.accessibilityLabel = choose_language
        toolbarLanguageButton.menu = buttonMenu
        return toolbarLanguageButton
    }
    
    private func buttonImage() -> UIImage {
        // Get the width of the current language
        let languageAbbreviation = PostLanguages.shared.postLanguage.uppercased()
        let attributedText = NSMutableAttributedString(string: languageAbbreviation, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 10, weight: .medium)])
        let textSize = attributedText.size()
        
        // FontAwesome characters are 21 pixels high;
        // width is 21 or more to accomodate the text width
        var badgeSize = CGSize(width: 25, height: 21)
        let textwidthWithMargins = textSize.width + 7.0
        badgeSize.width = max(badgeSize.width, textwidthWithMargins)

        let badge = UIGraphicsImageRenderer(size: badgeSize).image { _ in
            // Draw the surrounding rect
            let borderWidth = 1.6
            let lineRect = CGRect(x: 2, y: 2, width: badgeSize.width - 4.0, height: 15)
            let context = UIGraphicsGetCurrentContext()!
            let clipPath: CGPath = UIBezierPath(roundedRect: lineRect, cornerRadius: 2.0).cgPath
            context.addPath(clipPath)
            context.closePath()
            context.setLineWidth(borderWidth)
            context.strokePath()
            // Draw the language abbreviation string
            let leftMargin = (badgeSize.width - textSize.width) / 2.0
            attributedText.draw(at: CGPointMake(leftMargin, 3.5))
        }
        return badge.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
    }
        
    @objc func menuShowLanguagePicker() {
        self.hasEditedMetadata = true
        self.updatePostButton()
        let vc = TranslationComposeViewController()
        vc.fromSetLanguage = true
        vc.delegate = self
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    @objc func menuSelectLanguage(_ language: String) {
        PostLanguages.shared.selectPostLanguage(language)
        self.createToolbar()
    }
    
    // TranslationComposeViewControllerDelegate
    func didSelectLanguage(language: String) {
        PostLanguages.shared.selectPostLanguage(language)
        self.createToolbar()
    }
    
    func removeLanguage(language: String) {
        PostLanguages.shared.removePostLanguage(language)
        self.createToolbar()
    }

}
