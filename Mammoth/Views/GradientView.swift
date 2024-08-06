//
//  GradientView.swift
//  Mammoth
//
//  Created by Sophia Tung on 8/1/24
//  Copyright © 2024 The BLVD. All rights reserved.
//

import Foundation
import UIKit

public enum GradientType {
    case light
    case dark
}

class GradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradientLayer(gradientType: gradientStyleForCurrentInterface())
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradientLayer(gradientType: gradientStyleForCurrentInterface())
    }

    private func setupGradientLayer(gradientType: GradientType = .dark) {
        self.backgroundColor = UIColor.clear
        
        updateGradientType(gradientType: gradientType)
        
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    public func updateGradientType(gradientType: GradientType) {
        if gradientType == .dark {
            gradientLayer.colors = [
                UIColor.black.withAlphaComponent(0.0).cgColor,
                UIColor.black.withAlphaComponent(0.8).cgColor
            ]
        } else {
            gradientLayer.colors = [
                UIColor.white.withAlphaComponent(0.0).cgColor,
                UIColor.white.withAlphaComponent(0.8).cgColor
            ]
        }
        
        gradientLayer.locations = [0.0, 1.0].map { NSNumber(value: $0) }
    }
    
    private func gradientStyleForCurrentInterface() -> GradientType {
        return UIScreen.main.traitCollection.userInterfaceStyle == .dark ? GradientType.dark : GradientType.light
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateGradientType(gradientType: gradientStyleForCurrentInterface())
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
