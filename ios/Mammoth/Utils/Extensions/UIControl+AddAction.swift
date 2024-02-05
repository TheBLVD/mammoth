//
//  UIControl+AddAction.swift
//  Mammoth
//
//  Created by Benoit Nolens on 04/07/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

extension UIControl {
    func addAction(for controlEvents: UIControl.Event = .touchUpInside, _ closure: @escaping () -> Void) {
        addAction(UIAction { (action: UIAction) in closure() }, for: controlEvents)
    }
}
