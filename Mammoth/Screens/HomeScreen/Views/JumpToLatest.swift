//
//  JumpToLatest.swift
//  Mammoth
//
//  Created by Benoit Nolens on 26/02/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit
import SDWebImage

protocol JumpToLatestDelegate {
    func onClosePress()
}

final class JumpToLatest: UIButton {
    // MARK: - Properties
    
    public var delegate: JumpToLatestDelegate?
    
    private var blurEffectView: BlurredBackground
    private var animatedIn: Bool = false
    
    private var closeIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.image = UIImage()
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
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
            } else if !isEnabled {
                self.animateOut()
            }
        }
    }

    // Increase the tap target
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -20, dy: -20).contains(point)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI
private extension JumpToLatest {
    func setupUI() {

        self.blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        self.blurEffectView.layer.cornerRadius = 16
        self.blurEffectView.layer.cornerCurve = .continuous
        self.blurEffectView.clipsToBounds = true
        self.addSubview(self.blurEffectView)
        self.addSubview(self.closeIcon)

        self.alpha = 0
        self.isEnabled = true
        self.transform = CGAffineTransform(translationX: 0, y: -50)
        
        self.setTitleColor(.label, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        self.titleLabel?.textAlignment = .center
        self.setTitle(NSLocalizedString("home.jumpToNow", comment: ""), for: .normal)
        
        self.contentEdgeInsets = .init(top: 0, left: 14, bottom: 0, right: 32)
        
        self.closeIcon.image = FontAwesome.image(fromChar: "\u{f00d}", color: .label, size: 12, weight: .bold)
        
        let closeGesture = UITapGestureRecognizer(target: self, action: #selector(self.onClosePress))
        self.closeIcon.addGestureRecognizer(closeGesture)

        NSLayoutConstraint.activate([
            self.blurEffectView.topAnchor.constraint(equalTo: self.topAnchor),
            self.blurEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.blurEffectView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.blurEffectView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            self.heightAnchor.constraint(equalToConstant: 34),
            
            self.closeIcon.widthAnchor.constraint(equalToConstant: 37),
            self.closeIcon.heightAnchor.constraint(equalToConstant: 34),
            self.closeIcon.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.closeIcon.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
    
    @objc func onClosePress() {
        self.delegate?.onClosePress()
    }
    
    func animateIn() {
        self.animatedIn = true
        UIView.animate(withDuration: 0.72, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.44, options: .curveEaseOut, animations: {
            let translateY = CGAffineTransform(translationX: 0, y: 0)
            self.transform = translateY
            self.alpha = 1
        })
    }
    
    func animateOut() {
        self.animatedIn = false
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            let translateY = CGAffineTransform(translationX: 0, y: -50)
            self.transform = translateY
        })
    }
}

// MARK: - Configure
extension JumpToLatest {
    func configure(readCount: Int) {}
}

// MARK: Appearance changes
internal extension JumpToLatest {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 
            }
         }
    }
}
