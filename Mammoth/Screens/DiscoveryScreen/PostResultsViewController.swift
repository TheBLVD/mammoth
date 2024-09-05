//
//  PostResultsViewController.swift
//  Mammoth
//
//  Created by Riley Howard on 10/6/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class PostResultsViewController: UIViewController {
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        PostCardCell.registerForReuseIdentifierVariants(on: tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .custom.background
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .onDrag
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }
        
        return tableView
    }()

    // searchBar for the iPad aux column
    private lazy var searchBar: UISearchBar = {
        let searchBar: UISearchBar = UISearchBar()
        searchBar.placeholder = NSLocalizedString("activity.posts", comment: "")
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()

    // searchController for everything *except* the iPad aux column
    private lazy var searchController: UISearchController = {
        return UISearchController(searchResultsController: nil)
    }()

    
    private lazy var loader: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView()
        loader.startAnimating()
        loader.hidesWhenStopped = true
        loader.translatesAutoresizingMaskIntoConstraints = false
        return loader;
    }()

    private var viewModel: PostResultsViewModel
    private var throttledDecelarationEndTask: Task<Void, Error>?

    required init(viewModel: PostResultsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        self.title = NSLocalizedString("activity.posts", comment: "")
        self.navigationItem.title = NSLocalizedString("activity.posts", comment: "")

        if viewModel.position != .aux {
            self.searchController.delegate = self
            self.searchController.searchBar.delegate = self
            self.searchController.searchResultsUpdater = self
            self.searchController.navigationItem.hidesSearchBarWhenScrolling = false
            self.searchController.obscuresBackgroundDuringPresentation = false
            self.searchController.hidesNavigationBarDuringPresentation = false
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onThemeChange),
                                               name: NSNotification.Name(rawValue: "reloadAll"),
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if viewModel.position == .aux {
            searchBar.resignFirstResponder()
        }
        
        self.throttledDecelarationEndTask?.cancel()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Only clean up feed on tab change
        if !animated {
            self.viewModel.pauseAllVideos()
            AVManager.shared.currentPlayer?.pause()
        }
    }
    
    @objc private func onThemeChange() {
        self.tableView.reloadData()
    }
}

// MARK: UI Setup
private extension PostResultsViewController {
    func setupUI() {
        view.addSubview(tableView)
        view.addSubview(loader)
        
        if viewModel.position == .aux {
            view.addSubview(searchBar)
            searchBar.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                searchBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                searchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                searchBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
            ])
        }
        
        NSLayoutConstraint.activate([
            (viewModel.position == .aux
            ? self.tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor)
            : self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor)),
            
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            
            self.loader.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.loader.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        
        let px = 1 / UIScreen.main.scale
        let line = UIView(frame: .init(x: 0, y: 0, width: self.tableView.frame.size.width, height: px))
        self.tableView.tableHeaderView = line
        line.backgroundColor = self.tableView.separatorColor
        
    }
    
    func showSearchFieldLoader() {
        let loader = UIActivityIndicatorView()
        loader.startAnimating()
        if viewModel.position == .aux {
            self.searchBar.searchTextField.leftView = loader
        }
    }
    
    func hideSearchFieldLoader()  {
        if viewModel.position == .aux {
            self.searchBar.searchTextField.leftView = UISearchBar().searchTextField.leftView
        }
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate
extension PostResultsViewController: UITableViewDataSource, UITableViewDelegate {
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if viewModel.hasHeader(forSection: section) {
            return 29
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let postCard = viewModel.getInfo(forIndexPath: indexPath)
        let cell = self.tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: postCard), for: indexPath) as! PostCardCell
        cell.configure(postCard: postCard) { [weak self] (type, isActive, data) in
            guard let self else { return }
            PostActions.onActionPress(target: self, type: type, isActive: isActive, postCard: postCard, data: data)
            
            if [.profile, .deletePost, .link, .mention, .message, .muteForever, .muteOneDay, .postDetails, .quote, .viewInBrowser, .reply].contains(type) {
                self.viewModel.pauseAllVideos()
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if viewModel.hasHeader(forSection: section) {
            let header = SectionHeader(buttonTitle: nil)
            header.configure(labelText: viewModel.getSectionTitle(for: section))
            return header
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let postCard = viewModel.getInfo(forIndexPath: indexPath)
        if case .mastodon(_) = postCard.data  {
            let vc = DetailViewController(post: postCard)
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let task = self.throttledDecelarationEndTask, !task.isCancelled {
            self.throttledDecelarationEndTask?.cancel()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if self.viewModel.shouldSyncFollowStatus() {
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
}

// MARK: UISearchControllerDelegate
extension PostResultsViewController: UISearchControllerDelegate {
}

// MARK: UISearchResultsUpdating
extension PostResultsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
    }
}


// MARK: UISearchBarDelegate
extension PostResultsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.search(query: searchText, fullSearch: false)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.cancelSearch()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let query = searchBar.text {
            viewModel.search(query: query, fullSearch: true)
        }
    }
}

// MARK: RequestDelegate
extension PostResultsViewController: RequestDelegate {
    func didUpdate(with state: ViewState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .idle:
                break
            case .loading:
                self.showSearchFieldLoader()
                if self.viewModel.numberOfItems(forSection: 0) == 0 {
                    self.loader.isHidden = false
                    self.loader.startAnimating()
                }
                break
            case .success:
                self.hideSearchFieldLoader()
                self.loader.stopAnimating()
                self.loader.isHidden = true
                self.tableView.reloadData()
                break
            case .error(let error):
                self.hideSearchFieldLoader()
                self.loader.stopAnimating()
                self.loader.isHidden = true
                log.error("Error on PostResultsViewController didUpdate: \(state) - \(error)")
                break
            }
        }
    }
    
    func didUpdateCard(at indexPath: IndexPath) {
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func didDeleteCard(at indexPath: IndexPath) {
        self.tableView.deleteRows(at: [indexPath], with: .bottom)
    }
}

extension PostResultsViewController: JumpToNewest {
    @objc func jumpToNewest() {
        self.tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}
