//
//  UIColor+Asset.swift
//  Mammoth
//
//  Created by Riley Howard on 8/12/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

extension UIColor {
    
    // App-specific colors
    struct custom {
        
        // Previously in GlobalStruct
        static var backgroundTint: UIColor { return UIColor.custom.background }
        static var baseTint: UIColor { return appColorNamed("High Contrast") }
        static var mainTextColor = UIColor.label
        static var mainTextColor2 = UIColor.label
        static var quoteTint: UIColor { return UIColor.secondarySystemBackground }
        static var actionButtons: UIColor { return UIColor.secondaryLabel.withAlphaComponent(0.4) }
        
        // Previously used around the app
        static var appCol: UIColor { return UIColor(named: "AppCol")! }
        static var selectedCell: UIColor { return appColorNamed("selectedCell") }
        static var selectedFollowing: UIColor { return appColorNamed("selectedFollowing") }
        static var spinnerBG: UIColor { return appColorNamed("spinnerBG") }
        
        // From Figma docs
        static var activeInverted: UIColor { return appColorNamed("Active Inverted") }
        static var active: UIColor { return appColorNamed("Active") }
        static var background: UIColor { return appColorNamed("Background") }
        static var blurredOVRLYHigh: UIColor { return appColorNamed("Blurred OVRLY High") }
        static var blurredOVRLYMed: UIColor { return appColorNamed("Blurred OVRLY Med") }
        static var blurredOVRLYNeut: UIColor { return appColorNamed("Blurred OVRLY Neut") }
        static var destructive: UIColor { return appColorNamed("Destructive") }
        static var displayNames: UIColor { return appColorNamed("Display Names") }
        static var feintContrast: UIColor { return appColorNamed("Feint Contrast") }
        static var followButtonBG: UIColor { return appColorNamed("Follow Button BG") }
        static var highContrast: UIColor { return appColorNamed("High Contrast") }
        static var inactive: UIColor { return appColorNamed("Inactive") }
        static var linkTextInactive: UIColor { return appColorNamed("Link Text Inactive") }
        static var linkText: UIColor { return appColorNamed("Link Text") }
        static var mediumContrast: UIColor { return appColorNamed("Medium Contrast") }
        static var outlines: UIColor { return appColorNamed("Outlines") }
        static var OVRLYSoftContrast: UIColor { return appColorNamed("OVRLY Soft Contrast") }
        static var OVRLYMedContrast: UIColor { return appColorNamed("OVRLY Med Contrast") }
        static var softContrast: UIColor { return appColorNamed("Soft Contrast") }
        static var statusBar: UIColor { return appColorNamed("Status Bar") }
        static var gold: UIColor { return appColorNamed("Gold") }
    }
    
    func greenTintedColor() -> UIColor {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return UIColor(red: red, green: green * 2.0, blue: blue, alpha: alpha)
    }
    static func appColorNamed(_ name: String) -> UIColor {
#if false
        // For testing
        if GlobalStruct.overrideThemeHighContrast {
            return UIColor(named: name)!.greenTintedColor()
        } else {
            return UIColor(named: name)!
        }
#else
        let prefix = GlobalStruct.overrideThemeHighContrast ? "HC" : ""
        return UIColor(named: prefix + name)!
#endif
    }
}
