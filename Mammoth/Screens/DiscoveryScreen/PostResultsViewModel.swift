//
//  PostResultsViewModel.swift
//  Mammoth
//
//  Created by Riley Howard on 10/6/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class PostResultsViewModel {
    
    enum ScreenPosition {
        case main
        case aux
    }
    
    private enum ViewTypes: Int, CaseIterable {
        case regular
        case typing
        case searchResult
    }

    weak var delegate: RequestDelegate?
    let position: ScreenPosition
    
    private var type: ViewTypes = .regular
    private var state: ViewState {
        didSet {
            self.delegate?.didUpdate(with: state)
        }
    }
    
    private var searchDebouncer: Timer?
    private var searchTask: Task<Void, Never>?
    private var searchQuery: String = "" {
        didSet {
            if searchQuery.isEmpty {
                // TODO: make class vars thread-safe instead
                DispatchQueue.main.async {
                    self.type = .regular
                    self.state = .success
                }
            } else {
                if let task = self.searchTask, !task.isCancelled {
                    task.cancel()
                }
                
                self.searchTask = Task {
                    await self.searchAll(query: self.searchQuery)
                }
            }
        }
    }

    private var listData: [PostCardModel] = []  // posts visible to the user in the table
    private var suggested: [PostCardModel] = [] // all posts from search result

    init(screenPosition: ScreenPosition = .main) {
        self.state = .idle
        self.position = screenPosition
                
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didSwitchAccount),
                                               name: didSwitchCurrentAccountNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onUpdateClient),
                                               name: NSNotification.Name(rawValue: "updateClient"),
                                               object: nil)
                
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onPostCardUpdate),
                                               name: PostActions.didUpdatePostCardNotification,
                                               object: nil)
        Task {
            await self.loadRecommendations()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func pauseAllVideos() {
        self.listData.forEach({
            $0.videoPlayer?.pause()
        })
    }
}

// MARK: - DataSource
extension PostResultsViewModel {
    func numberOfItems(forSection section: Int) -> Int {
        return self.listData.count
    }
    
    var numberOfSections: Int {
        return 1
    }
    
    func hasHeader(forSection sectionIndex: Int) -> Bool {
        switch(self.type) {
        case .regular:
            return true
        case .typing:
            return false
        case .searchResult:
            return false
        }
    }
    
    func shouldSyncFollowStatus() -> Bool {
        switch self.type {
        case .typing:
            return false
        default:
            return true
        }
    }

    func getInfo(forIndexPath indexPath: IndexPath) -> PostCardModel {
        return self.listData[indexPath.row]
    }
    
    func getSectionTitle(for sectionIndex: Int) -> String {
        switch(self.type) {
        case .regular:
            return NSLocalizedString("activity.posts", comment: "")
        case .typing:
            return NSLocalizedString("activity.posts", comment: "")
        case .searchResult:
            return NSLocalizedString("activity.posts", comment: "")
        }
    }
    
    func updateFollowStatus(atIndexPath indexPath: IndexPath, forceUpdate: Bool = false) {
    }

    func updateFollowStatusForAccountName(_ accountName: String!, followStatus: FollowManager.FollowStatus) -> Int? {
        return nil
    }
}

// MARK: - Service
extension PostResultsViewModel {
    func loadRecommendations() async {
        // The initial state here is an empty list
        DispatchQueue.main.async {
            self.state = .loading
            self.suggested = []
            self.listData = self.suggested
            self.state = .success
        }
    }
    
    func search(query: String, fullSearch: Bool = false) {
        //Debounce search
        self.searchDebouncer?.invalidate()
        
        if fullSearch {
            self.type = .searchResult
            self.state = .success // force a table reload
        } else {
            self.type = .typing
            self.state = .success // force a table reload
        }
        
        if query.isEmpty {
            self.searchQuery = query
        } else {
            searchDebouncer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false, block: { [weak self] (timer) in
                guard let self else { return }
                self.searchQuery = query
            })
        }
    }
    
    func searchAll(query: String) async {
        self.state = .loading
        do {
            let result = try await SearchService.searchPosts(query: query)
            DispatchQueue.main.async {
                self.listData = result.map({ PostCardModel(status: $0) })
                self.state = .success
            }
        } catch let error {
            // TODO: make class vars thread-safe instead
            DispatchQueue.main.async {
                self.state = .error(error)
            }
        }
    }
    
    func cancelSearch() {
        self.type = .regular
        self.listData = self.suggested
        self.searchQuery = ""
    }
    
    func syncFollowStatus(forIndexPaths indexPaths: [IndexPath]) {
    }
}

// MARK: - Notification handlers
private extension PostResultsViewModel {
    @objc func didSwitchAccount() {
        Task {
            // Reload recommentations when a user is set/changed
            await self.loadRecommendations()
        }
    }
    
    @objc func onUpdateClient() {
        Task {
            // Reload recommentations when a user is set/changed
            await self.loadRecommendations()
        }
    }
        
    @objc func onPostCardUpdate(notification: Notification) {
        if let postCard = notification.userInfo?["postCard"] as? PostCardModel {
            if let cardIndex = self.listData.firstIndex(where: {$0.uniqueId == postCard.uniqueId}){
                DispatchQueue.main.async {
                    if let isDeleted = notification.userInfo?["deleted"] as? Bool, isDeleted == true {
                        // Delete post card data in list data
                        self.listData.remove(at: cardIndex)
                        // Request a table view cell refresh
                        self.delegate?.didDeleteCard(at: IndexPath(row: cardIndex, section: 0))
                    } else {
                        // Replace post card data in list data
                        self.listData[cardIndex] = postCard
                        // Request a table view cell refresh
                        self.delegate?.didUpdateCard(at: IndexPath(row: cardIndex, section: 0))
                    }
                }
            }
        }
    }
}
