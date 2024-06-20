//
//  AlertsSettingsViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 29/07/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

// swiftlint:disable:next type_body_length
class AlertsSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIColorPickerViewControllerDelegate {
    
    var tableView = UITableView()
    var section0: [String] = ["Post Sent", "Post Deleted", "User Actions", "List Actions", "Other Actions"]
    
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
        self.navigationItem.title = "Pop-Up Alerts"
        
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
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell2")
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.section0.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(self.section0[indexPath.row])"
            cell.imageView?.image = UIImage(systemName: "exclamationmark.circle")
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "popupPostPosted") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "popupPostPosted") as? Bool == false {
                    switchView.setOn(false, animated: false)
                } else {
                    switchView.setOn(true, animated: false)
                }
            } else {
                switchView.setOn(true, animated: false)
            }
            switchView.onTintColor = .custom.gold
            switchView.tintColor = .custom.baseTint
            switchView.tag = indexPath.row
            switchView.addTarget(self, action: #selector(self.switch1(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(self.section0[indexPath.row])"
            cell.imageView?.image = UIImage(systemName: "exclamationmark.circle")
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "popupPostDeleted") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "popupPostDeleted") as? Bool == false {
                    switchView.setOn(false, animated: false)
                } else {
                    switchView.setOn(true, animated: false)
                }
            } else {
                switchView.setOn(true, animated: false)
            }
            switchView.onTintColor = .custom.gold
            switchView.tintColor = .custom.baseTint
            switchView.tag = indexPath.row
            switchView.addTarget(self, action: #selector(self.switch2(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else if indexPath.row == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(self.section0[indexPath.row])"
            cell.imageView?.image = UIImage(systemName: "exclamationmark.circle")
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "popupUserActions") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "popupUserActions") as? Bool == false {
                    switchView.setOn(false, animated: false)
                } else {
                    switchView.setOn(true, animated: false)
                }
            } else {
                switchView.setOn(true, animated: false)
            }
            switchView.onTintColor = .custom.gold
            switchView.tintColor = .custom.baseTint
            switchView.tag = indexPath.row
            switchView.addTarget(self, action: #selector(self.switch3(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else if indexPath.row == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(self.section0[indexPath.row])"
            cell.imageView?.image = UIImage(systemName: "exclamationmark.circle")
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "popupListActions") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "popupListActions") as? Bool == false {
                    switchView.setOn(false, animated: false)
                } else {
                    switchView.setOn(true, animated: false)
                }
            } else {
                switchView.setOn(true, animated: false)
            }
            switchView.onTintColor = .custom.gold
            switchView.tintColor = .custom.baseTint
            switchView.tag = indexPath.row
            switchView.addTarget(self, action: #selector(self.switch4(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else if indexPath.row == 4 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(self.section0[indexPath.row])"
            cell.imageView?.image = UIImage(systemName: "exclamationmark.circle")
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "popupBookmarkActions") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "popupBookmarkActions") as? Bool == false {
                    switchView.setOn(false, animated: false)
                } else {
                    switchView.setOn(true, animated: false)
                }
            } else {
                switchView.setOn(true, animated: false)
            }
            switchView.onTintColor = .custom.gold
            switchView.tintColor = .custom.baseTint
            switchView.tag = indexPath.row
            switchView.addTarget(self, action: #selector(self.switch5(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell2", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(self.section0[indexPath.row])"
            cell.imageView?.image = UIImage(systemName: "exclamationmark.circle")
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "popupRateLimits") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "popupRateLimits") as? Bool == false {
                    switchView.setOn(false, animated: false)
                } else {
                    switchView.setOn(true, animated: false)
                }
            } else {
                switchView.setOn(true, animated: false)
            }
            switchView.onTintColor = .custom.gold
            switchView.tintColor = .custom.baseTint
            switchView.tag = indexPath.row
            switchView.addTarget(self, action: #selector(self.switch6(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        }
    }
    
    @objc func switch1(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.popupPostPosted = true
            UserDefaults.standard.set(true, forKey: "popupPostPosted")
            self.tableView.reloadData()
        } else {
            GlobalStruct.popupPostPosted = false
            UserDefaults.standard.set(false, forKey: "popupPostPosted")
            self.tableView.reloadData()
        }
    }
    
    @objc func switch2(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.popupPostDeleted = true
            UserDefaults.standard.set(true, forKey: "popupPostDeleted")
            self.tableView.reloadData()
        } else {
            GlobalStruct.popupPostDeleted = false
            UserDefaults.standard.set(false, forKey: "popupPostDeleted")
            self.tableView.reloadData()
        }
    }
    
    @objc func switch3(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.popupUserActions = true
            UserDefaults.standard.set(true, forKey: "popupUserActions")
            self.tableView.reloadData()
        } else {
            GlobalStruct.popupUserActions = false
            UserDefaults.standard.set(false, forKey: "popupUserActions")
            self.tableView.reloadData()
        }
    }
    
    @objc func switch4(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.popupListActions = true
            UserDefaults.standard.set(true, forKey: "popupListActions")
            self.tableView.reloadData()
        } else {
            GlobalStruct.popupListActions = false
            UserDefaults.standard.set(false, forKey: "popupListActions")
            self.tableView.reloadData()
        }
    }
    
    @objc func switch5(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.popupBookmarkActions = true
            UserDefaults.standard.set(true, forKey: "popupBookmarkActions")
            self.tableView.reloadData()
        } else {
            GlobalStruct.popupBookmarkActions = false
            UserDefaults.standard.set(false, forKey: "popupBookmarkActions")
            self.tableView.reloadData()
        }
    }
    
    @objc func switch6(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.popupRateLimits = true
            UserDefaults.standard.set(true, forKey: "popupRateLimits")
            self.tableView.reloadData()
        } else {
            GlobalStruct.popupRateLimits = false
            UserDefaults.standard.set(false, forKey: "popupRateLimits")
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Choose which pop-up alerts to display."
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}




