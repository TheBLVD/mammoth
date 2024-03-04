//
//  UserListViewController.swift
//  Mammoth
//
//  Created by Benoit Nolens on 08/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class UserListViewController: UIViewController {
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(UserCardCell.self, forCellReuseIdentifier: UserCardCell.reuseIdentifier)
        tableView.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
        tableView.register(ErrorCell.self, forCellReuseIdentifier: ErrorCell.reuseIdentifier)
        tableView.register(EmptyFeedCell.self, forCellReuseIdentifier: EmptyFeedCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        tableView.backgroundColor = .custom.background
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delaysContentTouches = false
        return tableView
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(self.onDragToRefresh(_:)), for: .valueChanged)
        return refresh
    }()
    
    private var viewModel: UserListViewModel
    private var carousel = Carousel(withContextButton: false)
    private var throttledDecelarationEndTask: Task<Void, Error>?
    
    required init(viewModel: UserListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        self.navigationItem.backButtonTitle = nil
        
        if [.likes, .reposts].contains(where: { self.viewModel.type == $0 }) {
            tableView.tableHeaderView = UIView()
            tableView.separatorStyle = .none
        }
        
        self.setupUI()
    }
    
    convenience init(type: UserListViewModel.UserListType, post: PostCardModel) {
        let viewModel = UserListViewModel(type: type, post: post)
        self.init(viewModel: viewModel)
    }
    
    convenience init(type: UserListViewModel.UserListType, user: UserCardModel) {
        let viewModel = UserListViewModel(type: type, user: user)
        self.init(viewModel: viewModel)
    }
    
    convenience init(listID: String) {
        let viewModel = UserListViewModel(listID: listID)
        self.init(viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = self.viewModel.title()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Update the appearance of the navbar
        configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
        
        if self.isModal {
            if #available(iOS 16.0, *) {
                let closeBtn = UIBarButtonItem(title: NSLocalizedString("generic.close", comment: ""), image: nil, target: self, action: #selector(self.onClosePressed))
                self.navigationItem.setLeftBarButton(closeBtn, animated: false)
            } else {}
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.throttledDecelarationEndTask?.cancel()
    }
    
    @objc func onClosePressed() {
        self.dismiss(animated: true)
    }
    
    func setupUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .top
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.backgroundColor = .custom.background
        self.view.addSubview(stack)
        
        stack.addArrangedSubview(self.tableView)
        self.view.addSubview(stack)
        self.tableView.refreshControl = self.refreshControl
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            
            tableView.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: stack.trailingAnchor)
        ])
        
        if !self.viewModel.carouselItems().isEmpty {
            self.carousel.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
            self.carousel.content = self.viewModel.carouselItems().map({ $0.title(self.viewModel.user) })
            
                
            carousel.translatesAutoresizingMaskIntoConstraints = false
            carousel.delegate = self
            stack.insertArrangedSubview(carousel, at: 0)
            
            NSLayoutConstraint.activate([
                carousel.heightAnchor.constraint(equalToConstant: 40),
                carousel.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
                carousel.trailingAnchor.constraint(equalTo: stack.trailingAnchor)
            ])
        }
    }
    
    @objc private func onDragToRefresh(_ sender: Any) {
        Sound().playSound(named: "soundSuction", withVolume: 0.6)
        Task {
            try await self.viewModel.refreshData()
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
            }
        }
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate
extension UserListViewController: UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(forSection: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                
        // Display loader cell in last row if needed
        if viewModel.shouldDisplayLoader() && indexPath.row == viewModel.numberOfItems(forSection: indexPath.section) - 1 {
            if let cell = self.tableView.dequeueReusableCell(withIdentifier: LoadingCell.reuseIdentifier, for: indexPath) as? LoadingCell {
                cell.startAnimation()
                
                // when only the loader is visible hide the separators
                if viewModel.numberOfItems(forSection: indexPath.section) == 1 {
                    self.tableView.separatorStyle = .none
                }
                return cell
            }
        }
        
        // Display error cell in last row if needed
        if viewModel.shouldDisplayError() && indexPath.row == viewModel.numberOfItems(forSection: indexPath.section) - 1 {
            if let cell = self.tableView.dequeueReusableCell(withIdentifier: ErrorCell.reuseIdentifier, for: indexPath) as? ErrorCell {
                return cell
            }
        }
        
        if viewModel.isListEmpty() {
            if let cell = self.tableView.dequeueReusableCell(withIdentifier: EmptyFeedCell.reuseIdentifier, for: indexPath) as? EmptyFeedCell {
                cell.configure()
                self.tableView.separatorStyle = .none
                return cell
            }
        }
        
        let model = viewModel.getInfo(forIndexPath: indexPath)
        let cell = self.tableView.dequeueReusableCell(withIdentifier: UserCardCell.reuseIdentifier, for: indexPath) as! UserCardCell
        
        if let userCard = model {
            if self.viewModel.actionButtonType() == .follow && userCard.followStatus != .unknown {
                userCard.forceFollowButtonDisplay = true
            }
            cell.configure(info: userCard, actionButtonType: self.viewModel.actionButtonType()) { [weak self] (type, isActive, data) in
                guard let self else { return }
                
                switch type {
                case .addToList:
                    if let listID = self.viewModel.listID {
                        PostActions.onActionPress(target: self, type: type, isActive: isActive, userCard: userCard, data: .list(listID))
                    }
                case .removeFromList:
                    if let listID = self.viewModel.listID {
                        PostActions.onActionPress(target: self, type: type, isActive: isActive, userCard: userCard, data: .list(listID))
                    }
                default:
                    PostActions.onActionPress(target: self, type: type, isActive: isActive, userCard: userCard, data: data)
                }
            }
            
            if [.followers, .following, .listMembers].contains(where: { self.viewModel.type == $0 }) {
                self.tableView.separatorStyle = .singleLine
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let userCard = viewModel.getInfo(forIndexPath: indexPath) {
            let vc = ProfileViewController(user: userCard, screenType: userCard.isSelf ? .own : .others)
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if viewModel.shouldFetchNext(prefetchRowsAt: indexPaths) {
            self.viewModel.ongoingTask = Task {
                try await viewModel.loadList(loadNextPage: true)
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let task = self.throttledDecelarationEndTask, !task.isCancelled {
            self.throttledDecelarationEndTask?.cancel()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Fetch next again if scrolling past the last elements
        if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height - 100,
               self.viewModel.shouldFetchNext(prefetchRowsAt: [IndexPath(row: viewModel.numberOfItems(forSection: 0), section: 0)]) {
            self.viewModel.ongoingTask = Task {
                try await viewModel.loadList(loadNextPage: true)
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.throttledDecelarationEndTask = Task {
            try await Task.sleep(seconds: 1.2)
            if !Task.isCancelled {
                if let indexPaths = self.tableView.indexPathsForVisibleRows {
                    self.viewModel.syncFollowStatus(forIndexPaths: indexPaths)
                }
            }
        }
    }
}

extension UserListViewController: RequestDelegate {
    func didUpdate(with state: ViewState) {
        switch state {
        case .idle:
            break
        case .loading:
            self.tableView.reloadData()
            break
        case .success:
            self.tableView.reloadData()
            break
        case .error(let error):
            log.error("Error on UserListViewController didUpdate: \(state) - \(error)")
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
        self.tableView.deleteRows(at: [indexPath], with: .bottom)
    }
}

// MARK: Carousel delegate and helpers
extension UserListViewController: CarouselDelegate {
    
    func carouselItemPressed(withIndex index: Int) {
        let menuItems = self.viewModel.carouselItems()
        guard menuItems.count > index else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.viewModel.changeType(type: menuItems[index])
        }
    }
    
    func carouselActiveItemDoublePressed() {
        self.tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
    
    func contextMenuForItem(withIndex index: Int) -> UIMenu? {
        return nil
    }
}

// MARK: Appearance changes
internal extension UserListViewController {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
             }
         }
    }
}
