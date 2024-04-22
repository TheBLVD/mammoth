//
//  DevelopmentViewController.swift
//  Mammoth
//
//  Created by Benoit Nolens on 22/04/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit

class DevelopmentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
        
    let sections = [
        SettingsSection(items: [
            .openSourceCredits,
            .sourceCode,
            .analytics
        ])
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .custom.backgroundTint
        self.navigationItem.title = NSLocalizedString("settings.development", comment: "Item title in settings list. Also used as the screen title.")
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0
        }
        
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Update the appearance of the navbar
        configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
    }
    
    @objc func switchAnalytics(_ sender: UISwitch) {
        if sender.isOn {
            GlobalStruct.shareAnalytics = true
            AnalyticsManager.initClient()
            AccountsManager.shared.syncIdentityData()
            AnalyticsManager.subscribe()
            UserDefaults.standard.set(true, forKey: "shareAnalytics")
        } else {
            GlobalStruct.shareAnalytics = false
            AnalyticsManager.unsubscribe()
            UserDefaults.standard.set(false, forKey: "shareAnalytics")
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let model = sections[indexPath.section].items[indexPath.item]
        
        var config = cell.defaultContentConfiguration()
        config.text = model.title
        config.textProperties.color = .custom.highContrast
        config.image = settingsFontAwesomeImage(model.imageName)
        config.secondaryTextProperties.color = .custom.highContrast
        
        cell.accessoryType = .none
        cell.selectionStyle = .none
        cell.textLabel?.textAlignment = .left
        
        switch model.style {
        case .normal:
            cell.textLabel?.textColor = .custom.highContrast
            cell.backgroundColor = .custom.OVRLYSoftContrast
            cell.imageView?.image = settingsFontAwesomeImage(model.imageName)
        case .destructive:
            cell.textLabel?.textColor = .white
            cell.backgroundColor = .custom.destructive
            cell.imageView?.image = nil
        }
        
        switch model {
        case .analytics:
            
            config.secondaryText = NSLocalizedString("settings.analytics.description", comment: "")
            
            let switchView = UISwitch(frame: .zero)
            if GlobalStruct.shareAnalytics {
                switchView.setOn(true, animated: false)
            } else {
                switchView.setOn(false, animated: false)
            }
            switchView.onTintColor = .custom.gold
            switchView.addTarget(self, action: #selector(switchAnalytics), for: .valueChanged)
            cell.accessoryView = switchView
            
        default:
            cell.accessoryView = nil
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            cell.textLabel?.textAlignment = .left
        }

        cell.contentConfiguration = config
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc: UIViewController?
        
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case .openSourceCredits:
            vc = TextFileViewController(filename: "About")
        case .sourceCode:
            PostActions.openLinks2("https://github.com/TheBLVD/mammoth")
            return
        default:
            vc = nil
        }
        
        if let vc {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
