//
//  AltTextViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 10/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import Vision
import NaturalLanguage


protocol AltTextViewControllerDelegate : AnyObject {
    func didConfirmText(updatedText: String)
}


// This is used for
//      - editing image ALT text
//      - creating/editing list names
//      - creating/editing filter names

class AltTextViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SKPhotoBrowserDelegate, UITextViewDelegate {

    let btn0 = UIButton(type: .custom)
    let btn2 = UIButton(type: .custom)
    var tableView = UITableView()
    var canAdd: Bool = false
    var id: String = ""
    var keyHeight: CGFloat = 0
    var currentImage: UIImage = UIImage()
    var newList: Bool = false
    var newFilter: Bool = false
    var filterId: String = ""
    var editList: String = ""
    var listId: String = ""
    var whichImagesAltText: Int? = nil
    var theAltText: String = ""
    weak var delegate: AltTextViewControllerDelegate? = nil
    private let onClose: (() -> Void)?
    
    init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        
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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextMultiCell {
            if let x = cell1.altText.text {
                if x != "" && x != " " {
                    self.addAlt(x)
                }
            }
        }
        
        self.onClose?()
    }

    @objc func keyboardWillChange(notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) - 4
            keyHeight = CGFloat(keyboardHeight)
        }
    }

    func addAlt(_ altText: String) {
        if self.editList != "" {
            ListManager.shared.updateListTitle(self.listId, title: altText) { success in
                if success {
                    self.delegate?.didConfirmText(updatedText: altText)
                }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchLists"), object: nil)
                }
            }
        } else {
            if self.newList {
                ListManager.shared.addList(altText) { success in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchLists"), object: nil)
                }
            } else {
                if self.newFilter {
                    let request = FilterPosts.addKeyword(id: self.filterId, keyword: altText)
                    AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
                        if let _ = (statuses.value) {
                            DispatchQueue.main.async {
                                print("added keyword")
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchFilters"), object: nil)
                            }
                        }
                    }
                } else {
                    GlobalStruct.mediaEditID = self.id
                    GlobalStruct.mediaEditDescription = altText
                    let request = Media.updateDescription(description: altText, id: self.id)
                    AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
                        DispatchQueue.main.async {
                            GlobalStruct.whichImagesAltText.append(self.whichImagesAltText ?? 0)
                            GlobalStruct.altAdded[self.whichImagesAltText ?? 0] = altText
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "updatePostButton"), object: nil)
                            print("added description")
                        }
                    }
                }
            }
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
            
            for cell in self.tableView.visibleCells {
                if let cell = cell as? AltTextMultiCell {
                    cell.backgroundColor = .custom.backgroundTint
                }
            }
        }
    }

    override var keyCommands: [UIKeyCommand]? {
        let closeWindow = UIKeyCommand(input: "w", modifierFlags: [.command], action: #selector(dismissTap))
        closeWindow.discoverabilityTitle = NSLocalizedString("generic.dismiss", comment: "")
        if #available(iOS 15, *) {
            closeWindow.wantsPriorityOverSystemBehavior = true
        }
        return [closeWindow]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .custom.backgroundTint
        
        if self.editList != "" {
            self.navigationItem.title = NSLocalizedString("list.edit", comment: "")
        } else {
            if self.newList {
                self.navigationItem.title = NSLocalizedString("title.newList", comment: "")
            } else {
                if self.newFilter {
                    self.navigationItem.title = NSLocalizedString("filters.keywords.add", comment: "")
                } else {
                    self.navigationItem.title = NSLocalizedString("composer.alt", comment: "")
                }
            }
        }

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
        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }

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

        btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
        btn2.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        btn2.layer.cornerRadius = 14
        btn2.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        btn2.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        btn2.addTarget(self, action: #selector(self.addTap), for: .touchUpInside)
        btn2.accessibilityLabel = "Add Image Description"
        let moreButton1 = UIBarButtonItem(customView: btn2)
        self.navigationItem.setRightBarButton(moreButton1, animated: true)

        // set up table
        setupTable()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextMultiCell {
            cell1.charCount.text = "1000"
            if self.theAltText != "" {
                cell1.charCount.text = "\(1000 - self.theAltText.count)"
                // Resize the cell now that is has data
                tableView.beginUpdates()
                tableView.endUpdates()
            }
            cell1.altText.becomeFirstResponder()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextMultiCell {
            cell1.altText.resignFirstResponder()
        }
    }

    @objc func addTap() {
        if canAdd {
            // add alt text
            triggerHapticImpact(style: .light)
            self.dismiss(animated: true, completion: nil)
        }
    }

    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        self.dismiss(animated: true, completion: nil)
    }

    func setupTable() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(AltTextMultiCell.self, forCellReuseIdentifier: "AltTextMultiCell")
        tableView.register(ImagePreviewCell.self, forCellReuseIdentifier: "ImagePreviewCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
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

    func numberOfSections(in tableView: UITableView) -> Int {
        if self.editList != "" {
            return 1
        } else {
            if self.newList {
                return 1
            } else {
                if self.newFilter {
                    return 1
                } else {
                    return 3
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.editList != "" {
            // Editing an existing list name
            let cell = tableView.dequeueReusableCell(withIdentifier: "AltTextMultiCell", for: indexPath) as! AltTextMultiCell
            
            cell.altText.placeholder = NSLocalizedString("list.editTitle.placehoder", comment: "")
            cell.altText.accessibilityLabel = NSLocalizedString("list.editTitle.placehoder", comment: "")
            cell.altText.delegate = self
            cell.altText.text = self.editList
            
            cell.altText.tag = indexPath.section
            
            cell.separatorInset = .zero
            let bgColorView = UIView()
            bgColorView.backgroundColor = .clear
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            return cell
        } else {
            if self.newList {
                // Creating a new list name
                let cell = tableView.dequeueReusableCell(withIdentifier: "AltTextMultiCell", for: indexPath) as! AltTextMultiCell
                
                cell.altText.placeholder = NSLocalizedString("list.new.placeholder", comment: "")
                cell.altText.accessibilityLabel = NSLocalizedString("list.new.placeholder", comment: "")
                cell.altText.delegate = self
                
                cell.altText.tag = indexPath.section
                
                cell.separatorInset = .zero
                let bgColorView = UIView()
                bgColorView.backgroundColor = .clear
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                return cell
            } else {
                if self.newFilter {
                    // Creating a new filter
                    let cell = tableView.dequeueReusableCell(withIdentifier: "AltTextMultiCell", for: indexPath) as! AltTextMultiCell
                    
                    cell.altText.placeholder = NSLocalizedString("filters.keywords.placeholder", comment: "")
                    cell.altText.accessibilityLabel = NSLocalizedString("filters.keywords.placeholder", comment: "")
                    cell.altText.delegate = self
                    
                    cell.altText.tag = indexPath.section
                    
                    cell.separatorInset = .zero
                    let bgColorView = UIView()
                    bgColorView.backgroundColor = .clear
                    cell.selectedBackgroundView = bgColorView
                    cell.backgroundColor = .custom.quoteTint
                    return cell
                } else {
                    // Editing an image's Alt text
                    if indexPath.section == 0 {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "AltTextMultiCell", for: indexPath) as! AltTextMultiCell
                        
                        cell.altText.placeholder = NSLocalizedString("composer.alt.placeholder", comment: "")
                        cell.altText.accessibilityLabel = NSLocalizedString("composer.alt.placeholder", comment: "")
                        cell.altText.delegate = self
                        
                        cell.altText.tag = indexPath.section
                        cell.altText.clipsToBounds = false
                        
                        cell.separatorInset = .zero
                        let bgColorView = UIView()
                        bgColorView.backgroundColor = .clear
                        cell.selectedBackgroundView = bgColorView
                        cell.backgroundColor = .custom.quoteTint
                        
                        cell.altText.text = self.theAltText
                        return cell
                    } else if indexPath.section == 1 {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "ImagePreviewCell", for: indexPath) as! ImagePreviewCell
                        
                        cell.image.image = self.currentImage
                        
                        cell.separatorInset = .zero
                        let bgColorView = UIView()
                        bgColorView.backgroundColor = .clear
                        cell.selectedBackgroundView = bgColorView
                        cell.backgroundColor = .custom.quoteTint
                        return cell
                    } else {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
                        
                        cell.textLabel?.text = NSLocalizedString("composer.alt.detect", comment: "")
                        cell.textLabel?.textColor = UIColor.label
                        cell.textLabel?.textAlignment = .center
                        cell.textLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
                        
                        cell.separatorInset = .zero
                        let bgColorView = UIView()
                        bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
                        cell.selectedBackgroundView = bgColorView
                        cell.backgroundColor = .custom.quoteTint
                        return cell
                    }
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            var images = [SKPhoto]()
            if let cell = self.tableView.cellForRow(at: indexPath) as? ImagePreviewCell {
                if let originImage = cell.image.image {
                    let photo = SKPhoto.photoWithImage(self.currentImage)
                    photo.shouldCachePhotoURLImage = true
                    images.append(photo)
                    let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: cell.image, imageText: "", imageText2: 0, imageText3: 0, imageText4: "")
                    browser.delegate = self
                    SKPhotoBrowserOptions.enableSingleTapDismiss = false
                    SKPhotoBrowserOptions.displayCounterLabel = false
                    SKPhotoBrowserOptions.displayBackAndForwardButton = false
                    SKPhotoBrowserOptions.displayAction = false
                    SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
                    SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
                    SKPhotoBrowserOptions.displayCloseButton = false
                    SKPhotoBrowserOptions.displayStatusbar = false
                    browser.initializePageIndex(0)
                    getTopMostViewController()?.present(browser, animated: true, completion: {})
                }
            }
        }
        if indexPath.section == 2 {
            tableView.deselectRow(at: indexPath, animated: true)
            self.translateThis()
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        tableView.beginUpdates()

        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: textView.tag)) as? AltTextMultiCell {
            cell.charCount.text = "\(1000 - (cell.altText.text?.count ?? 0))"
        }

        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextMultiCell {
            let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
            if cell1.altText.text != "" {
                self.canAdd = true
                self.btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.custom.activeInverted, renderingMode: .alwaysOriginal), for: .normal)
                btn2.backgroundColor = .custom.active
            } else {
                self.canAdd = false
                self.btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
                btn2.backgroundColor = UIColor.label.withAlphaComponent(0.08)
            }
        }
        tableView.endUpdates()
    }

    func translateThis() {
        guard let img = self.currentImage.cgImage else {
            return
        }
        let requestHandler = VNImageRequestHandler(cgImage: img, options: [:])
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            var str: String = ""
            for observation in observations {
                let topCandidate: [VNRecognizedText] = observation.topCandidates(1)
                if let recognizedText: VNRecognizedText = topCandidate.first {
                    let mess = recognizedText.string
                    str = "\(str) \(mess)"
                }
            }
            let stat = str
            let unreserved = "-._~/?"
            let allowed = NSMutableCharacterSet.alphanumeric()
            allowed.addCharacters(in: unreserved)
            let bodyText = stat
            let unreservedChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
            let unreservedCharset = NSCharacterSet(charactersIn: unreservedChars)
            var trans = bodyText.addingPercentEncoding(withAllowedCharacters: unreservedCharset as CharacterSet)
            trans = trans!.replacingOccurrences(of: "\n\n", with: "%20")
            var detectedLang = "auto"
            if bodyText != "" || bodyText != " " {
                let temp = self.detectedLanguage(for: bodyText) ?? "auto"
                detectedLang = "\(temp.split(separator: "-").first ?? "auto")"
            }
            let urlString = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=\(detectedLang)&tl=\(GlobalStruct.langStr)&dt=t&q=\(trans!)&ie=UTF-8&oe=UTF-8"
            guard let requestUrl = URL(string:urlString) else {
                return
            }
            let request = URLRequest(url:requestUrl)
            let task = URLSession.shared.dataTask(with: request) {
                (data, response, error) in
                if error == nil, let usableData = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: usableData, options: .mutableContainers) as! [Any]
                        var translatedText = ""
                        for i in (json[0] as! [Any]) {
                            translatedText = translatedText + ((i as! [Any])[0] as? String ?? "")
                        }
                        if translatedText == "" {
                            translatedText = "No text to translate."
                        }
                        DispatchQueue.main.async { [weak self] in
                            if let cell1 = self?.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextMultiCell {
                                cell1.altText.text = translatedText
                                self?.textViewDidChange(cell1.altText)
                            }
                        }
                    } catch let error as NSError {
                        log.error(error.localizedDescription)
                    }
                }
            }
            task.resume()
        }
        request.recognitionLevel = VNRequestTextRecognitionLevel.accurate
        try? requestHandler.perform([request])
    }

    func detectedLanguage(for string: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(string)
        guard let languageCode = recognizer.dominantLanguage?.rawValue else { return nil }
        return languageCode
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            if self.newList {
                return NSLocalizedString("list.new.footer", comment: "")
            } else {
                if self.newFilter {
                    return NSLocalizedString("filters.keywords.footer", comment: "")
                } else {
                    return nil
                }
            }
        } else if section == 1 {
            return NSLocalizedString("composer.alt.footer1", comment: "")
        } else {
            return NSLocalizedString("composer.alt.footer2", comment: "")
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

}

