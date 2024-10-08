//
//  SettingsViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 07/07/2020.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import SDWebImage

private let version = String.localizedStringWithFormat(NSLocalizedString("settings.version", comment: ""), Bundle.main.appVersion) + "\n" + String.localizedStringWithFormat(NSLocalizedString("settings.build", comment: ""), Bundle.main.appBuild)
private let bottomFooterText = NSLocalizedString("settings.clearData.footer", comment: "") + "\n\n" + version

class SettingsViewController: UIViewController {
    
    var tableView = UITableView()
    let btn0 = UIButton(type: .custom)
    var upgradeCell: UpgradeCell?
    
    private var sections: [SettingsSection] {
        if IAPManager.isGoldMember {
            return [
                SettingsSection(items: [
                    .upgrade
                ]),
                SettingsSection(items: [
                    .accounts
                ]),
                SettingsSection(items: [
                    .postAppearance,
                    UIApplication.shared.supportsAlternateIcons ? .appIcon : nil,
                    .composer,
                    .pushNotifications,
                    .soundsAndHaptics,
                    .siriShortcuts
                ].compactMap {$0}),
                SettingsSection(items: [
                    .openLinks,
                    GlobalStruct.preferredBrowser == "In-App Browser" ? .readerView : nil,
                    .appLock
                ].compactMap {$0}),
                SettingsSection(items: [
                    .cloudSync
                ].compactMap {$0}),
                SettingsSection(items: [
                    .getInTouch,
                    .subscriptions,
                    .development
                ]),
                SettingsSection(
                    items: [.clearData],
                    footerTitle: bottomFooterText)
            ]
        } else {
            return [
                SettingsSection(items: [
                    .upgrade
                ]),
                SettingsSection(items: [
                    .accounts
                ]),
                SettingsSection(items: [
                    .postAppearance,
                    UIApplication.shared.supportsAlternateIcons ? .appIcon : nil,
                    .composer,
                    .pushNotifications,
                    .soundsAndHaptics,
                    .siriShortcuts
                ].compactMap {$0}),
                SettingsSection(items: [
                    .openLinks,
                    GlobalStruct.preferredBrowser == "In-App Browser" ? .readerView : nil,
                    .appLock
                ].compactMap {$0}),
                SettingsSection(items: [
                    .cloudSync
                ].compactMap {$0}),
                SettingsSection(items: [
                    .getInTouch,
                    .development
                ]),
                SettingsSection(
                    items: [.clearData],
                    footerTitle: bottomFooterText)
            ]
        }
    }
    private var upgradeCellIsExpanded: Bool = false
    
    init(expandUpgradeCell: Bool = false) {
        super.init(nibName: nil, bundle: nil)
        self.upgradeCellIsExpanded = expandUpgradeCell
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func reloadAll() {
        let hcText = UserDefaults.standard.value(forKey: "hcText") as? Bool ?? true
        if hcText == true {
            UIColor.custom.mainTextColor = .label
        } else {
            UIColor.custom.mainTextColor = .secondaryLabel
        }
        self.tableView.reloadData()
        
        // update various elements
        self.view.backgroundColor = .custom.backgroundTint
    }
    
    var tempScrollPosition: CGFloat = 0
    @objc func scrollToTop() {
        // scroll to top
        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        self.tempScrollPosition = self.tableView.contentOffset.y
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if GlobalStruct.isNeedingColumnsUpdate {
            GlobalStruct.isNeedingColumnsUpdate = false
        }
        if GlobalStruct.isNeedingColumnsUpdate2 {
            GlobalStruct.isNeedingColumnsUpdate2 = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Update the appearance of the navbar
        configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
        
        // Sync upgrade cell with latest status
        if let cell = self.upgradeCell {
            let currentStatus: UpgradeRootView.UpgradeViewState = IAPManager.isGoldMember ? .subscribed : .unsubscribed
            if cell.rootView.state != currentStatus {
                cell.rootView.state = currentStatus
                
                // If the status changed to 'subscribed' the user subscribed on
                // the icon list page. When navigating back to settings we want
                // the cell to expand to invite users to join the community
                DispatchQueue.main.async {
                    if [.subscribed, .thanks].contains(currentStatus) {
                        self.upgradeCellIsExpanded = true
                        
                        if #available(iOS 15.0, *) {
                            self.tableView.beginUpdates()
                            self.tableView.reconfigureRows(at: [IndexPath(item: 0, section: 0)])
                            self.tableView.reloadSections([3], with: .automatic)
                            self.tableView.endUpdates()
                        } else {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .custom.backgroundTint
        self.navigationItem.title = NSLocalizedString("title.settings", comment: "")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.scrollToTop), name: NSNotification.Name(rawValue: "scrollToTop9"), object: nil)
        
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
                
        if #available(iOS 15.0, *) {
            self.tableView.allowsFocus = true
        }
        self.tableView = UITableView(frame: .zero, style: .insetGrouped)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.tableView.register(UpgradeCell.self, forCellReuseIdentifier: UpgradeCell.reuseIdentifier)
        self.tableView.alpha = 1
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.layer.masksToBounds = true
        self.tableView.rowHeight = UITableView.automaticDimension
        
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0
        }
        
        self.view.addSubview(self.tableView)
    }
        
    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func switchReaderView(_ sender: UISwitch) {
        if sender.isOn {
            GlobalStruct.openLinksInReaderView = true
            UserDefaults.standard.set(true, forKey: "openLinksInReaderView")
        } else {
            GlobalStruct.openLinksInReaderView = false
            UserDefaults.standard.set(false, forKey: "openLinksInReaderView")
        }
    }
    
    @objc func switchAppLock(_ sender: UISwitch) {
        if sender.isOn {
            GlobalStruct.appLock = true
            UserDefaults.standard.set(true, forKey: "appLock")
        } else {
            GlobalStruct.appLock = false
            UserDefaults.standard.set(false, forKey: "appLock")
        }
    }
    
    @objc func switchCloudSync(_ sender: UISwitch) {
        if sender.isOn {
            GlobalStruct.cloudSync = true
            UserDefaults.standard.setValue(true, forKey: "cloudSync")
        } else {
            GlobalStruct.cloudSync = false
            UserDefaults.standard.setValue(false, forKey: "cloudSync")
        }
    }
}

// MARK: - UITableView

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 && indexPath.row == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: UpgradeCell.reuseIdentifier, for: indexPath) as? UpgradeCell {
                cell.delegate = self
                cell.configure(expanded: upgradeCellIsExpanded, title: "Mammoth Gold")
                self.upgradeCell = cell
                return cell
            }
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = .default
        
        let item = sections[indexPath.section].items[indexPath.row]
        
        cell.textLabel?.text = item.title
        
        switch item.style {
        case .normal:
            cell.textLabel?.textColor = .custom.highContrast
            cell.backgroundColor = .custom.OVRLYSoftContrast
            cell.imageView?.image = settingsFontAwesomeImage(item.imageName)
        case .destructive:
            cell.textLabel?.textColor = .white
            cell.backgroundColor = .custom.destructive
            cell.imageView?.image = nil
        }
        if item == .readerView {
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "openLinksInReaderView") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "openLinksInReaderView") as? Bool == false {
                    switchView.setOn(false, animated: false)
                } else {
                    switchView.setOn(true, animated: false)
                }
            } else {
                switchView.setOn(false, animated: false)
            }
            switchView.onTintColor = .custom.gold

            switchView.addTarget(self, action: #selector(switchReaderView), for: .valueChanged)
            cell.accessoryView = switchView
            cell.accessoryType = .none
            cell.selectionStyle = .none
            cell.textLabel?.textAlignment = .left
        } else if item == .appLock {
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "appLock") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "appLock") as? Bool == false {
                    switchView.setOn(false, animated: false)
                } else {
                    switchView.setOn(true, animated: false)
                }
            } else {
                switchView.setOn(false, animated: false)
            }
            switchView.onTintColor = .custom.gold

            switchView.addTarget(self, action: #selector(switchAppLock), for: .valueChanged)
            cell.accessoryView = switchView
            cell.accessoryType = .none
            cell.selectionStyle = .none
            cell.textLabel?.textAlignment = .left
        } else if item == .cloudSync {
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "cloudSync") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "cloudSync") as? Bool == false {
                    switchView.setOn(false, animated: false)
                } else {
                    switchView.setOn(true, animated: false)
                }
            } else {
                switchView.setOn(false, animated: false)
            }
            switchView.onTintColor = .custom.gold

            switchView.addTarget(self, action: #selector(switchCloudSync), for: .valueChanged)
            cell.accessoryView = switchView
            cell.accessoryType = .none
            cell.selectionStyle = .none
            cell.textLabel?.textAlignment = .left
        } else if item == .clearData {
            cell.accessoryView = nil
            cell.accessoryType = .none
            cell.selectionStyle = .default
            cell.textLabel?.textAlignment = .center
        } else {
            cell.accessoryView = nil
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            cell.textLabel?.textAlignment = .left
        }
        
        if #available(iOS 15.0, *) {
            cell.focusEffect = UIFocusHaloEffect()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        sections[section].footerTitle
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let vc: UIViewController?
        
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case .upgrade:
            self.upgradeCellIsExpanded = !self.upgradeCellIsExpanded
            if #available(iOS 15.0, *) {
                tableView.beginUpdates()
                tableView.reconfigureRows(at: [IndexPath(item: 0, section: 0)])
                tableView.reloadSections([3], with: .automatic)
                tableView.endUpdates()
            } else {
                tableView.reloadData()
            }
            return
        case .appIcon:
            vc = IconSettingsViewController()
        case .postAppearance:
            vc = AppearanceSettingsViewController()
        case .soundsAndHaptics:
            vc = HapticsSettingsViewController()
        case .composer:
            vc = ComposerSettingsViewController()
        case .accounts:
            vc = AccountsSettingsViewController()
        case .pushNotifications:
            vc = NotificationSettingsViewController()
        case .siriShortcuts:
            vc = SiriSettingsViewController()
        case .getInTouch:
            vc = ContactSettingsViewController()
        case .development:
            vc = DevelopmentViewController()
        case .subscriptions:
            let url = URL(string: "https://apps.apple.com/account/subscriptions")
            UIApplication.shared.open(url!, options: [:])
            return
        case .clearData:
            vc = nil
            postClearCacheAlert()
        case .openLinks:
            vc = OpenLinksSettingsViewController()
            (vc as! OpenLinksSettingsViewController).delegate = self
        default:
            vc = nil
        }
        
        if let vc {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 3
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return UIView()
        }
        
        return nil
    }
}

extension SettingsViewController: UpgradeViewDelegate {
    func onStateChange(state: UpgradeRootView.UpgradeViewState) {
        if #available(iOS 15.0, *) {
            tableView.beginUpdates()
            tableView.reconfigureRows(at: [IndexPath(item: 0, section: 0)])
            tableView.reloadSections([3], with: .automatic)
            tableView.endUpdates()
        } else {
            tableView.reloadData()
        }
    }
}

extension SettingsViewController {
    
    func postClearCacheAlert() {
        let alert = UIAlertController(title: NSLocalizedString("settings.clearData.title", comment: ""), message: NSLocalizedString("settings.clearData.info", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.cancel", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("settings.clearData.confirm", comment: ""), style: .destructive , handler:{ (UIAlertAction) in
            self.clearAllCaches()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func clearAllCaches() {
        
        // Delete current caches
        ListManager.shared.clearCache()
        HashtagManager.shared.clearCache()
        FollowManager.shared.clearCache()
        InstanceManager.shared.clearCache()
        FeedsManager.shared.clearCache()
        ModerationManager.shared.clearCache()
        TutorialOverlay.resetTutorials()
        StatusCache.shared.clearCache()

        // Clear News Carousel Cache
        do {
            try Disk.remove("\(AccountsManager.shared.currentUser()?.id ?? "all")/allLinks.json", from: .documents)
        } catch {
            log.error("error clearing news carousel cache: \(error)")
        }
        
        // Clear Account Cacher
        if let mastodonAcctData = AccountsManager.shared.currentAccount as? MastodonAcctData {
            AccountCacher.clearCache(forAccount: mastodonAcctData.account)
        }

        // Clear Image Cache
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
    }

}

// MARK: - Appearance changes
internal extension SettingsViewController {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
             }
         }
         self.reloadAll()
    }
}

extension SettingsViewController: OpenLinksSettingsViewDelegate {
    func didChangeBrowserSettings() {
        self.reloadAll()
    }
}
