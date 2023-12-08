//
//  Task+Sleep.swift
//  Mammoth
//
//  Created by Benoit Nolens on 28/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
