//
//  StatusBar+Height.swift
//  Mammoth
//
//  Created by Benoit Nolens on 25/08/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class StatusBar {
    class func height() -> CGFloat  {
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        return window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    }
}
