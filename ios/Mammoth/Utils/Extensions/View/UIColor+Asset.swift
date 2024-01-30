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
        static let backgroundTint = UIColor.custom.background
        static var baseTint = UIColor(named: "High Contrast")!
        static var mainTextColor = UIColor.label
        static var mainTextColor2 = UIColor.label
        static let quoteTint = UIColor.secondarySystemBackground
        static let actionButtons = UIColor.secondaryLabel.withAlphaComponent(0.4)
        
        // Previously used around the app
        static let appCol = UIColor(named: "AppCol")!
        static let selectedCell = UIColor(named: "selectedCell")!
        static let selectedFollowing = UIColor(named: "selectedFollowing")!
        static let spinnerBG = UIColor(named: "spinnerBG")!
        
        // From Figma docs
        static let activeInverted = UIColor(named: "Active Inverted")!
        static let active = UIColor(named: "Active")!
        static let background = UIColor(named: "Background")!
        static let blurredOVRLYHigh = UIColor(named: "Blurred OVRLY High")!
        static let blurredOVRLYMed = UIColor(named: "Blurred OVRLY Med")!
        static let blurredOVRLYNeut = UIColor(named: "Blurred OVRLY Neut")!
        static let destructive = UIColor(named: "Destructive")!
        static let displayNames = UIColor(named: "Display Names")!
        static let feintContrast = UIColor(named: "Feint Contrast")!
        static let followButtonBG = UIColor(named: "Follow Button BG")!
        static let highContrast = UIColor(named: "High Contrast")!
        static let inactive = UIColor(named: "Inactive")!
        static let linkTextInactive = UIColor(named: "Link Text Inactive")!
        static let linkText = UIColor(named: "Link Text")!
        static let mediumContrast = UIColor(named: "Medium Contrast")!
        static let outlines = UIColor(named: "Outlines")!
        static let OVRLYSoftContrast = UIColor(named: "OVRLY Soft Contrast")!
        static let OVRLYMedContrast = UIColor(named: "OVRLY Med Contrast")!
        static let softContrast = UIColor(named: "Soft Contrast")!
        static let statusBar = UIColor(named: "Status Bar")!
        static let gold = UIColor(named: "Gold")!
    }
}
