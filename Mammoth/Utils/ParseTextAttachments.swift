//
//  ParseTextAttachments.swift
//  Mammoth
//
//  Created by Benoit Nolens on 15/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

/// Remove superfluous linebreaks
public func removeTrailingLinebreaks(string: NSAttributedString) -> NSAttributedString {
    let mutableString = NSMutableAttributedString(attributedString: string)
    while !mutableString.string.isEmpty && CharacterSet.newlines.contains(mutableString.string.unicodeScalars.last!) {
        mutableString.deleteCharacters(in: NSRange(location: mutableString.length - 1, length: 1))
    }

    return NSAttributedString(attributedString: mutableString)
}

public func removeTrailingLinebreaksFromMutableString(string: NSMutableAttributedString) -> NSMutableAttributedString {
    let mutableString = string
    while !mutableString.string.isEmpty && CharacterSet.newlines.contains(mutableString.string.unicodeScalars.last!) {
        mutableString.deleteCharacters(in: NSRange(location: mutableString.length - 1, length: 1))
    }

    return mutableString
}

public func parseRichText(text: String?) -> NSAttributedString? {
    guard Thread.isMainThread else {
        log.error(#function + " NSMutableAttributedString(data) must be on the main thread")
        return NSAttributedString()
    }
    
    do {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        
        let data = text.data(using: .utf16, allowLossyConversion: true)
        if let d = data {
            let str = try NSMutableAttributedString(data: d,
                                                    options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf16.rawValue],
                                                    documentAttributes: nil)
            

            // Remove superfluous linebreaks
            while !str.string.isEmpty && CharacterSet.newlines.contains(str.string.unicodeScalars.last!) {
                str.deleteCharacters(in: NSRange(location: str.length - 1, length: 1))
            }
            
            return str
        }
    } catch {
        log.error("error thrown creating a NSMutableAttributedString: \(error)")
    }
    
    return nil
}

public func formatRichText(string: NSAttributedString, label: UILabel, emojis: [Emoji]?) -> NSAttributedString {
    
    let str = NSMutableAttributedString(attributedString: string)
    let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = label.textAlignment
    
    str.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, str.length))
    
    if let font = label.font {
        str.addAttribute(.font, value: font, range: NSMakeRange(0, str.length))
    }
    
    if let textColor = label.textColor {
        str.addAttribute(.foregroundColor, value: textColor, range: NSMakeRange(0, str.length))
        str.addAttribute(.strokeColor, value: textColor, range: NSMakeRange(0, str.length))
    }
    
    
    if let emojis = emojis {
        emojis.forEach({
            let textAttachment = NSTextAttachment()
            textAttachment.kf.setImage(with: $0.url, attributedView: label)
            textAttachment.bounds = CGRect(x:0, y: -Int(label.font.lineHeight) / 10, width: Int(label.font.lineHeight - 6), height: Int(label.font.lineHeight - 6))
            let attrStringWithImage = NSAttributedString(attachment: textAttachment)
            
            while str.mutableString.contains(":\($0.shortcode):") {
                let range: NSRange = (str.mutableString as NSString).range(of: ":\($0.shortcode):")
                str.replaceCharacters(in: range, with: attrStringWithImage)
            }
        })
    }
    
    return str
}
