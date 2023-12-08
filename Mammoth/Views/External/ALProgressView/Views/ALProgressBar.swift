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
open class ALProgressBar: UIView {
    
    // MARK: Properties
    
    /// Distance between groove and progress bar. Default is 0
    public var barEdgeInset: CGFloat = 0 {
        didSet { configureBar(); styleBarLayer() }
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
        didSet { barLayer.strokeColor = grooveColor.cgColor }
    }
    
    /// The starting poin of the gradient. Default is (x: 0, y: 0.5)
    public var startGradientPoint: CGPoint = .init(x: 0, y: 0.5) {
        didSet { gradientLayer.startPoint = startGradientPoint }
    }
    
    /// The ending position of the gradient. Default is (x: 1, y: 0.5)
    public var endGradientPoint: CGPoint = .init(x: 1, y: 0.5) {
        didSet { gradientLayer.endPoint = endGradientPoint }
    }

    /// Duration of the ring's fill animation. Default is 2.0
    public var duration: TimeInterval = 2.0
    
    /// Timing function of the ring's fill animation. Default is `.easeOutExpo`
    public var timingFunction: ALTimingFunction = .easeOutExpo
    
    /// The progress of the ring between 0 and 1. The ring will fill based on the value.
    public private(set) var progress: CGFloat = 0

    private let ringLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineCap = .round
        layer.fillColor = nil
        layer.strokeStart = 0
        layer.strokeEnd = 1
        return layer
    }()
    
    private let barLayer: CAShapeLayer = {
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
        configureBar()
        styleBarLayer()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        styleBarLayer()
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
        layer.addSublayer(barLayer)
        layer.addSublayer(gradientLayer)
        styleBarLayer()
        setProgress(Float(progress), animated: false)
    }

    private func styleBarLayer() {
        barLayer.strokeColor = grooveColor.cgColor
        barLayer.lineWidth = frame.height
        
        ringLayer.lineWidth = frame.height - (barEdgeInset * 2)
        ringLayer.strokeColor = startColor.cgColor
        ringLayer.strokeEnd = min(progress, 1.0)

        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        gradientLayer.startPoint = startGradientPoint
        gradientLayer.endPoint = endGradientPoint
    }

    private func configureBar() {
        let inset = frame.height / 2
        let barInset = barEdgeInset / 2
        
        let grooveLinePath = UIBezierPath()
        grooveLinePath.move(to: CGPoint(x: inset, y: bounds.midY))
        grooveLinePath.addLine(to: CGPoint(x: bounds.width - inset, y: bounds.midY))
        barLayer.path = grooveLinePath.cgPath
        
        
        let barLinePath = UIBezierPath()
        barLinePath.move(to: CGPoint(x: inset + barInset, y: bounds.midY))
        barLinePath.addLine(to: CGPoint(x: bounds.width - (inset + barInset), y: bounds.midY))
        ringLayer.path = barLinePath.cgPath
        
        [barLayer, ringLayer, gradientLayer].forEach { $0.frame = bounds }
        gradientLayer.mask = ringLayer
    }
}

