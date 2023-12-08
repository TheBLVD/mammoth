//
//  ContactSettingsViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 04/05/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class ContactSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var tableView = UITableView()
    let firstSection = ["@mammoth@moth.social"]
    var section0Images: [String] = ["link"]
    let secondSection = ["Other Apps"]
    var section1Images: [String] = ["heart"]
    let thirdSection = ["Email"]
    var section2Images: [String] = ["envelope"]
    
    override func viewDidLayoutSubviews() {
        self.tableView.frame = CGRect(x: self.view.safeAreaInsets.left, y: 0, width: self.view.bounds.width - self.view.safeAreaInsets.left - self.view.safeAreaInsets.right, height: self.view.bounds.height)
        
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
    
    @objc func dismissTap() {
        self.dismiss(animated: true, completion: nil)
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
        self.navigationItem.title = "Get in Touch"
        
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
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell1")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell2")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell3")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell4")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell5")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell6")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.layer.masksToBounds = true
        self.tableView.estimatedRowHeight = UITableView.automaticDimension
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.showsVerticalScrollIndicator = false
        self.view.addSubview(self.tableView)
        self.tableView.reloadData()
    }
    
    //MARK: TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.firstSection.count
        } else if section == 4 {
            return 2
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell1", for: indexPath)
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "settingsCell1")
            cell.textLabel?.numberOfLines = 0
            cell.imageView?.image = UIImage(systemName: self.section0Images[indexPath.row])
            cell.textLabel?.text = self.firstSection[indexPath.row]
            cell.backgroundColor = .custom.OVRLYSoftContrast
            cell.accessoryType = .disclosureIndicator
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else if indexPath.section == 1 {
            var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell2", for: indexPath)
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "settingsCell2")
            cell.textLabel?.numberOfLines = 0
            cell.imageView?.image = UIImage(systemName: "safari")
            cell.textLabel?.text = "Website"
            cell.backgroundColor = .custom.OVRLYSoftContrast
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else if indexPath.section == 2 {
            var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell3", for: indexPath)
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "settingsCell3")
            cell.textLabel?.numberOfLines = 0
            cell.imageView?.image = UIImage(systemName: "hand.raised")
            cell.textLabel?.text = "Server Privacy Policy"
            cell.backgroundColor = .custom.OVRLYSoftContrast
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else if indexPath.section == 3 {
            var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell4", for: indexPath)
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "settingsCell4")
            cell.textLabel?.numberOfLines = 0
            cell.imageView?.image = UIImage(systemName: "heart")
            cell.textLabel?.text = "Review Prompt"
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "reviewPrompt") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "reviewPrompt") as? Bool == false {
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
            switchView.addTarget(self, action: #selector(self.switchReviewPrompt(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            cell.backgroundColor = .custom.OVRLYSoftContrast
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else {
            if indexPath.row == 0 {
                var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell5", for: indexPath)
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "settingsCell5")
                cell.textLabel?.numberOfLines = 0
                cell.imageView?.image = UIImage(systemName: "doc.text.magnifyingglass")
                cell.textLabel?.text = "Enable Debug Logging"
                let switchView = UISwitch(frame: .zero)
                
                switchView.setOn(GlobalStruct.enableLogging, animated: false)
                switchView.onTintColor = .custom.gold
                switchView.tintColor = .custom.baseTint
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchEnableLogging(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell
            } else {
                var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell6", for: indexPath)
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "settingsCell6")
                cell.textLabel?.numberOfLines = 0
                cell.imageView?.image = UIImage(systemName: "mail.and.text.magnifyingglass")
                cell.textLabel?.text = "Email Logs as Attachment"
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                if GlobalStruct.enableLogging {
                    cell.textLabel?.textColor = UIColor.label
                } else {
                    cell.textLabel?.textColor = UIColor.secondaryLabel
                }
                return cell
            }
        }
    }
    
    @objc func switchReviewPrompt(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.reviewPrompt = true
            UserDefaults.standard.set(true, forKey: "reviewPrompt")
        } else {
            GlobalStruct.reviewPrompt = false
            UserDefaults.standard.set(false, forKey: "reviewPrompt")
        }
    }
    
    @objc func switchEnableLogging(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.enableLogging = true
            UserDefaults.standard.set(true, forKey: "enableLogging")
        } else {
            GlobalStruct.enableLogging = false
            UserDefaults.standard.set(false, forKey: "enableLogging")
        }
        log.writeToFile(GlobalStruct.enableLogging)
        self.tableView.reloadRows(at: [IndexPath(row: 1, section: 4)], with: .none)
    }
    
    func emailLoggingData() {
        let attachmentData = [log.appFileData(), log.pushFileData()]
        let attachmentDataTitles = ["Mammoth Log.txt", "Mammoth Push Log.txt"]
        EmailHandler.shared.sendEmail(destination: "feedback@theblvd.app",
                                      subject: "Feedback with Debug Logging",
                                      body: "Please review the attached logs. I ran into an issue when…\n\n\n",
                                      attachmentData: attachmentData,
                                      attachmentDataTitles: attachmentDataTitles)
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath == IndexPath(row: 1, section: 4) {
            return GlobalStruct.enableLogging
        } else {
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let vc = ProfileViewController(fullAcct: "mammoth@moth.social", serverName: "moth.social")
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else if indexPath.section == 1 {
            let z = URL(string: "https://www.getmammoth.app")!
            PostActions.openLink(z)
        } else if indexPath.section == 2 {
            if let server = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.returnedText {
                if let y = URL(string: "https://\(server)/privacy-policy") {
                    PostActions.openLink(y)
                }
            } else {
                log.error("expected a server for privacy policy link")
            }
        } else if indexPath.section == 4 {
            if indexPath.row == 1 && GlobalStruct.enableLogging {
                let alert = UIAlertController(title: "Email Logs", message: "Logs may include your account handles (@mammoth@moth.social), but never login information, text from posts or DMs, or any other private info. You can review the email attachment before it's sent.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default , handler:{ (UIAlertAction) in
                    self.emailLoggingData()
                }))
                if let presenter = alert.popoverPresentationController {
                    presenter.sourceView = getTopMostViewController()?.view
                    presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                }
                getTopMostViewController()?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Mammoth was made with ♥ by The BLVD Inc."
        } else if section == 1 {
            return "Find out more about Mammoth."
        } else if section == 2 {
            return ""
        } else if section == 3 {
            return "You may sometimes be prompted to review Mammoth on the App Store when viewing post details. Disabling the above toggle will prevent these requests."
        } else {
            return "Logs may include your account handles (@mammoth@moth.social), but never login information, text from posts or DMs, or any other private info. You can review the email attachment before it's sent.\n" +
            "     1. Enable Debug Logging\n" +
            "     2. Reproduce the problem\n" +
            "     3. Email us the logs\n" +
            "     4. Disable Debug Logging\n"
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 2 {
            return 0
        } else {
            return UITableView.automaticDimension
        }
    }
    
}







