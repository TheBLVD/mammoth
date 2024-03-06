//
//  DiscoverSuggestionsViewController.swift
//  Mammoth
//
//  Created by Riley Howard on 9/25/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class DiscoverSuggestionsViewController: UIViewController {
    
    enum Sections: Int {
        case smartLists
        case hashtags
        case accounts
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(ChannelCell.self, forCellReuseIdentifier: ChannelCell.reuseIdentifier)
        tableView.register(ChannelSummaryCell.self, forCellReuseIdentifier: ChannelSummaryCell.reuseIdentifier)
        tableView.register(HashtagCell.self, forCellReuseIdentifier: HashtagCell.reuseIdentifier)
        tableView.register(UserCardCell.self, forCellReuseIdentifier: UserCardCell.reuseIdentifier)
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
    
    private(set) var viewModel: DiscoverSuggestionsViewModel

    required init(viewModel: DiscoverSuggestionsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        self.title = NSLocalizedString("navigator.discover", comment: "")
        self.navigationItem.title = NSLocalizedString("navigator.discover", comment: "")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.viewModel.cancelAllItemSyncs()
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
        self.viewModel.cancelAllItemSyncs()
    }
    
    @objc private func onThemeChange() {
        self.tableView.reloadData()
    }
}

// MARK: UI Setup
private extension DiscoverSuggestionsViewController {
    func setupUI() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])
    }
    
}

// MARK: UITableViewDataSource & UITableViewDelegate
extension DiscoverSuggestionsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.viewModel.requestItemSync(forIndexPath: indexPath, afterSeconds: 1)
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.viewModel.cancelItemSync(forIndexPath: indexPath)
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
        
        switch(viewModel.getInfo(forIndexPath: indexPath)) {
        case .account(let userCard):
            let cell = self.tableView.dequeueReusableCell(withIdentifier: UserCardCell.reuseIdentifier, for: indexPath) as! UserCardCell
            if let info = userCard {
                if info.followStatus != .unknown {
                    info.forceFollowButtonDisplay = true
                }
                cell.configure(info: info) { [weak self] (type, isActive, data) in
                    guard let self else { return }
                    PostActions.onActionPress(target: self, type: type, isActive: isActive, userCard: info, data: data)
                }
            }
            return cell
        case .channel(let channel):
            // Show the summary version if there is any search content,
            // otherwise, the full cell
            if viewModel.showSummaryCells {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: ChannelSummaryCell.reuseIdentifier, for: indexPath) as! ChannelSummaryCell
                if let channel = channel {
                    let subStatus = ChannelManager.shared.subscriptionStatusForChannel(channel)
                    let showAsSubscribed = (subStatus == .subscribed || subStatus == .subscribeRequested)
                    cell.configure(channel: channel, isSubscribed: showAsSubscribed)
                    cell.delegate = self
                    return cell
                }
            } else {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: ChannelCell.reuseIdentifier, for: indexPath) as! ChannelCell
                if let channel = channel {
                    let subStatus = ChannelManager.shared.subscriptionStatusForChannel(channel)
                    let showAsSubscribed = (subStatus == .subscribed || subStatus == .subscribeRequested)
                    cell.configure(channel: channel, isSubscribed: showAsSubscribed)
                    cell.delegate = self
                    return cell
                }
            }
        case .hashtag(let tag):
            let cell = self.tableView.dequeueReusableCell(withIdentifier: HashtagCell.reuseIdentifier, for: indexPath) as! HashtagCell
            if let tag = tag {
                let hashtagStatus = HashtagManager.shared.statusForHashtag(tag)
                let showAsSubscribed = (hashtagStatus == .following || hashtagStatus == .followRequested)
                cell.configure(hashtag: tag, isSubscribed: showAsSubscribed)
            }
            return cell
        }
        
        log.error("unable to dequeue the correct cell in DiscoverSuggestionsViewController")
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if viewModel.hasHeader(forSection: section) {
            let buttonTitle = (section == Sections.accounts.rawValue) ? nil : NSLocalizedString("discover.seeAll", comment: "")
            let header = SectionHeader(buttonTitle: buttonTitle)
            if buttonTitle != nil {
                header.delegate = self
                header.delegateContext = section
            }
            header.configure(labelText: viewModel.getSectionTitle(for: section))
            return header
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch(viewModel.getInfo(forIndexPath: indexPath)) {
        case .account(let userCard):
            if let user = userCard {
                let vc = ProfileViewController(user: user, screenType: user.isSelf ? .own : .others)
                if vc.isBeingPresented {} else {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        case .channel(let channel):
            if let channel = channel {
                let vc = NewsFeedViewController(type: .channel(channel))
                if vc.isBeingPresented {} else {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        case .hashtag(let tag):
            if let tag = tag {
                let vc = NewsFeedViewController(type: .hashtag(Tag(name: tag.name, url: tag.url)))
                if vc.isBeingPresented {} else {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
}

// MARK: UISearchControllerDelegate
extension DiscoverSuggestionsViewController: UISearchControllerDelegate {
}

// MARK: UISearchResultsUpdating
extension DiscoverSuggestionsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
    }
}



// MARK: RequestDelegate
extension DiscoverSuggestionsViewController: DiscoverySuggestionsDelegate {
    func didUpdateAll() {
        self.tableView.reloadData()
    }
    
    func didUpdateSection(section: DiscoverSuggestionsViewModel.DiscoverySuggestionSection, with state: ViewState) {
        let sectionIndex = section.rawValue
        self.tableView.reloadSections([sectionIndex], with: .none)
    }
    
    func didUpdateCard(at indexPath: IndexPath) {
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func didDeleteCard(at indexPath: IndexPath) {
        self.tableView.deleteRows(at: [indexPath], with: .bottom)
    }
}


// MARK: UISearchBarDelegate
extension DiscoverSuggestionsViewController: UISearchBarDelegate {
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

extension DiscoverSuggestionsViewController: SectionHeaderDelegate {
    func userTappedButton(context: Int) {
        if context == Sections.smartLists.rawValue {
            // Show all channels
            let vc = ChannelsViewController(viewModel: ChannelsViewModel(singleSection: true))
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else if context == Sections.hashtags.rawValue {
            // Show all hashtags
            let vc = HashtagsViewController(viewModel: HashtagsViewModel(allHashtags: viewModel.allTrendingHashtags))
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }

        }
    }
}

extension DiscoverSuggestionsViewController: JumpToNewest {
    @objc func jumpToNewest() {
        self.tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}

// MARK: Appearance changes
internal extension DiscoverSuggestionsViewController {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 tableView.backgroundColor = .custom.background
                 tableView.reloadData()
             }
         }
    }
}
