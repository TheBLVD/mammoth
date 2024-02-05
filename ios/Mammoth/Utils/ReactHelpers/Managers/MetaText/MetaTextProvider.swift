//
//  MetaTextProvider.swift
//  Mammoth
//
//  Created by Benoit Nolens on 02/02/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit
import Meta
import MastodonMeta
import MetaTextKit
import React

@objc class MetaTextProvider: NSObject, MetaTextDelegate {
    
    @objc let metaText = MetaText()
        
    func metaText(_ metaText: MetaTextKit.MetaText, processEditing textStorage: MetaTextStorage) -> MetaContent? {
        guard metaText === self.metaText else { return nil }

        let string = metaText.textStorage.string
        let content = MastodonContent(content: string, emojis: [:])
        let metaContent = MastodonMetaContent.convert(text: content)
        
        EventEmitter.shared.dispatch(name: "onMetaTextChange", body: nil)

        return metaContent
    }
    
    @objc func createMetaLabel() -> UITextView {
        
        metaText.textView.backgroundColor = .clear
        metaText.textView.isScrollEnabled = false

        self.metaText.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]
        
        self.metaText.linkAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold),
            .foregroundColor: UIColor.custom.highContrast,
        ]

        self.metaText.paragraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = DeviceHelpers.isiOSAppOnMac() ? 1 : 0
            style.paragraphSpacing = 4
            style.alignment = .natural
            return style
        }()
        
        self.metaText.delegate = self
        
        let content = MastodonMetaContent.convert(text: MastodonContent(content: "Hello world from @mammoth #mastodon", emojis: [:]))
        self.metaText.configure(content: content, isRedactedModeEnabled: false)
        
        return self.metaText.textView
    }
}
