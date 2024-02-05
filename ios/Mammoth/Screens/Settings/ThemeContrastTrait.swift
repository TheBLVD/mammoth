//
//  ThemeContrastTrait.swift
//  Mammoth
//
//  Created by Riley on 1/4/24
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit

enum ThemeContrast: Int {
    case standard
    case highContrast
}

struct ThemeContrastTrait: UITraitDefinition {
    static let defaultValue = ThemeContrast.standard
    static let affectsColorAppearance = true
}

@available(iOS 17.0, *)
extension UITraitCollection {
    var themeContrast: ThemeContrast { self[ThemeContrastTrait.self] }
}


@available(iOS 17.0, *)
extension UIMutableTraits {
    var themeContrast: ThemeContrast {
        get { self[ThemeContrastTrait.self] }
        set { self[ThemeContrastTrait.self] = newValue }
    }
}
