//
//  ComposerViewController.swift
//  Mammoth
//
//  Created by Benoit Nolens on 30/01/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit
import React

class ComposeViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.setupUI()
    }
}

private extension ComposeViewController {
    func setupUI() {
        if let jsCodeLocation = URL(string: "http://localhost:8081/index.bundle?platform=ios") {
            let rootView = RCTRootView(
              bundleURL: jsCodeLocation,
              moduleName: "Composer",
              initialProperties: nil,
              launchOptions: nil
            )
            
            self.view = rootView
        }
    }
}
