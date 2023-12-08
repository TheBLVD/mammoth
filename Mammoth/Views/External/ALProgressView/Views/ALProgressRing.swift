// The MIT License (MIT)
//
// Copyright (c) 2020 Alexandr Guzenko (alxrguz@icloud.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

/// A fillable progress ring drawing. 
open class ALProgressRing: UIView {
    
    // MARK: Properties
    
    /// Sets the line width for progress ring and groove ring.
    /// - Note: If you need separate customization use the `ringWidth` and `grooveWidth` properties
    public var lineWidth: CGFloat = 10 {
        didSet {
            ringWidth = lineWidth
            grooveWidth = lineWidth
        }
    }
    
    /// The line width of the progress ring.
    public var ringWidth: CGFloat = 10 {
        didSet {
            ringLayer.lineWidth = ringWidth
        }
    }

    /// The line width of the groove ring.
    public var grooveWidth: CGFloat = 10 {
        didSet {
            grooveLayer.lineWidth = grooveWidth
        }
    }
    
    /// The first gradient color of the track.
    public var startColor: UIColor = .systemPink {
        didSet { gradientLayer.colors = [startColor.cgColor, endColor.cgColor] }
    }
    
    /// The second gradient color of the track.
    public var endColor: UIColor = .systemRed {
        didSet { gradientLayer.colors = [startColor.cgColor, endColor.cgColor] }
    }
    
    /// The groove color in which the fillable ring resides.
    public var grooveColor: UIColor = UIColor.systemGray.withAlphaComponent(0.2) {
        didSet { grooveLayer.strokeColor = grooveColor.cgColor }
    }
    
    /// The start angle of the ring to begin drawing.
    public var startAngle: CGFloat = -.pi / 2 {
        didSet { ringLayer.path = ringPath() }
    }

    /// The end angle of the ring to end drawing.
    public var endAngle: CGFloat = 1.5 * .pi {
        didSet { ringLayer.path = ringPath() }
    }
    
    /// The starting poin of the gradient. Default is (x: 0.5, y: 0)
    public var startGradientPoint: CGPoint = .init(x: 0.5, y: 0) {
        didSet { gradientLayer.startPoint = startGradientPoint }
    }
    
    /// The ending position of the gradient. Default is (x: 0.5, y: 1)
    public var endGradientPoint: CGPoint = .init(x: 0.5, y: 1) {
        didSet { gradientLayer.endPoint = endGradientPoint }
    }

    /// Duration of the ring's fill animation. Default is 2.0
    public var duration: TimeInterval = 2.0
    
    /// Timing function of the ring's fill animation. Default is `.easeOutExpo`
    public var timingFunction: ALTimingFunction = .easeOutExpo

    /// The radius of the ring.
    public var ringRadius: CGFloat {
        var radius = min(bounds.height, bounds.width) / 2 - ringWidth / 2
        if ringWidth < grooveWidth {
            radius -= (grooveWidth - ringWidth) / 2
        }
        return radius
    }
    
    /// The radius of the groove.
    public var grooveRadius: CGFloat {
        var radius = min(bounds.height, bounds.width) / 2 - grooveWidth / 2
        if grooveWidth < ringWidth {
            radius -= (ringWidth - grooveWidth) / 2
        }
        return radius
    }
    
    /// The progress of the ring between 0 and 1. The ring will fill based on the value.
    public private(set) var progress: CGFloat = 0

    private let ringLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineCap = .round
        layer.fillColor = nil
        layer.strokeStart = 0
        return layer
    }()
    
    private let grooveLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineCap = .round
        layer.fillColor = nil
        layer.strokeStart = 0
        layer.strokeEnd = 1
        return layer
    }()
    
    private let gradientLayer = CAGradientLayer()

    // MARK: Life Cycle
    public init() {
        super.init(frame: .zero)
        setup()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        configureRing()
        styleRingLayer()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        styleRingLayer()
    }

    // MARK: Methods
    
    /// Set the progress value of the ring. The ring will fill based on the value.
    ///
    /// - Parameters:
    ///   - value: Progress value between 0 and 1.
    ///   - animated: Flag for the fill ring's animation.
    ///   - completion: Closure called after animation ends
    public func setProgress(_ value: Float, animated: Bool, completion: (() -> Void)? = nil) {
        layoutIfNeeded()
        let value = CGFloat(min(value, 1.0))
        let oldValue = ringLayer.presentation()?.strokeEnd ?? progress
        progress = value
        ringLayer.strokeEnd = progress
        guard animated else {
            layer.removeAllAnimations()
            ringLayer.removeAllAnimations()
            gradientLayer.removeAllAnimations()
            completion?()
            return
        }
        
        CATransaction.begin()
        let path = #keyPath(CAShapeLayer.strokeEnd)
        let fill = CABasicAnimation(keyPath: path)
        fill.fromValue = oldValue
        fill.toValue = value
        fill.duration = duration
        fill.timingFunction = timingFunction.function
        CATransaction.setCompletionBlock(completion)
        ringLayer.add(fill, forKey: "fill")
        CATransaction.commit()
    }

    
    private func setup() {
        preservesSuperviewLayoutMargins = true
        layer.addSublayer(grooveLayer)
        layer.addSublayer(gradientLayer)
        styleRingLayer()
    }

    private func styleRingLayer() {
        grooveLayer.strokeColor = grooveColor.cgColor
        grooveLayer.lineWidth = grooveWidth
        
        ringLayer.lineWidth = ringWidth
        ringLayer.strokeColor = UIColor.black.cgColor
        ringLayer.strokeEnd = min(progress, 1.0)
        
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 1)
        
        gradientLayer.shadowColor = startColor.cgColor
        gradientLayer.shadowOffset = .zero
    }

    private func configureRing() {
        let ringPath = self.ringPath()
        let groovePath = self.groovePath()
        grooveLayer.frame = bounds
        grooveLayer.path = groovePath
        
        ringLayer.frame = bounds
        ringLayer.path = ringPath
        
        gradientLayer.frame = bounds
        gradientLayer.mask = ringLayer
    }

    private func ringPath() -> CGPath {
        let center = CGPoint(x: bounds.origin.x + frame.width / 2.0, y: bounds.origin.y + frame.height / 2.0)
        let circlePath = UIBezierPath(arcCenter: center, radius: ringRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        return circlePath.cgPath
    }
    
    private func groovePath() -> CGPath {
        let center = CGPoint(x: bounds.origin.x + frame.width / 2.0, y: bounds.origin.y + frame.height / 2.0)
        let circlePath = UIBezierPath(arcCenter: center, radius: grooveRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        return circlePath.cgPath
    }
}
