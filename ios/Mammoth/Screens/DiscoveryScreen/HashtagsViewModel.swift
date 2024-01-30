//
//  HashtagsViewModel.swift
//  Mammoth
//
//  Created by Riley Howard on 9/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class HashtagsViewModel {
            
    weak var delegate: RequestDelegate?

    private var state: ViewState {
        didSet {
            self.delegate?.didUpdate(with: state)
        }
    }

    private var listData: [Tag]
    private var showingStaticList: Bool

    // If a list of hashtags is passed in, use that as the
    // list data. Otherwise, expect to do searches on the
    // user's instance for matching hashtags.
    init(allHashtags: [Tag]? = nil) {

        if allHashtags != nil {
            self.showingStaticList = true
            self.listData = allHashtags!
            self.state = .success
        } else {
            self.showingStaticList = false
            self.listData = []
            self.state = .idle
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didSwitchAccount),
                                               name: didSwitchCurrentAccountNotification,
                                               object: nil)
                                
        NotificationCenter.default.addObserver(self, selector: #selector(self.hashtagStatusDidChange), name: didChangeHashtagsNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - DataSource
extension HashtagsViewModel {
    func numberOfItems(forSection section: Int) -> Int {
        return listData.count
    }
    
    var numberOfSections: Int {
        return 1
    }
    
    func hasHeader(forSection sectionIndex: Int) -> Bool {
        return false
    }

    func getInfo(forIndexPath indexPath: IndexPath) -> (Tag, Bool)? {
        guard listData.count != 0 else {
            return nil
        }
        let hashtag = self.listData[indexPath.row]
        let hashtagStatus = HashtagManager.shared.statusForHashtag(hashtag)
        let subscribed = (hashtagStatus == .following || hashtagStatus == .followRequested)
        return (hashtag, subscribed)
    }
    
    func getSectionTitle(for sectionIndex: Int) -> String {
        return ""
    }

    
}

// MARK: - Search
extension HashtagsViewModel {
    
    func search(query: String, fullSearch: Bool = false) {
        if fullSearch {
            self.searchAll(query: query)
        }
    }
    
    // Actually do the searching/filtering here
    func searchAll(query: String) {
        self.listData = []
        self.state = .loading
        Task {
            let searchResults = try await SearchService.searchTags(query: query)
            DispatchQueue.main.async {
                self.listData = searchResults
                self.state = .success
            }
        }
    }

    
    func cancelSearch() {
    }

}

// MARK: - Notification handlers
private extension HashtagsViewModel {
    
    @objc func hashtagStatusDidChange(notification: Notification) {
        DispatchQueue.main.async {
            self.delegate?.didUpdate(with: self.state)
        }
    }
        
    @objc func didSwitchAccount() {
        DispatchQueue.main.async {
            if !self.showingStaticList {
                self.listData = []
                self.state = .loading
            }
        }
    }
    
}
