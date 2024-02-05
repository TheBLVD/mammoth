//
//  ReactViewController.swift
//  Mammoth
//
//  Created by Benoit Nolens on 31/01/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit
import React

@objc(ReactViewController)
class ReactViewController: UIViewController {
    
    private let moduleName: String
    var reactView: RCTRootView!
    let initialProps:[String : Any]?
    
    @objc var reactTag: NSNumber {
        return reactView.reactTag
    }
    
    override func loadView() {
        super.loadView()
        self.reactView = ReactBridge.shared.viewForModule(self.moduleName, initialProperties: self.initialProps)
        self.reactView.setReactViewController(self)
        self.view = self.reactView
    }
    
    @objc init(moduleName: String, initialProperties: [String : Any]? = nil) {
        self.moduleName = moduleName
        self.initialProps = initialProperties
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = .custom.background
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NavigationEventEmitter.globalNavigation()?.publishScreenChangeEvent(.viewWillAppear, rootTag: self.reactTag)
        // Natively handle hiding showing nav bar so it is immediate.
        if let navBarProps = self.initialProps?["navigationBar"] as? [String: Any], let hidden = navBarProps["hidden"] as? Bool {
            let animated = navBarProps["animated"] as? Bool ?? false
            self.navigationController?.setNavigationBarHidden(hidden, animated: animated)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NavigationEventEmitter.globalNavigation()?.publishScreenChangeEvent(.viewDidAppear, rootTag: self.reactTag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NavigationEventEmitter.globalNavigation()?.publishScreenChangeEvent(.viewWillDisappear, rootTag: self.reactTag)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NavigationEventEmitter.globalNavigation()?.publishScreenChangeEvent(.viewDidDisappear, rootTag: self.reactTag)
    }
}
