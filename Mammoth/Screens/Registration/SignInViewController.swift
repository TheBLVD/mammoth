//
//  SignInViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 26/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import AuthenticationServices
import SafariServices
import ArkanaKeys

class SignInViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    static var allInstances: [tagInstance] = []
    static var filteredInstances: [tagInstance] = []
    
    let loadingIndicator = UIActivityIndicatorView()
    var safariVC: SFSafariViewController?
    var textField = PaddedTextField()
    var tableView = UITableView()
    var defaultInstance: [tagInstance] = []
    var fromPlus: Bool = false
    var isFromSignIn: Bool = true
    var topBorder: CALayer = CALayer()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var safe = (UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
        if self.fromPlus {
            safe = 0
        }
        if !self.isFromSignIn {
            safe = 0
        }
        
        textField.frame = CGRect(x: self.view.safeAreaInsets.left + 13, y: (self.navigationController?.navigationBar.bounds.height ?? 0) + 50 + safe + 10, width: self.view.bounds.width - self.view.safeAreaInsets.left - self.view.safeAreaInsets.right - 40, height: 45)
        tableView.frame = CGRect(x: 0, y: (self.navigationController?.navigationBar.bounds.height ?? 0) + 100 + safe + 19.5, width: self.view.bounds.width, height: self.view.bounds.height - safe - 100 - 20 - (self.navigationController?.navigationBar.bounds.height ?? 0))
        
        self.topBorder.frame = .init(x: 0, y: textField.frame.origin.y + textField.frame.size.height + 14, width: self.view.frame.size.width, height: 0.5)
        
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.background
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
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if self.textField.isFirstResponder {
            self.textField.resignFirstResponder()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .custom.background
        if self.fromPlus {
            self.title = NSLocalizedString("newAccount.title", comment: "Sign up screen to choose your instance")
        } else {
            if self.isFromSignIn {
                self.title = NSLocalizedString("signIn.title", comment: "Sign in screen to choose your instance")
            } else {
                self.title = NSLocalizedString("communities.title", comment: "Screen to choose an instance")
                configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.newInstanceLogged), name: NSNotification.Name(rawValue: "newInstanceLogged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.loadSpecificInstance), name: NSNotification.Name(rawValue: "loadSpecificInstance"), object: nil)
        
        loadingIndicator.startAnimating()
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.center = self.view.center
        self.view.addSubview(loadingIndicator)
        
        let defaultInstance: [tagInstance]
        do {
            defaultInstance = try Disk.retrieve("defaultInstance.json", from: .documents, as: [tagInstance].self)
        } catch {
            // error fetching instances from Disk; use the default instance from disk
            defaultInstance = Bundle.main.decode([tagInstance].self, from: GlobalHostServer() + ".Instance.json")
        }
        self.defaultInstance = defaultInstance
        self.loadingIndicator.stopAnimating()

        let allInstances: [tagInstance]
        do {
            allInstances = try Disk.retrieve("allInstances.json", from: .documents, as: [tagInstance].self)
        } catch {
            // error fetching instances from Disk; use the default list fro disk
            allInstances = Bundle.main.decode([tagInstance].self, from: "OtherInstances.json")
        }
        SignInViewController.allInstances = allInstances
        if !self.isFromSignIn {
            let currentInstance = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData
            SignInViewController.allInstances = SignInViewController.allInstances.filter({ x in
                x.name != currentInstance?.returnedText ?? ""
            })
        }
        SignInViewController.filteredInstances = SignInViewController.allInstances
        self.loadingIndicator.stopAnimating()
        
        self.setupNav()
        self.setupUI()
        self.setupTable()
        if SignInViewController.allInstances.isEmpty {
            SignInViewController.loadInstances(isFromSignIn: self.isFromSignIn)
        } else {
            self.loadSpecificInstance()
        }
    }
    
    class func loadInstances(isFromSignIn: Bool) {
        let urlStr = "https://feature.\(GlobalHostServer())/api/v1/instances/list"
        let url: URL = URL(string: urlStr)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let task = session.dataTask(with: request) { (data, response, err) in
            do {
                let json = try JSONDecoder().decode(tagInstances.self, from: data ?? Data())
                DispatchQueue.main.async {
                    SignInViewController.allInstances = json.instances.sorted(by: { x, y in
                        Int(x.users ?? "0") ?? 0 > Int(y.users ?? "0") ?? 0
                    })
                    
                    if !isFromSignIn {
                        let currentInstance = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData
                        SignInViewController.allInstances = SignInViewController.allInstances.filter({ x in
                            x.name != currentInstance?.returnedText ?? ""
                        })
                    }
                    
                    SignInViewController.filteredInstances = SignInViewController.allInstances
                    do {
                        try Disk.save(SignInViewController.allInstances, to: .documents, as: "allInstances.json")
                    } catch {
                        log.error("error saving instances to Disk")
                    }
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "loadSpecificInstance"), object: nil)
                }
            } catch {
                log.error("err - \(error)")
            }
        }
        task.resume()
    }
    
    @objc func loadSpecificInstance() {
        let urlStr = "https://feature.\(GlobalHostServer())/api/v1/instances/search"
        let url: URL = URL(string: urlStr)!
        var request = URLRequest(url: url)
        var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "count", value: "15"), URLQueryItem(name: "q", value: GlobalHostServer())]
        request.url = components.url
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let task = session.dataTask(with: request) { (data, response, err) in
            do {
                let json = try JSONDecoder().decode(tagInstances.self, from: data ?? Data())
                DispatchQueue.main.async {
                    let ourInstance = json.instances.first(where: { tagInstance in
                        tagInstance.name == GlobalHostServer()
                    })
                    if let ourInstance {
                        // Remove our instance from the list of 'all instances'
                        SignInViewController.allInstances = SignInViewController.allInstances.filter({ tagInstance in
                            tagInstance.name != ourInstance.name
                        })
                        
                        // Add our instance to the top of the list
                        self.defaultInstance = [ourInstance]
                        self.loadingIndicator.stopAnimating()
                        self.tableView.reloadData()
                        do {
                            try Disk.save(self.defaultInstance, to: .documents, as: "defaultInstance.json")
                        } catch {
                            log.error("error saving defaultInstance to Disk")
                        }
                        do {
                            try Disk.save(SignInViewController.allInstances, to: .documents, as: "allInstances.json")
                        } catch {
                            log.error("error saving allInstances to Disk")
                        }
                    }
                }
            } catch {
                log.error("err - \(error)")
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.tableView.reloadData()
                }
            }
        }
        task.resume()
    }
    
    func signingInAlertController() -> UIAlertController {
        let alert = UIAlertController(title: nil, message: NSLocalizedString("signIn.toast", comment: ""), preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: .zero)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.widthAnchor.constraint(equalToConstant: 50),
            loadingIndicator.heightAnchor.constraint(equalToConstant: 50),
            loadingIndicator.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 10),
            loadingIndicator.centerYAnchor.constraint(equalTo: alert.view.centerYAnchor),
            ])
        return alert
    }
    
    func loadAccount(_ instance: String) {
        let topMost = getTopMostViewController()
        
        self.present(signingInAlertController(), animated: true, completion: nil)
        
        var serverName = instance
        if let url = URL(string: instance), let host = url.host {
            serverName = host
        }
        GlobalStruct.newInstance = InstanceData()
        GlobalStruct.newClient = Client(baseURL: "https://\(serverName)")
        let request = Clients.register(
            clientName: "Mammoth",
            redirectURI: "mammoth://addNewInstance",
            scopes: [.read, .write, .follow, .push],
            website: "https://getmammoth.app"
        )
        GlobalStruct.newClient.run(request) { (application) in
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    if application.value == nil {
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: NSLocalizedString("community.error.title", comment: "when choosing a community, an error occurse"), message: NSLocalizedString("community.error.description", comment: "when choosing a community, an error occurse"), preferredStyle: .alert)
                            let op1 = UIAlertAction(title: NSLocalizedString("generic.findOutMore", comment: ""), style: .default , handler:{ (UIAlertAction) in
                                let queryURL = URL(string: "https://joinmastodon.org")!
                                UIApplication.shared.open(queryURL, options: [.universalLinksOnly: true]) { (success) in
                                    if !success {
                                        UIApplication.shared.open(queryURL)
                                    }
                                }
                            })
                            alert.addAction(op1)
                            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
                            }))
                            if let presenter = alert.popoverPresentationController {
                                presenter.sourceView = self.view
                                presenter.sourceRect = self.view.bounds
                            }
                            self.present(alert, animated: true, completion: nil)
                        }
                    } else {
                        if let application = application.value {
                            GlobalStruct.newInstance?.clientID = application.clientID
                            GlobalStruct.newInstance?.clientSecret = application.clientSecret
                            GlobalStruct.newInstance?.returnedText = serverName
                            GlobalStruct.newInstance?.redirect = "mammoth://addNewInstance".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                            DispatchQueue.main.async {
                                let queryURL = URL(string: "https://\(serverName)/oauth/authorize?response_type=code&redirect_uri=\(GlobalStruct.newInstance!.redirect)&scope=read%20write%20follow%20push&client_id=\(application.clientID)")!
                                UIApplication.shared.open(queryURL, options: [.universalLinksOnly: true]) { (success) in
                                    if !success {
                                        self.safariVC = SFSafariViewController(url: queryURL)
                                        if self.safariVC?.isBeingPresented ?? false {} else {
                                            topMost?.present(self.safariVC!, animated: true, completion: nil)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func setupNav() {
        if !self.isFromSignIn {
            let btn0 = UIButton(type: .custom)
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
        }
    }
    
    func setupUI() {
        // categories
        let categoryButton = UIButton()
        var safe = (UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
        if self.fromPlus {
            safe = 0
        }
        if !self.isFromSignIn {
            safe = 0
        }
                
        categoryButton.frame = CGRect(x: (UIApplication.shared.windows.first?.safeAreaInsets.left ?? 0) + 13, y: (self.navigationController?.navigationBar.bounds.height ?? 0) + 10 + safe, width: self.view.bounds.width - 40, height: 50)
        
        let attachment1 = NSTextAttachment()
        let symbolConfig1 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .medium)
        let downImage1 = UIImage(systemName: "chevron.down", withConfiguration: symbolConfig1) ?? UIImage()
        attachment1.image = downImage1.withTintColor(.custom.softContrast, renderingMode: .alwaysOriginal)
        let attStringNewLine000 = NSMutableAttributedString()
        let attStringNewLine00 = NSMutableAttributedString(string: NSLocalizedString("communities.popular.title", comment: "") + " ", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16, weight: .semibold), NSAttributedString.Key.foregroundColor : UIColor.custom.highContrast])
        let attStringNewLine002 = NSMutableAttributedString(string: "  ", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16, weight: .semibold), NSAttributedString.Key.foregroundColor : UIColor.custom.highContrast])
        let attString00 = NSAttributedString(attachment: attachment1)
        attStringNewLine000.append(attStringNewLine00)
        attStringNewLine000.append(attString00)
        attStringNewLine000.append(attStringNewLine002)
        categoryButton.setAttributedTitle(attStringNewLine000, for: .normal)
        
        categoryButton.sizeToFit()
        categoryButton.backgroundColor = .custom.background
        self.view.addSubview(categoryButton)
        
        let popular = NSLocalizedString("communities.popular", comment: "")
        // TODO: localize all of these strings...
        let items = ["Academia", "Activism", "Anime", "Art", "Books", "Food", "Games", "Humor", "Journalism", "LGBT", "Music", "Sports", "Tech"]
        let itemsImages = ["books.vertical.fill", "figure.wave.circle.fill", "tv.fill", "paintbrush.pointed.fill", "book.fill", "fork.knife", "gamecontroller.fill", "theatermasks.fill", "newspaper.fill", "sparkles", "music.note", "sportscourt.fill", "desktopcomputer"]
        let option1 = UIAction(title: popular, image: UIImage(systemName: "star.fill"), identifier: nil) { [weak self] _ in
            guard let self else { return }
            SignInViewController.filteredInstances = SignInViewController.allInstances
            self.tableView.reloadData()
            
            let attStringNewLine000 = NSMutableAttributedString()
            let attStringNewLine00 = NSMutableAttributedString(string: NSLocalizedString("communities.popular.title", comment: "") + " ", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16, weight: .semibold), NSAttributedString.Key.foregroundColor : UIColor.custom.highContrast])
            attStringNewLine000.append(attStringNewLine00)
            attStringNewLine000.append(attString00)
            attStringNewLine000.append(attStringNewLine002)
            categoryButton.setAttributedTitle(attStringNewLine000, for: .normal)
            categoryButton.sizeToFit()
        }
        option1.accessibilityLabel = popular
        var optionItems: [UIAction] = []
        _ = items.enumerated().map({ (c,z) in
            let option2 = UIAction(title: "\(z)", image: UIImage(systemName: itemsImages[c]), identifier: nil) { [weak self] _ in
                guard let self else { return }
                SignInViewController.filteredInstances = SignInViewController.allInstances
                SignInViewController.filteredInstances = SignInViewController.filteredInstances.filter({ x in
                    x.info?.categories?.contains("\(z.lowercased())") ?? false
                })
                self.tableView.reloadData()
                
                let attStringNewLine000 = NSMutableAttributedString()
                let attStringNewLine00 = NSMutableAttributedString(string: String.localizedStringWithFormat(NSLocalizedString("communities.generic.title", comment: "Example: 'Activism Communities', as in 'Communities of Activism'"), z) + " ", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16, weight: .semibold), NSAttributedString.Key.foregroundColor : UIColor.custom.highContrast])
                attStringNewLine000.append(attStringNewLine00)
                attStringNewLine000.append(attString00)
                attStringNewLine000.append(attStringNewLine002)
                categoryButton.setAttributedTitle(attStringNewLine000, for: .normal)
                categoryButton.sizeToFit()
            }
            option2.accessibilityLabel = "\(z)"
            optionItems.append(option2)
        })
        let menu = UIMenu(title: "", image: UIImage(systemName: "square"), identifier: nil, options: [], children: [option1] + optionItems)
        categoryButton.menu = menu
        categoryButton.showsMenuAsPrimaryAction = true
        
        // text field
        let name_or_url = NSLocalizedString("communities.nameOrUrl", comment: "")
        textField.backgroundColor = .custom.OVRLYSoftContrast
        textField.borderStyle = .none
        textField.layer.cornerRadius = 10
        textField.layer.cornerCurve = .continuous
        textField.textColor = UIColor.label
        textField.spellCheckingType = .no
        textField.returnKeyType = .done
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .URL
        textField.delegate = self
        textField.attributedPlaceholder = NSAttributedString(string: name_or_url + "...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.custom.feintContrast])
        textField.accessibilityLabel = name_or_url
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.view.addSubview(textField)
        
        self.topBorder.backgroundColor = UIColor.custom.outlines.cgColor
        self.view.layer.addSublayer(self.topBorder)
    }
    
    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField.text ?? "" == "" {
            SignInViewController.filteredInstances = SignInViewController.allInstances
            self.tableView.reloadData()
        } else {
            SignInViewController.filteredInstances = SignInViewController.allInstances
            SignInViewController.filteredInstances = SignInViewController.filteredInstances.filter({ x in
                x.name.lowercased().contains(textField.text?.lowercased() ?? "")
            })
            self.tableView.reloadData()
        }
    }
    
    func setupTable() {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(SignInInstanceCell.self, forCellReuseIdentifier: "InstanceCellDefault")
        tableView.register(SignInInstanceCell.self, forCellReuseIdentifier: "InstanceCell")
        tableView.alpha = 1
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.layer.masksToBounds = true
        tableView.estimatedRowHeight = 89
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.cellLayoutMarginsFollowReadableWidth = true
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }
        
        view.addSubview(tableView)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if self.textField.isFirstResponder {
            self.textField.resignFirstResponder()
        }
        let returnedText = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if returnedText == "" || returnedText == " " || returnedText == "  " {} else {
            if self.isFromSignIn {
                self.loadAccount(returnedText)
            } else {
                self.loadOther(returnedText)
            }
        }
        return true
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return textField.text?.isEmpty as? Bool == true ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // if not searching
        if textField.text?.isEmpty as? Bool == true {
            if section == 0 {
                return self.defaultInstance.count
            } else {
                return SignInViewController.filteredInstances.count
            }
        } else {
            return SignInViewController.filteredInstances.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let placeholder = NSLocalizedString("communities.placeholder", comment: "")
        if indexPath.section == 0 && textField.text?.isEmpty as? Bool == true {
            let cell = tableView.dequeueReusableCell(withIdentifier: "InstanceCellDefault", for: indexPath) as! SignInInstanceCell
            
            let profileIcon = self.defaultInstance[indexPath.row].thumbnail ?? ""
            if let ur = URL(string: profileIcon) {
                cell.profileIcon.sd_setImage(with: ur, for: .normal)
            }
            
            cell.titleLabel.text = self.defaultInstance[indexPath.row].name
            
            if let shortDescription = self.defaultInstance[indexPath.row].info?.shortDescription {
                cell.bio.text = "\(shortDescription)"
            } else {
                cell.bio.text = "\(self.defaultInstance[indexPath.row].info?.categories?.first ?? placeholder)"
            }
            
            let users = Int(self.defaultInstance[indexPath.row].users ?? "0")?.formatUsingAbbrevation() ?? "0"
            let attachment1 = NSTextAttachment()
            let downImage1 = FontAwesome.image(fromChar: "\u{f007}", color: .custom.feintContrast, size: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular).withRenderingMode(.alwaysTemplate)
            attachment1.image = downImage1.withTintColor(UIColor.custom.feintContrast, renderingMode: .alwaysTemplate)
            
            let attStringNewLine000 = NSMutableAttributedString()
            let attStringNewLine00 = NSMutableAttributedString(string: " \(users)", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular), NSAttributedString.Key.foregroundColor : UIColor.custom.feintContrast])
            let attString00 = NSAttributedString(attachment: attachment1)
            attStringNewLine000.append(attString00)
            attStringNewLine000.addAttribute(.baselineOffset, value: -3, range: .init(location: 0, length: 1))
            attStringNewLine000.append(attStringNewLine00)
                        
            cell.users.attributedText = attStringNewLine000
            
            let lang = (self.defaultInstance[indexPath.row].info?.languages?.first ?? "EN").uppercased()
            let attachment2 = NSTextAttachment()
            let downImage2 = FontAwesome.image(fromChar: "\u{f0ac}", color: .custom.feintContrast, size: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular).withRenderingMode(.alwaysTemplate)
            attachment2.image = downImage2.withTintColor(UIColor.custom.feintContrast, renderingMode: .alwaysTemplate)

            let attStringNewLine0002 = NSMutableAttributedString()
            let attStringNewLine002 = NSMutableAttributedString(string: " \(lang)", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular), NSAttributedString.Key.foregroundColor : UIColor.custom.feintContrast])
            let attString002 = NSAttributedString(attachment: attachment2)
            attStringNewLine0002.append(attString002)
            attStringNewLine0002.addAttribute(.baselineOffset, value: -3, range: .init(location: 0, length: 1))
            attStringNewLine0002.append(attStringNewLine002)
            cell.lang.attributedText = attStringNewLine0002
            
            if (self.defaultInstance[indexPath.row].info?.prohibitedContent ?? []).contains("nudity_nocw") || (self.defaultInstance[indexPath.row].info?.prohibitedContent ?? []).contains("pornography_nocw") {
                cell.sfw.isHidden = false
            } else {
                cell.sfw.isHidden = true
            }
            
            cell.backgroundColor = .custom.background
            let bgColorView = UIView()
            bgColorView.backgroundColor = UIColor.clear
            cell.selectedBackgroundView = bgColorView
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "InstanceCell", for: indexPath) as! SignInInstanceCell
            
            let profileIcon = SignInViewController.filteredInstances[indexPath.row].thumbnail ?? ""
            if let ur = URL(string: profileIcon) {
                cell.profileIcon.sd_setImage(with: ur, for: .normal)
            }
            
            cell.titleLabel.text = SignInViewController.filteredInstances[indexPath.row].name
            
            if let shortDescription = SignInViewController.filteredInstances[indexPath.row].info?.shortDescription {
                cell.bio.text = "\(shortDescription)"
            } else {
                cell.bio.text = "\(SignInViewController.filteredInstances[indexPath.row].info?.categories?.first ?? placeholder)"
            }
            
            let users = Int(SignInViewController.filteredInstances[indexPath.row].users ?? "0")?.formatUsingAbbrevation() ?? "0"
            let attachment1 = NSTextAttachment()
            let downImage1 = FontAwesome.image(fromChar: "\u{f007}", color: .custom.feintContrast, size: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular).withRenderingMode(.alwaysTemplate)
            attachment1.image = downImage1.withTintColor(UIColor.custom.feintContrast, renderingMode: .alwaysTemplate)
            let attStringNewLine000 = NSMutableAttributedString()
            let attStringNewLine00 = NSMutableAttributedString(string: " \(users)", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular), NSAttributedString.Key.foregroundColor : UIColor.custom.feintContrast])
            let attString00 = NSAttributedString(attachment: attachment1)
            attStringNewLine000.append(attString00)
            attStringNewLine000.addAttribute(.baselineOffset, value: -3, range: .init(location: 0, length: 1))
            attStringNewLine000.append(attStringNewLine00)
            cell.users.attributedText = attStringNewLine000
            
            let lang = (SignInViewController.filteredInstances[indexPath.row].info?.languages?.first ?? "EN").uppercased()
            let attachment2 = NSTextAttachment()
            let downImage2 = FontAwesome.image(fromChar: "\u{f0ac}", color: .custom.feintContrast, size: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular).withRenderingMode(.alwaysTemplate)
            attachment2.image = downImage2.withTintColor(UIColor.custom.feintContrast, renderingMode: .alwaysTemplate)
            let attStringNewLine0002 = NSMutableAttributedString()
            let attStringNewLine002 = NSMutableAttributedString(string: " \(lang)", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular), NSAttributedString.Key.foregroundColor : UIColor.custom.feintContrast])
            let attString002 = NSAttributedString(attachment: attachment2)
            attStringNewLine0002.append(attString002)
            attStringNewLine0002.addAttribute(.baselineOffset, value: -3, range: .init(location: 0, length: 1))
            attStringNewLine0002.append(attStringNewLine002)
            cell.lang.attributedText = attStringNewLine0002
            
            // Safe For Work label is applied when the instance prohibates all nudity or pronography
            if (SignInViewController.filteredInstances[indexPath.row].info?.prohibitedContent ?? []).contains("nudity_all") || (SignInViewController.filteredInstances[indexPath.row].info?.prohibitedContent ?? []).contains("pornography_all") {
                cell.sfw.isHidden = false
            } else {
                cell.sfw.isHidden = true
            }
            
            cell.backgroundColor = .custom.background
            let bgColorView = UIView()
            bgColorView.backgroundColor = UIColor.clear
            cell.selectedBackgroundView = bgColorView
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        triggerHapticSelectionChanged()
        self.tableView.deselectRow(at: indexPath, animated: true)
        if self.textField.isFirstResponder {
            self.textField.resignFirstResponder()
        }
        if indexPath.section == 0 && textField.text?.isEmpty as? Bool == true {
            if self.isFromSignIn {
                self.loadAccount(self.defaultInstance[indexPath.row].name)
            } else {
                self.loadOther(self.defaultInstance[indexPath.row].name)
            }
        } else {
            if self.isFromSignIn {
                self.loadAccount(SignInViewController.filteredInstances[indexPath.row].name)
            } else {
                self.loadOther(SignInViewController.filteredInstances[indexPath.row].name)
            }
        }
    }
    
    @objc func newInstanceLogged() {
        self.safariVC?.dismiss(animated: true, completion: nil)
        
        let alert = signingInAlertController()
        self.present(alert, animated: true) {
            // Only call this after the alert has been presented; otherwise, this
            // view controller may disappear during the animation, causing problems.
            AccountsManager.shared.addExistingMastodonAccount(instanceData: GlobalStruct.newInstance!, client: GlobalStruct.newClient) { [weak self] error, acctData in
                guard let self else { return }
                
                // Channels don't work if logged in account is not copied to moth.social.
                // To fix this, we ping `v4/timelines/for_you/me` after login.
                // This will trigger the right backend event to copy the user's account to moth.social.
                Task {
                    if case .Mastodon = acctData?.acctType {
                        do {
                            let _ = try await TimelineService.forYouMe(remoteFullOriginalAcct: acctData!.remoteFullOriginalAcct)
                        } catch {}
                    }
                    
                    
                    await MainActor.run {
                        if error == nil {
                            alert.dismiss(animated: false)
                            // User is successfullly signed in. Present them with the
                            // option to subscribe to a smart list.

                            // Give these a chance to preload
                            SetupChannelsViewModel.preload()
                            SetupAccountsViewModel.preload()
                            SetupMammothViewModel.preload()

                            let vc = SetupChannelsViewController()
                            self.navigationController?.pushViewController(vc, animated: true)
                        } else {
                            alert.dismiss(animated: false) {
                                let alert = UIAlertController(title: NSLocalizedString("error.signIn", comment: ""), message: "\(error?.localizedDescription ?? "")", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
                                }))
                                getTopMostViewController()?.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
            
        }
    }
    
    func loadOther(_ instance: String) {
        let vc = NewsFeedViewController(type: .community(instance))
        if vc.isBeingPresented {} else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}
