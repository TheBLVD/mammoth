//
//  ShareViewController.swift
//  Mammoth Share Extension
//
//  Created by Shihab Mehboob on 17/01/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.parseMedia()
    }
    
    func redirect(key: String) {
        
        let url = URL(string: "mammoth://dataUrl=\(key)")
        var responder = self as UIResponder?
        let selectorOpenURL = sel_registerName("openURL:")
        while (responder != nil) {
            if (responder?.responds(to: selectorOpenURL))! {
                let _ = responder?.perform(selectorOpenURL, with: url)
            }
            responder = responder!.next
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1 ) {
            self.extensionContext?.completeRequest(returningItems: nil)
        }
        
    }
    
    func parseMedia() {
        let content = extensionContext!.inputItems[0] as! NSExtensionItem
        let textType = "public.url"
        let contentType = UTType.data.identifier as String
        guard let attachments = content.attachments else { return }
        for (index, attachment) in (attachments).enumerated() {
            if attachment.hasItemConformingToTypeIdentifier(textType) {
                attachment.loadItem(forTypeIdentifier: textType, options: nil) { [weak self] data, error in
                    if error == nil, let self = self {
                        let theData: String? = (data as? URL ?? URL(string: "www.google.com"))?.absoluteString ?? ""
                        DispatchQueue.main.async {
                            let userDefaults = UserDefaults(suiteName: "group.com.theblvd.mammoth.wormhole")
                            userDefaults?.set(theData, forKey: "shareExtensionText")
                            userDefaults?.synchronize()
                            self.redirect(key: "shareExtensionText")
                        }
                    }
                }
            } else if let x = content.attributedContentText {
                let theData: String? = x.string
                DispatchQueue.main.async {
                    let userDefaults = UserDefaults(suiteName: "group.com.theblvd.mammoth.wormhole")
                    userDefaults?.set(theData, forKey: "shareExtensionText")
                    userDefaults?.synchronize()
                    self.redirect(key: "shareExtensionText")
                }
            } else if attachment.hasItemConformingToTypeIdentifier("public.movie") {
                attachment.loadItem(forTypeIdentifier: "public.movie", options: nil) { [weak self] data, error in
                    if error == nil, let self = self {
                        var theData: Data? = nil
                        if let data = data as? Data {
                            theData = data
                        } else if let url = data as? URL {
                            theData = try? Data(contentsOf: url)
                        }
                        if index == (content.attachments?.count ?? 1) - 1 {
                            DispatchQueue.main.async {
                                let fileContent = theData ?? Data()
                                let sharedGroupContainerDirectory = FileManager().containerURL(
                                  forSecurityApplicationGroupIdentifier: "group.com.theblvd.mammoth.wormhole")
                                guard let fileURL = sharedGroupContainerDirectory?.appendingPathComponent("savedMedia.json") else { return }
                                try? fileContent.write(to: fileURL)
                                if let _ = try? Data(contentsOf: fileURL) {
                                    self.redirect(key: "shareExtensionVideo")
                                }
                            }
                        }
                    }
                }
            } else if attachment.hasItemConformingToTypeIdentifier(contentType) {
                attachment.loadItem(forTypeIdentifier: contentType, options: nil) { [weak self] data, error in
                    if error == nil, let self = self {
                        var theData: Data? = nil
                        if let data = data as? Data {
                            theData = data
                        } else if let url = data as? URL {
                            theData = try? Data(contentsOf: url)
                        } else if let imageData = data as? UIImage {
                            theData = imageData.pngData()
                        }
                        if index == (content.attachments?.count ?? 1) - 1 {
                            DispatchQueue.main.async {
                                let fileContent = theData ?? Data()
                                let sharedGroupContainerDirectory = FileManager().containerURL(
                                  forSecurityApplicationGroupIdentifier: "group.com.theblvd.mammoth.wormhole")
                                guard let fileURL = sharedGroupContainerDirectory?.appendingPathComponent("savedMedia.json") else { return }
                                try? fileContent.write(to: fileURL)
                                if let _ = try? Data(contentsOf: fileURL) {
                                    self.redirect(key: "shareExtensionMedia")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}
