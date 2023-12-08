//
//  ProcessID.swift
//  Mammoth
//
//  Created by Riley Howard on 11/3/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

func processID() -> String {
    struct StaticHolder {
        static var processIdentifier: Int32? = nil
    }

    if StaticHolder.processIdentifier == nil {
        StaticHolder.processIdentifier = ProcessInfo().processIdentifier
    }
    return "\(StaticHolder.processIdentifier!)"
}
