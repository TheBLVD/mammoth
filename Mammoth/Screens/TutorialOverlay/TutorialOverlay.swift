//
//  TutorialOverlay.swift
//  Mammoth
//
//  Created by Benoit Nolens on 06/12/2023
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class TutorialOverlay: UIViewController {
    
    public enum TutorialOverlayTypes: String, CaseIterable {
        case customizeFeed
        case forYou
        case smartList
        case quickFeedSwitcher
        case quickAccountSwitcher
        
        var description: String {
            switch self {
            case .customizeFeed:
                return String.localizedStringWithFormat(NSLocalizedString("tutorial.customize", comment: ""), NSLocalizedString("feed.customize", comment: ""))

            case .forYou:
                return NSLocalizedString("tutorial.forYou", comment: "")
            case .smartList:
                return NSLocalizedString("tutorial.smartList", comment: "")
            case .quickFeedSwitcher:
                return NSLocalizedString("tutorial.feedSwitch", comment: "")
            case .quickAccountSwitcher:
                return NSLocalizedString("tutorial.accountSwitch", comment: "")
            }
        }
        
        var header: UIView? {
            switch self {
            case .quickAccountSwitcher:
                return {
                    let view = UIStackView()
                    view.axis = .horizontal
                    view.spacing = 6
                    view.isLayoutMarginsRelativeArrangement = true
                    view.layoutMargins = .init(top: 3, left: 0, bottom: 0, right: 0)
                    ["\u{f2bd}", "\u{f356}", "\u{f2bd}"].map({
                        UIImageView(image: FontAwesome.image(fromChar: $0, size: 16, weight: .bold).withRenderingMode(.alwaysTemplate))
                    })
                    .forEach({
                        view.addArrangedSubview($0)
                    })
                    return view
                }()
            default:
                return nil
            }
        }
        
        var width: CGFloat {
            switch self {
            case .customizeFeed:
                return 218
            case .forYou:
                return 218
            case .smartList:
                return 216
            case .quickFeedSwitcher:
                return 157
            case .quickAccountSwitcher:
                return 157
            }
        }
        
        var arrowAlignment: ArrowAlignment {
            switch self {
            case .customizeFeed:
                return .topRight
            case .forYou:
                return .topCenter
            case .smartList:
                return .topCenter
            case .quickFeedSwitcher:
                return .bottomLeft
            case .quickAccountSwitcher:
                return .bottomRight
            }
        }
    }
    
    private let type: TutorialOverlayTypes
    private let ref: UIView
    private var mask: CALayer?
    
    private let spacing = 10.0
    private var leadingConstraint: NSLayoutConstraint?
    
    private let bubble: TextBubbleView!
    private var refSnapshot: UIView?
    private let onComplete: (() -> Void)?
    
    private let bubbleStack = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let bubbleText: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.custom.highContrast
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .regular)
        return label
    }()
    
    init(type: TutorialOverlayTypes, ref: UIView, onComplete: (() -> Void)? = nil) {
        self.type = type
        self.ref = ref
        self.bubble = TextBubbleView(alignment: type.arrowAlignment)
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = TouchDelegatingView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setupUI()
        
        if let delegatingView = view as? TouchDelegatingView {
            delegatingView.touchDelegate = presentingViewController?.view
            delegatingView.ref = self.refSnapshot
            delegatingView.dismissCallback = { [weak self] animated in
                guard let self else { return }
                
                if !animated {
                    self.dismiss(animated: false)
                } else {
                    UIView.animate(withDuration: 0.2, delay: 0.0, animations: { [weak self] in
                        guard let self else { return }
                        self.bubble.transform = .init(translationX: 0, y: 20)
                        self.bubble.alpha = 0
                        self.view.backgroundColor = .clear
                    })
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.dismiss(animated: false) { [weak self] in
                            guard let self else { return }
                            self.onComplete?()
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let refOrigin = self.ref.convert(CGPoint.zero, to: self.view)
            
            // Update arrow location on orientation change and window resize
            switch self.type.arrowAlignment {
            case .topLeft:
                self.leadingConstraint?.constant = refOrigin.x - self.bubble.rightArrowOffset
            case .topCenter:
                self.leadingConstraint?.constant = refOrigin.x + (ref.frame.width / 2) - (self.type.width / 2)
            case .topRight:
                self.leadingConstraint?.constant = refOrigin.x - 218 + 30 + self.bubble.rightArrowOffset
            default:
                break
            }
            
            // Update ref snapshot location on orientation change and window resize
            self.refSnapshot?.frame = .init(x: refOrigin.x, y: refOrigin.y, width: self.ref.frame.size.width, height: self.ref.frame.size.height)
        }
    }
    
    func setupUI() {
        self.bubble.translatesAutoresizingMaskIntoConstraints = false
        self.bubble.alpha = 0
        self.bubble.transform = .init(translationX: 0, y: 20)
        
        let refOrigin = ref.convert(CGPoint.zero, to: self.view)
        
        self.bubble.layoutMargins = .init(top: 22, left: 16, bottom: 23, right: 16)
        self.view.addSubview(self.bubble)
        
        if let header = self.type.header {
            self.bubbleStack.addArrangedSubview(header)
        }
        
        self.bubbleText.text = self.type.description
        self.bubbleStack.addArrangedSubview(self.bubbleText)
        self.bubble.addSubview(self.bubbleStack)
        
        switch self.type.arrowAlignment {
        case .topLeft, .bottomLeft:
            self.leadingConstraint = bubble.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: refOrigin.x - self.bubble.rightArrowOffset - (self.bubble.arrowWidth / 2) + (ref.frame.width / 2))
        case .topCenter, .bottomCenter:
            self.leadingConstraint = bubble.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: refOrigin.x + (ref.frame.width / 2) - (self.type.width / 2))
        case .topRight, .bottomRight:
            self.leadingConstraint = bubble.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: refOrigin.x - self.type.width + 30 + self.bubble.rightArrowOffset)
        }
        
        switch self.type.arrowAlignment {
        case .topLeft, .topCenter, .topRight:
            bubble.topAnchor.constraint(equalTo: self.view.topAnchor, constant: refOrigin.y + ref.frame.size.height - 8).isActive = true
            break
        case .bottomLeft, .bottomCenter, .bottomRight:
            bubble.bottomAnchor.constraint(equalTo: self.view.topAnchor, constant: refOrigin.y).isActive = true
            break
        }
        
        
        NSLayoutConstraint.activate([
            bubble.widthAnchor.constraint(lessThanOrEqualToConstant: 218),
            leadingConstraint!,
            
            bubbleStack.topAnchor.constraint(equalTo: bubble.layoutMarginsGuide.topAnchor),
            bubbleStack.bottomAnchor.constraint(equalTo: bubble.layoutMarginsGuide.bottomAnchor),
            bubbleStack.leadingAnchor.constraint(equalTo: bubble.layoutMarginsGuide.leadingAnchor),
            bubbleStack.trailingAnchor.constraint(equalTo: bubble.layoutMarginsGuide.trailingAnchor)
        ])
        
        if let refSnapshot = self.ref.snapshotView(afterScreenUpdates: true) {
            refSnapshot.frame = .init(x: refOrigin.x, y: refOrigin.y, width: self.ref.frame.size.width, height: self.ref.frame.size.height)
            self.refSnapshot = refSnapshot
            self.view.addSubview(refSnapshot)
            
            UIView.animate(withDuration: 1, delay: 0.0) { [weak self] in
                guard let self else { return }
                self.view.backgroundColor = UIColor.custom.background.withAlphaComponent(0.75)
            }
        }
        
        if #available(iOS 17.0, *) {
            UIView.animate(springDuration: 0.5, bounce: 0.4, initialSpringVelocity: 0.9, delay: 0.3, animations: { [weak self] in
                guard let self else { return }
                self.bubble.alpha = 1
                self.bubble.transform = .init(translationX: 0, y: 0)
            }) { [weak self] _ in
                if let delegatingView = self?.view as? TouchDelegatingView {
                    delegatingView.isAnimating = false
                }
            }
        } else {
            UIView.animate(withDuration: 0.3, delay: 0.3, animations: { [weak self] in
                guard let self else { return }
                self.bubble.transform = .init(translationX: 0, y: 0)
            }) { [weak self] _ in
                if let delegatingView = self?.view as? TouchDelegatingView {
                    delegatingView.isAnimating = false
                }
            }
        }
    }
}

class TouchDelegatingView: UIView {
    weak var touchDelegate: UIView? = nil
    weak var ref: UIView? = nil
    var isAnimating: Bool = true
    var dismissCallback: (_ animated: Bool) -> Void = {animated in }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard ![.hover].contains(event?.type) else { return nil}
        guard !isAnimating else { return nil }
        
        guard let view = super.hitTest(point, with: event) else {
            return touchDelegate?.hitTest(point, with: event)
        }
        
        guard view === self, let point = touchDelegate?.convert(point, from: self) else {
            if view === ref {
                dismissCallback(false)
                return touchDelegate?.hitTest(point, with: event)
            }
            
            dismissCallback(true)
            return view
        }
        
        dismissCallback(true)
        
        return touchDelegate?.hitTest(point, with: event)
    }
}

extension TutorialOverlay {
    static public func shouldShowOverlay(forType type: TutorialOverlayTypes) -> Bool {
        return !(UserDefaults.standard.value(forKey: type.rawValue) as? Bool ?? false)
    }
    
    static private func didSeeOverlay(forType type: TutorialOverlayTypes) {
        UserDefaults.standard.setValue(true, forKey: type.rawValue)
    }
    
    static public func resetTutorials() {
        TutorialOverlayTypes.allCases.forEach({
            UserDefaults.standard.removeObject(forKey: $0.rawValue)
        })
    }
    
    public override var isBeingPresented: Bool {
        return (getTopMostViewController() as? TutorialOverlay) != nil
    }
    
    static public func showOverlay(type: TutorialOverlayTypes, onRef ref: UIView, onComplete: (() -> Void)? = nil) {
        if let topVC = getTopMostViewController() {
            let overlay = TutorialOverlay(type: type, ref: ref, onComplete: onComplete)
            if !overlay.isBeingPresented {
                overlay.modalPresentationStyle = .overFullScreen
                topVC.present(overlay, animated: false) {
                    DispatchQueue.main.async {
                        triggerHapticImpact(style: .heavy)
                    }
                }
                
                self.didSeeOverlay(forType: type)
            }
        }
    }
}
