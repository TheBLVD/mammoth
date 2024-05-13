//
//  EditFieldsViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 16/12/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class EditFieldsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    let btn1 = UIButton(type: .custom)
    let btn2 = UIButton(type: .custom)
    var tableView = UITableView()
    var fields: [HashType] = []
    var keyHeight: CGFloat = 0
    var cells: [IndexPath:UITableViewCell] = [:]
    
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
    
    @objc func keyboardWillChange(notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) - 4
            keyHeight = CGFloat(keyboardHeight)
            
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.keyHeight, right: 0)
        }
    }
    
    @objc func addTap() {
        triggerHapticNotification()
        var label1: String? = nil
        if let cell = self.cells[IndexPath(row: 0, section: 0)] as? AltTextMultiCell {
            label1 = cell.altText.text ?? ""
        }
        var content1: String? = nil
        if let cell = self.cells[IndexPath(row: 1, section: 0)] as? AltTextMultiCell {
            content1 = cell.altText.text ?? ""
        }
        var label2: String? = nil
        if let cell = self.cells[IndexPath(row: 0, section: 1)] as? AltTextMultiCell {
            label2 = cell.altText.text ?? ""
        }
        var content2: String? = nil
        if let cell = self.cells[IndexPath(row: 1, section: 1)] as? AltTextMultiCell {
            content2 = cell.altText.text ?? ""
        }
        var label3: String? = nil
        if let cell = self.cells[IndexPath(row: 0, section: 2)] as? AltTextMultiCell {
            label3 = cell.altText.text ?? ""
        }
        var content3: String? = nil
        if let cell = self.cells[IndexPath(row: 1, section: 2)] as? AltTextMultiCell {
            content3 = cell.altText.text ?? ""
        }
        var label4: String? = nil
        if let cell = self.cells[IndexPath(row: 0, section: 3)] as? AltTextMultiCell {
            label4 = cell.altText.text ?? ""
        }
        var content4: String? = nil
        if let cell = self.cells[IndexPath(row: 1, section: 3)] as? AltTextMultiCell {
            content4 = cell.altText.text ?? ""
        }
        
        let request = Accounts.updateCurrentUser(fieldName1: label1, fieldValue1: content1, fieldName2: label2, fieldValue2: content2, fieldName3: label3, fieldValue3: content3, fieldName4: label4, fieldValue4: content4)
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let stat = (statuses.value) {
                DispatchQueue.main.async {
                    log.debug("updated fields\n\(stat)")
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
    
    func textViewDidChange(_ textView: UITextView) {
        // Ensures the text field grows as necessary
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
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
        self.navigationItem.title = NSLocalizedString("profile.edit.infoAndLinks", comment: "")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadThis), name: NSNotification.Name(rawValue: "reloadThis"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadBars), name: NSNotification.Name(rawValue: "reloadBars"), object: nil)
        
        NotificationCenter.default.addObserver(self,selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
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
        
        btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(.custom.activeInverted, renderingMode: .alwaysOriginal), for: .normal)
        btn2.backgroundColor = .custom.active
        btn2.layer.cornerRadius = 14
        btn2.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        btn2.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        btn2.addTarget(self, action: #selector(self.addTap), for: .touchUpInside)
        btn2.accessibilityLabel = NSLocalizedString("profile.edit.fields", comment: "")
        let moreButton1 = UIBarButtonItem(customView: btn2)
        self.navigationItem.setRightBarButton(moreButton1, animated: true)
    }
    
    func setupTable() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(AltTextMultiCell.self, forCellReuseIdentifier: "AltTextMultiCell")
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
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 52
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let bg = UIView()
        bg.frame = CGRect(x: 0, y: 6, width: self.view.bounds.width, height: 40)
        let lab = UILabel()
        lab.frame = bg.frame
        
        lab.attributedText = NSAttributedString(string: String.localizedStringWithFormat(NSLocalizedString("profile.edit.field", comment: ""), section + 1))
        
        lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        lab.textColor = UIColor.label
        bg.addSubview(lab)
        return bg
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = self.cells[indexPath] {
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "AltTextMultiCell", for: indexPath) as! AltTextMultiCell
        if indexPath.row == 0 {
            cell.altText.placeholder = NSLocalizedString("profile.edit.label", comment: "")
            if fields.count > indexPath.section {
                cell.altText.text = fields[indexPath.section].name.stripHTML()
            }
        } else {
            cell.altText.placeholder = NSLocalizedString("profile.edit.content", comment: "")
            if fields.count > indexPath.section {
                cell.altText.text = fields[indexPath.section].value.stripHTML()
            }
        }
        cell.altText.returnKeyType = .done
        cell.altText.delegate = self
        cell.separatorInset = .zero
        let bgColorView = UIView()
        bgColorView.backgroundColor = .clear
        cell.selectedBackgroundView = bgColorView
        cell.backgroundColor = .custom.quoteTint
        
        self.cells[indexPath] = cell
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let cell = self.tableView.cellForRow(at: indexPath) as? AltTextMultiCell {
            cell.altText.becomeFirstResponder()
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
        
    }
    
}


