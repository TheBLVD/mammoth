//
//  SettingsIcons.swift
//  Mammoth
//
//  Created by Riley on 12/21/23
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit


func settingsFontAwesomeImage(_ char: String) -> UIImage {
    let image = FontAwesome.image(fromChar: char)
    return settingsImage(image)
}

func settingsSystemImage(_ systemName: String) -> UIImage {
    let image = UIImage(systemName: systemName)!
    return settingsImage(image)
}

// Draw the image in a box as tall as the image, and in a standard width
func settingsImage(_ glyph: UIImage) -> UIImage {
    var settingsIconWidth = 28.0
    if glyph.size.width > settingsIconWidth {
        log.error("settings icon too wide")
        settingsIconWidth = glyph.size.width
    }
    let imageSize = CGSize(width: settingsIconWidth, height: glyph.size.height)
    let settingsImage = UIGraphicsImageRenderer(size: imageSize).image { _ in
        
        // Red background for testing
        #if false
        let context = UIGraphicsGetCurrentContext()!
        let clipPath: CGPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: settingsIconWidth, height: glyph.size.height)).cgPath
        context.addPath(clipPath)
        context.setFillColor(UIColor.red.cgColor)
        context.closePath()
        context.fillPath()
        #endif
        
        glyph.draw(at: CGPoint(x: (imageSize.width - glyph.size.width) / 2.0, y:0))
    }
    return settingsImage.withTintColor(.custom.mediumContrast, renderingMode: .alwaysOriginal)
}
