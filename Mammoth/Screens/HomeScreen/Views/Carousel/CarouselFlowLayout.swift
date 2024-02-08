//
//  CarouselFlowLayout.swift
//  Mammoth
//
//  Created by Benoit Nolens on 24/08/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class CarouselFlowLayout: UICollectionViewFlowLayout {
    
    override init() {
        super.init()
        
        scrollDirection = .horizontal
        minimumLineSpacing = 8
        minimumInteritemSpacing = 8
        estimatedItemSize = CGSize(width: 120, height: 40)
        sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
