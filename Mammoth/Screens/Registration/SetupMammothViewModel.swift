//
//  SetupMammothViewModel.swift
//  Mammoth
//
//  Created by Riley Howard on 10/13/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class SetupMammothViewModel {
    
    private enum ViewTypes: Int, CaseIterable {
        case regular
        case typing
        case searchResult
    }
    
    static let shared = SetupMammothViewModel()
    static func preload() {
        _ = self.shared
    }

    weak var delegate: RequestDelegate? {
        didSet {
            self.delegate?.didUpdate(with: state)
        }
    }
    
    private var type: ViewTypes = .regular
    private var state: ViewState {
        didSet {
            self.delegate?.didUpdate(with: state)
        }
    }
    
    private var listDataHeaders: [String] = []
    private var listData: UserCardModel? = nil
    private var postSyncingTasks: [IndexPath: Task<Void, Error>] = [:]

    init() {
        self.state = .idle
                
        Task {
            await self.loadRecommendations()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Always show this screen, unless we are sure the
    // current account already follows Mammoth
    public func shouldShow() -> Bool {
        guard let mammothAccount = listData?.account else {
            return true
        }
        let followStatus = FollowManager.shared.followStatusForAccount(mammothAccount)
        return followStatus != .following
    }
}

// MARK: - DataSource
extension SetupMammothViewModel {
    func numberOfItems(forSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return self.listData == nil ? 0 : 1
        }
    }
    
    var numberOfSections: Int {
        return 2
    }
    
    func hasHeader(forSection sectionIndex: Int) -> Bool {
        return false
    }
    
    func shouldSyncFollowStatus() -> Bool {
        return false
    }

    func getInfo(forIndexPath indexPath: IndexPath) -> UserCardModel? {
        guard indexPath.section > 0 else { return nil } // The first section is the header / no data
        return self.listData
    }
    
    func getSectionTitle(for sectionIndex: Int) -> String {
        return ""
    }

}

// MARK: - Service
extension SetupMammothViewModel {
    func loadRecommendations() async {
        self.state = .loading
        
        // Load the info for the Mammoth account
        guard let mammothAccount = await AccountService.lookup("mammoth", serverName: "moth.social") else {
            log.error("unable to get Mammoth account info")
            let error = NSError(domain: "Unable to get Mammoth account info", code: 100)
            self.state = .error(error)
            return
        }
        let mammothUserCard = UserCardModel(account: mammothAccount)
        await MainActor.run {
            self.listData = mammothUserCard
            self.state = .success
        }
        
        // Update the follow status for this account if not yet known
        let followStatus = FollowManager.shared.followStatusForAccount(mammothAccount, requestUpdate: .whenUncertain)
    }
    
    func followMammothAccount() {
        // Follow @mammoth if we already have the account info;
        // otherwise, go get it, and then follow.
        Task {
            var mammothAccount = self.listData?.account
            if mammothAccount == nil {
                mammothAccount = await AccountService.lookup("mammoth", serverName: "moth.social")
            }
            if let mammothAccount {
                await MainActor.run {
                    FollowManager.shared.followAccount(mammothAccount)
                }
            } else {
                log.error("Unable to get Mammoth account info ")
            }
        }
    }

    
}

