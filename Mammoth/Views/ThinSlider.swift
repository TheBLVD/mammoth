//
//  ThinSlider.swift
//  Mammoth
//
//  Created by Riley Howard on 9/6/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class ThinSlider: UISlider {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.tintColor = .custom.baseTint
        self.minimumTrackTintColor = .custom.feintContrast
        self.maximumTrackTintColor = .custom.feintContrast
        self.setThumbImage(UIImage(named: "ThinSliderThumb"), for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let point = CGPoint(x: bounds.minX, y: bounds.midY)
        return CGRect(origin: point, size: CGSize(width: bounds.width, height: 1))
    }
}
