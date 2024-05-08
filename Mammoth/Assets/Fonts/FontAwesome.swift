//
//  FontAwesome.swift
//  Mammoth
//
//  Created by Riley Howard on 4/17/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit


// Usage
// UIImage image = FontAwesome.image(fromChar:"\u{f085}", color: UIColor.white, size: 30.0)
//
// There is a simple dictionary cache (cachedImages) that is only valid
// for the duration of the app run (nothing saved to disk).
//
// Cache needs to be cleared anytime the theme or default system changes
// traitCollectionDidChange & when GlobalStruct.themeOverride is assigned

enum ColorTheme: String {
    case dark = "dark"
    case light = "light"
    case systemDefault = "systemDefault"
}

class FontAwesome {

    static var cachedImages: [String: UIImage] = [:]
    static var systemColorTheme: ColorTheme = ColorTheme.systemDefault
    
    // where ever global theme override is set we want to call and capture
    // on launch
    public static func setColorTheme(theme:ColorTheme) {
        clearCache()
        // set systemColorTheme
        systemColorTheme = theme
    }
    

    private static func clearCache() {
        cachedImages = [:]
    }
    public static func image(fromChar char: String,
                             color: UIColor? = nil,
                             size: CGFloat = 19.0,
                             weight: UIFont.Weight = .regular) -> UIImage {

        let cacheKey = char + "-" + StringFromUIColor(color) + " - \(size) - \(weight)"
        if let cachedValue = cachedImages[cacheKey] {
            // log.debug("got image from cache: \(cacheKey)")
            return cachedValue
        }
        
        let label = UILabel(frame: .zero)
        
        if let font = UIFont(name: "Font Awesome 6 Pro", size: size),
           let unicode = char.unicodeScalars.first,
           isSupported(unicode: unicode, font: font) {
            switch weight {
            case .bold:
                label.font = font.bold
            case .regular:
                label.font = font
            default:
                label.font = font
                log.error("unexpected font weight")
            }
        } else {
            // Fallback to Font Awesome 6 Brand font if this glyph is
            // not supported by "Font Awesome 6 Pro"
            label.font = UIFont(name: "Font Awesome 6 Brands", size: size)
        }

        if color != nil  {
            label.textColor = color
        } else {
            if (systemColorTheme != ColorTheme.systemDefault) {
                label.textColor = systemColorTheme == ColorTheme.light ? UIColor.black : UIColor.white //light or dark
            }
        }
        
        label.text = char
        label.sizeToFit()
        let renderer = UIGraphicsImageRenderer(size: label.frame.size)
        let image = renderer.image(actions: { context in
            label.layer.render(in: context.cgContext)
        })
        
        // log.debug("setting image to cache: \(cacheKey)")
        cachedImages[cacheKey] = image
        
        return image
    }
}


func StringFromUIColor(_ color: UIColor?) -> String {
    if color == nil {
        return "nil"
    } else {
        if let components = color!.cgColor.components {
            var s = ""
            for item in components {
                s += "\(item)"
            }
            return s
        } else {
            log.error("missing color components")
            return ""
        }
    }
}

func isSupported(unicode: UnicodeScalar, font: UIFont) -> Bool {
    let coreFont: CTFont = font
    let characterSet: CharacterSet = CTFontCopyCharacterSet(coreFont) as CharacterSet
    return characterSet.contains(unicode)
 }


extension UIFont {
    var bold: UIFont { return withWeight(.bold) }
    var regular: UIFont { return withWeight(.regular) }

    private func withWeight(_ weight: UIFont.Weight) -> UIFont {
        var attributes = fontDescriptor.fontAttributes
        var traits = (attributes[.traits] as? [UIFontDescriptor.TraitKey: Any]) ?? [:]

        traits[.weight] = weight

        attributes[.name] = nil
        attributes[.traits] = traits
        attributes[.family] = familyName

        let descriptor = UIFontDescriptor(fontAttributes: attributes)

        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
