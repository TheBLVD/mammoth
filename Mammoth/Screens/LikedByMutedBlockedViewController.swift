//
//  LikedByMutedBlockedViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 04/11/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import NaturalLanguage
import SafariServices
import AVFoundation
import MobileCoreServices

class LikedByMutedBlockedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIContextMenuInteractionDelegate, UITableViewDragDelegate {
    
    var currentUserID: String? = nil
    var client: Client? = nil
    let loadingIndicator = UIActivityIndicatorView()
    let emptyView = UIImageView()
    var tableView = UITableView()
    let refreshControl = UIRefreshControl()
    var otherInstance: String = ""
    var fromOtherCommunity: Bool = false
    var currentSegment: Int = 0
    var type: Int = 0
    var id: String = ""
    var listID: String = ""
    var nBounds: CGRect = CGRect.zero
    var nBar: UINavigationBar = UINavigationBar()
    var statusesAll: [Account] = []
    var statusesAllNext: RequestRange? = nil
    var statusesAllPrev: RequestRange? = nil
    var tempDetailUrl: String = ""
    
    @objc func reloadAll() {
        DispatchQueue.main.async {
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileCell {
                cell.profileIcon.layer.borderColor = UIColor.custom.baseTint.cgColor
            }
            
            // tints
            

            let hcText = UserDefaults.standard.value(forKey: "hcText") as? Bool ?? true
            if hcText == true {
                UIColor.custom.mainTextColor = .label
            } else {
                UIColor.custom.mainTextColor = .secondaryLabel
            }
            let hcText2 = UserDefaults.standard.value(forKey: "hcText2") as? Bool ?? false
            if hcText2 == true {
                UIColor.custom.mainTextColor2 = .label
            } else {
                UIColor.custom.mainTextColor2 = .secondaryLabel
            }
            
            if !self.statusesAll.isEmpty {
                self.statusesAll = self.statusesAll.filter { $0.id != GlobalStruct.idToDelete}
                self.tableView.reloadData()
                self.saveToDisk()
            }
            
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
        tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileCell {
            cell.profileIcon.layer.borderColor = UIColor.custom.baseTint.cgColor
        }
        tableView.tableHeaderView?.frame.size.height = 60
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.currentUserID = AccountsManager.shared.currentUser()?.id
        self.client = AccountsManager.shared.currentAccountClient
        self.view.backgroundColor = .custom.backgroundTint
        if type == 0 {
            self.navigationItem.title = "Liked By..."
        } else if type == 10 {
            self.navigationItem.title = "Reposted By..."
        } else if type == 1 {
            self.navigationItem.title = NSLocalizedString("profile.muted", comment: "")
        } else if type == 2 {
            self.navigationItem.title = NSLocalizedString("profile.blocked", comment: "")
        } else if type == 3 {
            self.navigationItem.title = "Pinned Users"
        } else if type == 4 {
            self.navigationItem.title = "Follow Requests"
        } else if type == 5 {
            self.navigationItem.title = "List Members"
        } else {
            self.navigationItem.title = "Top Friends Members"
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchAllTimelines), name: NSNotification.Name(rawValue: "fetchAllTimelinesLikedBy"), object: nil)
        
        loadingIndicator.startAnimating()
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.center = self.view.center
        self.view.addSubview(loadingIndicator)
        
        self.setupTable()
        
        self.fetchAllTimelines()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Update the appearance of the navbar
        configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
    }
    
    func saveToDisk() {
        
    }
    
    @objc func fetchAllTimelines() {
        fetchTimelines1()
    }
    
    @objc func prevRefresh1() {
        Sound().playSound(named: "soundSuction", withVolume: 1)
        self.fetchTimelines1(true, nextBatch: false)
    }
    
    func fetchTimelines1(_ prevBatch: Bool = false, nextBatch: Bool = false) {
        var canLoad: Bool = true
        var id = "\((self.tempDetailUrl).split(separator: "/").last ?? "")"
        if self.tempDetailUrl == "" {
            id = self.id
        }
        var request2 = Statuses.favouritedBy(id: id)
        if type == 0 {
            if prevBatch {
                if let ra = self.statusesAllPrev {
                    request2 = Statuses.favouritedBy(id: id, range: ra)
                }
            }
            if nextBatch {
                if let ra = self.statusesAllNext {
                    request2 = Statuses.favouritedBy(id: id, range: ra)
                } else {
                    canLoad = false
                }
            }
        } else if type == 10 {
            request2 = Statuses.rebloggedBy(id: id)
            if prevBatch {
                if let ra = self.statusesAllPrev {
                    request2 = Statuses.rebloggedBy(id: id, range: ra)
                }
            }
            if nextBatch {
                if let ra = self.statusesAllNext {
                    request2 = Statuses.rebloggedBy(id: id, range: ra)
                } else {
                    canLoad = false
                }
            }
        } else if type == 1 {
            request2 = Mutes.all()
            if prevBatch {
                if let ra = self.statusesAllPrev {
                    request2 = Mutes.all(range: ra)
                }
            }
            if nextBatch {
                if let ra = self.statusesAllNext {
                    request2 = Mutes.all(range: ra)
                } else {
                    canLoad = false
                }
            }
        } else if type == 2 {
            request2 = Blocks.all()
            if prevBatch {
                if let ra = self.statusesAllPrev {
                    request2 = Blocks.all(range: ra)
                }
            }
            if nextBatch {
                if let ra = self.statusesAllNext {
                    request2 = Blocks.all(range: ra)
                } else {
                    canLoad = false
                }
            }
        } else if type == 3 {
            request2 = Accounts.allEndorsements()
        } else if type == 4 {
            request2 = FollowRequests.all()
            if prevBatch {
                if let ra = self.statusesAllPrev {
                    request2 = FollowRequests.all(range: ra)
                }
            }
            if nextBatch {
                if let ra = self.statusesAllNext {
                    request2 = FollowRequests.all(range: ra)
                } else {
                    canLoad = false
                }
            }
        } else if type == 5 {
            request2 = Lists.accounts(id: self.listID)
            if prevBatch {
                if let ra = self.statusesAllPrev {
                    request2 = Lists.accounts(id: self.listID, range: ra)
                }
            }
            if nextBatch {
                if let ra = self.statusesAllNext {
                    request2 = Lists.accounts(id: self.listID, range: ra)
                } else {
                    canLoad = false
                }
            }
        }
        if type == 6 {
            self.statusesAll = Array(GlobalStruct.topAccounts.reversed())
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.loadingIndicator.stopAnimating()
                self.tableView.reloadData()
            }
        } else {
            if canLoad {
                var testClient = self.client!
                if self.fromOtherCommunity || self.tempDetailUrl != "" {
                    let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken
                    testClient = Client(
                        baseURL: "https://\(self.otherInstance)",
                        accessToken: accessToken
                    )
                }
                testClient.run(request2) { (statuses) in
                    if self.type == 3 {
                        canLoad = false
                    }
                    self.statusesAllNext = statuses.pagination?.next
                    self.statusesAllPrev = statuses.pagination?.previous
                    if let error = statuses.error {
                        log.error("Failed to fetch timeline: \(error)")
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
                        if prevBatch {
                            self.statusesAll = stat + self.statusesAll
                            self.statusesAll = self.statusesAll.removingDuplicates()
                        } else if nextBatch {
                            self.statusesAll += stat
                        } else {
                            self.statusesAll = stat
                        }
                        DispatchQueue.main.async {
                            self.refreshControl.endRefreshing()
                            self.loadingIndicator.stopAnimating()
                            self.tableView.reloadData()
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }
    
    func setupTable() {
        self.emptyView.bounds.size.width = 80
        self.emptyView.bounds.size.height = 80
        self.emptyView.backgroundColor = UIColor.clear
        self.emptyView.image = UIImage(systemName: "sparkles", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular))?.withTintColor(UIColor.secondaryLabel.withAlphaComponent(0.18), renderingMode: .alwaysOriginal)
        self.emptyView.alpha = 0
        self.tableView.addSubview(self.emptyView)
        
        tableView.register(UserCell.self, forCellReuseIdentifier: "UserCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.layer.masksToBounds = true
        tableView.estimatedRowHeight = 89
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.refreshControl = self.refreshControl
        tableView.dragDelegate = self
        tableView.dragInteractionEnabled = true
        refreshControl.addTarget(self, action: #selector(self.prevRefresh1), for: .valueChanged)
        
        view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.statusesAll.count
    }
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let stat: Account? = self.statusesAll[indexPath.row]
        
        let string = "\(stat?.url ?? "")"
        guard let data = string.data(using: .utf8) else { return [] }
        let provider = NSItemProvider(item: data as NSData, typeIdentifier: kUTTypeURL as String)
        let item = UIDragItem(itemProvider: provider)
        item.localObject = string
        return [item]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserCell
        
        cell.userName.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        cell.userTag.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
        cell.bioText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        
        if indexPath.row < self.statusesAll.count {
            self.emptyView.alpha = 0
            let tmpData = self.statusesAll[indexPath.row]
            
            if let ur = URL(string: tmpData.avatar) {
                cell.profileIcon.sd_setImage(with: ur, for: .normal)
            }

            cell.profileIcon.tag = indexPath.row
            cell.profileIcon.addTarget(self, action: #selector(self.profileTap), for: .touchUpInside)
            //
            let interaction = UIContextMenuInteraction(delegate: self)
            cell.profileIcon.addInteraction(interaction)
            //
            cell.profileIcon.tag = indexPath.row
            
            cell.userName.text = tmpData.displayName
            cell.userTag.text = "@\(tmpData.acct)"
            cell.bioText.text = tmpData.note.stripHTML()
            if GlobalStruct.limitProfileLines {
                cell.bioText.text = (cell.bioText.text ?? "").replacingOccurrences(of: "\n", with: " ")
                cell.bioText.numberOfLines = 2
            }
            
            cell.bioText.mentionColor = .custom.baseTint
            cell.bioText.hashtagColor = .custom.baseTint
            cell.bioText.URLColor = .custom.baseTint
            cell.bioText.emailColor = .custom.baseTint
            
            if tmpData.locked == false {
                cell.lockedBadge.alpha = 0
                cell.lockedBackground.alpha = 0
            } else {
                let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: GlobalStruct.smallerFontSize, weight: .bold)
                cell.lockedBadge.image = UIImage(systemName: "lock.circle.fill", withConfiguration: symbolConfig0)?.withTintColor(UIColor.label, renderingMode: .alwaysOriginal)
                cell.lockedBadge.alpha = 1
                cell.lockedBackground.alpha = 1
                cell.lockedBackground.backgroundColor = .custom.backgroundTint
            }
            
            cell.setupConstraints(tmpData)
            
            // tap items
            cell.bioText.handleMentionTap { (str) in
triggerHapticImpact(style: .light)
                let note = tmpData.note
                let sliced = "~\(note.slice(from: "<a href=\"", to: "</span></a>") ?? "")~"
                let sliced2 = sliced.slice(from: "@<span>", to: "~") ?? ""
                if sliced2 == str {
                    let sliced3 = sliced.slice(from: "~", to: "\" class=") ?? ""
                    if let ur = URL(string: "\(sliced3)") {
                        PostActions.openLink(ur)
                    }
                }
            }
            cell.bioText.handleHashtagTap { (str) in
triggerHapticImpact(style: .light)
                let vc = NewsFeedViewController(viewModel: NewsFeedViewModel(.hashtag(Tag(name: str, url: ""))))
                if vc.isBeingPresented {} else {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
            cell.bioText.handleURLTap { (str) in
triggerHapticImpact(style: .light)
                PostActions.openLink(str)
            }
            cell.bioText.handleEmailTap { (str) in
                
            }
        }
        
        cell.separatorInset = .zero
        let bgColorView = UIView()
        bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
        cell.selectedBackgroundView = bgColorView
        cell.backgroundColor = .custom.backgroundTint
        
        if self.type == 6 {} else {
            var minusDiff: Int = 3
            if self.statusesAll.count < 4 {
                minusDiff = 1
            }
            if indexPath.row == self.statusesAll.count - minusDiff {
                self.fetchTimelines1(false, nextBatch: true)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if self.type == 4 {
            let alert = UIAlertController(title: "Accept or reject the follow request from \(self.statusesAll[indexPath.row].displayName)?", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Accept", style: .default , handler:{ (UIAlertAction) in
                let request = FollowRequests.authorize(id: self.statusesAll[indexPath.row].id)
                self.client!.run(request) { (statuses) in
                    DispatchQueue.main.async {
                        self.statusesAll = self.statusesAll.filter({ x in
                            x.id != self.statusesAll[indexPath.row].id
                        })
                        self.tableView.reloadData()
                        triggerHapticNotification()
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Reject", style: .destructive , handler:{ (UIAlertAction) in
                let request = FollowRequests.reject(id: self.statusesAll[indexPath.row].id)
                self.client!.run(request) { (statuses) in
                    DispatchQueue.main.async {
                        self.statusesAll = self.statusesAll.filter({ x in
                            x.id != self.statusesAll[indexPath.row].id
                        })
                        self.tableView.reloadData()
                        triggerHapticNotification()
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler:{ (UIAlertAction) in
                
            }))
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = getTopMostViewController()?.view
                presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
            }
            getTopMostViewController()?.present(alert, animated: true, completion: nil)
        } else {
            let stat: Account? = self.statusesAll[indexPath.row]
            if let account = stat {
                let vc = ProfileViewController(user: UserCardModel(account: account), screenType: .others)
                if vc.isBeingPresented {} else {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        var acc: Account? = nil
        acc = self.statusesAll[interaction.view?.tag ?? 0]
        if acc?.id ?? "" == self.currentUserID ?? "" {
            return nil
        } else {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: {
                suggestedActions in
                return self.makeContextProfileMain(interaction.view?.tag ?? 0)
            })
        }
    }
    
    func makeContextProfileMain(_ index: Int) -> UIMenu {
        var acc: Account? = nil
        acc = self.statusesAll[index]
        let op0 = UIAction(title: NSLocalizedString("profile.mention", comment: ""), image: UIImage(systemName: "at"), identifier: nil) { action in
            let vc = NewPostViewController()
            vc.isModalInPresentation = true
            vc.fromPro = true
            vc.proText = "@\(acc?.acct ?? "") "
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
        let op00 = UIAction(title: "Message", image: UIImage(systemName: "tray.full"), identifier: nil) { action in
            let vc = NewPostViewController()
            vc.isModalInPresentation = true
            vc.fromPro = true
            vc.proText = "@\(acc?.acct ?? "") "
            vc.whoCanReply = .direct
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
        let mentionMenu = UIMenu(title: "", options: [.displayInline], children: [op0, op00])
        if #available(iOS 16.0, *) {
            mentionMenu.preferredElementSize = .medium
        }
        
        let op000 = UIAction(title: "Recent Media", image: UIImage(systemName: "photo.on.rectangle"), identifier: nil) { action in
            let vc = GalleryViewController()
            vc.otherUserId = acc?.id ?? ""
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        var opVIP = UIAction(title: "Add to Top Friends", image: UIImage(systemName: "star"), identifier: nil) { action in
            if GlobalStruct.displayingVIPLists == 0 {
                let userInfoDict = (acc == nil) ? nil : ["Account": acc!]
                NotificationCenter.default.post(name: Notification.Name(rawValue: "createVIPListPrompt"), object: nil, userInfo: userInfoDict)
            } else {
                let request2 = Lists.add(accountIDs: [acc?.id ?? ""], toList: GlobalStruct.VIPListID)
                self.client!.run(request2) { (statuses) in
                    if let error = statuses.error {
                        log.error("Failed to add to list: \(error)")
                        DispatchQueue.main.async {
                            if GlobalStruct.accountIDsToFollow.contains(acc?.id ?? "") {
                                if let account = acc {
                                    let userInfoDict = ["Account": account]
                                    NotificationCenter.default.post(name: Notification.Name(rawValue: "addToTopFriends"), object: nil, userInfo: userInfoDict)
                                }
                            } else {
                                let userInfoDict = (acc == nil) ? nil : ["Account": acc!]
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "followAndAddToTopFriends"), object: nil, userInfo:  userInfoDict)
                            }
                        }
                    }
                    if let _ = (statuses.value) {
                        DispatchQueue.main.async {
                            // added
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "postVIP"), object: nil)
                            print("added users to new VIP list")
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadThisExplore"), object: nil)
                            if let x = acc {
                                GlobalStruct.topAccounts.append(x)
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchAllTimelinesLikedBy"), object: nil)
                                if let x = self.currentUserID {
                                    do {
                                        try Disk.save(GlobalStruct.topAccounts, to: .documents, as: "\(x)/topAccounts2.json")
                                    } catch {
                                        log.error("error saving top accounts to Disk")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if GlobalStruct.topAccounts.contains(where: { x in
            x.id == acc?.id ?? ""
        }) {
            opVIP = UIAction(title: "Remove from Top Friends", image: UIImage(systemName: "star.slash"), identifier: nil) { action in
                let request2 = Lists.remove(accountIDs: [acc?.id ?? ""], fromList: GlobalStruct.VIPListID)
                self.client!.run(request2) { (statuses) in
                    if let _ = (statuses.value) {
                        DispatchQueue.main.async {
                            // added
                            print("removed users from VIP list")
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadThisExplore"), object: nil)
                            if let x = acc {
                                GlobalStruct.topAccounts = GlobalStruct.topAccounts.filter({ y in
                                    y != x
                                })
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchAllTimelinesLikedBy"), object: nil)
                                if let x = self.currentUserID {
                                    do {
                                        try Disk.save(GlobalStruct.topAccounts, to: .documents, as: "\(x)/topAccounts2.json")
                                    } catch {
                                        log.error("error saving top accounts to Disk")
                                    }
                                }
                            }
                        }
                    }
                }
                NotificationCenter.default.post(name: Notification.Name(rawValue: "postUnVIP"), object: nil)
            }
        }
        if GlobalStruct.displayingVIPLists == 2 {
            opVIP.attributes = .hidden
        }
        
        var listAct1: [UIAction] = []
        for x in ListManager.shared.allLists(includeTopFriends: false) {
            let op1 = UIAction(title: x.title, image: UIImage(systemName: "list.bullet"), identifier: nil) { action in
                ListManager.shared.addToList(accountID: acc?.id ?? "", listID: x.id) { success in
                    if !success {
                        log.error("Failed to add to list")
                        DispatchQueue.main.async {
                            let userInfoDict = (acc == nil) ? nil : ["Account": acc!, "List": x.id]
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "followAndAddToTopFriends"), object: nil, userInfo:  userInfoDict)
                        }
                    } else {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "postVIP"), object: nil)
                            triggerHapticNotification()
                        }
                    }
                }
            }
            listAct1.append(op1)
        }
        let list1 = UIMenu(title: "Add to List", image: UIImage(systemName: "plus"), options: [], children: listAct1)
        var listAct2: [UIAction] = []
        for x in ListManager.shared.allLists(includeTopFriends: false) {
            let op1 = UIAction(title: x.title, image: UIImage(systemName: "list.bullet"), identifier: nil) { action in
                NotificationCenter.default.post(name: Notification.Name(rawValue: "postUnVIP"), object: nil)
                ListManager.shared.removeFromList(accountID: acc?.id ?? "", listID: x.id) { success in
                    if success {
                        DispatchQueue.main.async {
                            triggerHapticNotification()
                        }
                    }
                }
            }
            listAct2.append(op1)
        }
        let list2 = UIMenu(title: "Remove from List", image: UIImage(systemName: "minus"), options: [], children: listAct2)
        let op3 = UIMenu(title: "Manage Lists", image: UIImage(systemName: "list.bullet"), options: [], children: [list1, list2])
        
        let trans = UIAction(title: "Translate Bio", image: UIImage(systemName: "globe"), identifier: nil) {_ in
            PostActions.translateString(acc?.note.stripHTML() ?? "")
        }
        
        let share = UIAction(title: "Share Profile", image: FontAwesome.image(fromChar: "\u{e09a}"), identifier: nil) { action in
            let text = URL(string: "\(acc?.url ?? "")")!
            let textToShare = [text]
            let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true, completion: nil)
        }
        let shareMenu = UIMenu(title: "", options: [.displayInline], children: [share])
        
        return UIMenu(title: "", options: [], children: [mentionMenu, op000, opVIP, op3, trans, shareMenu])
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if self.type == 1 {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: {
                suggestedActions in
                return self.makeContext(indexPath.row, type: 1)
            })
        } else if self.type == 2 {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: {
                suggestedActions in
                return self.makeContext(indexPath.row, type: 2)
            })
        } else if self.type == 4 {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: {
                suggestedActions in
                return self.makeContext(indexPath.row, type: 4)
            })
        } else {
            return nil
        }
    }
    
    func makeContext(_ index: Int, type: Int) -> UIMenu {
        var op1: UIAction? = nil
        if type == 1 {
            op1 = UIAction(title: "Unmute @\(self.statusesAll[index].username)", image: UIImage(systemName: "speaker"), identifier: nil) { action in
                let request = Accounts.unmute(id: self.statusesAll[index].id)
                self.client!.run(request) { (statuses) in
                    DispatchQueue.main.async {
                        self.statusesAll = self.statusesAll.filter({ x in
                            x.id != self.statusesAll[index].id
                        })
                        self.tableView.reloadData()
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "postUnmuted"), object: nil)
                        triggerHapticNotification()
                    }
                }
            }
        }
        if type == 2 {
            op1 = UIAction(title: "Unblock @\(self.statusesAll[index].username)", image: UIImage(systemName: "hand.raised"), identifier: nil) { action in
                let request = Accounts.unblock(id: self.statusesAll[index].id)
                self.client!.run(request) { (statuses) in
                    DispatchQueue.main.async {
                        let id = self.statusesAll[index].id
                        self.statusesAll = self.statusesAll.filter({ x in
                            x.id != id
                        })
                        GlobalStruct.blockedUsers = GlobalStruct.blockedUsers.filter({ x in
                            x != id
                        })
                        do {
                            try Disk.save(GlobalStruct.blockedUsers, to: .documents, as: "blockedUsers.json")
                        } catch {
                            log.warning("error saving blocked users to Disk - \(error)")
                        }
                        self.tableView.reloadData()
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "postUnblocked"), object: nil)
                        triggerHapticNotification()
                    }
                }
            }
        }
        if type == 4 {
            op1 = UIAction(title: "Accept", image: UIImage(systemName: "checkmark"), identifier: nil) { action in
                let request = FollowRequests.authorize(id: self.statusesAll[index].id)
                self.client!.run(request) { (statuses) in
                    DispatchQueue.main.async {
                        self.statusesAll = self.statusesAll.filter({ x in
                            x.id != self.statusesAll[index].id
                        })
                        self.tableView.reloadData()
                        triggerHapticNotification()
                    }
                }
            }
            let op2 = UIAction(title: "Reject", image: UIImage(systemName: "xmark"), identifier: nil) { action in
                let request = FollowRequests.reject(id: self.statusesAll[index].id)
                self.client!.run(request) { (statuses) in
                    DispatchQueue.main.async {
                        self.statusesAll = self.statusesAll.filter({ x in
                            x.id != self.statusesAll[index].id
                        })
                        self.tableView.reloadData()
                        triggerHapticNotification()
                    }
                }
            }
            op2.attributes = .destructive
            if let op = op1 {
                return UIMenu(title: "", options: [], children: [op, op2])
            } else {
                return UIMenu(title: "", options: [], children: [])
            }
        }
        if let op = op1 {
            return UIMenu(title: "", options: [], children: [op])
        } else {
            return UIMenu(title: "", options: [], children: [])
        }
    }
    
    @objc func profileTap(_ sender: UIButton) {
        triggerHapticImpact(style: .light)
        // tap user profile pics
        let stat: Account? = self.statusesAll[sender.tag]
        // default profile pics
        if let account = stat {
            let vc = ProfileViewController(user: UserCardModel(account: account), screenType: .others)
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if self.type == 6 {
            return true
        } else {
            return false
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let alert = UIAlertController(title: nil, message: "Are you sure you want to remove this account?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Remove", style: .destructive , handler:{ (UIAlertAction) in
                triggerHapticNotification()
                let request2 = Lists.remove(accountIDs: [self.statusesAll[indexPath.row].id], fromList: GlobalStruct.VIPListID)
                self.client!.run(request2) { (statuses) in
                    if let _ = (statuses.value) {
                        DispatchQueue.main.async {
                            // added
                            print("removed users from VIP list")
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadThisExplore"), object: nil)
                            self.statusesAll = self.statusesAll.filter({ x in
                                x.id != self.statusesAll[indexPath.row].id
                            })
                            self.tableView.reloadData()
                        }
                    }
                }
                NotificationCenter.default.post(name: Notification.Name(rawValue: "postUnVIP"), object: nil)
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
