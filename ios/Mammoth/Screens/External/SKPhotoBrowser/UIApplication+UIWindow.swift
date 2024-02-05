//
//  UIApplication+UIWindow.swift
//  SKPhotoBrowser
//
//  Created by Josef Dolezal on 25/09/2017.
//  Copyright © 2017 suzuki_keishi. All rights reserved.
//

import UIKit

internal extension UIApplication {
    var preferredApplicationWindow: UIWindow? {
        // Since delegate window is of type UIWindow??, we have to
        // unwrap it twice to be sure the window is not nil
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if let appWindow = UIApplication.shared.delegate?.window, let window = appWindow {
            return window
        } else if let window = keyWindow {
            return window
        }

        return nil
    }
}
