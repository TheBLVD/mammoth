//
//  Jumpable.swift
//  Mammoth
//
//  Created by Riley Howard on 6/14/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

protocol Jumpable {
    func controlBar(didSelect index: Int)
    func viewControllerAtIndex(_ index: Int) -> UIViewController?
    func barSingleTap(didSelect index: Int)
    func barDoubleTap(didSelect index: Int)
}

var previousTapDate: Date? = nil
var previousTappedIndex: Int?  = nil

extension Jumpable {

    func controlBar(didSelect index: Int) {        
        // Determine if this is a single or a double tap
        var isDoubleTap = false
        if index == previousTappedIndex {
            if let timeSincePreviousTap = previousTapDate?.timeIntervalSinceNow {
                isDoubleTap = timeSincePreviousTap > -0.4
            }
        }
        previousTapDate = Date()
        previousTappedIndex = index
        if isDoubleTap {
            self.barDoubleTap(didSelect: index)
        } else {
            self.barSingleTap(didSelect: index)
        }
    }
        
    func barDoubleTap(didSelect index: Int) {
        log.warning(#function)
        triggerHaptic2Impact()
        
        // Jump to Newest
        let jumpToSelector = Selector("jumpToNewest")
        if let currentViewController = viewControllerAtIndex(index) {
            if currentViewController.responds(to: jumpToSelector) {
                let success = UIApplication.shared.sendAction(jumpToSelector, to: currentViewController, from: self, for: nil)
                if !success {
                    log.warning("no handler for jumpToNewest:")
                }
            } else {
                log.warning("currentVC does not respond to jumpToSelector")
            }
        } else {
            log.warning("[jumpToSelector] cannot find VC at index")
        }
    }



}
