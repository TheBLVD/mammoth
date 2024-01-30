//
//  TextSizeCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 21/04/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class TextSizeCell: UITableViewCell {
    
    var slider = ThinSlider()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        slider.frame = CGRect(x: 15, y: 15, width: contentView.bounds.width - 20, height: 40)
        slider.isUserInteractionEnabled = true
        slider.minimumValue = -6
        slider.maximumValue = 6
        slider.isContinuous = true
        slider.value = Float(GlobalStruct.customTextSize)
        contentView.addSubview(slider)
        
        contentView.layer.masksToBounds = false
        
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 70).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureSize(_ width: CGFloat) {
        slider.frame = CGRect(x: 15, y: 15, width: width - 65, height: 40)
    }
    
}
