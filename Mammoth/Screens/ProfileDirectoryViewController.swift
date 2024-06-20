//
//  ProfileDirectoryViewController.swift
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

// swiftlint:disable:next type_body_length
class ProfileDirectoryViewController: LiveTableViewController, UITableViewDataSource, UIContextMenuInteractionDelegate, UITableViewDragDelegate {
    
    var currentUserID: String? = nil
    var client: Client? = nil
    let loadingIndicator = UIActivityIndicatorView()
    var tableView = UITableView()
    let refreshControl = UIRefreshControl()
    var currentSegment: Int = 0
    var fromSuggestions: Bool = false
    var id: String = ""
    var nBounds: CGRect = CGRect.zero
    var nBar: UINavigationBar = UINavigationBar()
    var statusesAll: [Account] = []
    var statusesAllNext: RequestRange? = nil
    var statusesAllPrev: RequestRange? = nil
    
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
    
    // LiveTableViewController
    override func dataForLiveTableView(_ table: UITableView) -> [AnyObject] {
        return statusesAll
    }

    override func performActionForVisibleCells(table: UITableView, dataArray: [AnyObject]) {
        ProfileCacher.shared.performActionForVisibleCells(table: table, dataArray: dataArray)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileCell {
            cell.profileIcon.layer.borderColor = UIColor.custom.baseTint.cgColor
        }
        tableView.tableHeaderView?.frame.size.height = 60
        
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
        if self.fromSuggestions {
            self.navigationItem.title = "Follow Suggestions"
        } else {
            self.navigationItem.title = "Profile Directory"
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        
        loadingIndicator.startAnimating()
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.center = self.view.center
        self.view.addSubview(loadingIndicator)
        
        self.setupNav()
        self.setupTable()
        
        self.fetchAllTimelines()
    }
    
    func saveToDisk() {
        
    }
    
    func setupNav() {
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
        
        if let navBar = self.navigationController?.navigationBar {
            self.nBounds = navBar.bounds
            self.nBar = navBar
        }
    }
    
    func fetchAllTimelines() {
        fetchTimelines1()
    }
    
    @objc func prevRefresh1() {
        Sound().playSound(named: "soundSuction", withVolume: 1)
        self.fetchTimelines1(true, nextBatch: false)
    }
    
    func fetchTimelines1(_ prevBatch: Bool = false, nextBatch: Bool = false) {
        // moth.social user recommendations API
        if self.fromSuggestions {
            let request3 = Accounts.followRecommendations(self.currentUserID ?? "")
            self.client!.run(request3) { (statuses) in
                if let error = statuses.error {
                    log.error("Failed to fetch follow recommendations: \(error)")
                    DispatchQueue.main.async {
                        log.error("error fetching moth.social recommendations, fetch default suggestions instead")
                        let request2 = Accounts.followSuggestions()
                        self.client!.run(request2) { (statuses) in
                            if let stat = (statuses.value) {
                                self.statusesAll = stat
                                DispatchQueue.main.async {
                                    self.refreshControl.endRefreshing()
                                    self.loadingIndicator.stopAnimating()
                                    self.tableView.reloadData()
                                }
                            }
                        }
                    }
                }
                if let stat = (statuses.value) {
                    DispatchQueue.main.async {
                        self.statusesAll = stat
                        self.refreshControl.endRefreshing()
                        self.loadingIndicator.stopAnimating()
                        self.tableView.reloadData()
                    }
                }
            }
        } else {
            var canLoad: Bool = true
            var request2 = ProfileDirectory.all()
            if prevBatch {
                if let ra = self.statusesAllPrev {
                    request2 = ProfileDirectory.all(range: ra)
                }
            }
            if nextBatch {
                if let ra = self.statusesAllNext {
                    request2 = ProfileDirectory.all(range: ra)
                } else {
                    canLoad = false
                }
            }
            if canLoad {
                self.client!.run(request2) { (statuses) in
                    self.statusesAllNext = statuses.pagination?.next
                    self.statusesAllPrev = statuses.pagination?.previous
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
        tableView.register(UserCell.self, forCellReuseIdentifier: "UserCell")
        tableView.alpha = 1
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.layer.masksToBounds = true
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
        
        cell.separatorInset = .zero
        let bgColorView = UIView()
        bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
        cell.selectedBackgroundView = bgColorView
        cell.backgroundColor = .custom.backgroundTint
        
        if self.fromSuggestions {} else {
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
        let stat: Account? = self.statusesAll[indexPath.row]
        if let account = stat {
            let vc = ProfileViewController(user: UserCardModel(account: account), screenType: .others)
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
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
    
    @objc func profileTap(_ sender: UIButton) {
        triggerHapticImpact(style: .light)
        // tap user profile pics
        var stat: Account? = nil
        if sender.tag < self.statusesAll.count {
            stat = self.statusesAll[sender.tag]
        }
        // default profile pics
        if let account = stat {
            let vc = ProfileViewController(user: UserCardModel(account: account), screenType: .others)
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
}
