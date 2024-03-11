//
//  FilterDetailsViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 03/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class FilterDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var showingSearch: Bool = true
    var isShowingXmark: Bool = false
    let btn1 = UIButton(type: .custom)
    let btn2 = UIButton(type: .custom)
    var tableView = UITableView()
    var filter: Filters? = nil
    var durationMin: Int = 0
    var hideCompletely: Bool = false
    var context1: Bool = true
    var context2: Bool = false
    var context3: Bool = false
    var context4: Bool = false
    var context5: Bool = false
    var hasBeenCreated: Bool = false
    var toDeleteId: String = ""
    var fromAddKeyword: Bool = false
    var cells: [IndexPath: UITableViewCell] = [:]
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)        
        if let _ = self.filter {
            
        } else {
            if let cell = self.cells[IndexPath(row: 0, section: 0)] as? AltTextCell {
                cell.altText.becomeFirstResponder()
            }
            
            let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
            self.btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
            self.btn2.backgroundColor = UIColor.label.withAlphaComponent(0.08)
            self.btn2.layer.cornerRadius = 14
            self.btn2.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            self.btn2.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
            self.btn2.addTarget(self, action: #selector(self.addTap), for: .touchUpInside)
            self.btn2.accessibilityLabel = "Add Filter"
            let moreButton1 = UIBarButtonItem(customView: self.btn2)
            self.navigationItem.setRightBarButton(moreButton1, animated: true)
        }
    }
    
    @objc func addTap() {
        if self.hasBeenCreated {
            triggerHapticNotification()
            self.dismiss(animated: true)
        } else {
            self.createNew(true)
        }
    }
    
    func createNew(_ canDismiss: Bool = false) {
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextCell {
            var con: [String] = []
            if self.context1 {
                con.append("home")
            }
            if self.context2 {
                con.append("notifications")
            }
            if self.context3 {
                con.append("public")
            }
            if self.context4 {
                con.append("thread")
            }
            if self.context5 {
                con.append("account")
            }
            var filt = "warn"
            if self.hideCompletely {
                filt = "hide"
            }
            var exp: String? = nil
            if self.durationMin == 100 {
                exp = self.filter?.expiresAt ?? ""
            }
            if self.durationMin == 30 {
                exp = Date().adding(minutes: 30).iso8601String
            }
            if self.durationMin == 60 {
                exp = Date().adding(minutes: 60).iso8601String
            }
            if self.durationMin == 360 {
                exp = Date().adding(minutes: 360).iso8601String
            }
            if self.durationMin == 720 {
                exp = Date().adding(minutes: 720).iso8601String
            }
            if self.durationMin == 1440 {
                exp = Date().adding(minutes: 1440).iso8601String
            }
            if self.durationMin == 1440 * 7 {
                exp = Date().adding(minutes: 1440 * 7).iso8601String
            }
            let request = FilterPosts.create(title: cell.altText.text ?? "", context: con, filterAction: filt, expiresAt: exp ?? nil)
            AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
                if let stat = (statuses.value) {
                    DispatchQueue.main.async {
                        print("created filter\n\(stat)")
                        self.filter = stat
                        GlobalStruct.currentFilterId = self.filter?.id ?? ""
                        if self.fromAddKeyword {
                            self.fromAddKeyword = false
                            let vc = AltTextViewController()
                            vc.newFilter = true
                            vc.filterId = self.filter?.id ?? ""
                            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
                        }
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchFilters"), object: nil)
                        if canDismiss {
                            triggerHapticNotification()
                            self.dismiss(animated: true)
                        } else {
                            self.toDeleteId = stat.id
                            self.hasBeenCreated = true
                            let vc = AltTextViewController()
                            vc.newFilter = true
                            vc.filterId = self.toDeleteId
                            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    func editExisting() {
        if let cell = self.cells[IndexPath(row: 0, section: 0)] as? AltTextCell {
            var con: [String] = []
            if self.context1 {
                con.append("home")
            }
            if self.context2 {
                con.append("notifications")
            }
            if self.context3 {
                con.append("public")
            }
            if self.context4 {
                con.append("thread")
            }
            if self.context5 {
                con.append("account")
            }
            var filt = "warn"
            if self.hideCompletely {
                filt = "hide"
            }
            var exp: Int64? = nil
            if self.durationMin == 100 {
                exp = Date().adding(minutes: 100).since(Date(), in: .second)
            }
            if self.durationMin == 30 {
                exp = Date().adding(minutes: 30).since(Date(), in: .second)
            }
            if self.durationMin == 60 {
                exp = Date().adding(minutes: 60).since(Date(), in: .second)
            }
            if self.durationMin == 360 {
                exp = Date().adding(minutes: 360).since(Date(), in: .second)
            }
            if self.durationMin == 720 {
                exp = Date().adding(minutes: 720).since(Date(), in: .second)
            }
            if self.durationMin == 1440 {
                exp = Date().adding(minutes: 1440).since(Date(), in: .second)
            }
            if self.durationMin == 1440 * 7 {
                exp = Date().adding(minutes: 1440 * 7).since(Date(), in: .second)
            }
            
            let request = FilterPosts.update(id: self.filter?.id ?? "", title: cell.altText.text ?? "", context: con, filterAction: filt, expiresAt: exp ?? nil)
            AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
                if let stat = (statuses.value) {
                    DispatchQueue.main.async {
                        print("edited filter\n\(stat)")
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchFilters"), object: nil)
                    }
                }
                if let error = (statuses.error) {
                    log.error("errediting - \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let cell1 = self.cells[IndexPath(row: 0, section: 0)] as? AltTextCell {
            let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
            if cell1.altText.text != "" {
                self.btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(.custom.activeInverted, renderingMode: .alwaysOriginal), for: .normal)
                btn2.backgroundColor = .custom.active
            } else {
                self.btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
                btn2.backgroundColor = UIColor.label.withAlphaComponent(0.08)
            }
            self.editThis()
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.editThis()
        textField.resignFirstResponder()
        return true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextCell {
            cell.altText.resignFirstResponder()
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
    
    @objc func fetchFilterAgain() {
        DispatchQueue.main.async {
            self.filter = GlobalStruct.currentFilter
            UIView.setAnimationsEnabled(false)
            self.tableView.reloadSections(IndexSet(1...3), with: .none)
            UIView.setAnimationsEnabled(true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .custom.backgroundTint
        if let _ = self.filter {
            self.navigationItem.title = "Filter Detail"
        } else {
            self.navigationItem.title = NSLocalizedString("filters.new", comment: "")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadThis), name: NSNotification.Name(rawValue: "reloadThis"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadBars), name: NSNotification.Name(rawValue: "reloadBars"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchFilterAgain), name: NSNotification.Name(rawValue: "fetchFilterAgain"), object: nil)
        
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
        
        // set up nav
        setupNav()
        
        // set up table
        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }
        
        if let filter = self.filter {
            if filter.context.contains("home") {
                self.context1 = true
            } else {
                self.context1 = false
            }
            if filter.context.contains("notifications") {
                self.context2 = true
            } else {
                self.context2 = false
            }
            if filter.context.contains("public") {
                self.context3 = true
            } else {
                self.context3 = false
            }
            if filter.context.contains("thread") {
                self.context4 = true
            } else {
                self.context4 = false
            }
            if filter.context.contains("account") {
                self.context5 = true
            } else {
                self.context5 = false
            }
            
            if filter.filterAction == "warn" {
                self.hideCompletely = false
            } else {
                self.hideCompletely = true
            }
            
            self.durationMin = 100
        }
        
        setupTable()
    }
    
    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        if self.hasBeenCreated {
            let request = FilterPosts.delete(id: self.toDeleteId)
            AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
                if let _ = (statuses.value) {
                    DispatchQueue.main.async {
                        print("deleted filter")
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchFilters"), object: nil)
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func setupNav() {
        let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        btn1.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
        btn1.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        btn1.layer.cornerRadius = 14
        btn1.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        btn1.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        btn1.addTarget(self, action: #selector(self.dismissTap), for: .touchUpInside)
        btn1.accessibilityLabel = NSLocalizedString("generic.dismiss", comment: "")
        let moreButton0 = UIBarButtonItem(customView: btn1)
        if self.isShowingXmark {
            self.navigationItem.setLeftBarButton(moreButton0, animated: true)
        }
    }
    
    func setupTable() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(AltTextCell.self, forCellReuseIdentifier: "AltTextCell")
        tableView.register(SelectionCell.self, forCellReuseIdentifier: "SelectionCell")
        tableView.register(TrendsCell.self, forCellReuseIdentifier: "TrendsCellList1")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCellK")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell1")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell2")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell3")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell4")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell5")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
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

    func saveToDisk() {
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return (self.filter?.keywords.count ?? 0) + 1
        } else if section == 3 {
            return 6
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 52
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let bg = UIView()
            bg.frame = CGRect(x: 0, y: 6, width: self.view.bounds.width, height: 40)
            let lab = UILabel()
            lab.frame = bg.frame
            
            let fullString = NSMutableAttributedString(string: "")
            fullString.append(NSAttributedString(string: "  " + NSLocalizedString("filters.title", comment: "")))
            lab.attributedText = fullString
            
            lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            lab.textColor = UIColor.label
            bg.addSubview(lab)
            return bg
        } else if section == 1 {
            let bg = UIView()
            bg.frame = CGRect(x: 0, y: 6, width: self.view.bounds.width, height: 40)
            let lab = UILabel()
            lab.frame = bg.frame
            
            let fullString = NSMutableAttributedString(string: "")
            fullString.append(NSAttributedString(string: "  " + NSLocalizedString("filters.keywords", comment: "")))
            lab.attributedText = fullString
            
            lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            lab.textColor = UIColor.label
            bg.addSubview(lab)
            return bg
        } else if section == 2 {
            let bg = UIView()
            bg.frame = CGRect(x: 0, y: 6, width: self.view.bounds.width, height: 40)
            let lab = UILabel()
            lab.frame = bg.frame
            
            let fullString = NSMutableAttributedString(string: "")
            fullString.append(NSAttributedString(string: "  " + NSLocalizedString("filters.duration", comment: "")))
            lab.attributedText = fullString
            
            lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            lab.textColor = UIColor.label
            bg.addSubview(lab)
            return bg
        } else {
            let bg = UIView()
            bg.frame = CGRect(x: 0, y: 6, width: self.view.bounds.width, height: 40)
            let lab = UILabel()
            lab.frame = bg.frame
            
            let fullString = NSMutableAttributedString(string: "")
            fullString.append(NSAttributedString(string: "  " + NSLocalizedString("filters.extras", comment: "")))
            lab.attributedText = fullString
            
            lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            lab.textColor = UIColor.label
            bg.addSubview(lab)
            return bg
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AltTextCell", for: indexPath) as! AltTextCell
            cell.altText.placeholder = NSLocalizedString("filters.title.placeholder", comment: "")
            cell.altText.text = self.filter?.title ?? ""
            cell.altText.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
            cell.altText.returnKeyType = .done
            cell.altText.delegate = self
            cell.separatorInset = .zero
            let bgColorView = UIView()
            bgColorView.backgroundColor = .clear
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            self.cells[indexPath] = cell
            return cell
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "TrendsCellList1", for: indexPath) as! TrendsCell
                cell.configure(NSLocalizedString("filters.keywords.add", comment: ""), titleLabel2: NSLocalizedString("filters.keywords.message", comment: ""))
                cell.separatorInset = .zero
                let bgColorView = UIView()
                bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                cell.accessoryType = .none
                self.cells[indexPath] = cell
                return cell
            } else {
                var cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCellK", for: indexPath)
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCellK")
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = self.filter?.keywords[indexPath.row - 1].keyword.lowercased() ?? ""
                cell.selectionStyle = .none
                cell.textLabel?.isEnabled = true
                cell.detailTextLabel?.isEnabled = false
                cell.textLabel?.textColor = UIColor.label
                cell.detailTextLabel?.textColor = UIColor.secondaryLabel
                cell.detailTextLabel?.numberOfLines = 0
                let bgColorView = UIView()
                bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                self.cells[indexPath] = cell
                return cell
            }
        } else if indexPath.section == 2 {
            // expires after
            let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell", for: indexPath) as! SelectionCell
            if let _ = self.filter {
                cell.textLabel?.text = NSLocalizedString("filters.duration.expiresAt", comment: "")
            } else {
                cell.textLabel?.text = NSLocalizedString("filters.duration.expiresAt", comment: "")
            }
            cell.imageView?.image = UIImage(systemName: "clock")
            
            let da1 = self.filter?.expiresAt ?? ""
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            let updatedAt = dateFormatter.date(from: da1)
            let da = updatedAt?.toString(dateStyle: .medium, timeStyle: .medium) ?? ""
            
            if self.durationMin == 100 {
                cell.detailTextLabel?.text = "\(da)"
            }
            if self.durationMin == 0 {
                cell.detailTextLabel?.text = NSLocalizedString("filters.duration.expiresAt.never", comment: "")
            }
            if self.durationMin == 30 {
                cell.detailTextLabel?.text = NSLocalizedString("filters.duration.expiresAt.halfHour", comment: "")
            }
            if self.durationMin == 60 {
                cell.detailTextLabel?.text = NSLocalizedString("filters.duration.expiresAt.hour", comment: "")
            }
            if self.durationMin == 360 {
                cell.detailTextLabel?.text = NSLocalizedString("filters.duration.expiresAt.6hours", comment: "")
            }
            if self.durationMin == 720 {
                cell.detailTextLabel?.text = NSLocalizedString("filters.duration.expiresAt.12hours", comment: "")
            }
            if self.durationMin == 1440 {
                cell.detailTextLabel?.text = NSLocalizedString("filters.duration.expiresAt.day", comment: "")
            }
            if self.durationMin == 1440 * 7 {
                cell.detailTextLabel?.text = NSLocalizedString("filters.duration.expiresAt.week", comment: "")
            }
            
            let view0 = UIAction(title: "\(da)", image: UIImage(systemName: "clock"), identifier: nil) { action in
                self.durationMin = 100
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
                self.editThis()
            }
            view0.accessibilityLabel = "\(da)"
            if self.durationMin == 100 {
                view0.state = .on
            }
            let view1 = UIAction(title: NSLocalizedString("filters.duration.expiresAt.never", comment: ""), image: UIImage(systemName: "clock"), identifier: nil) { action in
                self.durationMin = 0
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
                self.editThis()
            }
            view1.accessibilityLabel = NSLocalizedString("filters.duration.expiresAt.never", comment: "")
            if self.durationMin == 0 {
                view1.state = .on
            }
            let view3 = UIAction(title: NSLocalizedString("filters.duration.expiresAt.halfHour", comment: ""), image: UIImage(systemName: "clock"), identifier: nil) { action in
                self.durationMin = 30
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
                self.editThis()
            }
            view3.accessibilityLabel = NSLocalizedString("filters.duration.expiresAt.halfHour", comment: "")
            if self.durationMin == 30 {
                view3.state = .on
            }
            let view4 = UIAction(title: NSLocalizedString("filters.duration.expiresAt.hour", comment: ""), image: UIImage(systemName: "clock"), identifier: nil) { action in
                self.durationMin = 60
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
                self.editThis()
            }
            view4.accessibilityLabel = NSLocalizedString("filters.duration.expiresAt.hour", comment: "")
            if self.durationMin == 60 {
                view4.state = .on
            }
            let view5 = UIAction(title: NSLocalizedString("filters.duration.expiresAt.6hours", comment: ""), image: UIImage(systemName: "clock"), identifier: nil) { action in
                self.durationMin = 360
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
                self.editThis()
            }
            view5.accessibilityLabel = NSLocalizedString("filters.duration.expiresAt.6hours", comment: "")
            if self.durationMin == 360 {
                view5.state = .on
            }
            let view6 = UIAction(title: NSLocalizedString("filters.duration.expiresAt.12hours", comment: ""), image: UIImage(systemName: "clock"), identifier: nil) { action in
                self.durationMin = 720
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
                self.editThis()
            }
            view6.accessibilityLabel = NSLocalizedString("filters.duration.expiresAt.12hours", comment: "")
            if self.durationMin == 720 {
                view6.state = .on
            }
            let view7 = UIAction(title: NSLocalizedString("filters.duration.expiresAt.day", comment: ""), image: UIImage(systemName: "clock"), identifier: nil) { action in
                self.durationMin = 1440
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
                self.editThis()
            }
            view7.accessibilityLabel = NSLocalizedString("filters.duration.expiresAt.day", comment: "")
            if self.durationMin == 1440 {
                view7.state = .on
            }
            let view2 = UIAction(title: NSLocalizedString("filters.duration.expiresAt.week", comment: ""), image: UIImage(systemName: "clock"), identifier: nil) { action in
                self.durationMin = 1440 * 7
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
                self.editThis()
            }
            view2.accessibilityLabel = NSLocalizedString("filters.duration.expiresAt.week", comment: "")
            if self.durationMin == 1440 * 7 {
                view2.state = .on
            }
            
            let itemMenu1 = UIMenu(title: "", options: [], children: [view1, view3, view4, view5, view6, view7, view2])
            cell.backgroundButton.menu = itemMenu1
            
            cell.separatorInset = .zero
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            self.cells[indexPath] = cell
            return cell
        } else {
            if indexPath.row == 0 {
                var cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell1", for: indexPath)
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCell1")
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = NSLocalizedString("filters.extras.homeAndLists", comment: "")
                cell.imageView?.image = UIImage(systemName: "heart.text.square")
                let switchView = UISwitch(frame: .zero)
                if self.context1 {
                    switchView.setOn(true, animated: false)
                } else {
                    switchView.setOn(false, animated: false)
                }
                switchView.onTintColor = .custom.gold
                switchView.tintColor = .custom.baseTint
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchContext1(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.textLabel?.isEnabled = true
                cell.detailTextLabel?.isEnabled = false
                cell.textLabel?.textColor = UIColor.label
                cell.detailTextLabel?.textColor = UIColor.secondaryLabel
                cell.detailTextLabel?.numberOfLines = 0
                if indexPath.section == 0 {
                    cell.accessoryType = .disclosureIndicator
                } else {
                    cell.accessoryType = .none
                }
                let bgColorView = UIView()
                bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                self.cells[indexPath] = cell
                return cell
            } else if indexPath.row == 1 {
                var cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell2", for: indexPath)
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCell2")
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = NSLocalizedString("filters.extras.notifications", comment: "")
                cell.imageView?.image = UIImage(systemName: "bell")
                let switchView = UISwitch(frame: .zero)
                if self.context2 {
                    switchView.setOn(true, animated: false)
                } else {
                    switchView.setOn(false, animated: false)
                }
                switchView.onTintColor = .custom.gold
                switchView.tintColor = .custom.baseTint
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchContext2(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.textLabel?.isEnabled = true
                cell.detailTextLabel?.isEnabled = false
                cell.textLabel?.textColor = UIColor.label
                cell.detailTextLabel?.textColor = UIColor.secondaryLabel
                cell.detailTextLabel?.numberOfLines = 0
                if indexPath.section == 0 {
                    cell.accessoryType = .disclosureIndicator
                } else {
                    cell.accessoryType = .none
                }
                let bgColorView = UIView()
                bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                self.cells[indexPath] = cell
                return cell
            } else if indexPath.row == 2 {
                var cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell3", for: indexPath)
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCell3")
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = NSLocalizedString("filters.extras.public", comment: "")
                cell.imageView?.image = UIImage(systemName: "person.2.crop.square.stack")
                let switchView = UISwitch(frame: .zero)
                if self.context3 {
                    switchView.setOn(true, animated: false)
                } else {
                    switchView.setOn(false, animated: false)
                }
                switchView.onTintColor = .custom.gold
                switchView.tintColor = .custom.baseTint
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchContext3(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.textLabel?.isEnabled = true
                cell.detailTextLabel?.isEnabled = false
                cell.textLabel?.textColor = UIColor.label
                cell.detailTextLabel?.textColor = UIColor.secondaryLabel
                cell.detailTextLabel?.numberOfLines = 0
                if indexPath.section == 0 {
                    cell.accessoryType = .disclosureIndicator
                } else {
                    cell.accessoryType = .none
                }
                let bgColorView = UIView()
                bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                self.cells[indexPath] = cell
                return cell
            } else if indexPath.row == 3 {
                var cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell4", for: indexPath)
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCell4")
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = NSLocalizedString("filters.extras.conversations", comment: "")
                cell.imageView?.image = UIImage(systemName: "text.bubble")
                let switchView = UISwitch(frame: .zero)
                if self.context4 {
                    switchView.setOn(true, animated: false)
                } else {
                    switchView.setOn(false, animated: false)
                }
                switchView.onTintColor = .custom.gold
                switchView.tintColor = .custom.baseTint
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchContext4(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.textLabel?.isEnabled = true
                cell.detailTextLabel?.isEnabled = false
                cell.textLabel?.textColor = UIColor.label
                cell.detailTextLabel?.textColor = UIColor.secondaryLabel
                cell.detailTextLabel?.numberOfLines = 0
                if indexPath.section == 0 {
                    cell.accessoryType = .disclosureIndicator
                } else {
                    cell.accessoryType = .none
                }
                let bgColorView = UIView()
                bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                self.cells[indexPath] = cell
                return cell
            } else if indexPath.row == 4 {
                var cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell5", for: indexPath)
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCell5")
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = NSLocalizedString("filters.extras.profiles", comment: "")
                cell.imageView?.image = UIImage(systemName: "person.crop.circle")
                let switchView = UISwitch(frame: .zero)
                if self.context5 {
                    switchView.setOn(true, animated: false)
                } else {
                    switchView.setOn(false, animated: false)
                }
                switchView.onTintColor = .custom.gold
                switchView.tintColor = .custom.baseTint
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchContext5(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.textLabel?.isEnabled = true
                cell.detailTextLabel?.isEnabled = false
                cell.textLabel?.textColor = UIColor.label
                cell.detailTextLabel?.textColor = UIColor.secondaryLabel
                cell.detailTextLabel?.numberOfLines = 0
                if indexPath.section == 0 {
                    cell.accessoryType = .disclosureIndicator
                } else {
                    cell.accessoryType = .none
                }
                let bgColorView = UIView()
                bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                self.cells[indexPath] = cell
                return cell
            } else {
                var cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCell")
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = NSLocalizedString("filters.extras.hideCompletely", comment: "")
                cell.imageView?.image = UIImage(systemName: "hand.raised")
                cell.detailTextLabel?.text = NSLocalizedString("filters.extras.hideCompletely.footer", comment: "")
                let switchView = UISwitch(frame: .zero)
                if self.hideCompletely {
                    switchView.setOn(true, animated: false)
                } else {
                    switchView.setOn(false, animated: false)
                }
                switchView.onTintColor = .custom.gold
                switchView.tintColor = .custom.baseTint
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchHideCompletely(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.textLabel?.isEnabled = true
                cell.detailTextLabel?.isEnabled = true
                cell.textLabel?.textColor = UIColor.label
                cell.detailTextLabel?.textColor = UIColor.secondaryLabel
                cell.detailTextLabel?.numberOfLines = 0
                if indexPath.section == 0 {
                    cell.accessoryType = .disclosureIndicator
                } else {
                    cell.accessoryType = .none
                }
                let bgColorView = UIView()
                bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                self.cells[indexPath] = cell
                return cell
            }
        }
    }
    
    func editThis() {
        if let _ = self.filter {
            self.editExisting()
        }
    }
    
    @objc func switchContext1(_ sender: UISwitch!) {
        if sender.isOn {
            self.context1 = true
            self.editThis()
        } else {
            self.context1 = false
            self.editThis()
        }
    }
    
    @objc func switchContext2(_ sender: UISwitch!) {
        if sender.isOn {
            self.context2 = true
            self.editThis()
        } else {
            self.context2 = false
            self.editThis()
        }
    }
    
    @objc func switchContext3(_ sender: UISwitch!) {
        if sender.isOn {
            self.context3 = true
            self.editThis()
        } else {
            self.context3 = false
            self.editThis()
        }
    }
    
    @objc func switchContext4(_ sender: UISwitch!) {
        if sender.isOn {
            self.context4 = true
            self.editThis()
        } else {
            self.context4 = false
            self.editThis()
        }
    }
    
    @objc func switchContext5(_ sender: UISwitch!) {
        if sender.isOn {
            self.context5 = true
            self.editThis()
        } else {
            self.context5 = false
            self.editThis()
        }
    }
    
    @objc func switchHideCompletely(_ sender: UISwitch!) {
        if sender.isOn {
            self.hideCompletely = true
            self.editThis()
        } else {
            self.hideCompletely = false
            self.editThis()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            if let cell = self.cells[indexPath] as? AltTextCell {
                cell.altText.becomeFirstResponder()
            }
        }
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                self.fromAddKeyword = true
                if let _ = self.filter {
                    let vc = AltTextViewController()
                    vc.newFilter = true
                    vc.filterId = self.filter?.id ?? ""
                    self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
                } else {
                    self.createNew()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if indexPath.section == 1 && indexPath.row != 0 {
            return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { nil }, actionProvider: { suggestedActions in
                return self.makeContextMenu(indexPath.row)
            })
        } else {
            return nil
        }
    }
    
    func makeContextMenu(_ index: Int) -> UIMenu {
        let op1 = UIAction(title: "Remove Keyword", image: UIImage(systemName: "trash"), identifier: nil) { action in
            let id = self.filter?.keywords[index - 1].id ?? ""
            
            if let x = self.filter {
                let filt = x
                filt.keywords = self.filter?.keywords.filter({ x in
                    x.id != self.filter?.keywords[index - 1].id
                }) ?? []
                self.filter = filt
                self.tableView.reloadData()
            }
            
            let request = FilterPosts.removeKeyword(id: id)
            AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
                if let _ = (statuses.value) {
                    DispatchQueue.main.async {
                        triggerHapticNotification()
                        print("removed keyword")
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchFilters"), object: nil)
                    }
                }
            }
        }
        op1.accessibilityLabel = "Remove Keyword"
        op1.attributes = .destructive
        return UIMenu(title: "", options: [], children: [op1])
    }
    
}

