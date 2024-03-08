//
//  SidebarViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 29/04/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import Combine
import AuthenticationServices
import AVKit

public protocol SidebarViewControllerDelegate: AnyObject {
    func didSelect(_ index: Int)
    func viewControllerAtIndex(_ index: Int) -> UIViewController?
}

fileprivate var profileImage: UIImage? = nil
fileprivate var profileSelectedImage: UIImage? = nil
fileprivate let indexOfProfileButton: Int = 4

class SidebarViewController: UIViewController, UICollectionViewDelegate, UIPencilInteractionDelegate, ASWebAuthenticationPresentationContextProviding, ShareableViewController {
    
    public static let shared = SidebarViewController()
    
    let accountSwitcherButton = AccountSwitcherButton()
    let undoButton = UIButton()
    var collectionView: UICollectionView
    var previouslySelectedIndex: Int? = nil
    var doneOnceAppear: Bool = false
    var doneOnceList: Bool = false
    var doneOnceList2: Bool = false
    var timer = Timer()
    let counter = UIButton()
    
    var identity = CGAffineTransform.identity
    let undoBG = UIView()
    let undoTitle = UILabel()
    let undoNow = UIButton()
    var undoTimerCount: Int = 5
    var timUndo: Timer?
    let undoBG2 = UILabel()
    let undoBG3 = UILabel()
    var undoOnce: Bool = false
    var undoIm0 = UIView()
    var undoIm1 = UIButton()
    var undoImCount = 0
    var fetchPadFirstTimeCalled: Date? = nil
    var fetchPadTimer: Timer? = nil
    weak var delegate: SidebarViewControllerDelegate? = nil
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    enum Section: Int, Hashable, CaseIterable, CustomStringConvertible {
        case main, ownedlists, subscribedlists
        var description: String {
            switch self {
            case .main: return "Main"
            case .ownedlists: return "Owned Lists"
            case .subscribedlists: return "Lists"
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.undoBG.frame = CGRect(x: 15, y: UIScreen.main.bounds.height - self.view.safeAreaInsets.bottom - 66, width: 260 - 30, height: 50)
        
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        navApp.shadowColor = .clear
        self.navigationController?.setNavigationBarHidden(true, animated: false)
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
    
    @objc func reloadAllPadSidebar() {
        self.reloadAll()
    }
    
    @objc func reloadAll() {
        DispatchQueue.main.async {
            self.fetchPad()
        }
    }
    
    @objc func sidebarHighlight() {
        
    }
    
    @objc func fetchPad() {
        self.navigationItem.setLeftBarButtonItems([], animated: true)
        
        // If the app has just launched, use a timer delay before calling the refresh
        // notifications. This prevents the various view controllers from making their
        // network calls unnecessarily. (as of now, from 81 down to 54 calls)
        
        if self.fetchPadTimer != nil {
            self.fetchPadTimer!.invalidate()
            self.fetchPadTimer = nil
        }
        
        if self.fetchPadFirstTimeCalled == nil {
            self.fetchPadFirstTimeCalled = Date()
        }
        // Consider that the 'app just launched' if it's within the first 3 seconds
        let appJustLaunched = self.fetchPadFirstTimeCalled!.timeIntervalSinceNow > -3.0
        
        // If the app just launched, use the timer; otherwise, just make the call
        if appJustLaunched {
            self.fetchPadTimer = Timer.init(fire: Date(timeIntervalSinceNow: 0.1), interval: 0.0, repeats: false, block: { timer in
                self.fireFetchPadNotifications()
            })
            RunLoop.current.add(self.fetchPadTimer!, forMode: .common)
        } else {
            self.fireFetchPadNotifications()
        }
    }
    
    func fireFetchPadNotifications() {
        // fetch other timelines
        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchAllTimelinesPad"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchFilters"), object: nil)
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        self.view.translatesAutoresizingMaskIntoConstraints = false
        if let viewSuperview = self.view.superview {
            self.view.addFillConstraints(with: viewSuperview)
        } else {
            log.warning("expected to be moved to a superview")
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = ""
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationController?.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.setLeftBarButtonItems([], animated: true)
        self.navigationItem.setRightBarButtonItems([], animated: true)
        if let roundedTitleDescriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .largeTitle)
            .withDesign(.rounded)?
            .withSymbolicTraits(.traitBold) {
            self.navigationController?
                .navigationBar
                .largeTitleTextAttributes = [
                    .font: UIFont(descriptor: roundedTitleDescriptor, size: 0)
                ]
        }
        self.view.backgroundColor = .clear
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.startTimer), name: NSNotification.Name(rawValue: "startTimer"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.stopTimer), name: NSNotification.Name(rawValue: "stopTimer"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.selectItem), name: NSNotification.Name(rawValue: "selectItem"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAllPadSidebar), name: NSNotification.Name(rawValue: "reloadAllPadSidebar"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadDat), name: NSNotification.Name(rawValue: "reloadDat"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.sidebarHighlight), name: NSNotification.Name(rawValue: "sidebarHighlight"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.newPost), name: NSNotification.Name(rawValue: "newPost"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.newMessage), name: NSNotification.Name(rawValue: "newMessage"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.scrollTo), name: NSNotification.Name(rawValue: "scrollTo"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsTap), name: NSNotification.Name(rawValue: "settingsTap"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.restoreFromDrafts2), name: NSNotification.Name(rawValue: "restoreFromDrafts2"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchPad), name: NSNotification.Name(rawValue: "fetchPad"), object: nil)
        self.subscribeToShareNotifications()

        GlobalStruct.objects = [
            DiffSections(id: 1, title: "Feed", image: "\u{f015}"),
            DiffSections(id: 2, title: "Explore", image: "\u{f002}"),
            DiffSections(id: 3, title: "Activity", image: "\u{f0f3}"),
            DiffSections(id: 4, title: "Mentions", image: "\u{40}"),
            DiffSections(id: 5, title: NSLocalizedString("navigator.profile", comment: ""), image: "\u{f007}"),
        ]
        
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: true, scrollPosition: .top)

        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.isEnabled = true
        pencilInteraction.delegate = self
        self.view.addInteraction(pencilInteraction)
        
        self.fetchPad()

        self.collectionView.reloadData()
    }
    
    @objc func longPressedNB(sender: UILongPressGestureRecognizer) {
        if GlobalStruct.drafts.isEmpty {} else {
            triggerHapticImpact(style: .light)
            let vc = ScheduledPostsViewController()
            vc.drafts = GlobalStruct.drafts
            vc.fromComposeButton = true
            let nvc = UINavigationController(rootViewController: vc)
            nvc.isModalInPresentation = true
            self.present(nvc, animated: true, completion: nil)
        }
    }
    
    @objc func restoreFromDrafts2() {
        let vc = NewPostViewController()
        vc.isModalInPresentation = true
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "restoreFromDrafts"), object: nil)
        }
    }
    
    @objc func fireTimer(timer: Timer) {
        var count = (Int(self.counter.titleLabel?.text ?? "1") ?? 1) - 1
        if count < 0 {
            count = 0
        }
        self.counter.setTitle("\(count)", for: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if ToastNotificationManager.shared == nil {
            ToastNotificationManager.shared = ToastNotificationManager(hostWindow: self.view.window!)
        }
        self.startTimer()
    }
    
    @objc func stopTimer() {
        GlobalStruct.timer1.invalidate()
    }
    
    @objc func startTimer() {
        if AccountsManager.shared.allAccounts.isEmpty {} else {
            // auto-update feed
            // changing to 4 seconds as there are 4 endpoint calls happening with each timer fire
            // 300 calls allowed every 5 minutes = 1 call per second
            GlobalStruct.timer1.invalidate()
            GlobalStruct.timer1 = Timer(timeInterval: 14.0, target: self, selector: #selector(self.fireTimerAllFeeds), userInfo: [], repeats: true)
            RunLoop.current.add(GlobalStruct.timer1, forMode: .common)
        }
    }
    
    @objc func fireTimerAllFeeds(timer: Timer) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "fireTimerFeed"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "fireTimerActivity"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "fireTimerOther"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "fireTimerMessages"), object: nil)
    }
    
    func saveToDisk() {
        
    }
    func makeContextProfileMain() -> UIMenu {
        var allActions: [UIAction] = []
        for index in 0..<AccountsManager.shared.allAccounts.count {
            let im = UIImage(systemName: "person.crop.circle")
            let imV = UIImageView()
            imV.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            imV.layer.cornerRadius = 10
            imV.layer.masksToBounds = true
            let acctData = AccountsManager.shared.allAccounts[index]
            let a = acctData.avatar
            if let ur = URL(string: a) {
                imV.sd_setImage(with: ur)
            }
            let action1 = UIAction(title: "@\(AccountsManager.shared.allAccounts[index].fullAcct)", image: imV.image?.withRoundedCorners()?.resize(targetSize: CGSize(width: 20, height: 20)) ?? im, identifier: nil) { action in
                // switch account
                DispatchQueue.main.async {
                    if AccountsManager.shared.allAccounts.isEmpty {
                        
                    } else {
                        let account = AccountsManager.shared.allAccounts[index]
                        if account.uniqueID == AccountsManager.shared.currentAccount?.uniqueID {

                        } else {
                            AccountsManager.shared.switchToAccount(account)
                        }
                    }
                }
            }
            allActions.append(action1)
        }
        return UIMenu(title: "", options: [], children: allActions)
    }
    
    @objc func clearModels() {
        
    }
    
    @objc func newPost() {
        let vc = UINavigationController(rootViewController: NewPostViewController())
        vc.isModalInPresentation = true
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func newMessage() {
        let vc = NewPostViewController()
        vc.isModalInPresentation = true
        vc.fromNewDM = true
        vc.whoCanReply = .direct
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    @objc func reloadDat() {
        let selItem = self.collectionView.indexPathsForSelectedItems
        self.collectionView.reloadData()
        self.collectionView.selectItem(at: selItem?.first ?? IndexPath(item: 0, section: 0), animated: true, scrollPosition: .top)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        collectionView.collectionViewLayout = createLayout()
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(LCell.self, forCellWithReuseIdentifier: "LCell")

        view.addSubview(self.collectionView)
        view.addSubview(accountSwitcherButton)
        
        // Setup constraints
        accountSwitcherButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            accountSwitcherButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 25),
            accountSwitcherButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            accountSwitcherButton.widthAnchor.constraint(equalToConstant: 25),
            accountSwitcherButton.heightAnchor.constraint(equalToConstant: 25)
        ])
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: accountSwitcherButton.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reset() {
        self.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .top)
    }
    
    func createLayout(_ fromReload: Bool? = false) -> UICollectionViewLayout {
        var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
        config.backgroundColor = .clear
        return UICollectionViewCompositionalLayout.list(using: config)
    }
    
    @objc func scrollTo() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollToSpecific"), object: nil)
        }
    }
    
    @objc func settingsTap() {
        DispatchQueue.main.async {
            let vc = SettingsViewController()
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
    }
    
    @objc func selectItem() {
        self.collectionView.selectItem(at: IndexPath(item: GlobalStruct.sidebarItem, section: 0), animated: true, scrollPosition: .top)
        
        let x = GlobalStruct.columnsViews2[GlobalStruct.sidebarItem]
        
        let nvc = UINavigationController(rootViewController: x)
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        navApp.shadowColor = .clear
        nvc.navigationBar.standardAppearance = navApp
        nvc.navigationBar.scrollEdgeAppearance = navApp
        nvc.navigationBar.compactAppearance = navApp
        if #available(iOS 15.0, *) {
            nvc.navigationBar.compactScrollEdgeAppearance = navApp
        }
        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }
        
        GlobalStruct.currentSingleColumnViewController.viewController = nvc
        
        self.collectionView.selectItem(at: IndexPath(item: GlobalStruct.sidebarItem, section: 0), animated: true, scrollPosition: .top)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        previouslySelectedIndex = collectionView.indexPathsForSelectedItems?.first?.row
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.controlBar(didSelect: indexPath.item)
    }
    
}

extension SidebarViewController: Jumpable {
    
    func barSingleTap(didSelect index: Int) {
        delegate?.didSelect(index)

        if index == previouslySelectedIndex {
            let viewController = self.viewControllerAtIndex(index)
            if let navController = viewController?.navigationController as? UINavigationController {
                navController.popToRootViewController(animated: true)
            }
        }
        
        self.collectionView.selectItem(at: IndexPath(item: index, section: 0), animated: true, scrollPosition: .top)
    }

    func viewControllerAtIndex(_ index: Int) -> UIViewController? {
        return delegate?.viewControllerAtIndex(index)
    }
    
}

class LCell: UICollectionViewListCell {
    var cellIndex: Int = 0
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        guard var cConfig = self.contentConfiguration?.updated(for: state) as? UIListContentConfiguration else { return }
        cConfig.textProperties.colorTransformer = UIConfigurationColorTransformer { c in
            if state.isSelected || state.isHighlighted {
                return .white
            } else {
                return UIColor.label
            }
        }
        cConfig.imageProperties.tintColorTransformer = UIConfigurationColorTransformer { c in
            if state.isSelected || state.isHighlighted {
                return .custom.highContrast
            } else {
                return UIColor.label.withAlphaComponent(0.32)
            }
        }
        let item = GlobalStruct.objects[cellIndex]
        let selected = state.isSelected || state.isHighlighted
        if selected {
            cConfig.image = FontAwesome.image(fromChar: item.image, size: 22*3, weight: .bold).withRenderingMode(.alwaysTemplate)
        } else {
            cConfig.image = FontAwesome.image(fromChar: item.image, size: 22*3).withRenderingMode(.alwaysTemplate)
        }
        
        cConfig.imageProperties.maximumSize = .init(width: 26, height: 24)
        cConfig.imageProperties.reservedLayoutSize = .init(width: 38, height: 48)
        
        self.contentConfiguration = cConfig
    }
}


extension SidebarViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return GlobalStruct.objects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var content = UIListContentConfiguration.sidebarCell()
        content.textProperties.numberOfLines = 0
        content.imageProperties.reservedLayoutSize = CGSize(width: 36, height: 57)
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 0)

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LCell", for: indexPath) as? LCell
        cell!.cellIndex = indexPath.item
        cell!.contentConfiguration = content
        let bg = UIView()
        bg.layer.cornerRadius = 10
        bg.backgroundColor = .clear
        cell!.selectedBackgroundView = bg
        cell!.backgroundView = UIView()
        cell!.frame = collectionView.bounds
        cell!.layoutIfNeeded()
        
        cell!.addInteraction(UIPointerInteraction(delegate: nil))
        return cell!
    }
}

extension SidebarViewController: AppStateRestoration {
    
    public func storeUserActivity(in activity: NSUserActivity) {
        let selectedIndex = self.collectionView.indexPathsForSelectedItems?.first
        log.debug("SidebarViewController:" + #function + " selectedIndex:\(selectedIndex)")
        activity.userInfo?["SidebarViewController.selectedIndex"] = selectedIndex?.item
    }
    
    public func restoreUserActivity(from activity: NSUserActivity) {
        log.debug(#function)
        if let selectedIndex = activity.userInfo?["SidebarViewController.selectedIndex"] as? Int {
            log.debug("SidebarViewController:" + #function + " selectedIndex:\(selectedIndex)")
            let indexPath = IndexPath(item: selectedIndex, section: 0)
            self.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .top)
            self.collectionView(collectionView, didSelectItemAt: indexPath)
        }

    }
        
}
