//
//  ReadMoreButton.swift
//  Mammoth
//
//  Created by Benoit Nolens on 09/02/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit

class ReadMoreButton: UIButton {    
    init() {
        super.init(frame: .zero)
        self.setupUI()
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.setTitle("Read more", for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        self.setTitleColor(.custom.highContrast, for: .normal)
        self.contentEdgeInsets = .init(top: 2, left: 0, bottom: 0, right: 3)
    }
    
    public func configure(backgroundColor: UIColor) {
        
    }
}
