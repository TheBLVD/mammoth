//
//  UIKitScreenTracking.swift
//  Mammoth
//
//  Created by Benoit Nolens on 22/04/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import Foundation
import Segment

// Conform to this protocol if self-tracking screens are desired
@objc protocol UIKitScreenTrackable: NSObjectProtocol {
    @objc func seg__trackScreen(name: String?)
}

class UIKitScreenTracking: UtilityPlugin {
    static let notificationName = Notification.Name(rawValue: "UIKitScreenTrackNotification")
    static let screenNameKey = "name"
    static let controllerKey = "controller"
    
    static let ignoredViewControllers = [
        "UIPageViewController",
        "UIInputWindowController",
        "UINavigationController",
        "UIInputWindowController",
        "Mammoth.HomeViewController"
    ]
    
    let type = PluginType.utility
    weak var analytics: Analytics? = nil
    
    init() {
        setupUIKitHooks()
    }

    internal func setupUIKitHooks() {
        swizzle(forClass: UIViewController.self,
                original: #selector(UIViewController.viewDidAppear(_:)),
                new: #selector(UIViewController.seg__viewDidAppear)
        )

        NotificationCenter.default.addObserver(forName: Self.notificationName, object: nil, queue: OperationQueue.main) { notification in
            let name = notification.userInfo?[Self.screenNameKey] as? String
            if let controller = notification.userInfo?[Self.controllerKey] as? UIKitScreenTrackable {
                // if the controller conforms to UIKitScreenTrackable,
                // call the trackScreen method with the name we have (possibly even nil)
                // and the implementor will decide what to do.
                controller.seg__trackScreen(name: name)
            } else if let name = name {
                // if we have a name, call screen
                self.analytics?.screen(title: name)
            }
        }
    }
}

extension UIKitScreenTracking {
    private func swizzle(forClass: AnyClass, original: Selector, new: Selector) {
        guard let originalMethod = class_getInstanceMethod(forClass, original) else { return }
        guard let swizzledMethod = class_getInstanceMethod(forClass, new) else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

extension UIViewController {
    internal func activeController() -> UIViewController? {
        if let root = viewIfLoaded?.window?.rootViewController {
            return root
        } else if #available(iOS 13.0, *) {
            // preferred way to get active controller in ios 13+
            for scene in UIApplication.shared.connectedScenes {
                if scene.activationState == .foregroundActive {
                    let windowScene = scene as? UIWindowScene
                    let sceneDelegate = windowScene?.delegate as? UIWindowSceneDelegate
                    if let target = sceneDelegate, let window = target.window {
                        return window?.rootViewController
                    }
                }
            }
        } else {
            // this was deprecated in ios 13.0
            return UIApplication.shared.keyWindow?.rootViewController
        }
        return nil
    }
    
    internal func captureScreen() {
        let isIgnoredVC = UIKitScreenTracking.ignoredViewControllers.reduce(false) { result, current in
            if self.isOfType(className: current) {
                return true
            }
            
            return result
        }
        
        guard !isIgnoredVC else { return }
        
        var rootController = viewIfLoaded?.window?.rootViewController
        if rootController == nil {
            rootController = activeController()
        }
        guard let top = Self.seg__visibleViewController(activeController()) else { return }
        
        var name = String(describing: top.self.classForCoder).replacingOccurrences(of: "ViewController", with: "")
        if let newsFeedVC = top as? NewsFeedViewController {
            name = newsFeedVC.type.trackingTitle()
        }
        // name could've been just "ViewController"...
        if  name.count == 0 || name == "UI" {
            guard let title = top.title else { return }
            name = title
        }

        // post a notification that our plugin can capture.
        // if you were to do a custom implementation of how the name should
        // appear, you probably want to inspect the viewcontroller itself, `top` in this
        // case to generate your string for name and/or category.
        NotificationCenter.default.post(name: UIKitScreenTracking.notificationName,
                                        object: self,
                                        userInfo: [UIKitScreenTracking.screenNameKey: name,
                                                   UIKitScreenTracking.controllerKey: top])
    }
    
    @objc internal func seg__viewDidAppear(animated: Bool) {
        captureScreen()
        seg__viewDidAppear(animated: animated)
    }
    
    static func seg__visibleViewController(_ controller: UIViewController?) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return seg__visibleViewController(navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return seg__visibleViewController(selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return seg__visibleViewController(presented)
        }
        if let homeVC = controller as? HomeViewController {
            return seg__visibleViewController(homeVC.currentPage())
        }
        if let discoverVC = controller as? SearchHostViewController {
            return seg__visibleViewController(discoverVC.currentPage())
        }
        if let activityVC = controller as? ActivityViewController {
            return seg__visibleViewController(activityVC.currentPage())
        }
        if let mentionsVC = controller as? MentionsViewController {
            return seg__visibleViewController(mentionsVC.currentPage())
        }
        return controller
    }
    
    internal func isOfType(className: String) -> Bool {
        if let className: AnyClass = NSClassFromString(className),
           self.isKind(of: className) {
            return true
        }
        
        return false
    }
}
