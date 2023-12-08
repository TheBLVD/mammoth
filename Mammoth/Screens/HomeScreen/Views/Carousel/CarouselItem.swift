//
//  CarouselItem.swift
//  Mammoth
//
//  Created by Benoit Nolens on 24/08/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class CarouselItem: UICollectionViewCell {
    static let reuseIdentifier = "CarouselItem"

    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.contentView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 9, right: 0)
        } else {
            self.contentView.layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        }
                
        titleLabel.textAlignment = .left
        titleLabel.font = .systemFont(ofSize: 16.0, weight: .semibold)
        titleLabel.textColor = .custom.highContrast
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
