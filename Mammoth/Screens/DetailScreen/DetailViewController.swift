//
//  DetailViewController.swift
//  Mammoth
//
//  Created by Benoit Nolens on 05/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import StoreKit

class DetailViewController: UIViewController {
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        PostCardCell.registerForReuseIdentifierVariants(on: tableView)
        tableView.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
        tableView.register(ErrorCell.self, forCellReuseIdentifier: ErrorCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .custom.background
        tableView.separatorStyle = .none
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.tableHeaderView = UIView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delaysContentTouches = false
        return tableView
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(self.onDragToRefresh(_:)), for: .valueChanged)
        return refresh
    }()
    
    private let scrollUpIndicator = ScrollUpIndicator()
    private var viewModel: DetailViewModel
    private var initialized = false
    private var shouldScrollToReplies: Bool
    
    required init(viewModel: DetailViewModel, scrollToReplies: Bool = false) {
        self.viewModel = viewModel
        self.shouldScrollToReplies = scrollToReplies
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        self.navigationItem.backButtonTitle = nil
        
        self.setupUI()
    }
    
    convenience init(post: PostCardModel, showStatusSource: Bool = false, scrollToReplies: Bool = false) {
        let viewModel = DetailViewModel(post: post, showStatusSource: showStatusSource)
        self.init(viewModel: viewModel, scrollToReplies: scrollToReplies)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setRightBarButtonItems(self.createNavBarButtons(), animated: false)
        
        let gestureScrollUp = UITapGestureRecognizer(target: self, action: #selector(self.onScrollUpTapped))
        self.scrollUpIndicator.addGestureRecognizer(gestureScrollUp)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Update the appearance of the navbar
        configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Only pause on tab change
        if !animated {
            self.viewModel.post.videoPlayer?.pause()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // review prompt
        if GlobalStruct.reviewPrompt {
            GlobalStruct.reviewCount += 1
            if GlobalStruct.reviewCount % 14 == 0 {
                let infoDictionaryKey = kCFBundleVersionKey as String
                if let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String {
                    let lastVersionPromptedForReview = UserDefaults.standard.string(forKey: "lastVersionPromptedForReviewKey")
                    if currentVersion != lastVersionPromptedForReview {
                        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                            DispatchQueue.main.async {
                                SKStoreReviewController.requestReview(in: scene)
                            }
                        }
                        UserDefaults.standard.set(currentVersion, forKey: "lastVersionPromptedForReviewKey")
                    }
                }
            }
        }
    }
    
    func setupUI() {
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.scrollUpIndicator)
        self.tableView.refreshControl = self.refreshControl
        
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            
            self.scrollUpIndicator.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -13),
            self.scrollUpIndicator.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 13),
        ])
    }
    
    private func createNavBarButtons() -> [UIBarButtonItem] {
        // Create nav button
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 19, weight: .regular)
        let btn = UIButton(type: .custom)
        btn.setImage(FontAwesome.image(fromChar: "\u{e10a}").withConfiguration(symbolConfig).withTintColor(.custom.highContrast, renderingMode: .alwaysTemplate), for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btn.accessibilityLabel = NSLocalizedString("generic.more", comment: "")
        btn.imageEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: -1, right: 0)
        
        // Create context menu
        let view_in_browser = NSLocalizedString("post.viewInBrowser", comment: "")
        var contextMenuOptions: [UIAction] = []
        let option0 = UIAction(title: view_in_browser, image: PostCardButtonType.viewInBrowser.icon(symbolConfig: postCardSymbolConfig), identifier: nil) { [weak self] _ in
            guard let self else { return }
            PostActions.onViewInBrowser(postCard: self.viewModel.post)
        }
        option0.accessibilityLabel = view_in_browser
        contextMenuOptions.append(option0)
        
        let translate_post = NSLocalizedString("post.translatePost", comment: "")
        let option1 = UIAction(title: translate_post, image: PostCardButtonType.translate.icon(symbolConfig: postCardSymbolConfig), identifier: nil) { [weak self] _ in
            guard let self else { return }
            PostActions.onTranslate(target: self, postCard: self.viewModel.post)
        }
        option1.accessibilityLabel = translate_post
        contextMenuOptions.append(option1)
        
        let share_post = NSLocalizedString("post.sharePost", comment: "")
        let option2 = UIAction(title: share_post, image: PostCardButtonType.share.icon(symbolConfig: postCardSymbolConfig), identifier: nil) { [weak self] _ in
            guard let self else { return }
            PostActions.onShare(target: self, postCard: self.viewModel.post)
        }
        option2.accessibilityLabel = share_post
        contextMenuOptions.append(option2)
        
        
        let itemMenu = UIMenu(title: "", options: [], children: contextMenuOptions)
        btn.menu = itemMenu
        btn.showsMenuAsPrimaryAction = true
        let moreButton = UIBarButtonItem(customView: btn)

        return [moreButton]
    }
    
    @objc private func onDragToRefresh(_ sender: Any) {
        Sound().playSound(named: "soundSuction", withVolume: 0.6)
        Task { [weak self] in
            guard let self else { return }
            try await self.viewModel.refreshData()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    @objc private func onScrollUpTapped() {
        self.tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate
extension DetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? PostCardCell {
            cell.willDisplay()
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? PostCardCell {
            cell.didEndDisplay()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(forSection: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = DetailViewModel.Section(rawValue: indexPath.section)
        let model = viewModel.getInfo(forIndexPath: indexPath)
        let hasParent = viewModel.hasParent(indexPath: indexPath)
        let hasChild = viewModel.hasChild(indexPath: indexPath)
        
        switch section {
            
        case .parents:
            if let postCard = model {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: postCard, cellType: .parent), for: indexPath) as! PostCardCell
                cell.configure(postCard: postCard, type: .parent, hasParent: hasParent, hasChild: hasChild) { [weak self] (type, isActive, data) in
                    guard let self else { return }
                    PostActions.onActionPress(target: self, type: type, isActive: isActive, postCard: postCard, data: data)
                }
                return cell
            }
            
        case .post:
            if let postCard = model {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: postCard, cellType: .detail), for: indexPath) as! PostCardCell
                cell.configure(postCard: postCard, type: .detail, hasParent: hasParent || postCard.isAReply, hasChild: hasChild || postCard.hasReplies) { [weak self] (type, isActive, data) in
                    guard let self else { return }
                    
                    if type == .replies && postCard.hasReplies {
                        let repliesHeight = self.tableView.rect(forSection: DetailViewModel.Section.replies.rawValue).size.height
                        let boundsHeight = self.tableView.bounds.size.height
                        let safeAreaInsets = self.view.safeAreaInsets
                        let spacerHeight = max(0, boundsHeight - repliesHeight - safeAreaInsets.top - safeAreaInsets.bottom)
                        self.tableView.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: self.tableView.bounds.size.width, height: spacerHeight))
                        if self.tableView.numberOfRows(inSection: DetailViewModel.Section.replies.rawValue) > 0 {
                            self.tableView.scrollToRow(at: IndexPath(row: 0, section: DetailViewModel.Section.replies.rawValue), at: .top, animated: true)
                        }
                    } else {
                        PostActions.onActionPress(target: self, type: type, isActive: isActive, postCard: postCard, data: data)
                        
                        if [.profile, .deletePost, .link, .mention, .message, .muteForever, .muteOneDay, .postDetails, .quote, .viewInBrowser, .reply].contains(type) {
                            self.viewModel.post.videoPlayer?.pause()
                        }
                    }
                }
                
                return cell
            }
            
        case .replies:
            
            // Display loader cell in last row if needed
            if viewModel.shouldDisplayLoader() && indexPath.row == viewModel.numberOfItems(forSection: indexPath.section) - 1 {
                if let cell = self.tableView.dequeueReusableCell(withIdentifier: LoadingCell.reuseIdentifier, for: indexPath) as? LoadingCell {
                    cell.startAnimation()
                    return cell
                }
            }
            
            // Display error cell in last row if needed
            if viewModel.shouldDisplayError() && indexPath.row == viewModel.numberOfItems(forSection: indexPath.section) - 1 {
                if let cell = self.tableView.dequeueReusableCell(withIdentifier: ErrorCell.reuseIdentifier, for: indexPath) as? ErrorCell {
                    return cell
                }
            }
            
            if let postCard = model {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: postCard, cellType: .reply), for: indexPath) as! PostCardCell
                cell.configure(postCard: postCard, type: .reply, hasParent: hasParent, hasChild: hasChild) { [weak self] (type, isActive, data) in
                    guard let self else { return }
                    PostActions.onActionPress(target: self, type: type, isActive: isActive, postCard: postCard, data: data)
                    
                    if [.profile, .deletePost, .link, .mention, .message, .muteForever, .muteOneDay, .postDetails, .quote, .viewInBrowser, .reply].contains(type) {
                        self.viewModel.post.videoPlayer?.pause()
                    }
                }
                
                return cell
            }
        default:
            break
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = DetailViewModel.Section(rawValue: indexPath.section), section != .post else {
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            return
        }
        
        if let model = viewModel.getInfo(forIndexPath: indexPath) {
            self.viewModel.post.videoPlayer?.pause()
            
            let vc = DetailViewController(post: model)
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        self.viewModel.dismissScrollUpIndicator()
        self.scrollUpIndicator.isEnabled = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.scrollUpIndicator.isEnabled {
            let postRect = self.tableView.rect(forSection: DetailViewModel.Section.post.rawValue)
            let safeAreaInset = self.view.safeAreaInsets.top
            let threshold = 50.0
            if (scrollView.contentOffset.y + safeAreaInset) < (postRect.origin.y - threshold) {
                self.viewModel.dismissScrollUpIndicator()
                self.scrollUpIndicator.isEnabled = false
            }
        }
    }
}

extension DetailViewController: RequestDelegate {
    func didUpdate(with state: ViewState) {
        switch state {
        case .idle:
            break
        case .loading:
            self.tableView.reloadData()
            break
        case .success:
            UIView.setAnimationsEnabled(false)
            self.tableView.reloadData()
            
            // keep position of main post when context is loaded (only the first time)
            if !self.initialized {
                self.initialized = true
                
                let postHeight = self.tableView.rect(forSection: DetailViewModel.Section.post.rawValue).size.height
                let repliesHeight = self.tableView.rect(forSection: DetailViewModel.Section.replies.rawValue).size.height
                let boundsHeight = self.tableView.bounds.size.height
                let safeAreaInsets = self.view.safeAreaInsets
                let spacerHeight = max(0, boundsHeight - postHeight - repliesHeight - safeAreaInsets.top - safeAreaInsets.bottom)
                self.tableView.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: self.tableView.bounds.size.width, height: spacerHeight))
                
                // only keep scroll position if user didn't already scroll
                if self.tableView.contentOffset.y == 0 - self.view.safeAreaInsets.top {
                    if self.tableView.numberOfRows(inSection: DetailViewModel.Section.post.rawValue) > 0 {
                        self.tableView.scrollToRow(at: IndexPath(row: 0, section: DetailViewModel.Section.post.rawValue), at: .top, animated: false)
                    }
                }
            }
            
            UIView.setAnimationsEnabled(true)
            self.tableView.flashScrollIndicators()
            
            self.scrollUpIndicator.isEnabled = self.viewModel.shouldShowScrollUpIndicator()
            
            if self.shouldScrollToReplies {
                self.shouldScrollToReplies = false
                if self.tableView.contentOffset.y == 0 - self.view.safeAreaInsets.top {
                    if self.tableView.numberOfRows(inSection: DetailViewModel.Section.post.rawValue) > 0 {
                        self.tableView.scrollToRow(at: IndexPath(row: 0, section: DetailViewModel.Section.replies.rawValue), at: .top, animated: true)
                    }
                }
            }
            
            break
        case .error(let error):
            log.error("Error on DetailViewController didUpdate: \(state) - \(error)")
            self.tableView.reloadData()
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
            break
        }
    }
    
    func didUpdateCard(at indexPath: IndexPath) {
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func didDeleteCard(at indexPath: IndexPath) {
        let section = DetailViewModel.Section(rawValue: indexPath.section)
        if section != .post {
            self.tableView.deleteRows(at: [indexPath], with: .bottom)
        }
    }
}

// MARK: UIContextMenuInteractionDelegate
extension DetailViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        if let section = DetailViewModel.Section(rawValue: indexPath.section), section == .post { return nil }

        if let postCard = viewModel.getInfo(forIndexPath: indexPath) {
            if let cell = self.tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: postCard), for: indexPath) as? PostCardCell {

                return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { nil }, actionProvider: { suggestedActions in
                    return cell.createContextMenu(postCard: postCard) { [weak self] type, isActive, data in
                        guard let self else { return }
                        PostActions.onActionPress(target: self, type: type, isActive: isActive, postCard: postCard, data: data)
                    }
                })
            }
        }
        
        return nil
    }
}

// MARK: Appearance changes
internal extension DetailViewController {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
             }
         }
    }
}

extension DetailViewController: JumpToNewest {
    @objc func jumpToNewest() {
        self.tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}
