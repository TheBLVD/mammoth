//
//  VariableBlurNavigationController.swift
//  Mammoth
//
//  Created by Sophia Tung on 8/5/24
//  Copyright © 2024 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class VariableBlurNavigationController: UINavigationController {
    
    private let tabBarGradientBackground: GradientView = {
        let view = GradientView(frame: CGRectZero, gradientDirection: .solidTopClearBottom)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let tabBarVariableBlurView: VariableBlurView = {
        let view = VariableBlurView(maxBlurRadius: 10, direction: .blurredTopClearBottom, startOffset: 0.1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTransparentNavigationBar()
        setupVariableBlur()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // setupTransparentNavigationBar()
    }
    
    private func setupTransparentNavigationBar() {
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        navigationBarAppearance.backgroundColor = .clear
        
        self.navigationBar.standardAppearance = navigationBarAppearance
        self.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        self.navigationBar.compactAppearance = navigationBarAppearance
        
        if #available(iOS 15.0, *) {
            self.navigationBar.compactScrollEdgeAppearance = navigationBarAppearance
        }
    }
    
    private func setupVariableBlur() {
        log.debug("LAYOUT: navigation setup")
        self.view.insertSubview(tabBarVariableBlurView, belowSubview: self.navigationBar)
        self.view.insertSubview(tabBarGradientBackground, belowSubview: self.navigationBar)
        
        NSLayoutConstraint.activate([
            tabBarVariableBlurView.topAnchor.constraint(equalTo: self.view.topAnchor),
            tabBarVariableBlurView.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
            tabBarVariableBlurView.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),
            tabBarVariableBlurView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            
            tabBarGradientBackground.topAnchor.constraint(equalTo: self.view.topAnchor),
            tabBarGradientBackground.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
            tabBarGradientBackground.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),
            tabBarGradientBackground.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor)
        ])
        
    }
    
    override func viewDidLayoutSubviews() {
        log.debug("LAYOUT: navigation layoutsubviews")
        
        //navigationBar.sendSubviewToBack(tabBarGradientBackground)
        //navigationBar.sendSubviewToBack(tabBarVariableBlurView)
    }
    
    // Ensure the navigation bar remains transparent when pushing/popping view controllers
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        log.debug("LAYOUT: navigation push")
        
        setupTransparentNavigationBar()
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        let viewController = super.popViewController(animated: animated)
        log.debug("LAYOUT: navigation pop")
        
        setupTransparentNavigationBar()
        return viewController
    }
    
    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        let viewControllers = super.popToViewController(viewController, animated: animated)
        log.debug("LAYOUT: navigation popto")
        
        setupTransparentNavigationBar()
        return viewControllers
    }
    
    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        let viewControllers = super.popToRootViewController(animated: animated)
        log.debug("LAYOUT: navigation poproot")
        
        setupTransparentNavigationBar()
        return viewControllers
    }
}
