//
//  DeviceHelpers.swift
//  Mammoth
//
//  Created by Benoit Nolens on 06/12/2023
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

struct DeviceHelpers {
    static func isiOSAppOnMac() -> Bool {
        if #available(iOS 14.0, *) {
            return ProcessInfo.processInfo.isiOSAppOnMac
        }
        
        return false
    }
}
