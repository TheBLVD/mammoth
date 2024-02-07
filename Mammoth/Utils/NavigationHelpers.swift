//
//  Utility.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 28/03/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

func getTopMostViewController() -> UIViewController? {
    var topMostViewController = UIApplication.shared.preferredApplicationWindow?.rootViewController
    while let presentedViewController = topMostViewController?.presentedViewController {
        topMostViewController = presentedViewController
    }
    return topMostViewController
}

func getTabBarController() -> AnimateTabController? {
    return UIApplication.shared.preferredApplicationWindow?.rootViewController as? AnimateTabController
}
