//
//  RoundedTextField.swift
//  Mastodon
//
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class RoundedTextField: UITextField {
    
    private let padding: CGFloat
    
    init(padding: CGFloat = 16) {
        self.padding = padding
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.masksToBounds = true
        layer.cornerRadius = 16
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        super.textRect(forBounds: bounds).insetBy(dx: padding, dy: 0)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        super.editingRect(forBounds: bounds).insetBy(dx: padding, dy: 0)
    }
    
    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        super.clearButtonRect(forBounds: bounds).offsetBy(dx: -8, dy: 0)
    }
    
}
