//
//  SearchHostViewModel.swift
//  Mammoth
//
//  Created by Riley Howard on 8/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

protocol SearchHostDelegate: AnyObject {
    func didUpdateViewType(with viewType: SearchHostViewModel.ViewTypes)
}

class SearchHostViewModel {
    
    enum ViewTypes: Int, CaseIterable {
        case suggestions
        case users
        case channels
        case hashtags
        case posts
        case instances
    }

    weak var delegate: SearchHostDelegate?
    private var viewType: ViewTypes = .suggestions {
        didSet {
            self.delegate?.didUpdateViewType(with: viewType)
        }
    }

    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didSwitchAccount),
                                               name: didSwitchCurrentAccountNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Notification handlers
private extension SearchHostViewModel {
    @objc func didSwitchAccount() {
        Task {
            // Reset view choice
            self.viewType = .suggestions
        }
    }
}

extension SearchHostViewModel {
    
    public func userInitiatedSearch() {
        // If showing suggestions, and the user taps 'search',
        // switch to showing Users
        if self.viewType == .suggestions {
            self.viewType = .users
        }
    }
    
    public func userClearedTextField() {
        // Switch to showing Suggestions when the user clears the
        // search field / taps 'X'
        self.viewType = .suggestions
    }

    public func userCancelledSearch() {
        // Switch to showing Suggestions when the user taps 'cancel'
        self.viewType = .suggestions
    }
    
    public func switchToViewAtIndex(_ index: Int) {
        self.viewType = ViewTypes.allCases[index]
    }
    
    public func shouldShowCarousel() -> Bool {
        return self.viewType != .suggestions
    }
}
