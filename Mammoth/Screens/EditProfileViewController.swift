//
//  EditProfileViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 10/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class EditProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    let btn1 = UIButton(type: .custom)
    let btn2 = UIButton(type: .custom)
    var tableView = UITableView()
    var context1: Bool = false
    var context2: Bool = false
    var context3: Bool = false
    var context4: Bool = false
    var privacyType: String = ""
    
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
    
    @objc func addTap() {
        triggerHapticNotification()
        var theTitle: String? = nil
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextCell {
            theTitle = cell.altText.text ?? ""
        }
        var theNote: String? = nil
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AltTextMultiCell {
            theNote = cell.altText.text ?? ""
        }
        
        let request = Accounts.updateCurrentUser(displayName: theTitle, note: theNote, locked: self.context1, bot: self.context2, discoverable: self.context3, sensitive: self.context4, privacy: self.privacyType.lowercased(), language: GlobalStruct.currentPostLang2 ?? "EN")
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let stat = (statuses.value) {
                DispatchQueue.main.async {
                    print("updated user\n\(stat)")
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "updateCurrentUser"), object: nil)
                    
                    // Consolidate profile screen with updated user card data
                    NotificationCenter.default.post(name: UserActions.didUpdateUserCardNotification, object: nil, userInfo: ["userCard": UserCardModel(account: stat)])
                    // Update current user globally
                    AccountsManager.shared.updateCurrentAccountFromNetwork()
                    
                    self.dismiss(animated: true)
                }
            }
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
    }

    func textViewDidChange(_ textView: UITextView) {
        // Ensures the text field grows as necessary
        tableView.beginUpdates()
        tableView.endUpdates()
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
        textField.resignFirstResponder()
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextCell {
            cell.altText.resignFirstResponder()
        }
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AltTextMultiCell {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .custom.backgroundTint
        self.navigationItem.title = NSLocalizedString("profile.edit", comment: "")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadThis), name: NSNotification.Name(rawValue: "reloadThis"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadBars), name: NSNotification.Name(rawValue: "reloadBars"), object: nil)
        
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
        
        self.context1 = AccountsManager.shared.currentUser()?.locked ?? false
        self.context2 = AccountsManager.shared.currentUser()?.bot ?? false
        self.context3 = AccountsManager.shared.currentUser()?.discoverable ?? false
        
        self.context4 = AccountsManager.shared.currentUser()?.source?.sensitive ?? false
        self.privacyType = AccountsManager.shared.currentUser()?.source?.privacy?.capitalized ?? "Public"
        GlobalStruct.currentPostLang2 = AccountsManager.shared.currentUser()?.source?.language ?? "EN"
        
        // set up nav
        setupNav()
        
        // set up table
        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }
        
        setupTable()
    }
    
    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        self.dismiss(animated: true, completion: nil)
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
        self.navigationItem.setLeftBarButton(moreButton0, animated: true)
        
        btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.custom.activeInverted, renderingMode: .alwaysOriginal), for: .normal)
        btn2.backgroundColor = .custom.active
        btn2.layer.cornerRadius = 14
        btn2.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        btn2.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        btn2.addTarget(self, action: #selector(self.addTap), for: .touchUpInside)
        btn2.accessibilityLabel = NSLocalizedString("profile.edit", comment: "")
        let moreButton1 = UIBarButtonItem(customView: btn2)
        self.navigationItem.setRightBarButton(moreButton1, animated: true)
    }
    
    func setupTable() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(AltTextCell.self, forCellReuseIdentifier: "AltTextCell")
        tableView.register(AltTextMultiCell.self, forCellReuseIdentifier: "AltTextMultiCell")
        tableView.register(SelectionCell.self, forCellReuseIdentifier: "SelectionCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell1")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell2")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell3")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell4")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCellz")
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
        if section == 0 {
            return 1
        } else if section == 1 {
            return 1
        } else if section == 2 {
            return 3
        } else {
            return 3
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
            
            lab.attributedText = NSAttributedString(string: NSLocalizedString("profile.edit.details.displayName", comment: ""))
            
            lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            lab.textColor = UIColor.label
            bg.addSubview(lab)
            return bg
        } else if section == 1 {
            let bg = UIView()
            bg.frame = CGRect(x: 0, y: 6, width: self.view.bounds.width, height: 40)
            let lab = UILabel()
            lab.frame = bg.frame
            
            lab.attributedText = NSAttributedString(string: NSLocalizedString("profile.edit.details.note", comment: ""))
            
            lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            lab.textColor = UIColor.label
            bg.addSubview(lab)
            return bg
        } else if section == 2 {
            let bg = UIView()
            bg.frame = CGRect(x: 0, y: 6, width: self.view.bounds.width, height: 40)
            let lab = UILabel()
            lab.frame = bg.frame
            
            lab.attributedText = NSAttributedString(string: NSLocalizedString("profile.edit.details.extras", comment: ""))
            
            lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            lab.textColor = UIColor.label
            bg.addSubview(lab)
            return bg
        } else {
            let bg = UIView()
            bg.frame = CGRect(x: 0, y: 6, width: self.view.bounds.width, height: 40)
            let lab = UILabel()
            lab.frame = bg.frame
            
            lab.attributedText = NSAttributedString(string: NSLocalizedString("profile.posts", comment: ""))
            
            lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            lab.textColor = UIColor.label
            bg.addSubview(lab)
            return bg
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AltTextCell", for: indexPath) as! AltTextCell
            cell.altText.placeholder = NSLocalizedString("profile.edit.details.displayName.placeholder", comment: "")
            cell.altText.text = AccountsManager.shared.currentUser()?.displayName.stripHTML() ?? ""
            cell.altText.returnKeyType = .done
            cell.altText.delegate = self
            cell.separatorInset = .zero
            let bgColorView = UIView()
            bgColorView.backgroundColor = .clear
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AltTextMultiCell", for: indexPath) as! AltTextMultiCell
            cell.altText.placeholder = NSLocalizedString("profile.edit.details.note.placeholder", comment: "")
            cell.altText.text = AccountsManager.shared.currentUser()?.note.stripHTML() ?? ""
            cell.altText.returnKeyType = .done
            cell.altText.delegate = self
            cell.separatorInset = .zero
            let bgColorView = UIView()
            bgColorView.backgroundColor = .clear
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            return cell
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                var cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell1", for: indexPath)
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCell1")
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = NSLocalizedString("profile.edit.details.locked", comment: "")
                cell.imageView?.image = UIImage(systemName: "lock")
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
                return cell
            } else if indexPath.row == 1 {
                var cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell2", for: indexPath)
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCell2")
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = NSLocalizedString("profile.edit.details.bot", comment: "")
                cell.imageView?.image = UIImage(systemName: "cpu")
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
                return cell
            } else {
                var cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell3", for: indexPath)
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCell3")
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = NSLocalizedString("profile.edit.details.discoverable", comment: "")
                cell.imageView?.image = UIImage(systemName: "binoculars")
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
                return cell
            }
        } else {
            if indexPath.row == 0 {
                var cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell4", for: indexPath)
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCell4")
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = " " + NSLocalizedString("composer.sensitive.add", comment: "")
                cell.imageView?.image = UIImage(systemName: "exclamationmark.triangle")
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
                return cell
            } else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell", for: indexPath) as! SelectionCell
                cell.textLabel?.text = NSLocalizedString("profile.privacy.default", comment: "")
                cell.detailTextLabel?.text = self.privacyType
                cell.imageView?.image = UIImage(systemName: "eye")
                
                let view0 = UIAction(title: NSLocalizedString("profile.privacy.public", comment: ""), image: UIImage(systemName: "person.2"), identifier: nil) { action in
                    self.privacyType = "Public"
                    self.tableView.reloadRows(at: [IndexPath(row: 1, section: 3)], with: .none)
                }
                view0.accessibilityLabel = NSLocalizedString("profile.privacy.public", comment: "")
                if self.privacyType == "Public" {
                    view0.state = .on
                }
                let view1 = UIAction(title: NSLocalizedString("profile.privacy.unlisted", comment: ""), image: UIImage(systemName: "lock.open"), identifier: nil) { action in
                    self.privacyType = "Unlisted"
                    self.tableView.reloadRows(at: [IndexPath(row: 1, section: 3)], with: .none)
                }
                view1.accessibilityLabel = NSLocalizedString("profile.privacy.unlisted", comment: "")
                if self.privacyType == "Unlisted" {
                    view1.state = .on
                }
                let view2 = UIAction(title: NSLocalizedString("profile.privacy.private", comment: ""), image: UIImage(systemName: "lock"), identifier: nil) { action in
                    self.privacyType = "Private"
                    self.tableView.reloadRows(at: [IndexPath(row: 1, section: 3)], with: .none)
                }
                view2.accessibilityLabel = NSLocalizedString("profile.privacy.private", comment: "")
                if self.privacyType == "Private" {
                    view2.state = .on
                }
                let itemMenu1 = UIMenu(title: "", options: [], children: [view0, view1, view2])
                cell.backgroundButton.menu = itemMenu1
                
                cell.separatorInset = .zero
                let bgColorView = UIView()
                bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                return cell
            } else {
                var cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCellz", for: indexPath)
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCellz")
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = " " + NSLocalizedString("profile.edit.defaultLanguage", comment: "")
                cell.imageView?.image = UIImage(systemName: "globe")
                cell.accessoryType = .none
                let bgColorView = UIView()
                bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                return cell
            }
        }
    }
    
    @objc func switchContext1(_ sender: UISwitch!) {
        if sender.isOn {
            self.context1 = true
        } else {
            self.context1 = false
        }
    }
    
    @objc func switchContext2(_ sender: UISwitch!) {
        if sender.isOn {
            self.context2 = true
        } else {
            self.context2 = false
        }
    }
    
    @objc func switchContext3(_ sender: UISwitch!) {
        if sender.isOn {
            self.context3 = true
        } else {
            self.context3 = false
        }
    }
    
    @objc func switchContext4(_ sender: UISwitch!) {
        if sender.isOn {
            self.context4 = true
        } else {
            self.context4 = false
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            if let cell = self.tableView.cellForRow(at: indexPath) as? AltTextCell {
                cell.altText.becomeFirstResponder()
            }
        }
        if indexPath.section == 1 {
            if let cell = self.tableView.cellForRow(at: indexPath) as? AltTextMultiCell {
                cell.altText.becomeFirstResponder()
            }
        }
        if indexPath.section == 3 && indexPath.row == 2 {
            let vc = TranslationComposeViewController()
            vc.fromEditProfile = true
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
    }
    
}

