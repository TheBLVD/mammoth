//
//  ProfileBackButton.swift
//  Mammoth
//
//  Created by Benoit Nolens on 04/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class ProfileBackButton: UIView {
    
    let onButtonPress: () -> Void
    var blurEffectView: BlurredBackground?
    var icon: UIImageView?
    
    init(_ onButtonPress: @escaping () -> Void) {
        self.onButtonPress = onButtonPress
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        self.backgroundColor = .clear
        self.layer.cornerRadius = 37 / 2
        self.clipsToBounds = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.onTapped))
        self.addGestureRecognizer(tapGesture)
        
        self.blurEffectView = BlurredBackground()
        self.blurEffectView!.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.blurEffectView!)
        
        self.icon = UIImageView(image: FontAwesome.image(fromChar: "\u{f053}").withRenderingMode(.alwaysTemplate))
        self.icon?.tintColor = .custom.highContrast
        icon!.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(icon!)
        
        NSLayoutConstraint.activate([
            blurEffectView!.topAnchor.constraint(equalTo: self.topAnchor),
            blurEffectView!.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            blurEffectView!.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            blurEffectView!.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            blurEffectView!.widthAnchor.constraint(equalToConstant: 37.0),
            blurEffectView!.heightAnchor.constraint(equalToConstant: 37.0),
            
            icon!.centerXAnchor.constraint(equalTo: blurEffectView!.centerXAnchor),
            icon!.centerYAnchor.constraint(equalTo: blurEffectView!.centerYAnchor, constant: 1)
        ])
    }
}

// MARK: - Configuration
extension ProfileBackButton {
    
    func didScroll(scrollView: UIScrollView) {
        let startOffset = 100.0 - scrollView.safeAreaInsets.top
        let endOffset = 110.0 - scrollView.safeAreaInsets.top
        if scrollView.contentOffset.y > startOffset && scrollView.contentOffset.y < endOffset {
            let opacity = 1 - Float(min(max((scrollView.contentOffset.y - startOffset) / (endOffset - startOffset), 0), 1))
            self.blurEffectView?.layer.opacity = opacity
        } else if scrollView.contentOffset.y >= endOffset {
            self.blurEffectView?.layer.opacity = 0
        } else {
            self.blurEffectView?.layer.opacity = 1
        }
    }
    
    @objc func onTapped() {
        self.onButtonPress()
    }
}
