//
//  ReadMoreButton.swift
//  Mammoth
//
//  Created by Benoit Nolens on 09/02/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit

class ReadMoreButton: UIButton {
    private let maskBackground = ReadMoreMask()
    
    init() {
        super.init(frame: .zero)
        self.setupUI()
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.setTitle("...more", for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .semibold)
        self.setTitleColor(.custom.mediumContrast, for: .normal)
        
        maskBackground.isUserInteractionEnabled = false
        maskBackground.translatesAutoresizingMaskIntoConstraints = false
        maskBackground.layoutMargins = .init(top: 2, left: 0, bottom: 2, right: 0)
        self.insertSubview(maskBackground, belowSubview: self.titleLabel!)
        
        self.contentEdgeInsets = .init(top: 2, left: 0, bottom: 0, right: 3)
        
        NSLayoutConstraint.activate([
            maskBackground.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            maskBackground.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            maskBackground.widthAnchor.constraint(equalTo: self.widthAnchor, constant: 35),
            maskBackground.heightAnchor.constraint(equalTo: self.heightAnchor)
        ])
    }
    
    public func configure(backgroundColor: UIColor) {
        self.maskBackground.gradientColor = backgroundColor
    }
}


private class ReadMoreMask: UIView {
    
    private var gradientLayer = CAGradientLayer()
    public var gradientColor: UIColor = .custom.background
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.layer.addSublayer(gradientLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientLayer.frame = self.bounds
        
        // Define the gradient colors
        let transparentColor = gradientColor.withAlphaComponent(0).cgColor
        let whiteColor = gradientColor.cgColor
        gradientLayer.colors = [transparentColor, whiteColor]
        
        // Convert to percentual location
        let startLocation = 0
        let endLocation = 30.0 / self.frame.size.width
        gradientLayer.locations = [NSNumber(value: startLocation), NSNumber(value: endLocation)]
        
        // Define the gradient direction
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)

        self.layer.shouldRasterize = false
    }
}
