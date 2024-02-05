//
//  Array+Duplicates.swift
//  Mammoth
//
//  Created by Benoit Nolens on 17/07/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
    mutating func removeAllDuplicates() {
        self = self.removingDuplicates()
    }
    var orderedSet: Self {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
    mutating func removeDuplicates() {
        var set = Set<Element>()
        removeAll { !set.insert($0).inserted }
    }
}
