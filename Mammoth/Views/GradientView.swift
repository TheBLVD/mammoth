//
//  GradientView.swift
//  Mammoth
//
//  Created by Sophia Tung on 8/1/24
//  Copyright © 2024 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class GradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradientLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradientLayer()
    }

    private func setupGradientLayer() {
        self.backgroundColor = UIColor.clear
        
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.0).cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor
        ]
        
        gradientLayer.locations = [0.0, 1.0].map { NSNumber(value: $0) }
        
        layer.insertSublayer(gradientLayer, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
