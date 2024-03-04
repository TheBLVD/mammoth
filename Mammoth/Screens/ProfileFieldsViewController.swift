//
//  ProfileFieldsViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 14/11/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class ProfileFieldsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var fields: [HashType] = []
    var account: Account? = nil
    var tableView = UITableView()
    var items: [String] = ["", ""]
    var keyHeight: CGFloat = 0
    var canPost: Bool = true
    var allTags: [Tag] = []
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateToolbar"), object: nil)
    }
    
    override var keyCommands: [UIKeyCommand]? {
        let closeWindow = UIKeyCommand(input: "w", modifierFlags: [.command], action: #selector(dismissTap))
        closeWindow.discoverabilityTitle = NSLocalizedString("generic.dismiss", comment: "")
        if #available(iOS 15, *) {
            closeWindow.wantsPriorityOverSystemBehavior = true
        }
        return [closeWindow]
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
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .custom.backgroundTint
        
        self.navigationItem.title = "Info and Links"
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        
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
        
        // set up table
        setupTable()
        
        if account?.id ?? "" == AccountsManager.shared.currentUser()?.id ?? "" {
            self.fetchFollowingTags()
        }
    }
    
    func fetchFollowingTags() {
        let request = TrendingTags.followedTags()
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let error = statuses.error {
                log.error("error getting hashtags: \(error)")
            }
            if let stat = (statuses.value) {
                DispatchQueue.main.async {
                    self.allTags = stat
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell2 {
            cell1.pollItem.becomeFirstResponder()
        }
    }
    
    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        self.dismiss(animated: true, completion: nil)
    }
    
    func setupTable() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(ProfileFieldsCell.self, forCellReuseIdentifier: "ProfileFieldsCell")
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
        return fields.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileFieldsCell", for: indexPath) as! ProfileFieldsCell
        
        cell.title.urlMaximumLength = 200
        
        cell.title.text = fields[indexPath.section].value.stripHTML()
        cell.title.isUserInteractionEnabled = false
        
        // tap items
        cell.title.handleMentionTap { (str) in
            
        }
        cell.title.handleHashtagTap { (str) in
            triggerHapticImpact(style: .light)
            let vc = NewsFeedViewController(viewModel: NewsFeedViewModel(.hashtag(Tag(name: str, url: ""))))
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        cell.title.handleURLTap { (str) in
            triggerHapticImpact(style: .light)
            PostActions.openLink(str)
        }
        cell.title.handleEmailTap { (str) in
            
        }
        
        if let _ = self.fields[indexPath.section].verifiedAt {
            cell.layer.borderColor = UIColor.systemGreen.cgColor
            cell.layer.borderWidth = 2
            cell.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
        } else {
            cell.layer.borderColor = UIColor.clear.cgColor
            cell.layer.borderWidth = 0
            cell.backgroundColor = .custom.quoteTint
        }
        
        cell.separatorInset = .zero
        let bgColorView = UIView()
        bgColorView.backgroundColor = .clear
        cell.selectedBackgroundView = bgColorView
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if fields[indexPath.section].value.stripHTML().contains("http") {
            if let str = URL(string: fields[indexPath.section].value.stripHTML()) {
triggerHapticImpact(style: .light)
                PostActions.openLink(str)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 52
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section <= 4 else {
            return nil
        }
        let bg = UIView()
        bg.frame = CGRect(x: 0, y: 6, width: self.view.bounds.width, height: 40)
        let lab = UILabel()
        lab.frame = bg.frame
        
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        let fullString = NSMutableAttributedString(string: "")
        let image1Attachment = NSTextAttachment()
        image1Attachment.image = UIImage(systemName: "quote.bubble.fill", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysTemplate)
        let image1String = NSAttributedString(attachment: image1Attachment)
        fullString.append(image1String)
        fullString.append(NSAttributedString(string: "  \(fields[section].name.stripHTML())"))
        lab.attributedText = fullString
        
        lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        lab.textColor = UIColor.label
        bg.addSubview(lab)
        lab.translatesAutoresizingMaskIntoConstraints = false
        lab.addFillConstraints(with:bg)
        return bg
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section <= 4 else {
            return nil
        }
        if let ver = self.fields[section].verifiedAt {
            return "Verified on \(ver.toDate().toString(dateStyle: .short, timeStyle: .short))"
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}

