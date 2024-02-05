//
//  ReactBridge.swift
//  Mammoth
//
//  Created by Benoit Nolens on 31/01/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import Foundation
import React

class ReactBridge: NSObject {
    @objc static let shared = ReactBridge()

    @objc public lazy var bridge: RCTBridge = {
        guard let bridge = RCTBridge(delegate: self, launchOptions: nil) else {
            fatalError("Unable to instantiate RCTBridge")
        }
        return bridge
    }()
}

extension ReactBridge: RCTBridgeDelegate {

    func sourceURL(for bridge: RCTBridge!) -> URL! {
        return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
    }

    func viewForModule(_ moduleName: String, initialProperties: [String : Any]?) -> RCTRootView {
        return RCTRootView(bridge: self.bridge, moduleName: moduleName, initialProperties: initialProperties)
    }
}
