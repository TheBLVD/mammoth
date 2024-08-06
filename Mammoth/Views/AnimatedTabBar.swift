//
//  AnimatedTabBar.swift
//  Mammoth
//
//  Created by Riley Howard on 8/8/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

private let animationDuration = 0.3
private let animationSpringDampening = 0.8
private let animationInitialVelocity = 0.9

private let tabBarIconTouchedScaleFactor = 1.2

private let pillHeight = 35.0
private let pillHorizontalMargin = 15.0
private let pillVerticalMargin = 12.0
private let gapBetweenButtons = 5.0
private let gapBetweenImageAndTitle = 7.0

class AnimatedTabBarController: UITabBarController {
    let animatedTabBar = AnimatedTabBarView()
    private let tabBarBackground: BlurredBackground = {
        let view = BlurredBackground(dimmed: true)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let tabBarGradientBackground: GradientView = {
        let view = GradientView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let tabBarVariableBlurView: VariableBlurView = {
        let view = VariableBlurView(maxBlurRadius: 10, direction: .blurredBottomClearTop, startOffset: 0.1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.isHidden = false
        tabBar.layer.opacity = 0
        tabBar.isTranslucent = true

        if #available(iOS 15.0, *) {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithTransparentBackground()
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            tabBar.standardAppearance = tabBarAppearance
            tabBar.scrollEdgeAppearance = tabBarAppearance
        }
        
        setupUI()
    }
    
    private func setupUI() {
        // self.view.addSubview(tabBarBackground)
        self.view.addSubview(tabBarVariableBlurView)
        self.view.addSubview(tabBarGradientBackground)
        self.view.addSubview(animatedTabBar)
        animatedTabBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tabBarVariableBlurView.topAnchor.constraint(equalTo: tabBar.topAnchor),
            tabBarVariableBlurView.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            tabBarVariableBlurView.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            tabBarVariableBlurView.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor),
            
            tabBarGradientBackground.topAnchor.constraint(equalTo: tabBar.topAnchor),
            tabBarGradientBackground.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            tabBarGradientBackground.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            tabBarGradientBackground.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor),
            
            animatedTabBar.topAnchor.constraint(equalTo: tabBar.topAnchor),
            animatedTabBar.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            animatedTabBar.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            animatedTabBar.bottomAnchor.constraint(equalTo: tabBar.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // When setViewControllers is called, create the related
    // AnimatedTabBarView buttons.
    override func setViewControllers(_ viewControllers: [UIViewController]?, animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        createTabBarView()
    }

    private func createTabBarView() {
        var animTabBarItems: [AnimatedTabBarItem] = []
        for vc in viewControllers! {
            let tabBarItem = vc.tabBarItem!
            let animTabBarItem = AnimatedTabBarItem(icon: tabBarItem.image!, title: tabBarItem.title!)
            animTabBarItem.translatesAutoresizingMaskIntoConstraints = false
            animTabBarItem.addTarget(self, action: #selector(self.barItemTap), for: .touchUpInside)
            
            animTabBarItems.append(animTabBarItem)
        }
        animatedTabBar.setTabBarItems(animTabBarItems)
    }
    
    public func showActivityUnreadIndicator() {
        let items = animatedTabBar.tabBarItems
        items[2].unreadDot.isHidden = false
    }
    
    public func hideActivityUnreadIndicator() {
        let items = animatedTabBar.tabBarItems
        items[2].unreadDot.isHidden = true
    }
    
    public func showMessagesUnreadIndicator() {
        let items = animatedTabBar.tabBarItems
        items[3].unreadDot.isHidden = false
    }
    
    public func hideMessagesUnreadIndicator() {
        let items = animatedTabBar.tabBarItems
        items[3].unreadDot.isHidden = true
    }

    @objc func barItemTap(_ sender: Any) {
        guard let animatedTabBarItem = sender as? AnimatedTabBarItem else {
            log.error("unexpected type")
            return
        }
        if let itemIndex = animatedTabBar.indexOfTabBarItem(animatedTabBarItem) {
            self.selectedIndex = itemIndex
        }
    }
    
    override var selectedViewController: UIViewController? {
        didSet {
            animatedTabBar.selectTabBarItemAtIndex(self.selectedIndex)
        }
    }

    override var selectedIndex: Int {
        didSet {
            animatedTabBar.selectTabBarItemAtIndex(self.selectedIndex)
        }
    }
}

class AnimatedTabBarView: UIView {
    
    var tabBarItems = [AnimatedTabBarItem]()
    let itemsStackView = UIStackView()
    let selectionPill: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: UIScreen.main.traitCollection.userInterfaceStyle == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight)
        let view = UIVisualEffectView(effect: blurEffect)
        view.layer.cornerRadius = pillHeight / 2
        // view.layer.opacity = 0.85
        view.clipsToBounds = true
        // view.backgroundColor = .custom.OVRLYMedContrast
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
    var pillLeadingConstraint: NSLayoutConstraint?
    var pillWidthConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func setTabBarItems(_ items: [AnimatedTabBarItem]) {
        // Remove all previous subviews
        itemsStackView.arrangedSubviews.forEach({
            itemsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        })
        
        tabBarItems = items
        
        // Create and add new buttons + unread indicator if needed
        for tabBarItem in tabBarItems {
            itemsStackView.addArrangedSubview(tabBarItem)
        }
    }
    
    private func setupUI() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(itemsStackView)
        itemsStackView.axis = .horizontal
        itemsStackView.distribution = .equalSpacing
        itemsStackView.alignment = .center
        itemsStackView.spacing = gapBetweenButtons
        itemsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let leading = itemsStackView.leadingAnchor.constraint(lessThanOrEqualTo: self.leadingAnchor, constant: 32)
        leading.priority = .defaultLow
        let trailing = itemsStackView.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -32)
        trailing.priority = .defaultLow
        
        NSLayoutConstraint.activate([
            itemsStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 1),
            leading,
            trailing,
            itemsStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            itemsStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
        
        self.addSubview(selectionPill)
        pillLeadingConstraint = selectionPill.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0)
        pillWidthConstraint = selectionPill.widthAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            pillLeadingConstraint!,
            pillWidthConstraint!,
            selectionPill.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            selectionPill.heightAnchor.constraint(equalToConstant: pillHeight)
        ])
        self.bringSubviewToFront(itemsStackView)
    }
    
    func indexOfTabBarItem(_ animatedTabBarItem: AnimatedTabBarItem) -> Int? {
        return tabBarItems.firstIndex(of: animatedTabBarItem)
    }
    
    func selectTabBarItemAtIndex(_ itemIndex: Int) {
        self.layoutIfNeeded()
        for (index, tabBarItem) in self.tabBarItems.enumerated() {
            tabBarItem.isSelected = (index == itemIndex)
        }
        
        UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: animationSpringDampening, initialSpringVelocity: animationInitialVelocity, options: [.curveEaseOut, .allowUserInteraction], animations: {
            self.layoutIfNeeded()
        })
        
        for tabBarItem in self.tabBarItems {
            if tabBarItem.isSelected {
                let tabBarItemFrame = tabBarItem.bounds
                let tabBarItemOrigin = self.convert(tabBarItemFrame, from: tabBarItem).origin
                
                self.pillLeadingConstraint!.constant = tabBarItemOrigin.x
                self.pillWidthConstraint!.constant = tabBarItemFrame.size.width
                UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: animationSpringDampening, initialSpringVelocity: animationInitialVelocity, options: [.beginFromCurrentState], animations: {
                    tabBarItem.tintColor = .custom.tabBarSelected
                    tabBarItem.setTitleColor(.custom.tabBarSelected, for: .normal)
                    tabBarItem.unreadDot.backgroundColor = .custom.tabBarSelected
                    
                    self.layoutIfNeeded()
                })
            } else {
                UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: animationSpringDampening, initialSpringVelocity: animationInitialVelocity, options: [.beginFromCurrentState], animations: {
                    tabBarItem.tintColor = .custom.tabBarForeground
                    tabBarItem.setTitleColor(.custom.tabBarForeground, for: .normal)
                    tabBarItem.unreadDot.backgroundColor = .custom.tabBarForeground
                    
                    self.layoutIfNeeded()
                })
            }
        }
    }
}

// MARK: Appearance changes
internal extension AnimatedTabBarView {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 let blurEffect = UIBlurEffect(style: UIScreen.main.traitCollection.userInterfaceStyle == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterial)
                 self.selectionPill.effect = blurEffect
             }
         }
    }
}

class AnimatedTabBarItem: UIButton {
    private let itemTitle: String
    let unreadDot: UIView = {
        let view = UIView()
        // view.backgroundColor = .custom.mediumContrast
        view.clipsToBounds = true
        view.layer.cornerRadius = 2.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    required init(icon: UIImage, title: String, isUnread: Bool = false) {
        self.itemTitle = title.uppercased()
        super.init(frame: .zero)
        self.alpha = 0

        translatesAutoresizingMaskIntoConstraints = false
        self.clipsToBounds = true
        self.adjustsImageWhenHighlighted = false
        
        self.setImage(icon.withRenderingMode(.alwaysTemplate)/*.withShadow()*/, for: .normal)
        self.tintColor = .custom.tabBarForeground

        // Setting the title during init is needed to
        // correctly set the frame. If not done, the label animates in
        // from the top left on its first animation.
        self.setTitle(title, for: .normal)
        self.titleLabel?.sizeToFit()
        
        self.titleLabel?.alpha = 0
        self.setTitle(title, for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setTitle("", for: .normal)
            self.alpha = 1
        }
        
        self.setTitleColor(.custom.tabBarForeground, for: .normal)
        
        self.unreadDot.isHidden = !isUnread
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.titleLabel?.font = .systemFont(ofSize: 10.0, weight: .bold)
        self.contentHorizontalAlignment = .center
        
        self.addSubview(unreadDot)
        
        NSLayoutConstraint.activate([
            unreadDot.widthAnchor.constraint(equalToConstant: 5),
            unreadDot.heightAnchor.constraint(equalToConstant: 5),
            unreadDot.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            unreadDot.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        let widthC = self.widthAnchor.constraint(greaterThanOrEqualToConstant: 28)
        widthC.priority = .required
        widthC.isActive = true
        
        let contentPadding = UIEdgeInsets(top: pillVerticalMargin, left: 0, bottom: pillVerticalMargin, right: 0)
        self.setInsets(forContentPadding: contentPadding, imageTitlePadding: 0)
    }
    
    override var isSelected: Bool {
        didSet {
            let imageTitleGap = isSelected ? gapBetweenImageAndTitle : 0.0
            let t = isSelected ? itemTitle : ""
            if t != self.title(for: .normal) {
                self.setTitle(t, for: .normal)
                self.titleLabel?.alpha = self.isSelected ? 1 : 0
                
                let contentPadding = UIEdgeInsets(top: pillVerticalMargin, left: pillHorizontalMargin, bottom: pillVerticalMargin, right: pillHorizontalMargin)
                self.setInsets(forContentPadding: contentPadding, imageTitlePadding: imageTitleGap)
            }
        }
    }
    
    // Larger tap targets
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let biggerFrame = bounds.insetBy(dx: -20, dy: -30)
        return biggerFrame.contains(point)
    }
    
    // MARK: Interaction Animations
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        accentImageView(self)
        
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let viewTestingTouch = touch.location(in: self)
        
        if self.bounds.contains(viewTestingTouch) {
            accentImageView(self)
        } else {
            unaccentImageView(self)
        }
        
        super.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        unaccentImageView(self)
        
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        unaccentImageView(self)
        
        super.touchesCancelled(touches, with: event)
    }
    
    func accentImageView(_ view: UIView) {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.9, options: .beginFromCurrentState, animations: {
            view.transform = CGAffineTransform(scaleX: tabBarIconTouchedScaleFactor, y: tabBarIconTouchedScaleFactor)
        }, completion: nil)
    }
    
    func unaccentImageView(_ view: UIView) {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.9, options: .beginFromCurrentState, animations: {
            view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }, completion: nil)
    }
}

internal extension AnimatedTabBarItem {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 if self.isSelected {
                     self.tintColor = .custom.tabBarSelected
                     self.setTitleColor(.custom.tabBarSelected, for: .normal)
                     self.unreadDot.backgroundColor = .custom.tabBarSelected
                 } else {
                     self.tintColor = .custom.tabBarForeground
                     self.setTitleColor(.custom.tabBarForeground, for: .normal)
                     self.unreadDot.backgroundColor = .custom.tabBarForeground
                 }
             }
         }
    }
}

fileprivate extension UIButton {
    func setInsets(
        forContentPadding contentPadding: UIEdgeInsets,
        imageTitlePadding: CGFloat
    ) {
        self.contentEdgeInsets = UIEdgeInsets(
            top: contentPadding.top,
            left: contentPadding.left,
            bottom: contentPadding.bottom,
            right: contentPadding.right + imageTitlePadding
        )
        self.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: imageTitlePadding,
            bottom: 0,
            right: -imageTitlePadding
        )
    }
}

extension UIImage {
    // Returns a new image with the specified shadow properties.
    // This will increase the size of the image to fit the shadow and the original image.
    func withShadow(blur: CGFloat = 3, offset: CGSize = .zero, color: UIColor = UIColor(white: 1, alpha: 0.8)) -> UIImage {

        let shadowRect = CGRect(
            x: offset.width - blur,
            y: offset.height - blur,
            width: size.width + blur * 2,
            height: size.height + blur * 2
        )
        
        UIGraphicsBeginImageContextWithOptions(
            CGSize(
                width: max(shadowRect.maxX, size.width) - min(shadowRect.minX, 0),
                height: max(shadowRect.maxY, size.height) - min(shadowRect.minY, 0)
            ),
            false, 0
        )
        
        let context = UIGraphicsGetCurrentContext()!

        context.setShadow(
            offset: offset,
            blur: blur,
            color: color.cgColor
        )
        
        draw(
            in: CGRect(
                x: max(0, -shadowRect.origin.x),
                y: max(0, -shadowRect.origin.y),
                width: size.width,
                height: size.height
            )
        )
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        return image
    }
}
