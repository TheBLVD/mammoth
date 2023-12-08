//
//  Gradient.swift
//  Mammoth
//
//  Created by Benoit Nolens on 27/11/2023.
//

import UIKit

extension UIColor {
    
    struct gradients {
        static let goldText = [
            UIColor(red: 234.0/255, green: 205.0/255, blue: 161.0/255, alpha: 1.0).cgColor,
            UIColor(red: 223.0/255, green: 168.0/255, blue: 86.0/255, alpha: 1.0).cgColor,
        ]
        
        static let goldBorder = [
            UIColor(red: 234.0/255, green: 205.0/255, blue: 161.0/255, alpha: 1.0).cgColor,
            UIColor(red: 223.0/255, green: 168.0/255, blue: 86.0/255, alpha: 1.0).cgColor,
        ]
        
        static let goldButtonBackground = [
            UIColor(red: 240.0/255, green: 203.0/255, blue: 147.0/255, alpha: 1.0).cgColor,
            UIColor(red: 223.0/255, green: 168.0/255, blue: 86.0/255, alpha: 1.0).cgColor,
        ]
    }
    
    
    internal static func getGradientLayer(colors: [CGColor], startPoint: CGPoint, endPoint: CGPoint, bounds : CGRect) -> CAGradientLayer{
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        gradient.locations = [0, 1]
        return gradient
    }

    static func gradient(colors: [CGColor], startPoint: CGPoint, endPoint: CGPoint, bounds: CGRect) -> UIColor? {
        let gradientLayer = self.getGradientLayer(colors: colors, startPoint: startPoint, endPoint: endPoint, bounds: bounds)
        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return UIColor(patternImage: image!)
    }
}
