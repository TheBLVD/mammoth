//
//  AppearanceSettingsViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 21/04/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage

class AppearanceSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIColorPickerViewControllerDelegate {
    
    private enum AppearanceOptions: Int, CaseIterable {
        static var allCases: [AppearanceSettingsViewController.AppearanceOptions] {
            // Only include the High Contrast option for iOS 17+
            let allItems: [AppearanceSettingsViewController.AppearanceOptions?] = [
                AppearanceOptions.theme,
                {
                    if #available(iOS 17.0, *) {
                        return AppearanceOptions.highContrast
                    } else {
                        return nil
                    }
                }(),
                AppearanceOptions.names,
                AppearanceOptions.maximumLines,
                AppearanceOptions.mediaSize,
                AppearanceOptions.profileIcon,
                AppearanceOptions.contentWarning,
                AppearanceOptions.sensitiveContent,
                AppearanceOptions.autoplay,
                AppearanceOptions.translation,
                AppearanceOptions.language,
            ]
            return allItems.compactMap({$0})
        }
        
        case theme
        @available(iOS 17.0, *)
        case highContrast
        case names
        case maximumLines
        case mediaSize
        case profileIcon
        case contentWarning
        case sensitiveContent
        case autoplay
        case translation
        case language

        @available(*, unavailable)
        case all

        var index: Int {
            self.rawValue
        }
    }

    var tableView = UITableView()
    let btn0 = UIButton(type: .custom)
    
    let firstSection = [NSLocalizedString("settings.appearance.textSize", comment: "")]
    let sampleStatus = {
        let currentUserAccount = AccountsManager.shared.currentUser()!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let fiveMinsAgo = formatter.string(from: Date().addingTimeInterval(-(5*60)))
        let status = Status(id: "",
                            uri: "",
                            account: currentUserAccount,
                            content: NSLocalizedString("settings.appearance.placeholder", comment: ""),
                            createdAt: fiveMinsAgo,
                            emojis: [],
                            repliesCount: 20,
                            reblogsCount: 3,
                            favouritesCount: 8000,
                            spoilerText: "",
                            visibility: .public,
                            mediaAttachments: [],
                            mentions: [],
                            tags: [])
        return status
    }()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
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

    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        self.dismiss(animated: true, completion: nil)
    }

    @objc func reloadAll() {
        // tints
        let hcText = UserDefaults.standard.value(forKey: "hcText") as? Bool ?? true
        if hcText == true {
            UIColor.custom.mainTextColor = .label
        } else {
            UIColor.custom.mainTextColor = .secondaryLabel
        }

        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }

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

    @objc func reloadBars() {
        DispatchQueue.main.async {
            if GlobalStruct.hideNavBars2 {
                self.extendedLayoutIncludesOpaqueBars = true
            } else {
                self.extendedLayoutIncludesOpaqueBars = false
            }
        }
    }


    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        log.error("traitCollectionDidChange!")
        super.traitCollectionDidChange(previousTraitCollection)
        self.reloadAll()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .custom.backgroundTint
        self.title = NSLocalizedString("settings.appearance", comment: "")

        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadBars), name: NSNotification.Name(rawValue: "reloadBars"), object: nil)

        // nav bar
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
        if #available(iOS 15.0, *) {
            self.tableView.allowsFocus = true
        }
        
        self.tableView = UITableView(frame: .zero, style: .insetGrouped)
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.tableView.register(TextSizeCell.self, forCellReuseIdentifier: "TextSizeCell")
        self.tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .textOnly))
        self.tableView.register(SelectionCell.self, forCellReuseIdentifier: "SelectionCell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.layer.masksToBounds = true
        self.tableView.showsVerticalScrollIndicator = false
        self.view.addSubview(self.tableView)
        self.tableView.reloadData()

        let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        btn0.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
        btn0.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        btn0.layer.cornerRadius = 14
        btn0.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        btn0.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        btn0.addTarget(self, action: #selector(self.dismissTap), for: .touchUpInside)
        btn0.accessibilityLabel = NSLocalizedString("generic.dismiss", comment: "")
    }

    // MARK: TableView

    func numberOfSections(in tableView: UITableView) -> Int {
        3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1    // sample cell
        case 1: return 2    // text size + slider
        case 2: return AppearanceOptions.allCases.count    // remaining options
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: // sample post cell
            let cell = tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: .textOnly), for: indexPath) as! PostCardCell
            let postCard = PostCardModel(status: sampleStatus)
            cell.configure(postCard: postCard) {type,isActive,data in
                // Do nothing
            }
            
            cell.willDisplay()
            cell.layer.borderColor = UIColor.custom.outlines.cgColor
            cell.layer.borderWidth = 0.5
            cell.isUserInteractionEnabled = false // ignore tapping on the sample post
            return cell

        case 1: // text size + slider cell
            switch indexPath.row {
            case 0:
                let cell = UITableViewCell(style: .value1, reuseIdentifier: "UITableViewCell.value1")
                cell.textLabel?.numberOfLines = 0
                cell.imageView?.image = settingsFontAwesomeImage("\u{f894}")
                cell.textLabel?.text = self.firstSection[indexPath.row]
                let system = NSLocalizedString("settings.appearance.system", comment: "")
                if GlobalStruct.customTextSize == 0 {
                    cell.detailTextLabel?.text = "\(system)"
                } else if GlobalStruct.customTextSize > 0 {
                    cell.detailTextLabel?.text = "\(system) \("+\(Int(GlobalStruct.customTextSize))")"
                } else {
                    cell.detailTextLabel?.text = "\(system) \(Int(GlobalStruct.customTextSize))"
                }
                
                cell.backgroundColor = .custom.OVRLYSoftContrast
                cell.selectionStyle = .none
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextSizeCell", for: indexPath) as! TextSizeCell
                cell.textLabel?.numberOfLines = 0
                cell.configureSize(self.view.bounds.width)
                cell.slider.setValue(Float(GlobalStruct.customTextSize), animated: false)
                cell.slider.addTarget(self, action: #selector(self.valueChanged(_:)), for: .valueChanged)
                cell.backgroundColor = .custom.OVRLYSoftContrast
                cell.selectionStyle = .none
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell
                
            default: return UITableViewCell()
            }
            
        case 2: // remaining cells
            guard indexPath.row < AppearanceOptions.allCases.count else {
                log.error("Unsupported Appearance option")
                return UITableViewCell()
            }
            let option = AppearanceOptions.allCases[indexPath.row]
            
            switch option {
            case AppearanceOptions.theme:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell", for: indexPath) as! SelectionCell
                cell.textLabel?.text = NSLocalizedString("settings.appearance.theme", comment: "")
                cell.imageView?.image = settingsFontAwesomeImage("\u{f1fc}")
                switch GlobalStruct.overrideTheme {
                case 1:
                    cell.detailTextLabel?.text = NSLocalizedString("settings.appearance.light", comment: "")
                case 2:
                    cell.detailTextLabel?.text = NSLocalizedString("settings.appearance.dark", comment: "")
                default:
                    cell.detailTextLabel?.text = NSLocalizedString("settings.appearance.system", comment: "")
                }

                var gestureActions: [UIAction] = []
                let op1 = UIAction(title: NSLocalizedString("settings.appearance.system", comment: ""), image: settingsFontAwesomeImage("\u{f042}"), identifier: nil) { action in
                    GlobalStruct.overrideTheme = 0
                    UserDefaults.standard.set(GlobalStruct.overrideTheme, forKey: "overrideTheme")
                    FontAwesome.setColorTheme(theme: ColorTheme.systemDefault)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "overrideTheme"), object: nil)
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
                if GlobalStruct.overrideTheme == 0 {
                    op1.state = .on
                }
                gestureActions.append(op1)
                let op2 = UIAction(title: NSLocalizedString("settings.appearance.light", comment: ""), image: settingsFontAwesomeImage("\u{e0c9}"), identifier: nil) { action in
                    GlobalStruct.overrideTheme = 1
                    UserDefaults.standard.set(GlobalStruct.overrideTheme, forKey: "overrideTheme")
                    FontAwesome.setColorTheme(theme: ColorTheme.light)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "overrideTheme"), object: nil)
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
                if GlobalStruct.overrideTheme == 1 {
                    op2.state = .on
                }
                gestureActions.append(op2)
                let op3 = UIAction(title: NSLocalizedString("settings.appearance.dark", comment: ""), image: settingsFontAwesomeImage("\u{f186}"), identifier: nil) { action in
                    GlobalStruct.overrideTheme = 2
                    UserDefaults.standard.set(GlobalStruct.overrideTheme, forKey: "overrideTheme")
                    FontAwesome.setColorTheme(theme: ColorTheme.dark)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "overrideTheme"), object: nil)
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
                if GlobalStruct.overrideTheme == 2 {
                    op3.state = .on
                }
                gestureActions.append(op3)

                cell.backgroundButton.menu = UIMenu(title: "", image: UIImage(systemName: "sun.max"), options: [.displayInline], children: gestureActions)
                return cell

            case AppearanceOptions.highContrast:
                let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = NSLocalizedString("settings.appearance.highContrast", comment: "")
                cell.imageView?.image = settingsFontAwesomeImage("\u{f042}")
                let switchView = UISwitch(frame: .zero)
                switchView.setOn(GlobalStruct.overrideThemeHighContrast, animated: false)
                switchView.onTintColor = .custom.gold
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchHighContrast(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell

            case AppearanceOptions.names:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell", for: indexPath) as! SelectionCell
                cell.textLabel?.text = NSLocalizedString("settings.appearance.names", comment: "")
                cell.accessibilityLabel = NSLocalizedString("settings.appearance.names", comment: "")
                
                cell.imageView?.image = settingsFontAwesomeImage("\u{f5b7}")
                if GlobalStruct.displayName == .full {
                    cell.detailTextLabel?.text = NSLocalizedString("settings.appearance.names.full", comment: "")
                } else if GlobalStruct.displayName == .usernameOnly {
                    cell.detailTextLabel?.text = NSLocalizedString("settings.appearance.names.username", comment: "")
                } else if GlobalStruct.displayName == .usertagOnly {
                    cell.detailTextLabel?.text = NSLocalizedString("generic.none", comment: "")
                } else {
                    cell.detailTextLabel?.text = "None" // .none
                }
                
                var gestureActions: [UIAction] = []
                let image1 = settingsFontAwesomeImage("\u{f47f}")
                let op1 = UIAction(title: NSLocalizedString("settings.appearance.names.full", comment: ""), image: image1, identifier: nil) { action in
                    
                    GlobalStruct.displayName = .full
                    UserDefaults.standard.set(GlobalStruct.displayName.rawValue, forKey: "displayName")
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
                }
                if GlobalStruct.displayName == .full {
                    op1.state = .on
                }
                
                gestureActions.append(op1)
                let image2 = settingsFontAwesomeImage("\u{f007}")
                let op2 = UIAction(title: NSLocalizedString("settings.appearance.names.username", comment: ""), image: image2, identifier: nil) { action in
                    
                    GlobalStruct.displayName = .usernameOnly
                    UserDefaults.standard.set(GlobalStruct.displayName.rawValue, forKey: "displayName")
                
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
                }
                if GlobalStruct.displayName == .usernameOnly {
                    op2.state = .on
                }
                
                gestureActions.append(op2)
                let image3 = settingsFontAwesomeImage("\u{40}")
                let op3 = UIAction(title: NSLocalizedString("settings.appearance.names.usertag", comment: ""), image: image3, identifier: nil) { action in
                    
                    GlobalStruct.displayName = .usertagOnly
                    UserDefaults.standard.set(GlobalStruct.displayName.rawValue, forKey: "displayName")
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
                }
                if GlobalStruct.displayName == .usertagOnly {
                    op3.state = .on
                }
                
                gestureActions.append(op3)
                let image4 = settingsFontAwesomeImage("\u{f656}")
                let op4 = UIAction(title: NSLocalizedString("generic.none", comment: ""), image: image4, identifier: nil) { action in
                    
                    GlobalStruct.displayName = .none
                    UserDefaults.standard.set(GlobalStruct.displayName.rawValue, forKey: "displayName")
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
                }
                if GlobalStruct.displayName == .none {
                    op4.state = .on
                }
                
                gestureActions.append(op4)
                cell.backgroundButton.menu = UIMenu(title: "", image: UIImage(systemName: "person.crop.square.fill.and.at.rectangle"), options: [.displayInline], children: gestureActions)
                return cell

            case AppearanceOptions.maximumLines:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell", for: indexPath) as! SelectionCell
                cell.textLabel?.text = NSLocalizedString("settings.appearance.maximumLines", comment: "")
                cell.accessibilityLabel = NSLocalizedString("settings.appearance.maximumLines", comment: "")
                
                cell.imageView?.image = settingsFontAwesomeImage("\u{f7a4}")
                if GlobalStruct.maxLines == 0 {
                    cell.detailTextLabel?.text = NSLocalizedString("generic.none", comment: "")
                } else {
                    cell.detailTextLabel?.text = "\(GlobalStruct.maxLines)"
                }
                
                var gestureActions: [UIAction] = []
                let actionValues = [0, 2, 4, 6, 8, 10]
                for actionValue in actionValues {
                    let title = (actionValue==0) ? NSLocalizedString("generic.none", comment: "") : "\(actionValue)"
                    let op1 = UIAction(title: title, image: nil, identifier: nil) { action in
                        GlobalStruct.maxLines = actionValue
                        UserDefaults.standard.set(GlobalStruct.maxLines, forKey: "maxLines")
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
                    }
                    if GlobalStruct.maxLines == actionValue {
                        op1.state = .on
                    }
                    gestureActions.append(op1)
                }
                cell.backgroundButton.menu = UIMenu(title: "", image: UIImage(systemName: "person.crop.square.fill.and.at.rectangle"), options: [.displayInline], children: gestureActions)
                return cell
                
            case AppearanceOptions.mediaSize:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell", for: indexPath) as! SelectionCell
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = NSLocalizedString("settings.appearance.mediaSize", comment: "")
                cell.accessibilityLabel = NSLocalizedString("settings.appearance.mediaSize", comment: "")
                cell.imageView?.image = settingsFontAwesomeImage("\u{f03e}")
                cell.detailTextLabel?.text = GlobalStruct.mediaSize.displayName
                
                let gestureActions: [UIAction] = PostCardCell.PostCardMediaVariant.allCases.map({ mediaVariant in
                    let op = UIAction(title: mediaVariant.displayName , image: nil, identifier: nil) { action in
                        // Call on next runloop for smooth menu animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            GlobalStruct.mediaSize = mediaVariant
                            UserDefaults.standard.set(GlobalStruct.mediaSize.rawValue, forKey: "mediaSize")
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
                        }
                  }
                    if GlobalStruct.mediaSize == mediaVariant { op.state = .on }
                    
                    return op
                })
                
                cell.backgroundButton.menu = UIMenu(title: "", image: nil, options: [.displayInline], children: gestureActions)
                return cell
                
            case AppearanceOptions.profileIcon:
                let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = NSLocalizedString("settings.appearance.circleIcons", comment: "")
                cell.imageView?.image = settingsFontAwesomeImage("\u{f2bd}")

                let switchView = UISwitch(frame: .zero)
                if UserDefaults.standard.value(forKey: "circleProfiles") as? Bool != nil {
                    if UserDefaults.standard.value(forKey: "circleProfiles") as? Bool == false {
                        switchView.setOn(false, animated: false)
                    } else {
                        switchView.setOn(true, animated: false)
                    }
                } else {
                    switchView.setOn(true, animated: false)
                }
                
                switchView.onTintColor = .custom.gold
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchCircleProfiles(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell

            case AppearanceOptions.contentWarning:
                let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = NSLocalizedString("settings.appearance.showCW", comment: "")
                cell.imageView?.image = settingsFontAwesomeImage("\u{f05e}")
                let switchView = UISwitch(frame: .zero)
                if UserDefaults.standard.value(forKey: "showCW") as? Bool != nil {
                    if UserDefaults.standard.value(forKey: "showCW") as? Bool == false {
                        switchView.setOn(false, animated: false)
                    } else {
                        switchView.setOn(true, animated: false)
                    }
                } else {
                    switchView.setOn(true, animated: false)
                }
                switchView.onTintColor = .custom.gold
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchShowCW(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell

            case AppearanceOptions.sensitiveContent:
                let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = NSLocalizedString("settings.appearance.blurSensitive", comment: "")
                cell.imageView?.image = settingsFontAwesomeImage("\u{f071}")
                let switchView = UISwitch(frame: .zero)
                if UserDefaults.standard.value(forKey: "blurSensitiveContent") as? Bool != nil {
                    if UserDefaults.standard.value(forKey: "blurSensitiveContent") as? Bool == false {
                        switchView.setOn(false, animated: false)
                    } else {
                        switchView.setOn(true, animated: false)
                    }
                } else {
                    switchView.setOn(true, animated: true)
                }
                switchView.onTintColor = .custom.gold
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchBlurSensitiveContent(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell

            case AppearanceOptions.autoplay:
                let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = NSLocalizedString("settings.appearance.autoplay", comment: "")
                cell.imageView?.image = settingsFontAwesomeImage("\u{f04b}")
                let switchView = UISwitch(frame: .zero)
                if UserDefaults.standard.value(forKey: "autoPlayVideos") as? Bool != nil {
                    if UserDefaults.standard.value(forKey: "autoPlayVideos") as? Bool == false {
                        switchView.setOn(false, animated: false)
                    } else {
                        switchView.setOn(true, animated: false)
                    }
                } else {
                    switchView.setOn(true, animated: true)
                }
                switchView.onTintColor = .custom.gold
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchAutoPlayingVideos(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell
                
            case AppearanceOptions.translation:
                let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
                cell.textLabel?.text = NSLocalizedString("settings.appearance.translationLang", comment: "")
                cell.imageView?.image = settingsFontAwesomeImage("\u{f0ac}")
                cell.accessoryView = nil
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell
                
            case AppearanceOptions.language:
                let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
                cell.textLabel?.text = NSLocalizedString("settings.appearance.language", comment: "")
                cell.imageView?.image = settingsFontAwesomeImage("\u{f1ab}")
                cell.accessoryView = nil
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell
            }
            
        default: return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 2:
            if AppearanceOptions.allCases[indexPath.row] == AppearanceOptions.translation {
                let vc = TranslationSettingsViewController()
                navigationController?.pushViewController(vc, animated: true)
            }
            
            if AppearanceOptions.allCases[indexPath.row] == AppearanceOptions.language {
                let alert = UIAlertController(title: NSLocalizedString("settings.appearance.language.alert.title", comment: "Alert title when tapping on the language setting item"), message: NSLocalizedString("settings.appearance.language.alert.description", comment: "Alert description when tapping on the language setting item"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("generic.continue", comment: ""), style: .default, handler: { _ in
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }

                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { _ in })
                    }
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("generic.cancel", comment: ""), style: .cancel, handler: nil))
                getTopMostViewController()?.present(alert, animated: true)
            }
        default:
            break
        }
    }

    @objc func valueChanged(_ sender: UISlider) {
        let step: Float = 1
        let roundedValue = round(sender.value / step) * step
        sender.value = roundedValue

        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) {
            if sender.value == 0 {
                cell.detailTextLabel?.text = "\("System Size")"
            } else if sender.value < 0 {
                cell.detailTextLabel?.text = "\("System Size") \(Int(sender.value))"
            } else {
                cell.detailTextLabel?.text = "\("System Size") \("+\(Int(sender.value))")"
            }
        }

        GlobalStruct.customTextSize = CGFloat(sender.value)
        UserDefaults.standard.set(GlobalStruct.customTextSize, forKey: "customTextSize")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
        
        self.tableView.reloadData()
    }
    
    @objc func switchShowCW(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.showCW = true
            UserDefaults.standard.set(true, forKey: "showCW")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
        } else {
            GlobalStruct.showCW = false
            UserDefaults.standard.set(false, forKey: "showCW")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
        }
    }
    
    @objc func switchBlurSensitiveContent(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.blurSensitiveContent = true
            UserDefaults.standard.set(true, forKey: "blurSensitiveContent")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
        } else {
            GlobalStruct.blurSensitiveContent = false
            UserDefaults.standard.set(false, forKey: "blurSensitiveContent")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
        }
    }
    
    @objc func switchCircleProfiles(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.circleProfiles = true
            UserDefaults.standard.set(true, forKey: "circleProfiles")
        } else {
            GlobalStruct.circleProfiles = false
            UserDefaults.standard.set(false, forKey: "circleProfiles")
        }
        
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "tabBarProfileIcon"), object: nil)
    }
    
    @objc func switchAutoPlayingVideos(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.autoPlayVideos = true
            UserDefaults.standard.set(true, forKey: "autoPlayVideos")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
        } else {
            GlobalStruct.autoPlayVideos = false
            UserDefaults.standard.set(false, forKey: "autoPlayVideos")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
        }
    }
    
    @objc func switchHighContrast(_ sender: UISwitch!) {
        GlobalStruct.overrideThemeHighContrast = sender.isOn
        UserDefaults.standard.set(GlobalStruct.overrideThemeHighContrast, forKey: "overrideThemeHighContrast")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "overrideTheme"), object: nil)
    }
        
}
