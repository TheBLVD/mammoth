//
//  SingleColumnViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 01/07/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class SingleColumnViewController: UIViewController {
    
    var viewController: UIViewController = UIViewController() {
        didSet {
            self.view.addSubview(viewController.view)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up nav bar
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        self.navigationController?.navigationBar.standardAppearance = navApp
        self.navigationController?.navigationBar.scrollEdgeAppearance = navApp
        self.navigationController?.navigationBar.compactAppearance = navApp
        if #available(iOS 15.0, *) {
            self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
        }
        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewController.view.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        self.navigationController?.navigationBar.standardAppearance = navApp
        self.navigationController?.navigationBar.scrollEdgeAppearance = navApp
        self.navigationController?.navigationBar.compactAppearance = navApp
        if #available(iOS 15.0, *) {
            self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
        }
        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }
    }
    
}
