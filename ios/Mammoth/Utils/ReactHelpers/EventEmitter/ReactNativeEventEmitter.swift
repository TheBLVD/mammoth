//
//  ReactNativeEventEmitter.swift
//  Mammoth
//
//  Created by Benoit Nolens on 05/02/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//


import Foundation

@objc(ReactNativeEventEmitter)
open class ReactNativeEventEmitter: RCTEventEmitter {
    
    override init() {
        super.init()
        EventEmitter.shared.registerEventEmitter(eventEmitter: self)
    }
    
    /// Base overide for RCTEventEmitter.
    ///
    /// - Returns: all supported events
    @objc open override func supportedEvents() -> [String] {
        return EventEmitter.shared.allEvents
    }

}
