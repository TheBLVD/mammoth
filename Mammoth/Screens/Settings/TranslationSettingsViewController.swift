//
//  TranslationSettingsViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 23/04/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import OrderedCollections

class TranslationSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TableOfContentsSelectionDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    var tableView = UITableView()
    var searchView: UIView = UIView()
    let firstSection0 = [Locale.current.localizedString(forLanguageCode: Locale.current.languageCode ?? "en")]
    let firstSection02 = [Locale.current.languageCode ?? "en"]
    var firstSection: OrderedDictionary = ["Afrikaans": "af", "Albanian": "sq", "Amharic": "am", "Arabic": "ar", "Armenian": "hy", "Azerbaijani": "az", "Basque": "eu", "Belarusian": "be", "Bengali": "bn", "Bosnian": "bs", "Bulgarian": "bg", "Catalan": "ca", "Cebuano": "ceb", "Chinese (Simplified)": "zh", "Chinese (Traditional)": "zh-TW", "Corsican": "co", "Croatian": "hr", "Czech": "cs", "Danish": "da", "Dutch": "nl", "English": "en", "Esperanto": "eo", "Estonian": "et", "Finnish": "fi", "French": "fr", "Frisian": "fy", "Galician": "gl", "Georgian": "ka", "German": "de", "Greek": "el", "Gujarati": "gu", "Haitian Creole": "ht", "Hausa": "ha", "Hawaiian": "haw", "Hebrew": "he", "Hindi": "hi", "Hmong": "hmn", "Hungarian": "hu", "Icelandic": ": is", "Igbo": "ig", "Indonesian": "id", "Irish": "ga", "Italian": "it", "Japanese": "ja", "Javanese": "jv", "Kannada": "kn", "Kazakh": "kk", "Khmer": "km", "Kinyarwanda": "rw", "Korean": "ko", "Kurdish": "ku", "Kyrgyz": "ky", "Lao": "lo", "Latin": "la", "Latvian": "lv", "Lithuanian": "lt", "Luxembourgish": "lb", "Macedonian": "mk", "Malagasy": "mg", "Malay": "ms", "Malayalam": "ml", "Maltese": "mt", "Maori": "mi", "Marathi": "mr", "Mongolian": "mn", "Myanmar (Burmese)": "my", "Nepali": "ne", "Norwegian": "no", "Nyanja (Chichewa)": "ny", "Odia (Oriya)": "or", "Pashto": "ps", "Persian": "fa", "Polish": "pl", "Portuguese": "pt", "Punjabi": "pa", "Romanian": "ro", "Russian": "ru", "Samoan": "sm", "Scots Gaelic": "gd", "Serbian": "sr", "Sesotho": "st", "Shona": "sn", "Sindhi": "sd", "Sinhala (Sinhalese)": "si", "Slovak": "sk", "Slovenian": "sl", "Somali": "so", "Spanish": "es", "Sundanese": "su", "Swahili": "sw", "Swedish": "sv", "Tagalog (Filipino)": "tl", "Tajik": "tg", "Tamil": "ta", "Tatar": "tt", "Telugu": "te", "Thai": "th", "Turkish": "tr", "Turkmen": "tk", "Ukrainian": "uk", "Urdu": "ur", "Uyghur": "ug", "Uzbek": "uz", "Vietnamese": "vi", "Welsh": "cy", "Xhosa": "xh", "Yiddish": "yi", "Yoruba": "yo", "Zulu": "zu"]
    
    let tableOfContentsSelector1 = TableOfContentsSelector()
    
    override func viewDidLayoutSubviews() {
        self.tableView.frame = CGRect(x: self.view.safeAreaInsets.left, y: 0, width: self.view.bounds.width - self.view.safeAreaInsets.left - self.view.safeAreaInsets.right, height: self.view.bounds.height)
        
        tableOfContentsSelector1.frame.size.height = self.tableView.bounds.height
        tableOfContentsSelector1.frame.size.width = 30
        tableOfContentsSelector1.frame.origin.x = self.tableView.bounds.width - 32
        tableOfContentsSelector1.frame.origin.y = self.tableView.frame.origin.y
        tableView.tableHeaderView?.frame.size.height = 60
        searchController.searchBar.sizeToFit()
        searchController.searchBar.frame.size.width = searchView.frame.size.width
        searchController.searchBar.frame.size.height = searchView.frame.size.height
        
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
        self.dismiss(animated: true, completion: nil)
    }
    
    var searchFirstTime: Bool = true
    var searchController = UISearchController()
    var tempSearchStuff: OrderedDictionary<String, String> = [:]
    var isSearching: Bool = false
    func updateSearchResults(for searchController: UISearchController) {
        self.isSearching = true
        if self.tempSearchStuff.isEmpty {} else {
            self.firstSection = self.tempSearchStuff
        }
        if let theText = searchController.searchBar.text?.lowercased() {
            if theText.isEmpty {
                if self.searchFirstTime {
                    self.searchFirstTime = false
                    self.tempSearchStuff = self.firstSection
                } else {
                    self.firstSection = self.tempSearchStuff
                    self.tableView.reloadData()
                }
            } else {
                let z = self.firstSection.filter({ $0.key.lowercased().contains(theText) })
                self.firstSection = z
                self.tableView.reloadData()
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.isSearching = false
        if !self.tempSearchStuff.isEmpty {
            firstSection = self.tempSearchStuff
        }
        self.tableView.reloadData()
        self.searchFirstTime = true
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if self.searchController.searchBar.isFirstResponder {
            self.searchController.searchBar.resignFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchFirstTime = true
        if self.searchController.searchBar.isFirstResponder {
            self.searchController.searchBar.resignFirstResponder()
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .custom.backgroundTint
        self.navigationItem.title = NSLocalizedString("title.translationLang", comment: "")
        
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
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.layer.masksToBounds = true
        self.tableView.estimatedRowHeight = UITableView.automaticDimension
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.backgroundView = UIView()
        self.searchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.obscuresBackgroundDuringPresentation = false
            controller.hidesNavigationBarDuringPresentation = false
            controller.searchBar.backgroundImage = UIImage()
            controller.searchBar.backgroundColor = .custom.backgroundTint
            controller.searchBar.barTintColor = .custom.backgroundTint
            controller.searchBar.sizeToFit()
            controller.searchBar.delegate = self
            controller.definesPresentationContext = true
            self.definesPresentationContext = true
            
            return controller
        })()
        self.view.addSubview(self.tableView)
        self.tableView.reloadData()
        
        // scrubber
        let tableOfContentsItems1: [TableOfContentsItem] = [.symbol(name: "star.fill", isCustom: false)] + TableOfContentsSelector.alphanumericItems
        
        tableOfContentsSelector1.updateWithItems(tableOfContentsItems1)
        tableOfContentsSelector1.font = UIFont.systemFont(ofSize: 11, weight: .light)
        tableOfContentsSelector1.selectionDelegate = self
        self.view.addSubview(tableOfContentsSelector1)
    }
    
    func viewToShowOverlayIn() -> UIView? {
        return self.navigationController?.view
    }

    func selectedItem(_ item: TableOfContentsItem) {
        switch item {
        case let .letter(letter):
            let ind = Array(self.firstSection.keys).firstIndex(where: { (x) -> Bool in
                x.first ?? Character("a") == letter
            })
            self.tableView.scrollToRow(at: IndexPath(row: ind ?? 0, section: 1), at: .top, animated: false)
        case let .symbol(name, isCustom):
            print("symbol - \(isCustom) - \(name)")
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
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
            lab.text = NSLocalizedString("settings.appearance.translationLang.preferred", comment: "")
            lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            lab.textColor = UIColor.label
            bg.addSubview(lab)
            return bg
        } else if section == 1 {
            let bg = UIView()
            bg.frame = CGRect(x: 0, y: 6, width: self.view.bounds.width, height: 40)
            let lab = UILabel()
            lab.frame = bg.frame
            lab.text = NSLocalizedString("settings.appearance.translationLang.all", comment: "")
            lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            lab.textColor = UIColor.label
            bg.addSubview(lab)
            return bg
        } else {
            return nil
        }
    }

    func beganSelection() {
        
    }
    
    func endedSelection() {
        
    }
    
    //MARK: TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.firstSection0.count
        } else {
            return self.firstSection.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        cell = UITableViewCell(style: .subtitle, reuseIdentifier: "settingsCell")
        cell.textLabel?.numberOfLines = 0
        if indexPath.section == 0 {
            cell.textLabel?.text = self.firstSection0[indexPath.row]
        } else {
            cell.textLabel?.text = Array(self.firstSection.keys)[indexPath.row]
        }
        cell.backgroundColor = .custom.quoteTint
        if indexPath.section == 0 {
            if GlobalStruct.langStr == self.firstSection02[indexPath.row] {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        } else {
            if GlobalStruct.langStr == Array(self.firstSection.values)[indexPath.row] {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        if #available(iOS 15.0, *) {
            cell.focusEffect = UIFocusHaloEffect()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            GlobalStruct.langStr = self.firstSection02[indexPath.row]
        } else {
            GlobalStruct.langStr = Array(self.firstSection.values)[indexPath.row]
        }
        UserDefaults.standard.setValue(GlobalStruct.langStr, forKey: "langStr")
        self.tableView.reloadData()
    }
    
}

