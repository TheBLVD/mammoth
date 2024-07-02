//
//  ProcessInfo+.swift
//  Mammoth
//
//  Created by Kern Jackson on 6/29/24
//  Copyright © 2024 The BLVD. All rights reserved.
//

extension ProcessInfo {
    static var isRunningUnitTests: Bool {
        return processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
