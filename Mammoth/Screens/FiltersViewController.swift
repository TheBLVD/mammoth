//
//  FiltersViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 03/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class FiltersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var showingSearch: Bool = true
    let btn1 = UIButton(type: .custom)
    let btn2 = UIButton(type: .custom)
    let emptyView = UIImageView()
    var tableView = UITableView()
    var allFilters: [Filters] = []
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        tableView.tableHeaderView?.frame.size.height = 60
        self.emptyView.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 30)
    }
    
    var tempScrollPosition: CGFloat = 0
    @objc func scrollToTop() {
        if !self.allFilters.isEmpty {
            // scroll to top
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            self.tempScrollPosition = self.tableView.contentOffset.y
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
            for cell in self.tableView.visibleCells {
                if let cell = cell as? TrendsFeedCell {
                    cell.titleLabel.textColor = .custom.mainTextColor
                    cell.backgroundColor = .custom.quoteTint
                    
                    cell.titleLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
                    cell.bio.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize + GlobalStruct.customTextSize, weight: .regular)
                }
                if let cell = cell as? TrendsCell {
                    cell.titleLabel.textColor = .custom.mainTextColor
                    cell.backgroundColor = .custom.quoteTint
                    
                    cell.titleLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
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
    
    @objc func reloadThis() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .custom.backgroundTint
        self.navigationItem.title = NSLocalizedString("profile.filters", comment: "")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadThis), name: NSNotification.Name(rawValue: "reloadThis"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadBars), name: NSNotification.Name(rawValue: "reloadBars"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchFilters), name: NSNotification.Name(rawValue: "fetchFilters"), object: nil)
        
        // set up nav
        setupNav()
        
        setupTable()
        
        // fetch data
        self.fetchFilters()
    }
    
    func setupNav() {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        btn2.setImage(UIImage(systemName: "plus", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysTemplate), for: .normal)
        btn2.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btn2.addTarget(self, action: #selector(self.newFilter), for: .touchUpInside)
        btn2.accessibilityLabel = NSLocalizedString("filters.new", comment: "")
        let moreButton3 = UIBarButtonItem(customView: btn2)
        self.navigationItem.setRightBarButtonItems([moreButton3], animated: true)
    }
    
    @objc func newFilter() {
        triggerHapticImpact(style: .light)
        let vc = FilterDetailsViewController()
        vc.showingSearch = false
        vc.isShowingXmark = true
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    func setupTable() {
        self.emptyView.bounds.size.width = 80
        self.emptyView.bounds.size.height = 80
        self.emptyView.backgroundColor = UIColor.clear
        self.emptyView.image = UIImage(systemName: "sparkles", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular))?.withTintColor(UIColor.secondaryLabel.withAlphaComponent(0.18), renderingMode: .alwaysOriginal)
        self.emptyView.alpha = 0
        self.tableView.addSubview(self.emptyView)
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.register(TrendsFeedCell.self, forCellReuseIdentifier: "TrendsFeedCell")
        tableView.register(TrendsCell.self, forCellReuseIdentifier: "TrendsCell")
        tableView.register(TrendsTopCell.self, forCellReuseIdentifier: "TrendsTopCell")
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

    @objc func fetchFilters() {
        let request0 = FilterPosts.all()
        AccountsManager.shared.currentAccountClient.run(request0) { (statuses) in
            if let error = statuses.error {
                log.error("Failed to fetch filters: \(error)")
                DispatchQueue.main.async {
                    if self.allFilters.isEmpty {
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
                    self.allFilters = stat
                    self.tableView.reloadData()
                    self.saveToDisk()
                    
                    if let filt = stat.first(where: { f in
                        f.id == GlobalStruct.currentFilterId
                    }) {
                        GlobalStruct.currentFilter = filt
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchFilterAgain"), object: nil)
                    }
                }
            }
        }
    }
    
    func saveToDisk() {
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.allFilters.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrendsCell", for: indexPath) as! TrendsCell
        var keyW: String = ""
        for (c,x) in self.allFilters[indexPath.row].keywords.enumerated() {
            let aa = x.keyword.lowercased()
            if c == 0 {
                keyW = "\(aa)"
            } else {
                keyW = "\(keyW), \(aa)"
            }
        }
        var filt: String = ""
        for (c,x) in self.allFilters[indexPath.row].context.enumerated() {
            let aa = x.capitalized.replacingOccurrences(of: "Home", with: NSLocalizedString("filters.extras.homeAndLists", comment: "")).replacingOccurrences(of: "Public", with: "Public Timelines").replacingOccurrences(of: "Thread", with: NSLocalizedString("filters.extras.conversations", comment: "")).replacingOccurrences(of: "Account", with: NSLocalizedString("filters.extras.profiles", comment: ""))
            if c == 0 {
                filt = "\(aa)"
            } else if c == self.allFilters[indexPath.row].context.count - 1 {
                filt = "\(filt), and \(aa)"
            } else {
                filt = "\(filt), \(aa)"
            }
        }
        if keyW == "" {
            keyW = "Not filtering any keywords\n\(filt)"
        } else {
            keyW = "Filtering: \(keyW)\n\(filt)"
        }
        cell.configure(self.allFilters[indexPath.row].title, titleLabel2: "\(keyW)")
        cell.separatorInset = .zero
        let bgColorView = UIView()
        bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
        cell.selectedBackgroundView = bgColorView
        cell.backgroundColor = .custom.backgroundTint
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        GlobalStruct.currentFilterId = self.allFilters[indexPath.row].id
        let vc = FilterDetailsViewController()
        vc.showingSearch = false
        vc.filter = self.allFilters[indexPath.row]
        if vc.isBeingPresented {} else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { nil }, actionProvider: { suggestedActions in
            return self.makeContextMenu(indexPath.row)
        })
    }
    
    func makeContextMenu(_ index: Int) -> UIMenu {
        let op1 = UIAction(title: "Delete Filter", image: UIImage(systemName: "trash"), identifier: nil) { action in
            let alert = UIAlertController(title: nil, message: "Are you sure you want to delete this filter?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive , handler:{ (UIAlertAction) in
                let request = FilterPosts.delete(id: self.allFilters[index].id)
                AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
                    if let _ = (statuses.value) {
                        DispatchQueue.main.async {
                            print("deleted filter")
                            triggerHapticNotification()
                            self.fetchFilters()
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
        }
        op1.accessibilityLabel = "Delete Filter"
        op1.attributes = .destructive
        return UIMenu(title: "", options: [], children: [op1])
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
            let alert = UIAlertController(title: nil, message: "Are you sure you want to delete this filter?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive , handler:{ (UIAlertAction) in
                let request = FilterPosts.delete(id: self.allFilters[indexPath.row].id)
                AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
                    if let _ = (statuses.value) {
                        DispatchQueue.main.async {
                            print("deleted filter")
                            triggerHapticNotification()
                            self.fetchFilters()
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
        }
    }
    
}

extension FiltersViewController: JumpToNewest {
    @objc func jumpToNewest() {
        self.scrollToTop()
        self.fetchFilters()
    }
}
