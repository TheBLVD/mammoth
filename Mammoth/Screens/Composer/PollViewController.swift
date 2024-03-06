//
//  PollViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 09/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class PollViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let btn0 = UIButton(type: .custom)
    let btn2 = UIButton(type: .custom)
    var tableView = UITableView()
    var options: [String] = ["", ""]
    var canAdd: Bool = false
    var fromEdit: Bool = false
    var durationMin: Int = 1440 * 60
    var currentOptions: [String] = []
    var pollsMultiple: Bool = false
    var tempOptions: [String] = ["", "", "", ""]
    
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
                if let cell = cell as? SelectionCell {
                    cell.textLabel?.textColor = .custom.mainTextColor
                    cell.backgroundColor = .custom.backgroundTint
                }
                if let cell = cell as? PollCell {
                    cell.backgroundColor = .custom.backgroundTint
                }
            }
        }
    }
    
    override var keyCommands: [UIKeyCommand]? {
        let closeWindow = UIKeyCommand(input: "w", modifierFlags: [.command], action: #selector(dismissTap))
        closeWindow.discoverabilityTitle = NSLocalizedString("generic.dismiss", comment: "")
        if #available(iOS 15, *) {
            closeWindow.wantsPriorityOverSystemBehavior = true
        }
        return [closeWindow]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .custom.backgroundTint
        
        self.navigationItem.title = "Add Poll"
        
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
        
        btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
        btn2.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        btn2.layer.cornerRadius = 14
        btn2.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        btn2.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        btn2.addTarget(self, action: #selector(self.addTap), for: .touchUpInside)
        btn2.accessibilityLabel = "Add Poll"
        let moreButton1 = UIBarButtonItem(customView: btn2)
        self.navigationItem.setRightBarButton(moreButton1, animated: true)
        
        if self.fromEdit {
            if let opts = GlobalStruct.newPollPost?[0] as? [String] {
                self.options = opts
                self.tempOptions = self.options
                if self.tempOptions.count == 2 {
                    self.tempOptions = self.tempOptions + ["", ""]
                }
                if self.tempOptions.count == 3 {
                    self.tempOptions = self.tempOptions + [""]
                }
            }
        }
        
        // set up table
        setupTable()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
            cell1.pollItem.becomeFirstResponder()
        }
        if self.fromEdit {
            self.updateCharacterCounts()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
            cell1.pollItem.resignFirstResponder()
        }
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PollCell {
            cell1.pollItem.resignFirstResponder()
        }
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? PollCell {
            cell1.pollItem.resignFirstResponder()
        }
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
            cell1.pollItem.resignFirstResponder()
        }
    }
    
    @objc func addTap() {
        if canAdd {
            triggerHapticImpact(style: .light)
            // add poll
            if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
                self.currentOptions.append(cell1.pollItem.text ?? "")
                if let cell2 = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PollCell {
                    self.currentOptions.append(cell2.pollItem.text ?? "")
                    if let cell3 = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? PollCell {
                        self.currentOptions.append(cell3.pollItem.text ?? "")
                        if let cell4 = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
                            self.currentOptions.append(cell4.pollItem.text ?? "")
                        }
                    }
                }
            }
            GlobalStruct.newPollPost = [self.currentOptions, self.durationMin, self.pollsMultiple, false]
            NotificationCenter.default.post(name: Notification.Name(rawValue: "createToolbar"), object: nil)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        self.dismiss(animated: true, completion: nil)
    }
    
    func setupTable() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(PollCell.self, forCellReuseIdentifier: "PollCell")
        tableView.register(SelectionCell.self, forCellReuseIdentifier: "SelectionCell")
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return options.count + 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    @objc func switchPollMultiple(_ sender: UISwitch!) {
        if sender.isOn {
            self.pollsMultiple = true
        } else {
            self.pollsMultiple = false
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == options.count + 1 {
            var cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCell")
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "Allow Multiple Votes"
            cell.imageView?.image = UIImage(systemName: "hand.raised")
            cell.detailTextLabel?.text = "Toggle whether multiple votes are allowed in polls"
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "pollMultiple") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "pollMultiple") as? Bool == false {
                    switchView.setOn(false, animated: false)
                } else {
                    switchView.setOn(true, animated: false)
                }
            } else {
                switchView.setOn(false, animated: false)
            }
            switchView.onTintColor = .custom.gold
            switchView.tintColor = .custom.baseTint
            switchView.tag = indexPath.row
            switchView.addTarget(self, action: #selector(self.switchPollMultiple(_:)), for: .valueChanged)
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
            return cell
        } else if indexPath.section == options.count {
            // duration cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell", for: indexPath) as! SelectionCell
            cell.textLabel?.text = "Duration"
            cell.imageView?.image = UIImage(systemName: "chart.pie")
            
            if self.durationMin == 5 * 60 {
                cell.detailTextLabel?.text = "5 mins"
            }
            if self.durationMin == 15 * 60 {
                cell.detailTextLabel?.text = "15 mins"
            }
            if self.durationMin == 30 * 60 {
                cell.detailTextLabel?.text = "30 mins"
            }
            if self.durationMin == 60 * 60 {
                cell.detailTextLabel?.text = "1 hour"
            }
            if self.durationMin == 360 * 60 {
                cell.detailTextLabel?.text = "6 hours"
            }
            if self.durationMin == 720 * 60 {
                cell.detailTextLabel?.text = "12 hours"
            }
            if self.durationMin == 1440 * 60 {
                cell.detailTextLabel?.text = "1 day"
            }
            
            let view1 = UIAction(title: "5 mins", image: UIImage(systemName: "clock"), identifier: nil) { action in
                self.durationMin = 5 * 60
                self.tableView.reloadData()
            }
            view1.accessibilityLabel = "5 mins"
            if self.durationMin == 5 * 60 {
                view1.state = .on
            }
            let view2 = UIAction(title: "15 mins", image: UIImage(systemName: "clock"), identifier: nil) { action in
                self.durationMin = 15 * 60
                self.tableView.reloadData()
            }
            view2.accessibilityLabel = "15 mins"
            if self.durationMin == 15 * 60 {
                view2.state = .on
            }
            let view3 = UIAction(title: "30 mins", image: UIImage(systemName: "clock"), identifier: nil) { action in
                self.durationMin = 30 * 60
                self.tableView.reloadData()
            }
            view3.accessibilityLabel = "30 mins"
            if self.durationMin == 30 * 60 {
                view3.state = .on
            }
            let view4 = UIAction(title: "1 hour", image: UIImage(systemName: "clock"), identifier: nil) { action in
                self.durationMin = 60 * 60
                self.tableView.reloadData()
            }
            view4.accessibilityLabel = "1 hour"
            if self.durationMin == 60 * 60 {
                view4.state = .on
            }
            let view5 = UIAction(title: "6 hours", image: UIImage(systemName: "clock"), identifier: nil) { action in
                self.durationMin = 360 * 60
                self.tableView.reloadData()
            }
            view5.accessibilityLabel = "6 hours"
            if self.durationMin == 360 * 60 {
                view5.state = .on
            }
            let view6 = UIAction(title: "12 hours", image: UIImage(systemName: "clock"), identifier: nil) { action in
                self.durationMin = 720 * 60
                self.tableView.reloadData()
            }
            view6.accessibilityLabel = "12 hours"
            if self.durationMin == 720 * 60 {
                view6.state = .on
            }
            let view7 = UIAction(title: "1 day", image: UIImage(systemName: "clock"), identifier: nil) { action in
                self.durationMin = 1440 * 60
                self.tableView.reloadData()
            }
            view7.accessibilityLabel = "1 day"
            if self.durationMin == 1440 * 60 {
                view7.state = .on
            }
            let itemMenu1 = UIMenu(title: "", options: [], children: [view1, view2, view3, view4, view5, view6, view7])
            cell.backgroundButton.menu = itemMenu1
            
            cell.separatorInset = .zero
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            return cell
        } else {
            // poll items
            let cell = tableView.dequeueReusableCell(withIdentifier: "PollCell", for: indexPath) as! PollCell
            
            cell.pollItem.text = "\(self.tempOptions[indexPath.section])"
            cell.pollItem.placeholder = "Option \(indexPath.section + 1)"
            cell.pollItem.accessibilityLabel = "Option \(indexPath.section + 1)"
            cell.pollItem.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
            
            cell.pollItem.tag = indexPath.section
            cell.addButton.tag = indexPath.section
            
            if indexPath.section == 0 {
                cell.addButton.alpha = 0
            } else {
                let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
                cell.addButton.alpha = 1
                if (indexPath.section == self.options.count - 1) && indexPath.section != 3 {
                    cell.addButton.layer.borderColor = UIColor.custom.baseTint.cgColor
                    cell.addButton.setImage(UIImage(systemName: "plus.circle.fill", withConfiguration: symbolConfig0)?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal), for: .normal)
                    cell.addButton.removeTarget(self, action: #selector(self.minusTap(_:)), for: .touchUpInside)
                    cell.addButton.addTarget(self, action: #selector(self.plusTap(_:)), for: .touchUpInside)
                } else {
                    cell.addButton.layer.borderColor = UIColor.systemRed.cgColor
                    cell.addButton.setImage(UIImage(systemName: "minus.circle.fill", withConfiguration: symbolConfig0)?.withTintColor(UIColor.systemRed, renderingMode: .alwaysOriginal), for: .normal)
                    cell.addButton.removeTarget(self, action: #selector(self.plusTap(_:)), for: .touchUpInside)
                    cell.addButton.addTarget(self, action: #selector(self.minusTap(_:)), for: .touchUpInside)
                }
            }
            
            cell.separatorInset = .zero
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            return cell
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField.tag == 0 {
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
                self.tempOptions[0] = textField.text ?? ""
            }
        }
        if textField.tag == 1 {
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PollCell {
                self.tempOptions[1] = textField.text ?? ""
            }
        }
        if textField.tag == 2 {
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? PollCell {
                self.tempOptions[2] = textField.text ?? ""
            }
        }
        if textField.tag == 3 {
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
                self.tempOptions[3] = textField.text ?? ""
            }
        }
        self.updateCharacterCounts()
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
            if let cell2 = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PollCell {
                let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
                if cell1.pollItem.text != "" && cell2.pollItem.text != "" {
                    self.canAdd = true
                    self.btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.custom.activeInverted, renderingMode: .alwaysOriginal), for: .normal)
                    btn2.backgroundColor = .custom.active
                } else {
                    self.canAdd = false
                    self.btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
                    btn2.backgroundColor = UIColor.label.withAlphaComponent(0.08)
                }
            }
        }
    }
    
    @objc func plusTap(_ sender: UIButton) {
        triggerHapticImpact(style: .light)
        options.append("")
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
            self.tempOptions[0] = cell.pollItem.text ?? ""
        }
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PollCell {
            self.tempOptions[1] = cell.pollItem.text ?? ""
        }
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? PollCell {
            self.tempOptions[2] = cell.pollItem.text ?? ""
        }
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
            self.tempOptions[3] = cell.pollItem.text ?? ""
        }
        tableView.reloadData()
        self.updateCharacterCounts()
    }
    
    @objc func minusTap(_ sender: UIButton) {
        triggerHapticImpact(style: .light)
        options.remove(at: sender.tag)
        if sender.tag == 1 {
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
                self.tempOptions[0] = cell.pollItem.text ?? ""
            }
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PollCell {
                if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? PollCell {
                    self.tempOptions[1] = cell.pollItem.text ?? ""
                } else {
                    self.tempOptions[1] = ""
                }
            }
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? PollCell {
                if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
                    self.tempOptions[2] = cell.pollItem.text ?? ""
                } else {
                    self.tempOptions[2] = ""
                }
            }
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
                self.tempOptions[3] = ""
            }
        }
        if sender.tag == 2 {
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
                self.tempOptions[0] = cell.pollItem.text ?? ""
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PollCell {
                self.tempOptions[1] = cell.pollItem.text ?? ""
            }
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? PollCell {
                if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
                    self.tempOptions[2] = cell.pollItem.text ?? ""
                } else {
                    self.tempOptions[2] = ""
                }
            }
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
                self.tempOptions[3] = ""
            }
        }
        if sender.tag == 3 {
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
                self.tempOptions[0] = cell.pollItem.text ?? ""
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PollCell {
                self.tempOptions[1] = cell.pollItem.text ?? ""
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? PollCell {
                self.tempOptions[2] = cell.pollItem.text ?? ""
            }
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
                self.tempOptions[3] = ""
            }
        }
        tableView.reloadData()
        self.updateCharacterCounts()
    }
    
    func updateCharacterCounts() {
        for (c,_) in self.tempOptions.enumerated() {
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: c)) as? PollCell {
                cell.charCount.text = "\(25 - (self.tempOptions[c].count))"
                if (Int(cell.charCount.text ?? "0") ?? 0) < 0 {
                    cell.charCount.textColor = UIColor.systemRed
                } else {
                    cell.charCount.textColor = .custom.baseTint
                }
            }
        }
    }
    
}
