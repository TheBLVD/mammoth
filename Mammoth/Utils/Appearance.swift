//
//  Appearance.swift
//  Mammoth
//
//  Created by Benoit Nolens on 11/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class AppearanceManager {
    static let shared = AppearanceManager()
    
    struct ColorTheme {
        var backgroundTint: UIColor?
        var mainTextColor: UIColor?
    }
    
    @objc func reloadAll() {
        // tints
        let hcText = UserDefaults.standard.value(forKey: "hcText") as? Bool ?? true
        if hcText == true {
            UIColor.custom.mainTextColor = .label
        } else {
            UIColor.custom.mainTextColor = .secondaryLabel
        }
        let hcText2 = UserDefaults.standard.value(forKey: "hcText2") as? Bool ?? false
        if hcText2 == true {
            UIColor.custom.mainTextColor2 = .label
        } else {
            UIColor.custom.mainTextColor2 = .secondaryLabel
        }
    }
}

func NavBarBlurEffect() -> UIBlurEffect {
    return UIBlurEffect(style: .regular)
}

func NavBarBackgroundColor(userInterfaceStyle: UIUserInterfaceStyle) -> UIColor? {
    if userInterfaceStyle == .light {
        return .custom.background.withAlphaComponent(0.7)
    } else {
        return .custom.background.darker(by: 0.27)?.withAlphaComponent(0.8)
    }
}

func configureNavigationBarLayout(navigationController: UINavigationController?, userInterfaceStyle: UIUserInterfaceStyle = .light) {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()
    
    appearance.backgroundColor = NavBarBackgroundColor(userInterfaceStyle: userInterfaceStyle)
    appearance.backgroundEffect = NavBarBlurEffect()
    appearance.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]

    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    
    navigationController?.navigationBar.standardAppearance = appearance
    navigationController?.navigationBar.scrollEdgeAppearance = appearance
    navigationController?.navigationBar.compactAppearance = appearance
    
    navigationController?.navigationBar.tintColor = .custom.highContrast
}
