//
//  FeedEditorViewModel.swift
//  Mammoth
//
//  Created by Benoit Nolens on 12/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class FeedEditorViewModel {
    
    weak var delegate: RequestDelegate?
    private var isLoadMoreEnabled: Bool = true
    
    private var state: ViewState {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.didUpdate(with: self.state)
            }
        }
    }
    
    private struct ListData {
        var enabled: [FeedTypeItem] {
            return FeedsManager.shared.feeds.filter({ $0.isEnabled })
        }
        var disabled: [FeedTypeItem] {
            return FeedsManager.shared.feeds.filter({ !$0.isEnabled })
        }
        
        func data(forSection section: Int) -> [FeedTypeItem] {
            switch section {
            case 0:
                return enabled
            case 1:
                return disabled
            default:
                return []
            }
        }
    }
    
    private var listData: ListData = ListData()

    init() {
        self.state = .success
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - DataSource
extension FeedEditorViewModel {
    func numberOfItems(forSection section: Int) -> Int {
        self.listData.data(forSection: section).count
    }
    
    var numberOfSections: Int {
        return 2
    }

    func getInfo(forIndexPath indexPath: IndexPath) -> FeedTypeItem? {
        let data = self.listData.data(forSection: indexPath.section)
        if data.count > indexPath.row {
            return data[indexPath.row]
        }
        
        return nil
    }
    
    func moveItem(fromIndexPath sourceIndexPath: IndexPath, toIndexPath destinationIndexPath: IndexPath) {
        let item = self.listData.data(forSection: sourceIndexPath.section)[sourceIndexPath.row]
        
        // dropping an active item in the 'disabled' section
        if item.isEnabled && destinationIndexPath.section == 1 {
            item.isEnabled = false
        }
        
        // dropping a disabled item in the 'enabled' section
        if !item.isEnabled && destinationIndexPath.section == 0 {
            item.isEnabled = true
        }
        
        if let index = FeedsManager.shared.feeds.firstIndex(where: { $0  == item }) {
            // The feeds array is a unidimensional array including both enabled and disabled items,
            // so normalize the destination index to the index from the array that includes all items.
            // In the UI "enabled" and "disabled" items are split in different sections
            if destinationIndexPath.section == 0 { // enabled section
                let enabledItems = FeedsManager.shared.feeds.filter({ $0.isEnabled })
                if enabledItems.count > destinationIndexPath.row {
                    let destinationItem = enabledItems[destinationIndexPath.row]
                    if let destinationIndex = FeedsManager.shared.feeds.firstIndex(of: destinationItem) {
                        FeedsManager.shared.moveItem(item, fromIndex: index, toIndex: destinationIndex)
                    }
                }
            }
            if destinationIndexPath.section == 1 { // disabled section
                let disabledItems = FeedsManager.shared.feeds.filter({ !$0.isEnabled })
                if disabledItems.count > destinationIndexPath.row {
                    let destinationItem = disabledItems[destinationIndexPath.row]
                    if let destinationIndex = FeedsManager.shared.feeds.firstIndex(of: destinationItem) {
                        FeedsManager.shared.moveItem(item, fromIndex: index, toIndex: destinationIndex)
                    }
                }
            }
        }
    }
}
