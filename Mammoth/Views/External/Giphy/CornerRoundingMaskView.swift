//
//  CornerRoundingMaskView.swift
//  Pods
//
//  Created by Brendan Lee on 3/9/17.
//
//

import UIKit

class CornerRoundingMaskView: UIView {
    
    @IBInspectable var cornerRadius: CGFloat = 8.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
        self.contentMode = .redraw
        self.isUserInteractionEnabled = false
    }
    
    required init(cornerRadius: CGFloat) {
        super.init(frame: CGRect.zero)
        
        self.cornerRadius = cornerRadius
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
        self.contentMode = .redraw
        self.isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
        self.contentMode = .redraw
        self.isUserInteractionEnabled = false
    }
    
    override func draw(_ rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        
        UIColor.clear.set()
        
        context?.fill(rect)
        
        UIColor.white.withAlphaComponent(1.0).set()
        
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        
        path.fill()
    }
}

