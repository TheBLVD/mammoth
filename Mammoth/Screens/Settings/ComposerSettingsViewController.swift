//
//  ComposerSettingsViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 22/04/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class ComposerSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIColorPickerViewControllerDelegate {
    
    var tableView = UITableView()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateTabBar"), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateTabBar"), object: nil)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .custom.backgroundTint
        self.navigationItem.title = NSLocalizedString("settings.composer", comment: "")
        
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadBars), name: NSNotification.Name(rawValue: "reloadBars"), object: nil)
        
        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }
        if #available(iOS 15.0, *) {
            self.tableView.allowsFocus = true
        }
        self.tableView = UITableView(frame: .zero, style: .insetGrouped)
        self.tableView.register(SelectionCell.self, forCellReuseIdentifier: "SelectionCell2")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell2")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell3")
        self.tableView.register(SelectionCell.self, forCellReuseIdentifier: "SelectionCell3")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCellS")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCellU")
        self.tableView.alpha = 1
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.layer.masksToBounds = true
        self.tableView.estimatedRowHeight = 89
        self.tableView.rowHeight = UITableView.automaticDimension
        self.view.addSubview(self.tableView)
    }
    
    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        self.dismiss(animated: true, completion: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return 2
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell2", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = NSLocalizedString("settings.composer.requireDescriptions", comment: "")
            cell.imageView?.image = settingsSystemImage("text.below.photo")
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "altText") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "altText") as? Bool == false {
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
            switchView.addTarget(self, action: #selector(self.switchAltText(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.OVRLYSoftContrast
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell3", for: indexPath)
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = NSLocalizedString("settings.composer.threaderMode", comment: "")
                cell.imageView?.image = settingsSystemImage("lineweight")
                let switchView = UISwitch(frame: .zero)
                if UserDefaults.standard.value(forKey: "threaderMode") as? Bool != nil {
                    if UserDefaults.standard.value(forKey: "threaderMode") as? Bool == false {
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
                switchView.addTarget(self, action: #selector(self.switchThreaderMode(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                let bgColorView = UIView()
                bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell3", for: indexPath) as! SelectionCell
                cell.textLabel?.text = NSLocalizedString("settings.composer.threadStyle", comment: "")
                cell.accessibilityLabel = NSLocalizedString("settings.composer.threadStyle", comment: "")
                if GlobalStruct.threaderStyle == 0 {
                    cell.detailTextLabel?.text = NSLocalizedString("generic.none", comment: "")
                    cell.imageView?.image = settingsSystemImage("1.circle")
                } else if GlobalStruct.threaderStyle == 1 {
                    cell.detailTextLabel?.text = "..."
                    cell.imageView?.image = settingsSystemImage("2.circle")
                } else if GlobalStruct.threaderStyle == 2 {
                    cell.detailTextLabel?.text = "(x/n)"
                    cell.imageView?.image = settingsSystemImage("3.circle")
                } else if GlobalStruct.threaderStyle == 3 {
                    cell.detailTextLabel?.text = "🧵"
                    cell.imageView?.image = settingsSystemImage("4.circle")
                } else {
                    cell.detailTextLabel?.text = "🪡"
                    cell.imageView?.image = settingsSystemImage("5.circle")
                }
                var gestureActions: [UIAction] = []
                let op1 = UIAction(title: "None", image: settingsSystemImage("1.circle"), identifier: nil) { action in
                    GlobalStruct.threaderStyle = 0
                    UserDefaults.standard.set(GlobalStruct.threaderStyle, forKey: "threaderStyle")
                    self.tableView.reloadData()
                }
                if GlobalStruct.threaderStyle == 0 {
                    op1.state = .on
                }
                gestureActions.append(op1)
                let op2 = UIAction(title: "...", image: settingsSystemImage("2.circle"), identifier: nil) { action in
                    GlobalStruct.threaderStyle = 1
                    UserDefaults.standard.set(GlobalStruct.threaderStyle, forKey: "threaderStyle")
                    self.tableView.reloadData()
                }
                if GlobalStruct.threaderStyle == 1 {
                    op2.state = .on
                }
                gestureActions.append(op2)
                let op3 = UIAction(title: "(x/n)", image: settingsSystemImage("3.circle"), identifier: nil) { action in
                    GlobalStruct.threaderStyle = 2
                    UserDefaults.standard.set(GlobalStruct.threaderStyle, forKey: "threaderStyle")
                    self.tableView.reloadData()
                }
                if GlobalStruct.threaderStyle == 2 {
                    op3.state = .on
                }
                gestureActions.append(op3)
                let op4 = UIAction(title: "🧵", image: settingsSystemImage("4.circle"), identifier: nil) { action in
                    GlobalStruct.threaderStyle = 3
                    UserDefaults.standard.set(GlobalStruct.threaderStyle, forKey: "threaderStyle")
                    self.tableView.reloadData()
                }
                if GlobalStruct.threaderStyle == 3 {
                    op4.state = .on
                }
                gestureActions.append(op4)
                let op5 = UIAction(title: "🪡", image: settingsSystemImage("5.circle"), identifier: nil) { action in
                    GlobalStruct.threaderStyle = 4
                    UserDefaults.standard.set(GlobalStruct.threaderStyle, forKey: "threaderStyle")
                    self.tableView.reloadData()
                }
                if GlobalStruct.threaderStyle == 4 {
                    op5.state = .on
                }
                gestureActions.append(op5)
                cell.backgroundButton.menu = UIMenu(title: "", image: settingsSystemImage("1.circle"), options: [.displayInline], children: gestureActions)
                cell.accessoryView = .none
                cell.selectionStyle = .none
                let bgColorView = UIView()
                bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if GlobalStruct.threaderMode {
                    cell.textLabel?.isEnabled = true
                    cell.isUserInteractionEnabled = true
                    cell.imageView?.tintColor = .custom.baseTint
                } else {
                    cell.textLabel?.isEnabled = false
                    cell.isUserInteractionEnabled = false
                    cell.imageView?.tintColor = UIColor.secondaryLabel
                }
                return cell
            }
        }
        return UITableViewCell()
    }
    
    @objc func switchAltText(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.altText = true
            UserDefaults.standard.set(true, forKey: "altText")
            self.tableView.reloadData()
        } else {
            GlobalStruct.altText = false
            UserDefaults.standard.set(false, forKey: "altText")
            self.tableView.reloadData()
        }
    }
    
    @objc func switchThreaderMode(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.threaderMode = true
            UserDefaults.standard.set(true, forKey: "threaderMode")
            self.tableView.reloadData()
        } else {
            GlobalStruct.threaderMode = false
            UserDefaults.standard.set(false, forKey: "threaderMode")
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return NSLocalizedString("settings.composer.requireDescriptions.footer", comment: "")
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}


