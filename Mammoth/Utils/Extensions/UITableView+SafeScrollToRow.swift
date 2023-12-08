//
//  UITableView+SafeScrollToRow.swift
//  Mammoth
//
//  Created by Riley on 11/30/23
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

extension UITableView {
    // First verify index exists, then scroll to it.
    func safeScrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        if indexPath.section < self.numberOfSections,
           indexPath.row < self.numberOfRows(inSection: indexPath.section) {
            self.scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
        } else {
            log.error("Tried to scroll to a non-existant indexPath: \(indexPath)")
        }
    }
}
