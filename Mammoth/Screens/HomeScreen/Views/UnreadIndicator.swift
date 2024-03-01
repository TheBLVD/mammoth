//
//  UnreadIndicator.swift
//  Mammoth
//
//  Created by Benoit Nolens on 30/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class UnreadIndicator: UIButton {
    // MARK: - Properties
    
    private var unreadCount: Int = 0
    
    private var blurEffectView: BlurredBackground
    private var animatedIn: Bool = false
    
    private var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    override init(frame: CGRect) {
        self.blurEffectView = BlurredBackground(dimmed: false)
        
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setupUI()
    }
    
    public override var isEnabled: Bool {
        didSet {
            if isEnabled && unreadCount > 0 {
                self.animateIn()
            } else if !isEnabled {
                self.animateOut()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI
private extension UnreadIndicator {
    func setupUI() {

        self.blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        self.blurEffectView.layer.cornerRadius = 16
        self.blurEffectView.clipsToBounds = true
        self.addSubview(self.blurEffectView)
                
        self.setTitleColor(.label, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        self.titleLabel?.textAlignment = .center

        self.alpha = 0
        self.transform = CGAffineTransform(translationX: 0, y: -50)
        self.isEnabled = true

        NSLayoutConstraint.activate([
            self.blurEffectView.topAnchor.constraint(equalTo: self.topAnchor),
            self.blurEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.blurEffectView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.blurEffectView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            self.widthAnchor.constraint(equalToConstant: 42),
            self.heightAnchor.constraint(equalToConstant: 34)
        ])
    }
    
    func animateIn() {
        if !self.animatedIn {
            self.animatedIn = true
            UIView.animate(withDuration: 0.72, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.44, options: .curveEaseOut, animations: {
                let translateY = CGAffineTransform(translationX: 0, y: 0)
                self.transform = translateY
                self.alpha = 1
            })
        }
    }
    
    func animateOut() {
        if self.animatedIn {
            self.animatedIn = false
            self.transform = .identity
            UIView.animate(withDuration: 0.25, animations: {
                self.alpha = 0
                let translateY = CGAffineTransform(translationX: 0, y: -50)
                self.transform = translateY
            })
        }
    }
}

// MARK: - Configure
extension UnreadIndicator {
    func configure(unreadCount: Int) {
        guard self.unreadCount != unreadCount else {
            if unreadCount == 0 && self.isEnabled {
                self.isEnabled = false
            }
            return
        }
        self.unreadCount = unreadCount
        self.setTitle(self.formatter.dividedByK(number: Double(unreadCount)), for: .normal)
        
        if unreadCount == 0 && self.isEnabled && animatedIn {
            self.isEnabled = false
        } else if unreadCount > 0 && !self.isEnabled {
            self.isEnabled = true
        }
    }
}

// MARK: Appearance changes
internal extension UnreadIndicator {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 self.blurEffectView.layer.borderColor = UIColor.systemGray4.cgColor
                 self.setTitleColor(.label, for: .normal)
            }
         }
    }
}

