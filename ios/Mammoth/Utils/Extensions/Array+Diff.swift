//
//  Array+Diff.swift
//  Mammoth
//
//  Created by Benoit Nolens on 10/10/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}
