//
//  LargerTapTargetButton.swift
//  Mammoth
//
//  Created by Riley Howard on 6/16/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit


// We adjust the image size and insets to get a bigger tap target.
// (the usual trick of overriding point(inside point: with event:) doesn't
// seem to work with navbar buttons.
class LargerTapTargetButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.imageEdgeInsets = UIEdgeInsets(top: -10, left: -5, bottom: -10, right: 5)
    }

    override func setImage(_ image: UIImage?, for state: UIControl.State) {
        let offsetImage = image?.imageWithInsets(UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5))
        super.setImage(offsetImage, for: state)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
