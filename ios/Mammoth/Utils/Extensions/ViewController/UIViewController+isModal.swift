//
//  UIViewController+isModal.swift
//  Mammoth
//
//  Created by Benoit Nolens on 25/08/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

extension UIViewController {
    var isModal: Bool {
        let presentingIsModal = presentingViewController != nil
        let presentingIsNavigation = navigationController?.presentingViewController?.presentedViewController == navigationController
        let presentingIsTabBar = tabBarController?.presentingViewController is UITabBarController

        return presentingIsModal || presentingIsNavigation || presentingIsTabBar
    }
}
