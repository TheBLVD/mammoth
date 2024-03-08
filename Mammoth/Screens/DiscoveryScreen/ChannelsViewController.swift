//
//  ChannelsViewController.swift
//  Mammoth
//
//  Created by Riley Howard on 8/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class ChannelsViewController: UIViewController {
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(ChannelCell.self, forCellReuseIdentifier: ChannelCell.reuseIdentifier)
        tableView.register(NoResultsCell.self, forCellReuseIdentifier: NoResultsCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
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

    private lazy var loader: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView()
        loader.startAnimating()
        loader.hidesWhenStopped = true
        loader.translatesAutoresizingMaskIntoConstraints = false
        return loader;
    }()

    private var viewModel: ChannelsViewModel
    private let onClose: (() -> Void)?

    required init(viewModel: ChannelsViewModel, onClose: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        self.title = NSLocalizedString("discover.smartLists", comment: "")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func onThemeChange() {
        self.tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onThemeChange),
                                               name: NSNotification.Name(rawValue: "reloadAll"),
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
        
        if self.isModal {
            if #available(iOS 16.0, *) {
                let closeBtn = UIBarButtonItem(title: NSLocalizedString("generic.close", comment: ""), image: nil, target: self, action: #selector(self.onClosePressed))
                closeBtn.setTitleTextAttributes([
                    NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18, weight: .semibold)],
                                                for: .normal)
                closeBtn.setTitleTextAttributes([
                    NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18, weight: .semibold)],
                                                for: .highlighted)
                self.navigationItem.setRightBarButton(closeBtn, animated: false)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.onClose?()
    }
    
    @objc func onClosePressed() {
        self.dismiss(animated: true)
    }
}

// MARK: UI Setup
private extension ChannelsViewController {
    func setupUI() {
        view.addSubview(tableView)
        view.addSubview(loader)
                
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            
            self.loader.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.loader.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
    }
    
}

// MARK: UITableViewDataSource & UITableViewDelegate
extension ChannelsViewController: UITableViewDataSource & UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If no items present, return 1 to show the No Results cell
        let numItems = viewModel.numberOfItems(forSection: section)
        return numItems == 0 ? 1 : numItems
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
        if let (channel, isSubscribed) = viewModel.getInfo(forIndexPath: indexPath), let channel {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: ChannelCell.reuseIdentifier, for: indexPath) as! ChannelCell
            cell.configure(channel: channel, isSubscribed: isSubscribed)
            cell.delegate = self
            return cell
        } else {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: NoResultsCell.reuseIdentifier) as! NoResultsCell
            return cell
        }
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
        log.debug(#function)
        if let (channel, _) = viewModel.getInfo(forIndexPath: indexPath), let channel {
            let vc = NewsFeedViewController(type: .channel(channel))
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
}

extension ChannelsViewController: ChannelsViewModelDelegate {
    
    func didUpdate(with state: ViewState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .idle:
                break
            case .loading:
                if self.viewModel.numberOfItems(forSection: 0) == 0 {
                    self.loader.isHidden = false
                    self.loader.startAnimating()
                }
                break
            case .success:
                self.loader.stopAnimating()
                self.loader.isHidden = true
                self.tableView.reloadData()
                break
            case .error(let error):
                self.loader.stopAnimating()
                self.loader.isHidden = true
                log.error("Error on ChannelsViewController didUpdate: \(state) - \(error)")
                break
            }
        }
    }

}

// MARK: UISearchBarDelegate
extension ChannelsViewController: UISearchBarDelegate {
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

extension ChannelsViewController: JumpToNewest {
    @objc func jumpToNewest() {
        self.tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}
