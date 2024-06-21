//
//  ScheduledPostsViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 29/11/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

// swiftlint:disable:next type_body_length
class ScheduledPostsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let btn0 = UIButton(type: .custom)
    let btn1 = UIButton(type: .custom)
    let btn2 = UIButton(type: .custom)
    let launchIndicator = UIImageView()
    let emptyView = UIImageView()
    var tableView = UITableView()
    let refreshControl = UIRefreshControl()
    var hashtag: String = ""
    var listTitle: String = ""
    var listID: String = ""
    var otherInstance: String = ""
    var nBounds: CGRect = CGRect.zero
    var nBar: UINavigationBar = UINavigationBar()
    var reloadCount: Int = 0
    var nextCursor: String? = nil
    var statusesAll: [ScheduledStatus] = []
    var allUserIds: [String] = []
    let dateViewBG = UIButton()
    let dateView = UIView()
    let datePicker = UIDatePicker()
    var tempDate = Date()
    var scheduledTime: String? = nil
    var tempIndex: Int = 0
    var statusesEdited: [StatusEdit] = []
    var fromEdit: Status? = nil
    var drafts: [Draft] = []
    var fromComposeButton: Bool = false
    var showXmark: Bool = false
    var currentUser: Account? = nil
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        for cell in self.tableView.visibleCells {
            if let cell = cell as? MessageCell {
                cell.bioText.textColor = .custom.mainTextColor
            }
        }
        self.dateViewBG.frame = self.view.frame
        self.emptyView.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 30)
        
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
    
    var tempScrollPosition: CGFloat = 0
    @objc func scrollToTop() {
        DispatchQueue.main.async {
            if let _ = self.fromEdit {
                if !self.statusesEdited.isEmpty {
                    // scroll to top
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                    self.tempScrollPosition = self.tableView.contentOffset.y
                }
            } else {
                if !self.statusesAll.isEmpty {
                    // scroll to top
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                    self.tempScrollPosition = self.tableView.contentOffset.y
                }
            }
        }
    }
    
    @objc func reloadAll() {
        DispatchQueue.main.async {
            // tints
            

            let hcText = UserDefaults.standard.value(forKey: "hcText") as? Bool ?? true
            if hcText == true {
                UIColor.custom.mainTextColor = .label
            } else {
                UIColor.custom.mainTextColor = .secondaryLabel
            }
            self.tableView.reloadData()
            
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
            
            for cell in self.tableView.visibleCells {
                if let cell = cell as? MessageCell {
                    cell.bioText.textColor = .custom.mainTextColor
                    cell.backgroundColor = .custom.backgroundTint
                    
                    cell.indi.backgroundColor = .custom.baseTint
                }
            }
        }
    }
    
    @objc func reloadBars() {
        DispatchQueue.main.async {
            if GlobalStruct.hideNavBars2 {
                self.extendedLayoutIncludesOpaqueBars = true
            } else {
                self.extendedLayoutIncludesOpaqueBars = false
            }
        }
    }
    
    @objc func reloadMessages() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            GlobalStruct.allCW = []
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .custom.backgroundTint
        if self.drafts.isEmpty {
            if let _ = self.fromEdit {
                self.navigationItem.title = "Edit History"
            } else {
                self.navigationItem.title = "Scheduled Posts"
            }
        } else {
            self.navigationItem.title = "Drafts"
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.scrollToTop), name: NSNotification.Name(rawValue: "scrollToTop3"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadBars), name: NSNotification.Name(rawValue: "reloadBars"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadMessages), name: NSNotification.Name(rawValue: "reloadMessages"), object: nil)
        
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
        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }
        
        if self.showXmark == false {
            if self.drafts.isEmpty {} else {
                let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
                btn0.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
                btn0.backgroundColor = UIColor.label.withAlphaComponent(0.08)
                btn0.layer.cornerRadius = 14
                btn0.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
                btn0.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
                btn0.addTarget(self, action: #selector(self.dismissTap), for: .touchUpInside)
                btn0.accessibilityLabel = NSLocalizedString("generic.dismiss", comment: "")
                let moreButton0 = UIBarButtonItem(customView: btn0)
                self.navigationItem.setLeftBarButton(moreButton0, animated: true)
            }
        } else {
            let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
            btn0.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
            btn0.backgroundColor = UIColor.label.withAlphaComponent(0.08)
            btn0.layer.cornerRadius = 14
            btn0.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            btn0.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
            btn0.addTarget(self, action: #selector(self.dismissTap), for: .touchUpInside)
            btn0.accessibilityLabel = NSLocalizedString("generic.dismiss", comment: "")
            let moreButton0 = UIBarButtonItem(customView: btn0)
            self.navigationItem.setLeftBarButton(moreButton0, animated: true)
        }
        
        self.reloadMessages()
        
        // setup
        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }
        setupTable()
        
        // fetch data
        if self.drafts.isEmpty {
            if let _ = self.fromEdit {
                if self.statusesEdited.isEmpty {
                    fetchAll2()
                }
            } else {
                if self.statusesAll.isEmpty {
                    fetchAll()
                }
            }
        } else {
            self.fetchDrafts()
        }
    }
    
    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        self.dismiss(animated: true, completion: nil)
    }
    
    func fetchDrafts() {
        self.tableView.reloadData()
    }
    
    func fetchAll(_ prevBatch: Bool = false, nextBatch: Bool = false) {
        let request = Statuses.allScheduled()
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let error = statuses.error {
                log.error("Failed to fetch scheduled posts: \(error)")
                DispatchQueue.main.async {
                    if self.statusesAll.isEmpty {
                        self.emptyView.alpha = 1
                    }
                }
            } else {
                DispatchQueue.main.async {
                    if (statuses.value?.count ?? 0) > 0 {
                        self.emptyView.alpha = 0
                    } else {
                        self.emptyView.alpha = 1
                    }
                }
            }
            if let stat = (statuses.value) {
                DispatchQueue.main.async {
                    self.statusesAll = stat
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func fetchAll2(_ prevBatch: Bool = false, nextBatch: Bool = false) {
        if let stat = self.fromEdit {
            let request = Statuses.editHistory(id: stat.reblog?.id ?? stat.id ?? "")
            AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
                if let stat = (statuses.value) {
                    DispatchQueue.main.async {
                        self.statusesEdited = stat
                        self.tableView.reloadData()
                        
                        var c = stat.count - 1
                        for _ in stat {
                            if c == 0 {} else {
                                self.diffs(c)
                                c -= 1
                            }
                        }
                    }
                }
            }
        }
    }
    
    func diffs(_ ind: Int) {
        let text1 = statusesEdited[ind].content.stripHTML()
        let text2 = statusesEdited[ind - 1].content.stripHTML()
        
        if let cell = self.tableView.cellForRow(at: IndexPath(row: ind, section: 0)) as? PostCell {
            let cell = cell.p
            let arr1 = Array(text1.replacingOccurrences(of: "\n", with: "±"))
            let arr2 = Array(text2.replacingOccurrences(of: "\n", with: "±"))
            let insertions = arr1.difference(from: arr2).insertions
            let removals = arr1.difference(from: arr2).removals
            
            let attributes1 = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular), NSAttributedString.Key.foregroundColor : UIColor.custom.mainTextColor, NSAttributedString.Key.backgroundColor : UIColor.systemGreen.withAlphaComponent(0.26)] as [NSAttributedString.Key : Any]
            let attributes2 = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular), NSAttributedString.Key.foregroundColor : UIColor.systemRed.withAlphaComponent(0.76), NSAttributedString.Key.strikethroughColor : UIColor.systemRed.withAlphaComponent(0.76), NSAttributedString.Key.strikethroughStyle : NSUnderlineStyle.thick.rawValue] as [NSAttributedString.Key : Any]
            
            _ = insertions.map({ x in
                let offset = Int("\(x)".slice(from: "offset: ", to: ",") ?? "") ?? 0
                let attributedString = NSMutableAttributedString(string: String("\(x)".slice(from: "element: \"", to: "\"") ?? ""), attributes: attributes1)
                let attributedString2 = NSMutableAttributedString(string: "\n", attributes: attributes1)
                if offset >= (cell.postText.text?.count ?? 0) {
                    if (cell.postText.text?.count ?? 0) == 0 {
                        cell.postText.textStorage.replaceCharacters(in: NSRange(location: 0, length: 1), with: attributedString)
                    } else {
                        cell.postText.textStorage.replaceCharacters(in: NSRange(location: (cell.postText.text?.count ?? 0) - 1, length: 1), with: attributedString)
                    }
                } else {
                    if String("\(x)".slice(from: "element: \"", to: "\"") ?? "") == "±" {
                        cell.postText.textStorage.replaceCharacters(in: NSRange(location: offset, length: 1), with: attributedString2)
                    } else {
                        cell.postText.textStorage.replaceCharacters(in: NSRange(location: offset, length: 1), with: attributedString)
                    }
                }
            })
            
            _ = removals.map({ x in
                let offset = Int("\(x)".slice(from: "offset: ", to: ",") ?? "") ?? 0
                let attributedString = NSMutableAttributedString(string: String("\(x)".slice(from: "element: \"", to: "\"") ?? ""), attributes: attributes2)
                let attributedString2 = NSMutableAttributedString(string: "\n", attributes: attributes2)
                if offset >= (cell.postText.text?.count ?? 0) {
                    if (cell.postText.text?.count ?? 0) == 0 {
                        cell.postText.textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: attributedString)
                    } else {
                        cell.postText.textStorage.replaceCharacters(in: NSRange(location: (cell.postText.text?.count ?? 0) - 1, length: 0), with: attributedString)
                    }
                } else {
                    if String("\(x)".slice(from: "element: \"", to: "\"") ?? "") == "±" {
                        cell.postText.textStorage.replaceCharacters(in: NSRange(location: offset, length: 0), with: attributedString2)
                    } else {
                        cell.postText.textStorage.replaceCharacters(in: NSRange(location: offset, length: 0), with: attributedString)
                    }
                }
            })
        }
    }
    
    func saveToDisk() {
        
    }
    
    func setupTable() {
        self.emptyView.bounds.size.width = 80
        self.emptyView.bounds.size.height = 80
        self.emptyView.backgroundColor = UIColor.clear
        self.emptyView.image = UIImage(systemName: "sparkles", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular))?.withTintColor(UIColor.secondaryLabel.withAlphaComponent(0.18), renderingMode: .alwaysOriginal)
        self.emptyView.alpha = 0
        self.tableView.addSubview(self.emptyView)
        
        tableView.register(PostCell.self, forCellReuseIdentifier: "PostCell")
        tableView.register(PostCell.self, forCellReuseIdentifier: "PostCell2")
        tableView.alpha = 1
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.layer.masksToBounds = true
        tableView.estimatedRowHeight = 89
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: .zero)
        view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.drafts.isEmpty {
            if let _ = self.fromEdit {
                return self.statusesEdited.count
            } else {
                return self.statusesAll.count
            }
        } else {
            return self.drafts.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.drafts.isEmpty {
            if let _ = self.fromEdit {
                let newCell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
                let cell = newCell.p
                cell.userName.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
                cell.userTag.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
                cell.dateTime.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
                cell.postText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
                cell.postText.lineSpacing = GlobalStruct.customLineSize
                cell.linkUsername.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
                cell.linkUsertag.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
                cell.linkPost.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
                cell.linkPost.lineSpacing = GlobalStruct.customLineSize
                cell.repostView.repostText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
                
                let stat: StatusEdit? = self.statusesEdited[indexPath.row]
                
                if let profileURL = URL(string: stat?.account?.avatar ?? "") {
                    cell.profileIcon.sd_setImage(with: profileURL, for: .normal, completed: nil)
                }

                let text = stat?.content.stripHTML() ?? ""
                var linkStr: Card? = nil
                if GlobalStruct.linkPreviewCards1 == false {
                    linkStr = nil
                }
                cell.postText.commitUpdates {
                    cell.postText.textColor = .custom.mainTextColor
                    cell.linkPost.textColor = .custom.mainTextColor2
                    cell.postText.text = text
                    cell.postText.numberOfLines = GlobalStruct.maxLines
                    if GlobalStruct.maxLines != 0 {
                        cell.postText.text = (cell.postText.text ?? "").replacingOccurrences(of: "\n", with: " ")
                    }
                    cell.postText.mentionColor = .custom.baseTint
                    cell.postText.hashtagColor = .custom.baseTint
                    cell.postText.URLColor = .custom.baseTint
                    cell.postText.emailColor = .custom.baseTint
                    
                    let userName = stat?.account?.displayName ?? ""
                    cell.userName.text = userName
                    
                    let userTag = stat?.account?.acct ?? ""
                    cell.userTag.text = "@\(userTag)"
                    
                    let time1 = (stat?.createdAt ?? "")
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = GlobalStruct.dateFormat
                    var time = dateFormatter.date(from: time1)?.toStringWithRelativeTime() ?? ""
                    
                    if GlobalStruct.originalPostTimeStamp == false {
                        let time1 = (stat?.createdAt ?? "")
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = GlobalStruct.dateFormat
                        time = dateFormatter.date(from: time1)?.toStringWithRelativeTime() ?? ""
                    }
                    if GlobalStruct.timeStampStyle == 1 {
                        let time1 = (stat?.createdAt ?? "")
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = GlobalStruct.dateFormat
                        time = dateFormatter.date(from: time1)?.toString(dateStyle: .short, timeStyle: .short) ?? ""
                        if GlobalStruct.originalPostTimeStamp == false {
                            let time1 = (stat?.createdAt ?? "")
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = GlobalStruct.dateFormat
                            time = dateFormatter.date(from: time1)?.toString(dateStyle: .short, timeStyle: .short) ?? ""
                        }
                    } else if GlobalStruct.timeStampStyle == 2 {
                        time = ""
                    }
                    cell.dateTime.text = time
                }
                
                if stat?.account?.locked ?? false == false {
                    cell.lockedBadge.alpha = 0
                    cell.lockedBackground.alpha = 0
                } else {
                    let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: GlobalStruct.smallerFontSize, weight: .bold)
                    cell.lockedBadge.image = UIImage(systemName: "lock.circle.fill", withConfiguration: symbolConfig0)?.withTintColor(UIColor.label, renderingMode: .alwaysOriginal)
                    cell.lockedBadge.alpha = 1
                    cell.lockedBackground.alpha = 1
                    cell.lockedBackground.backgroundColor = .custom.backgroundTint
                }
                
                // images
                var alt: [String] = []
                if stat?.mediaAttachments.count ?? 0 > 0 {
                    let z = stat?.mediaAttachments ?? []
                    var isVideo: Bool = false
                    let mediaItems = z[0].previewURL
                    if let a = z.first?.description {
                        alt.append(a)
                    }
                    
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
                        if let a = z[1].description {
                            alt.append(a)
                        }
                    }
                    
                    var mediaItems2: String?
                    if z.count > 2 {
                        mediaItems2 = z[2].previewURL
                        if let a = z[2].description {
                            alt.append(a)
                        }
                    }
                    
                    var mediaItems3: String?
                    if z.count > 3 {
                        mediaItems3 = z[3].previewURL
                        if let a = z[3].description {
                            alt.append(a)
                        }
                    }
                    
                    cell.setupImages(url1: mediaItems ?? "", url2: mediaItems1, url3: mediaItems2, url4: mediaItems3, isVideo: isVideo, altText: alt, fullImages: z)
                    cell.setupConstraints(containsImages: true, quotePostCard: nil, containsRepost: false, containsPoll: false, pollOptions: nil, link: linkStr, showButtons: false, stat: nil)
                } else {
                    cell.setupConstraints(containsImages: false, quotePostCard: nil, containsRepost: false, containsPoll: false, pollOptions: nil, link: linkStr, showButtons: false, stat: nil)
                }
                
                // tap items
                cell.postText.handleMentionTap { (str) in
                    
                }
                cell.postText.handleHashtagTap { (str) in
                    triggerHapticImpact(style: .light)
                    let vc = NewsFeedViewController(viewModel: NewsFeedViewModel(.hashtag(Tag(name: str, url: ""))))
                    if vc.isBeingPresented {} else {
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
                cell.postText.handleURLTap { (str) in
                    triggerHapticImpact(style: .light)
                    PostActions.openLink(str)
                }
                cell.postText.handleEmailTap { (str) in
                    
                }
                
                newCell.separatorInset = .zero
                let bgColorView = UIView()
                bgColorView.backgroundColor = .clear
                newCell.selectedBackgroundView = bgColorView
                newCell.backgroundColor = .custom.backgroundTint
                
                var minusDiff: Int = 3
                if self.statusesAll.count < 4 {
                    minusDiff = 1
                }
                if indexPath.row == self.statusesAll.count - minusDiff {
                    self.fetchAll(false, nextBatch: true)
                }
                
                return newCell
            } else {
                let newCell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
                let cell = newCell.p
                cell.userName.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
                cell.userTag.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
                cell.dateTime.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
                cell.postText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
                cell.postText.lineSpacing = GlobalStruct.customLineSize
                cell.linkUsername.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
                cell.linkUsertag.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
                cell.linkPost.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
                cell.linkPost.lineSpacing = GlobalStruct.customLineSize
                cell.repostView.repostText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
                
                let stat: ScheduledStatus? = self.statusesAll[indexPath.row]
                
                if let profileURL = URL(string: AccountsManager.shared.currentUser()?.avatar ?? "") {
                    cell.profileIcon.sd_setImage(with: profileURL, for: .normal, completed: nil)
                }

                let text = stat?.params.text.stripHTML() ?? ""
                var linkStr: Card? = nil
                if GlobalStruct.linkPreviewCards1 == false {
                    linkStr = nil
                }
                cell.postText.commitUpdates {
                    cell.postText.textColor = .custom.mainTextColor
                    cell.linkPost.textColor = .custom.mainTextColor2
                    cell.postText.text = text
                    cell.postText.numberOfLines = GlobalStruct.maxLines
                    if GlobalStruct.maxLines != 0 {
                        cell.postText.text = (cell.postText.text ?? "").replacingOccurrences(of: "\n", with: " ")
                    }
                    cell.postText.mentionColor = .custom.baseTint
                    cell.postText.hashtagColor = .custom.baseTint
                    cell.postText.URLColor = .custom.baseTint
                    cell.postText.emailColor = .custom.baseTint
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                    let updatedAt = dateFormatter.date(from: stat?.scheduledAt ?? "")
                    cell.userName.text = updatedAt?.toString(dateStyle: .medium, timeStyle: .medium) ?? ""
                    cell.userName.textColor = .secondaryLabel
                    
                    cell.userTag.text = ""
                    cell.dateTime.text = updatedAt?.toStringWithRelativeTime() ?? ""
                }
                
                cell.lockedBadge.alpha = 0
                cell.lockedBackground.alpha = 0
                cell.indicator.alpha = 0
                
                // images
                var alt: [String] = []
                if stat?.mediaAttachments.count ?? 0 > 0 {
                    let z = stat?.mediaAttachments ?? []
                    var isVideo: Bool = false
                    let mediaItems = z[0].previewURL
                    if let a = z.first?.description {
                        alt.append(a)
                    }
                    
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
                        if let a = z[1].description {
                            alt.append(a)
                        }
                    }
                    
                    var mediaItems2: String?
                    if z.count > 2 {
                        mediaItems2 = z[2].previewURL
                        if let a = z[2].description {
                            alt.append(a)
                        }
                    }
                    
                    var mediaItems3: String?
                    if z.count > 3 {
                        mediaItems3 = z[3].previewURL
                        if let a = z[3].description {
                            alt.append(a)
                        }
                    }
                    
                    cell.setupImages(url1: mediaItems ?? "", url2: mediaItems1, url3: mediaItems2, url4: mediaItems3, isVideo: isVideo, altText: alt, fullImages: z)
                    cell.setupConstraints(containsImages: true, quotePostCard: nil, containsRepost: false, containsPoll: false, pollOptions: nil, link: linkStr, showButtons: false, stat: nil)
                } else {
                    // Check if this is a quote post
                    cell.setupConstraints(containsImages: false, quotePostCard: nil, containsRepost: false, containsPoll: false, pollOptions: nil, link: linkStr, showButtons: false, stat: nil)
                }
                
                // tap items
                cell.postText.handleMentionTap { (str) in
                    
                }
                cell.postText.handleHashtagTap { (str) in
                    triggerHapticImpact(style: .light)
                    let vc = NewsFeedViewController(viewModel: NewsFeedViewModel(.hashtag(Tag(name: str, url: ""))))
                    if vc.isBeingPresented {} else {
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
                cell.postText.handleURLTap { (str) in
                    triggerHapticImpact(style: .light)
                    PostActions.openLink(str)
                }
                cell.postText.handleEmailTap { (str) in
                    
                }
                
                newCell.separatorInset = .zero
                let bgColorView = UIView()
                bgColorView.backgroundColor = .clear
                newCell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.backgroundTint
                
                var minusDiff: Int = 3
                if self.statusesAll.count < 4 {
                    minusDiff = 1
                }
                if indexPath.row == self.statusesAll.count - minusDiff {
                    self.fetchAll(false, nextBatch: true)
                }
                
                return newCell
            }
        } else {
            let newCell = tableView.dequeueReusableCell(withIdentifier: "PostCell2", for: indexPath) as! PostCell
            let cell = newCell.p
            cell.userName.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
            cell.userTag.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
            cell.dateTime.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
            cell.postText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
            cell.postText.lineSpacing = GlobalStruct.customLineSize
            cell.linkUsername.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
            cell.linkUsertag.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
            cell.linkPost.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
            cell.linkPost.lineSpacing = GlobalStruct.customLineSize
            cell.repostView.repostText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
            
            let stat: Status? = self.drafts[indexPath.row].contents
            
            if let profileURL = URL(string: stat?.reblog?.account?.avatar ?? stat?.account?.avatar ?? "") {
                cell.profileIcon.sd_setImage(with: profileURL, for: .normal, completed: nil)
            }
            var rt: Bool = false
            if let _ = stat?.reblog {
                rt = true
            }
            
            if GlobalStruct.showCW {
                if (stat?.reblog?.spoilerText ?? stat?.spoilerText ?? "" != "") && !(GlobalStruct.allCW.contains(stat?.id ?? "")) {
                    cell.cwOverlay.alpha = 1
                    var st = stat?.reblog?.spoilerText.stripHTML() ?? stat?.spoilerText.stripHTML() ?? "Sensitive Content"
                    if st.count > (stat?.reblog?.content.stripHTML().count ?? stat?.content.stripHTML().count ?? 0) {
                        let co = (stat?.reblog?.content.stripHTML().count ?? stat?.content.stripHTML().count ?? 0) - 3
                        if co < 0 {} else {
                            if co > 38 {
                                st = "\(st.prefix(co))..."
                            }
                        }
                        cell.cwOverlay.setTitle(st, for: .normal)
                    } else {
                        cell.cwOverlay.setTitle(st, for: .normal)
                    }
                } else {
                    cell.cwOverlay.alpha = 0
                    cell.cwOverlay.setTitle("Sensitive Content", for: .normal)
                }
            } else {
                cell.cwOverlay.alpha = 0
                cell.cwOverlay.setTitle("Sensitive Content", for: .normal)
            }

            cell.profileIcon.tag = indexPath.row
                
            let text = stat?.reblog?.content ?? stat?.content ?? ""
            var linkStr = stat?.reblog?.card ?? stat?.card ?? nil
            if GlobalStruct.linkPreviewCards1 == false {
                linkStr = nil
            }
                cell.postText.commitUpdates {
                    cell.postText.textColor = .custom.mainTextColor
                    cell.linkPost.textColor = .custom.mainTextColor2
                    cell.postText.text = text.stripHTML()
                    cell.postText.numberOfLines = GlobalStruct.maxLines
                    if GlobalStruct.maxLines != 0 {
                        cell.postText.text = (cell.postText.text ?? "").replacingOccurrences(of: "\n", with: " ")
                    }
                    cell.postText.mentionColor = .custom.baseTint
                    cell.postText.hashtagColor = .custom.baseTint
                    cell.postText.URLColor = .custom.baseTint
                    cell.postText.emailColor = .custom.baseTint
                    
                    let userName = stat?.reblog?.account?.displayName ?? stat?.account?.displayName ?? ""
                    cell.userName.text = userName
                    
                    let userTag = stat?.reblog?.account?.acct ?? stat?.account?.acct ?? ""
                    cell.userTag.text = "@\(userTag)"
                    
                    cell.dateTime.text = ""
                }
            
            if stat?.reblog?.account?.locked ?? stat?.account?.locked ?? false == false {
                cell.lockedBadge.alpha = 0
                cell.lockedBackground.alpha = 0
            } else {
                let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: GlobalStruct.smallerFontSize, weight: .bold)
                cell.lockedBadge.image = UIImage(systemName: "lock.circle.fill", withConfiguration: symbolConfig0)?.withTintColor(UIColor.label, renderingMode: .alwaysOriginal)
                cell.lockedBadge.alpha = 1
                cell.lockedBackground.alpha = 1
                cell.lockedBackground.backgroundColor = .custom.backgroundTint
            }
                    
            // indicators
            cell.indicator.alpha = 0
            
            var containsPoll: Bool = false
            if let _ = stat?.reblog?.poll ?? stat?.poll {
                containsPoll = true
            }
                    // images
            var alt: [String] = []
            if stat?.reblog?.mediaAttachments.count ?? stat?.mediaAttachments.count ?? 0 > 0 {
                let z = stat?.reblog?.mediaAttachments ?? stat?.mediaAttachments ?? []
                var isVideo: Bool = false
                let mediaItems = z[0].previewURL
                if let a = z.first?.description {
                    alt.append(a)
                }
                
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
                    if let a = z[1].description {
                        alt.append(a)
                    }
                }
                
                var mediaItems2: String?
                if z.count > 2 {
                    mediaItems2 = z[2].previewURL
                    if let a = z[2].description {
                        alt.append(a)
                    }
                }
                
                var mediaItems3: String?
                if z.count > 3 {
                    mediaItems3 = z[3].previewURL
                    if let a = z[3].description {
                        alt.append(a)
                    }
                }
                
                cell.setupImages(url1: mediaItems ?? "", url2: mediaItems1, url3: mediaItems2, url4: mediaItems3, isVideo: isVideo, altText: alt, fullImages: z)
                cell.setupConstraints(containsImages: true, quotePostCard: nil, containsRepost: rt, containsPoll: containsPoll, pollOptions: stat?.reblog?.poll ?? stat?.poll ?? nil, link: linkStr, showButtons: false, stat: stat)
            } else {
                // Check if this is a quote post
                let quotePostCard = stat?.quotePostCard()
                cell.setupConstraints(containsImages: false, quotePostCard: quotePostCard, containsRepost: rt, containsPoll: containsPoll, pollOptions: stat?.reblog?.poll ?? stat?.poll ?? nil, link: linkStr, showButtons: false, stat: stat)
            }
            
            // tap items
            cell.postText.handleMentionTap { (str) in
                
            }
            cell.postText.handleHashtagTap { (str) in
triggerHapticImpact(style: .light)
                let vc = NewsFeedViewController(viewModel: NewsFeedViewModel(.hashtag(Tag(name: str, url: ""))))
                if vc.isBeingPresented {} else {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
            cell.postText.handleURLTap { (str) in
triggerHapticImpact(style: .light)
                PostActions.openLink(str)
            }
            cell.postText.handleEmailTap { (str) in

            }
            
            newCell.separatorInset = .zero
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
            newCell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.backgroundTint
            
            var minusDiff: Int = 3
            if self.statusesAll.count < 4 {
                minusDiff = 1
            }
            if indexPath.row == self.statusesAll.count - minusDiff {
                self.fetchAll(false, nextBatch: true)
            }
            
            return newCell
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if self.drafts.isEmpty {
            if let _ = self.fromEdit {
                return nil
            } else {
                return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { nil }, actionProvider: { suggestedActions in
                    return self.makeContextMenu(indexPath.row)
                })
            }
        } else {
            return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { nil }, actionProvider: { suggestedActions in
                return self.makeContextMenuD(indexPath.row)
            })
        }
    }
    
    func makeContextMenu(_ index: Int) -> UIMenu {
        let option1 = UIAction(title: "Update Schedule", image: UIImage(systemName: "pencil"), identifier: nil) {_ in
            self.tempIndex = index
            self.schedulePost()
        }
        option1.accessibilityLabel = "Update Schedule"
        let option2 = UIAction(title: "Delete Scheduled Post", image: UIImage(systemName: "xmark.circle"), identifier: nil) {_ in
            let request = Statuses.deleteScheduled(id: self.statusesAll[index].id)
            AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
                if let _ = (statuses.value) {
                    DispatchQueue.main.async {
                        self.statusesAll = self.statusesAll.filter({ x in
                            x.id != self.statusesAll[index].id
                        })
                        self.tableView.reloadData()
                    }
                }
            }
        }
        option2.attributes = .destructive
        option2.accessibilityLabel = "Delete Scheduled Post"
        return UIMenu(title: "", options: [], children: [option1, option2])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if self.drafts.isEmpty {} else {
            GlobalStruct.currentDraft = self.drafts[indexPath.row]
            self.drafts = self.drafts.filter({ x in
                x.id != self.drafts[indexPath.row].id
            })
            GlobalStruct.drafts = self.drafts
            self.dismiss(animated: true, completion: nil)
            if self.fromComposeButton {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "restoreFromDrafts2"), object: nil)
            } else {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "restoreFromDrafts"), object: nil)
            }
            do {
                try Disk.save(GlobalStruct.drafts, to: .documents, as: "\(AccountsManager.shared.currentAccount?.diskFolderName() ?? "")/drafts.json")
            } catch {
                log.error("error saving drafts to Disk")
            }
        }
    }
    
    func makeContextMenuD(_ index: Int) -> UIMenu {
        let delete = UIAction(title: "Delete Draft", image: UIImage(systemName: "trash"), identifier: nil) { action in
            self.drafts = self.drafts.filter({ x in
                x.id != self.drafts[index].id
            })
            GlobalStruct.drafts = self.drafts
            self.tableView.reloadData()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "createToolbar"), object: nil)
            do {
                try Disk.save(GlobalStruct.drafts, to: .documents, as: "\(AccountsManager.shared.currentAccount?.diskFolderName() ?? "")/drafts.json")
            } catch {
                log.error("error saving drafts to Disk")
            }
        }
        delete.attributes = .destructive
        delete.accessibilityLabel = "Delete Draft"
        return UIMenu(title: "", options: [], children: [delete])
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if tableView == self.tableView {
            return true
        } else {
            return false
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            if self.drafts.isEmpty {
                let alert = UIAlertController(title: nil, message: "Are you sure you want to delete this scheduled post?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive , handler:{ (UIAlertAction) in
                    let request = Statuses.deleteScheduled(id: self.statusesAll[indexPath.row].id)
                    AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
                        if let _ = (statuses.value) {
                            DispatchQueue.main.async {
                                self.statusesAll = self.statusesAll.filter({ x in
                                    x.id != self.statusesAll[indexPath.row].id
                                })
                                self.tableView.reloadData()
                            }
                        }
                    }
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
                    
                }))
                if let presenter = alert.popoverPresentationController {
                    presenter.sourceView = getTopMostViewController()?.view
                    presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                }
                getTopMostViewController()?.present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: nil, message: "Are you sure you want to delete this draft post?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive , handler:{ (UIAlertAction) in
                    self.drafts = self.drafts.filter({ x in
                        x.id != self.drafts[indexPath.row].id
                    })
                    GlobalStruct.drafts = self.drafts
                    self.tableView.reloadData()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "createToolbar"), object: nil)
                    do {
                        try Disk.save(GlobalStruct.drafts, to: .documents, as: "\(AccountsManager.shared.currentAccount?.diskFolderName() ?? "")/drafts.json")
                    } catch {
                        log.error("error saving drafts to Disk")
                    }
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
                    
                }))
                if let presenter = alert.popoverPresentationController {
                    presenter.sourceView = getTopMostViewController()?.view
                    presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                }
                getTopMostViewController()?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @objc func schedulePost() {
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) as? ComposeCell {
            cell.post.resignFirstResponder()
        }
        
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
        dateDone.setTitle("Update", for: .normal)
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
        let request = Statuses.updateScheduled(id: self.statusesAll[self.tempIndex].id, scheduledAt: self.scheduledTime)
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let _ = (statuses.value) {
                DispatchQueue.main.async {
                    self.fetchAll()
                }
            }
        }
    }
    
    @objc func handleDateSelection(_ sender: UIDatePicker) {
        self.tempDate = sender.date
    }
    
    @objc func dismissDateView() {
        self.scheduledTime = nil
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: { () -> Void in
            self.dateView.frame.origin.y = self.view.bounds.height/2 - 105
        })
        UIView.animate(withDuration: 0.29, delay: 0.16, options: [.curveEaseOut], animations: { () -> Void in
            self.dateViewBG.alpha = 0
            self.dateView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            self.dateView.frame.origin.y = self.view.bounds.height/2 + 150
        }) { x in
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) as? ComposeCell {
                cell.post.becomeFirstResponder()
            }
            self.dateViewBG.removeFromSuperview()
            self.dateView.removeFromSuperview()
            self.datePicker.removeFromSuperview()
            self.dateView.transform = CGAffineTransform.identity
        }
    }
    
}



