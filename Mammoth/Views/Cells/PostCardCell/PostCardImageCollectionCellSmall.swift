//
//  PostCardImageCollectionCellSmall.swift
//  Mammoth
//
//  Created by Riley Howard on 5/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit


// MARK: - PostCardImageCollectionCellSmall
class PostCardImageCollectionCellSmall: PostCardImageCollectionCell {
    
// MARK: - Setup UI
    override func setupUI() {
        self.isOpaque = true
        
        self.imageView.contentMode = .scaleAspectFill
        self.bgImage.backgroundColor = .custom.background
        self.bgImage.frame = CGRect(x: 0, y: 0, width: 66, height: 66)
        self.bgImage.layer.cornerRadius = 6
        contentView.addSubview(bgImage)
        
        self.imageView.layer.borderWidth = 1.0 / UIScreen.main.scale
        self.imageView.layer.borderColor = UIColor.custom.outlines.cgColor
        
        self.imageView.backgroundColor = .custom.background
        self.imageView.layer.cornerRadius = 6
        self.imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
    
    // MARK: - Configuration
    override func configure(model: PostCardImageCollectionCellModel, withRoundedCorners roundedCorners: Bool = true) {
        self.imageView.sd_setImage(with: URL(string: model.mediaAttachment.previewURL!))
        for x in self.imageView.subviews {
            x.removeFromSuperview()
        }
        if model.isSensitive  && GlobalStruct.blurSensitiveContent {
            let blurEffect = UIBlurEffect(style: .regular)
            var blurredEffectView = UIVisualEffectView()
            blurredEffectView = UIVisualEffectView(effect: blurEffect)
            blurredEffectView.frame = self.imageView.bounds
            blurredEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.imageView.addSubview(blurredEffectView)
        }
    }
}

