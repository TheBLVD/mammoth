//
//  VariableBlurView.swift
//  Mammoth
//
//  Created by Sophia Tung on 8/2/24
//  Copyright © 2024 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class VariableBlurView: UIVisualEffectView {
    init(gradientMask: UIImage, maxBlurRadius: CGFloat = 20) {
        super.init(effect: UIBlurEffect(style: .regular))
        
        // `CAFilter` is a private QuartzCore class that we dynamically declare in `CAFilter.h`.
        // We need to pull out a CAFilter reference via the header file.
        let variableBlur = CAFilter.filter(withType: "variableBlur") as! NSObject
        
        // The blur radius at each pixel depends on the alpha value of the corresponding pixel in the gradient mask.
        // An alpha of 1 results in the max blur radius, while an alpha of 0 is completely unblurred.
        guard let gradientImageRef = gradientMask.cgImage else {
            fatalError("Could not decode gradient image")
        }
        
        variableBlur.setValue(maxBlurRadius, forKey: "inputRadius")
        variableBlur.setValue(gradientImageRef, forKey: "inputMaskImage")
        variableBlur.setValue(true, forKey: "inputNormalizeEdges")
        
        // Get rid of the visual effect view's dimming/tint view, so we don't see a hard line.
        let tintOverlayView = subviews[1]
        tintOverlayView.alpha = 0
        
        // We use a `UIVisualEffectView` here purely to get access to its `CABackdropLayer`,
        // which is able to apply various, real-time CAFilters onto the views underneath.
        let backdropLayer = subviews.first?.layer
        
        // Replace the standard filters (i.e. `gaussianBlur`, `colorSaturate`, etc.) with only the variableBlur.
        backdropLayer?.filters = [variableBlur]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
