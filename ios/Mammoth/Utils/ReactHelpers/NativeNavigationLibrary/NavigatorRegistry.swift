//
//  NavigatorManager.swift
//  Mammoth
//
//  Created by Benoit Nolens on 31/01/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import Foundation

@objc(NavigationManager)
class NavigationManager: NSObject {
    
    @objc var route: NavigatorRoute {
        didSet { applyRoute() }
    }
    
    // Weak to prevent a retain cycle preventing the VC from deallocing.
    // This class is held indirectly by the life cycle of the ViewController.
    @objc weak var viewController: ReactViewController? = nil {
        didSet { applyRoute() }
    }
    
    init(route: NavigatorRoute, viewController: ReactViewController? = nil ) {
        self.route = route
        self.viewController = viewController
        super.init()
        applyRoute()
    }
    
    func updateRoute(route: NavigatorRoute, viewController: ReactViewController?) {
        self.route = route
        self.viewController = viewController
    }
    
    func navigationController() -> UINavigationController? {
        return viewController?.navigationController
    }
    
    func applyRoute() {
        if let title = route.title {
            viewController?.title = title
        }
        if let hidesBottomBarWhenPushed = route.hidesBottomBarWhenPushed {
            viewController?.hidesBottomBarWhenPushed = hidesBottomBarWhenPushed
        }
        if let navigationBar = route.navigationBar {
            viewController?.navigationController?.setNavigationBarHidden(navigationBar.hidden, animated: navigationBar.animated)
        }
        if let leftButtons = route.leftButtons {
            viewController?.navigationItem.leftBarButtonItems = leftButtons.barButtonItems(target: self, action: #selector(buttonPressed(button:)))
        }
        if let rightButtons = route.rightButtons {
            viewController?.navigationItem.rightBarButtonItems = rightButtons.barButtonItems(target: self, action: #selector(buttonPressed(button:)))
        }
        
        if let navigationItem = route.titleView {
            let rctView = RCTRootView(bridge: ReactBridge.shared.bridge, moduleName: navigationItem, initialProperties: [:])
            let frame = viewController?.navigationController?.navigationBar.bounds ?? CGRect.zero
            let customTitleView = RCCCustomTitleView(frame: frame, subView: rctView, alignment: "center")
            viewController?.navigationItem.titleView = customTitleView
        }
        
        if let _ = route.useTransparentBackground {
            viewController?.view.backgroundColor = .clear
            viewController?.reactView.backgroundColor = .clear
        }
    }
    
    @objc func buttonPressed(button: UIBarButtonItem) {
        
        guard let navigationButton = button.navigationButton else {
            return
        }

        let event = [
            "type": "NavBarButtonPress",
            "id" : navigationButton.id
        ]

        NavigationEventEmitter.globalNavigation()?.publishEvent(event)
    }
}



@objc(NavigationRegistry)
class NavigationRegistry: NSObject {
    
    @objc static public var ActiveRegistry: NavigationRegistry?

    override init() {
        super.init()
        NavigationRegistry.ActiveRegistry = self
    }
    
    private var registry: [Int: NavigationManager] = [:]
    
    func updateManager(tag: Int, viewController: ReactViewController?) {
        if let existingManager = navigationManager(forTag: tag) {
            existingManager.viewController = viewController
        }
    }
    
    @objc func update(tag: Int, route: NavigatorRoute, viewController: ReactViewController?) {
        if let existingManager = navigationManager(forTag: tag) {
            existingManager.updateRoute(route: route, viewController: viewController)
        } else {
            registry[tag] = NavigationManager(route: route, viewController: viewController)
        }
    }
    
    @objc func remove(tag: Int) {
        registry.removeValue(forKey: tag)
    }
    
    @objc func navigationManager(forTag tag: Int) -> NavigationManager? {
        return registry[tag]
    }
    
    // Debug-time only function. Called when RN hard-reloads
    @objc func _resetNavigation() {
        registry.keys.forEach { (key) in
            let manager: NavigationManager? = registry[key]
            manager?.viewController?.dismiss(animated: false, completion: nil)
            manager?.navigationController()?.popToRootViewController(animated: false)
        }
    }
}

@objc(NavigatorRoute)
class NavigatorRoute: NSObject {
    
    struct ReactKeys {
        static let routeId = "id"
        static let title = "title"
        static let titleView = "titleView"
        static let hidesBottomBarWhenPushed = "hidesBottomBarWhenPushed"
        static let leftButtons = "leftButtons"
        static let rightButtons = "rightButtons"
        static let navigationBar = "navigationBar"
        static let useTransparentBackground = "useTransparentBackground"
    }

    @objc var routeId: String?
    var title: String?
    var titleView: String?
    var hidesBottomBarWhenPushed: Bool?
    var navigationBar: (hidden: Bool, animated: Bool)?
    var leftButtons: Array<NavigationButton>?
    var rightButtons: Array<NavigationButton>?
    var useTransparentBackground: Bool?
    
    @objc init(dictionary: [String: Any]) {
        super.init()
        self.routeId = dictionary[ReactKeys.routeId] as? String
        self.title = dictionary[ReactKeys.title] as? String
        self.titleView = dictionary[ReactKeys.titleView] as? String
        self.hidesBottomBarWhenPushed = dictionary[ReactKeys.hidesBottomBarWhenPushed] as? Bool
        self.navigationBar = dictionary.navigationBar()
        self.leftButtons = dictionary.leftButtons()
        self.rightButtons = dictionary.rightButtons()
        self.useTransparentBackground = dictionary[ReactKeys.useTransparentBackground] as? Bool
    }
    
    //Obj-C Compatability
    @objc var objc_useTransparentBackground: Bool {
        if let useTransparentBackground = self.useTransparentBackground {
            return useTransparentBackground
        }
        return false;
    }
}

private extension Dictionary where Key == String, Value: Any {
    func navigationBar() -> (hidden: Bool, animated: Bool)? {
        if let hidesNav = self[NavigatorRoute.ReactKeys.navigationBar] as? [String: Bool],
            let visible = hidesNav["hidden"],
            let animated = hidesNav["animated"] {
            return (visible, animated)
        } else {
            return nil
        }
    }
    
    func leftButtons() -> Array<NavigationButton>? {
        guard let buttons = self[NavigatorRoute.ReactKeys.leftButtons] as? Array<[String: Any]> else {
            return nil
        }
        return buttons.map{ (dict: [String: Any]) -> NavigationButton in
            return NavigationButton(dictionary: dict)
        }
    }
    
    func rightButtons() -> Array<NavigationButton>? {
        guard let buttons = self[NavigatorRoute.ReactKeys.rightButtons] as? Array<[String: Any]> else {
            return nil
        }
        return buttons.map{ (dict: [String: Any]) -> NavigationButton in
            return NavigationButton(dictionary: dict)
        }
    }
}


struct NavigationButton {
    let id: String
    let title: String
    let disabled: Bool
    let color: String
    let customView: String? // Name of the custom component if supplied
    let image: UIImage?
    
    init(dictionary: [String: Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.title = dictionary["title"] as? String ?? ""
        self.disabled = dictionary["disabled"] as? Bool ?? false
        self.color = dictionary["color"] as? String ?? ""
        self.customView = dictionary["component"] as? String ?? nil
        if let imageData = dictionary["image"] {
            let image = RCTConvert.uiImage(imageData)
            self.image = image
        } else {
            self.image = nil
        }
    }
}

extension Array where Element == NavigationButton {
    
    func barButtonItems(target: NSObject, action: Selector) -> Array<UIBarButtonItem> {
        return self.map{ (navigationButton: NavigationButton) -> UIBarButtonItem in
           
            let item = UIBarButtonItem(title: navigationButton.title,
                                       style: UIBarButtonItem.Style.plain,
                                       target: target,
                                       action: action);
            // Check if a custom component/view was passed
            if let customViewName = navigationButton.customView {
                let rctView = RCTRootView(bridge: ReactBridge.shared.bridge, moduleName: customViewName, initialProperties: [:])
                let frame = rctView.frame
                let customView = RCCCustomTitleView(frame: frame, subView: rctView, alignment: "center")
                if let customView = customView {
                    item.customView = customView
                }
            }
            
            // Check for an Image
            if let image = navigationButton.image {
                item.image = image
            }
            
            item.isEnabled = !navigationButton.disabled
            if let color = UIColor.init(hexString: navigationButton.color) {
                item.setTitleTextAttributes([.foregroundColor: color], for: .normal)
                item.setTitleTextAttributes([.foregroundColor: color], for: .highlighted)
            }
            item.navigationButton = navigationButton
            return item
        }
    }
}

/**
 * Associate the NavigationButton data w the UIBarButtonItem to accomodate
 * for how target-action works in cocoa. This allows us to identify
 * which UIBarButtonItem has been tapped.
 * */
private var AssociatedObjectHandle: UInt8 = 0
private extension UIBarButtonItem {
    var navigationButton: NavigationButton? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectHandle) as? NavigationButton
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectHandle, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
