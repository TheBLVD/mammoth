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
        
        var description: String {
            switch self {
            case .customizeFeed:
                return "Tap here and choose “Customize For You” to choose what shows up here!"
            case .forYou:
                return "For You shows the top posts from all of your \n/smart lists."
            case .smartList:
                return "Smart lists marked with a /slash are community curated lists."
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
            }
        }
        
        var arrowAlignment: NSTextAlignment {
            switch self {
            case .customizeFeed:
                return .right
            case .forYou:
                return .center
            case .smartList:
                return .center
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
            case .left:
                log.error("ARROW LEFT ALIGNEMENT NOT YET IMPLEMENTED")
                break
            case .center:
                self.leadingConstraint?.constant = refOrigin.x + (ref.frame.width / 2) - (self.type.width / 2)
            case .right:
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
        
        self.bubble.layoutMargins = .init(top: 22, left: 16, bottom: 13, right: 16)
        self.view.addSubview(self.bubble)
        
        self.bubbleText.text = self.type.description
        self.bubble.addSubview(self.bubbleText)
        
        switch self.type.arrowAlignment {
        case .left:
            log.error("ARROW LEFT ALIGNEMENT NOT YET IMPLEMENTED")
            break
        case .center:
            self.leadingConstraint = bubble.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: refOrigin.x + (ref.frame.width / 2) - (self.type.width / 2))
        case .right:
            self.leadingConstraint = bubble.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: refOrigin.x - self.type.width + 30 + self.bubble.rightArrowOffset)
        default:
            break
        }
        
        
        NSLayoutConstraint.activate([
            bubble.widthAnchor.constraint(lessThanOrEqualToConstant: 218),
            bubble.topAnchor.constraint(equalTo: self.view.topAnchor, constant: refOrigin.y + ref.frame.size.height - 8),
            leadingConstraint!,
            
            bubbleText.topAnchor.constraint(equalTo: bubble.layoutMarginsGuide.topAnchor),
            bubbleText.bottomAnchor.constraint(equalTo: bubble.layoutMarginsGuide.bottomAnchor),
            bubbleText.leadingAnchor.constraint(equalTo: bubble.layoutMarginsGuide.leadingAnchor),
            bubbleText.trailingAnchor.constraint(equalTo: bubble.layoutMarginsGuide.trailingAnchor)
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
            UIView.animate(springDuration: 0.5, bounce: 0.4, initialSpringVelocity: 0.9, delay: 0.3) { [weak self] in
                guard let self else { return }
                self.bubble.alpha = 1
                self.bubble.transform = .init(translationX: 0, y: 0)
            }
        } else {
            UIView.animate(withDuration: 0.3, delay: 0.3) { [weak self] in
                guard let self else { return }
                self.bubble.transform = .init(translationX: 0, y: 0)
            }
        }
    }
}

class TouchDelegatingView: UIView {
    weak var touchDelegate: UIView? = nil
    weak var ref: UIView? = nil
    var dismissCallback: (_ animated: Bool) -> Void = {animated in }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard  ![.hover].contains(event?.type) else { return nil}
        
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
