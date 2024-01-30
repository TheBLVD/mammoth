//
//  UIView+Layout.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

protocol LayoutTarget {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var leftAnchor: NSLayoutXAxisAnchor { get }
    var rightAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var widthAnchor: NSLayoutDimension { get }
    var heightAnchor: NSLayoutDimension { get }
    var centerXAnchor: NSLayoutXAxisAnchor { get }
    var centerYAnchor: NSLayoutYAxisAnchor { get }
}

extension UIView: LayoutTarget { }
extension UILayoutGuide: LayoutTarget { }

struct LayoutConstraints {
    var constraints: [NSLayoutConstraint]
    
    init() {
        constraints = []
    }
    
    init(_ constraints: [NSLayoutConstraint]) {
        self.constraints = constraints
    }
    
    init(_ combiningConstraints: [LayoutConstraints]) {
        constraints = combiningConstraints.flatMap { $0.constraints }
    }
}

extension UIView {
    private func prepareForConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
    }
}

// MARK: - Edges

extension UIView {
    
    enum Edge {
        case leading
        case trailing
        case left
        case right
        case top
        case bottom
        
        struct Set: OptionSet {
            let rawValue: Int
            
            static let leading =  Set(rawValue: 1 << 0)
            static let trailing = Set(rawValue: 1 << 1)
            static let left =     Set(rawValue: 1 << 2)
            static let right =    Set(rawValue: 1 << 3)
            static let top =      Set(rawValue: 1 << 4)
            static let bottom =   Set(rawValue: 1 << 5)
            
            static let horizontal: Set = [.leading, .trailing]
            static let vertical: Set = [.top, .bottom]
            static let all: Set = [.leading, .trailing, .top, .bottom]
            
            var values: [Edge] {
                var v: [Edge] = []
                if contains(.leading)  { v.append(.leading) }
                if contains(.trailing) { v.append(.trailing) }
                if contains(.left)     { v.append(.left) }
                if contains(.right)    { v.append(.right) }
                if contains(.top)      { v.append(.top) }
                if contains(.bottom)   { v.append(.bottom) }
                return v
            }
        }
    }
    
    struct EdgeInsets {
        var leading: CGFloat
        var trailing: CGFloat
        var top: CGFloat
        var bottom: CGFloat
    }
    
    @discardableResult
    func pinEdges() -> LayoutConstraints {
        pinEdges(.all)
    }
    
    @discardableResult
    func pinEdges(
        to target: LayoutTarget? = nil,
        padding: CGFloat = 0)
    -> LayoutConstraints {
        
        pinEdges(.all, to: target, padding: padding)
    }
    
    @discardableResult
    func pinEdges(
        _ edges: Edge.Set,
        to target: LayoutTarget? = nil,
        padding: CGFloat = 0)
    -> LayoutConstraints {
        
        LayoutConstraints(edges.values.map {
            pinEdge($0, to: target, padding: padding)
        })
    }
    
    @discardableResult
    func pinEdges(
        to target: LayoutTarget? = nil,
        padding: EdgeInsets)
    -> LayoutConstraints {
        
        LayoutConstraints([
            pinEdge(.leading, to: target, padding: padding.leading),
            pinEdge(.trailing, to: target, padding: padding.trailing),
            pinEdge(.top, to: target, padding: padding.top),
            pinEdge(.bottom, to: target, padding: padding.bottom),
        ])
    }
    
    private func pinEdge(
        _ edge: Edge,
        to target: LayoutTarget?,
        padding: CGFloat)
    -> LayoutConstraints {
        
        switch edge {
        case .leading:
            return pin(.leading, to: target, constant: padding)
        case .trailing:
            return pin(.trailing, to: target, constant: -padding)
        case .left:
            return pin(.left, to: target, constant: padding)
        case .right:
            return pin(.right, to: target, constant: -padding)
        case .top:
            return pin(.top, to: target, constant: padding)
        case .bottom:
            return pin(.bottom, to: target, constant: -padding)
        }
    }
    
}

// MARK: - Centers

extension UIView {
    
    enum Center {
        case horizontal
        case vertical
    }
    
    @discardableResult
    func pinCenter(_ center: Center, to target: LayoutTarget? = nil)
    -> LayoutConstraints {
        
        switch center {
        case .horizontal:
            return pin(.centerX, to: target, toAnchor: .centerX)
        case .vertical:
            return pin(.centerY, to: target, toAnchor: .centerY)
        }
    }
    
    @discardableResult
    func pinCenter(to target: LayoutTarget? = nil)
    -> LayoutConstraints {
        
        LayoutConstraints([
            pin(.centerX, to: target),
            pin(.centerY, to: target),
        ])
    }
    
}

// MARK: - Anchors

extension UIView {
    
    enum HorizontalAnchor {
        case leading
        case trailing
        case left
        case right
        case centerX
        
        func anchor(in t: LayoutTarget) -> NSLayoutXAxisAnchor {
            switch self {
            case .leading:  return t.leadingAnchor
            case .trailing: return t.trailingAnchor
            case .left:     return t.leftAnchor
            case .right:    return t.rightAnchor
            case .centerX:  return t.centerXAnchor
            }
        }
    }
    
    enum VerticalAnchor {
        case top
        case bottom
        case centerY
        
        func anchor(in t: LayoutTarget) -> NSLayoutYAxisAnchor {
            switch self {
            case .top:     return t.topAnchor
            case .bottom:  return t.bottomAnchor
            case .centerY: return t.centerYAnchor
            }
        }
    }
    
    enum SizeAnchor {
        case width
        case height
        
        func anchor(in t: LayoutTarget) -> NSLayoutDimension {
            switch self {
            case .width:  return t.widthAnchor
            case .height: return t.heightAnchor
            }
        }
    }
    
    enum LayoutRelation {
        case equal
        case lessOrEqual
        case greaterOrEqual
    }
    
    @discardableResult
    func pin(
        _ selfAnchor: HorizontalAnchor,
        to t: LayoutTarget? = nil,
        toAnchor targetAnchor: HorizontalAnchor? = nil,
        constant: CGFloat = 0,
        relation: LayoutRelation = .equal)
    -> LayoutConstraints {
        
        prepareForConstraints()
        guard let target = t ?? superview else { return LayoutConstraints() }
        
        let a1 = selfAnchor.anchor(in: self)
        let a2 = (targetAnchor ?? selfAnchor).anchor(in: target)
        
        let c: NSLayoutConstraint
        switch relation {
        case .equal:
            c = a1.constraint(equalTo: a2, constant: constant)
        case .lessOrEqual:
            c = a1.constraint(lessThanOrEqualTo: a2, constant: constant)
        case .greaterOrEqual:
            c = a1.constraint(greaterThanOrEqualTo: a2, constant: constant)
        }
        c.isActive = true
        
        return LayoutConstraints([c])
    }
    
    @discardableResult
    func pin(
        _ selfAnchor: VerticalAnchor,
        to t: LayoutTarget? = nil,
        toAnchor targetAnchor: VerticalAnchor? = nil,
        constant: CGFloat = 0,
        relation: LayoutRelation = .equal)
    -> LayoutConstraints {
        
        prepareForConstraints()
        guard let target = t ?? superview else { return LayoutConstraints() }
        
        let a1 = selfAnchor.anchor(in: self)
        let a2 = (targetAnchor ?? selfAnchor).anchor(in: target)
        
        let c: NSLayoutConstraint
        switch relation {
        case .equal:
            c = a1.constraint(equalTo: a2, constant: constant)
        case .lessOrEqual:
            c = a1.constraint(lessThanOrEqualTo: a2, constant: constant)
        case .greaterOrEqual:
            c = a1.constraint(greaterThanOrEqualTo: a2, constant: constant)
        }
        c.isActive = true
        
        return LayoutConstraints([c])
    }
    
    @discardableResult
    func pin(
        _ selfAnchor: SizeAnchor,
        to t: LayoutTarget? = nil,
        toAnchor targetAnchor: SizeAnchor? = nil,
        constant: CGFloat = 0,
        relation: LayoutRelation = .equal)
    -> LayoutConstraints {
        
        prepareForConstraints()
        guard let target = t ?? superview else { return LayoutConstraints() }
        
        let a1 = selfAnchor.anchor(in: self)
        let a2 = (targetAnchor ?? selfAnchor).anchor(in: target)
        
        let c: NSLayoutConstraint
        switch relation {
        case .equal:
            c = a1.constraint(equalTo: a2, constant: constant)
        case .lessOrEqual:
            c = a1.constraint(lessThanOrEqualTo: a2, constant: constant)
        case .greaterOrEqual:
            c = a1.constraint(greaterThanOrEqualTo: a2, constant: constant)
        }
        c.isActive = true
        
        return LayoutConstraints([c])
    }
    
}

// MARK: - Size

extension UIView {
    
    @discardableResult
    func pinSize(to size: CGFloat) -> LayoutConstraints {
        LayoutConstraints([
            pinWidth(to: size),
            pinHeight(to: size),
        ])
    }
    
    @discardableResult
    func pinWidth(to size: CGFloat) -> LayoutConstraints {
        prepareForConstraints()
        
        let c = widthAnchor.constraint(equalToConstant: size)
        c.isActive = true
        
        return LayoutConstraints([c])
    }
    
    @discardableResult
    func pinHeight(to size: CGFloat) -> LayoutConstraints {
        prepareForConstraints()
        
        let c = heightAnchor.constraint(equalToConstant: size)
        c.isActive = true
        
        return LayoutConstraints([c])
    }
    
    @discardableResult
    func pinAspectRatio(to aspectRatio: CGFloat) -> LayoutConstraints {
        prepareForConstraints()
        
        let c = widthAnchor.constraint(
            equalTo: heightAnchor,
            multiplier: aspectRatio)
        c.isActive = true
        
        return LayoutConstraints([c])
    }
    
}

// MARK: - Priority

extension LayoutConstraints {
    
    func priority(_ rawValue: Float) {
        priority(UILayoutPriority(rawValue))
    }
    
    func priority(_ priority: UILayoutPriority) {
        constraints.forEach { $0.priority = priority }
    }
    
}
