//
//  CarouselCollectionView.swift
//  Mammoth
//
//  Created by Benoit Nolens on 24/08/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class CarouselCollectionView: UICollectionView {
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        
        // Define the gradient colors
        let transparentColor = UIColor.clear.cgColor
        let blackColor = UIColor.black.cgColor
        gradientLayer.colors = [blackColor, transparentColor]
        
        // Define the gradient locations
        
        // Convert frame.width-18px to percentual location
        let startLocation = (1.0 - (18.0 / self.frame.size.width))
        gradientLayer.locations = [NSNumber(value: startLocation), 1.0]
        
        // Define the gradient direction
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        
        self.layer.mask = gradientLayer
    }
}
