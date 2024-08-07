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

public enum GradientDirection {
    case solidBottomClearTop
    case solidTopClearBottom
}

class GradientView: UIView {
    private let gradientLayer = CAGradientLayer()
    private var gradientDirection: GradientDirection = .solidBottomClearTop

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradientLayer(gradientType: gradientStyleForCurrentInterface())
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradientLayer(gradientType: gradientStyleForCurrentInterface())
    }
    
    convenience init(frame: CGRect, gradientDirection: GradientDirection) {
        self.init(frame: frame)
        
        setupGradientLayer(gradientType: gradientStyleForCurrentInterface(), gradientDirection: gradientDirection)
    }

    private func setupGradientLayer(gradientType: GradientType = .dark, gradientDirection: GradientDirection = .solidBottomClearTop) {
        self.backgroundColor = UIColor.clear
        self.gradientDirection = gradientDirection
        
        updateGradientType(gradientType: gradientType, gradientDirection: gradientDirection)
        
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    public func updateGradientType(gradientType: GradientType, gradientDirection: GradientDirection) {
        #warning("make fades adjustable to compensate for navbar area")
        if gradientType == .dark {
            if gradientDirection == .solidBottomClearTop {
                gradientLayer.colors = [
                    UIColor.black.withAlphaComponent(0.0).cgColor,
                    UIColor.black.withAlphaComponent(0.8).cgColor
                ]
            } else {
                gradientLayer.colors = [
                    UIColor.black.withAlphaComponent(0.8).cgColor,
                    UIColor.black.withAlphaComponent(0.0).cgColor
                ]
            }
        } else {
            if gradientDirection == .solidBottomClearTop {
                gradientLayer.colors = [
                    UIColor.white.withAlphaComponent(0.0).cgColor,
                    UIColor.white.withAlphaComponent(0.8).cgColor
                ]
            } else {
                gradientLayer.colors = [
                    UIColor.white.withAlphaComponent(0.8).cgColor,
                    UIColor.white.withAlphaComponent(0.0).cgColor
                ]
            }
        }
    }
    
    private func gradientStyleForCurrentInterface() -> GradientType {
        return UIScreen.main.traitCollection.userInterfaceStyle == .dark ? GradientType.dark : GradientType.light
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateGradientType(gradientType: gradientStyleForCurrentInterface(), gradientDirection: self.gradientDirection)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
