//
//  TextBubbleView.swift
//  Mammoth
//
//  Created by Benoit Nolens on 07/12/2023
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class TextBubbleView: UIView {
    
    private let arrowWidth: CGFloat = 22.0
    private let arrowHeight: CGFloat = 10.0
    private let cornerRadius: CGFloat = 10.0
    
    private let arrowRadius: CGFloat = 3.0
    public let rightArrowOffset: CGFloat = 27.0
    
    private let bubbleLayer = CAShapeLayer()
    private let blurBackground = BlurredBackground(dimmed: false, underlayAlpha: 0.15)
    
    public let arrowAlignment: NSTextAlignment
    
    init(alignment: NSTextAlignment) {
        self.arrowAlignment = alignment
        super.init(frame: .zero)
        setupBlurEffect()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.arrowAlignment = .right
        super.init(coder: aDecoder)
         setupBlurEffect()
    }
    
    private func setupBlurEffect() {
        blurBackground.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(blurBackground)
        
        self.clipsToBounds = false
        
        NSLayoutConstraint.activate([
            blurBackground.topAnchor.constraint(equalTo: topAnchor),
            blurBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurBackground.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        bubbleLayer.fillRule = .evenOdd
        blurBackground.layer.mask = bubbleLayer
    }
    
    override func draw(_ rect: CGRect) {
        
        let path = UIBezierPath()
        let bubbleRect = CGRect(x: 0, y: arrowHeight, width: rect.width, height: rect.height - arrowHeight)
        
        path.move(to: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.minY))
        path.addLine(to: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.minY))
        path.addArc(withCenter: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.minY + cornerRadius), radius: cornerRadius, startAngle: CGFloat(-Double.pi / 2), endAngle: 0, clockwise: true)
        
        path.addLine(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY - cornerRadius))
        path.addArc(withCenter: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.maxY - cornerRadius), radius: cornerRadius, startAngle: 0, endAngle: CGFloat(Double.pi / 2), clockwise: true)
        
        path.addLine(to: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.maxY))
        path.addArc(withCenter: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.maxY - cornerRadius), radius: cornerRadius, startAngle: CGFloat(Double.pi / 2), endAngle: CGFloat(Double.pi), clockwise: true)
        
        path.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.minY + cornerRadius))
        path.addArc(withCenter: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.minY + cornerRadius), radius: cornerRadius, startAngle: CGFloat(Double.pi), endAngle: CGFloat(CGFloat(-Double.pi / 2)), clockwise: true)
        
        // Creating the arrow with rounded corner
        
        
        switch self.arrowAlignment {
        case .left:
           break
        case .center:
            let curveStartX = bubbleRect.midX - arrowRadius
            let curveStartY = bubbleRect.minY - arrowHeight + arrowRadius
            let curveEndX = bubbleRect.midX + arrowRadius
            let curveEndY = bubbleRect.minY - arrowHeight + arrowRadius
            
            path.move(to: CGPoint(x: bubbleRect.midX - (arrowWidth / 2), y: bubbleRect.minY))
            path.addLine(to: CGPoint(x: curveStartX, y: curveStartY))
            path.addCurve(to: CGPoint(x: curveEndX, y: curveEndY),
                          controlPoint1: CGPoint(x: curveStartX + arrowRadius/2, y: curveStartY - arrowRadius/2),
                          controlPoint2: CGPoint(x: curveEndX - arrowRadius/2, y: curveEndY - arrowRadius/2))
            path.addLine(to: CGPoint(x: bubbleRect.midX + (arrowWidth / 2), y: bubbleRect.minY))
            path.addLine(to: CGPoint(x: bubbleRect.midX - (arrowWidth / 2), y: bubbleRect.minY))
        case .right:
            let curveStartX = bubbleRect.maxX - (arrowWidth / 2) - arrowRadius - rightArrowOffset
            let curveStartY = bubbleRect.minY - arrowHeight + arrowRadius
            let curveEndX = bubbleRect.maxX - (arrowWidth / 2) + arrowRadius - rightArrowOffset
            let curveEndY = bubbleRect.minY - arrowHeight + arrowRadius
            
            path.move(to: CGPoint(x: bubbleRect.maxX - arrowWidth - rightArrowOffset, y: bubbleRect.minY))
            path.addLine(to: CGPoint(x: curveStartX, y: curveStartY))
            path.addCurve(to: CGPoint(x: curveEndX, y: curveEndY),
                          controlPoint1: CGPoint(x: curveStartX + arrowRadius/2, y: curveStartY - arrowRadius/2),
                          controlPoint2: CGPoint(x: curveEndX - arrowRadius/2, y: curveEndY - arrowRadius/2))
            path.addLine(to: CGPoint(x: bubbleRect.maxX - rightArrowOffset, y: bubbleRect.minY))
            path.addLine(to: CGPoint(x: bubbleRect.maxX - arrowWidth - rightArrowOffset, y: bubbleRect.minY))
        default:
            break
        }
        
        path.close()
        
        bubbleLayer.path = path.cgPath
        
        bubbleLayer.fillRule = .evenOdd
        blurBackground.layer.mask = bubbleLayer
        
        super.draw(rect)
    }
}
