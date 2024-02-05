//
//  ScrollUpIndicator.swift
//  Mammoth
//
//  Created by Benoit Nolens on 11/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class ScrollUpIndicator: UIButton {
    // MARK: - Properties
    private var blurEffectView: BlurredBackground
    private var animatedIn: Bool = false
    
    private var hiddenTransformation: CGAffineTransform = {
        let shrink = CGAffineTransform(scaleX: 0.8, y: 0.8)
        let move = CGAffineTransform(translationX: 0, y: -20)
        return CGAffineTransformConcat(shrink, move)
    }()
    
    private var visibleTransformation: CGAffineTransform = {
        let grow = CGAffineTransform(scaleX: 1, y: 1)
        let move = CGAffineTransform(translationX: 0, y: 0)
        return CGAffineTransformConcat(grow, move)
    }()
    
    override init(frame: CGRect) {
        self.blurEffectView = BlurredBackground(dimmed: false)
        
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setupUI()
    }
    
    public override var isEnabled: Bool {
        didSet {
            if isEnabled {
                self.animateIn()
            } else {
                self.animateOut()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI
private extension ScrollUpIndicator {
    func setupUI() {

        self.blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        self.blurEffectView.layer.cornerRadius = 18
        self.blurEffectView.clipsToBounds = true
        self.addSubview(self.blurEffectView)
        
        let image = UIImageView(image: FontAwesome.image(fromChar: "\u{f062}", size: 16, weight: .regular).withTintColor(.custom.active, renderingMode: .alwaysOriginal))
        image.contentMode = .center
        image.translatesAutoresizingMaskIntoConstraints = false
        self.blurEffectView.addSubview(image)
        
        self.alpha = 0
        self.isEnabled = false
        self.transform = self.hiddenTransformation

        NSLayoutConstraint.activate([
            self.blurEffectView.topAnchor.constraint(equalTo: self.topAnchor),
            self.blurEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.blurEffectView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.blurEffectView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            image.topAnchor.constraint(equalTo: self.blurEffectView.topAnchor),
            image.bottomAnchor.constraint(equalTo: self.blurEffectView.bottomAnchor),
            image.leadingAnchor.constraint(equalTo: self.blurEffectView.leadingAnchor),
            image.trailingAnchor.constraint(equalTo: self.blurEffectView.trailingAnchor),
            
            self.widthAnchor.constraint(equalToConstant: 36),
            self.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    func animateIn() {
        self.animatedIn = true
        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.64, options: .curveEaseOut, animations: {
            self.transform = self.visibleTransformation
            self.alpha = 1
        })
    }
    
    func animateOut() {
        self.animatedIn = false
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            self.transform = self.hiddenTransformation
        })
    }
}

// MARK: - Configure
extension ScrollUpIndicator {
    func configure(enable: Bool) {
        self.isEnabled = enable
    }
}

// MARK: Appearance changes
internal extension ScrollUpIndicator {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 self.blurEffectView.layer.borderColor = UIColor.systemGray4.cgColor
            }
         }
    }
}

