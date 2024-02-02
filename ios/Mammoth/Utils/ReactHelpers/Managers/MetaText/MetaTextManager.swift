//
//  MetaTextManager.swift
//  Mammoth
//
//  Created by Benoit Nolens on 02/02/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit
import Meta
import MastodonMeta
import MetaTextKit

@objc(MetaTextManager)
class MetaTextManager: RCTViewManager {
    
    override func view() -> UIView! {
        return MetaTextView()
    }
    
    // Expose this method to React Native
//    @objc func myCustomFunction(_ node: NSNumber, value: NSNumber) {
//        DispatchQueue.main.async {
//            if let view = self.bridge.uiManager.view(forReactTag: node) as? MetaTextView {
//                view.myCustomFunction(value)
//            }
//        }
//    }
    
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}
