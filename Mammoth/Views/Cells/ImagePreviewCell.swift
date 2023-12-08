//
//  ImagePreviewCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 12/12/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class ImagePreviewCell: UITableViewCell {
    
    var image = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFill
        contentView.addSubview(image)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "image" : image,
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[image]-0-|", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[image(280)]-0-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
