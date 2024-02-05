//
//  ProfilePrefetchViewController.swift
//  Mammoth
//
//  Created by Riley Howard on 2/2/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit


// Will try to cache profiles related to objects visible in the
// contrllers tableView(s).
//
// Usage notes:
//  • Subclass this instead of UIViewController
//  • The subclass must be the tableViewDelegate
//  • Subclass must either:
//          implement dataForLiveTableView() and performActionForVisibleCells()
//      or
//          implement performActionForVisibleCellsInTableView()
//  • If your subclass calls any of these, call super (and mark it's as 'override'):
//      scrollViewDidEndDecelerating()
//      scrollViewDidEndDragging()
//      tableView(_:willDisplay cell:forRowAt:)


class LiveTableViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate {
    
    func dataForLiveTableView(_ table: UITableView) -> [AnyObject] {
        log.error("error - subclass must implement dataForLiveTableView")
        return []
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.stoppedScrolling(table: scrollView as! UITableView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.stoppedScrolling(table: scrollView as! UITableView)
        }
    }

    private func stoppedScrolling(table: UITableView) {
        performActionForVisibleCellsInTableView(table)
    }
    
    // Try to detect first display
    var detectFirstDisplay = true
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if detectFirstDisplay { // }&& !dataForLiveTableView(tableView).isEmpty {
            // See if this is the last row
            if indexPath.row == tableView.indexPathsForVisibleRows?.last?.row {
                // We've loaded some data into the table
                detectFirstDisplay = false
                performActionForVisibleCellsInTableView(tableView)
            }
        }
    }

    func performActionForVisibleCellsInTableView(_ table: UITableView) {
        let dataForTable = self.dataForLiveTableView(table)
        if !dataForTable.isEmpty {
            performActionForVisibleCells(table: table, dataArray: dataForTable)
        }
    }
    
    func performActionForVisibleCells(table: UITableView, dataArray: [AnyObject]) {
        log.error("error - subclass must implement performActionForVisibleCells or performActionForVisibleCellsInTableView")
    }
    
    
}

