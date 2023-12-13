//
//  UIImage+ColorTile.swift
//  Mammoth
//
//  Created by Riley Howard on 5/25/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

// Color tiles
extension UIImage {
    static func render(size: CGSize, _ draw: () -> Void) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        draw()
        
        return UIGraphicsGetImageFromCurrentImageContext()?
            .withRenderingMode(.alwaysTemplate)
    }
    
    static func makeColorTile(size: CGSize, color: UIColor = .white) -> UIImage? {
        return render(size: size) {
            color.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
        }
    }
}

// Image with insets
extension UIImage {
    func imageWithInsets(_ insets: UIEdgeInsets) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: self.size.width + insets.left + insets.right,
                   height: self.size.height + insets.top + insets.bottom), false, self.scale)
        let _ = UIGraphicsGetCurrentContext()
        let origin = CGPoint(x: insets.left, y: insets.top)
        self.draw(at: origin)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithInsets
    }
    
    func imageWithOffset(_ offset: CGPoint) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: self.size.width ,
                   height: self.size.height), false, self.scale)
        let _ = UIGraphicsGetCurrentContext()
        self.draw(at: offset)
        let imageWithOffset = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithOffset
    }
}

// Rounded corners
extension UIImage {
    func roundedCornerImage(with radius: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { rendererContext in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: .allCorners,
                                    cornerRadii: CGSize(width: radius, height: radius))
            path.close()
            

            let cgContext = rendererContext.cgContext
            cgContext.saveGState()
            path.addClip()
            
            cgContext.setFillColor(UIColor.custom.background.cgColor)
            cgContext.fill(rect)
            
            draw(in: rect)
            cgContext.restoreGState()
        }
    }
}
