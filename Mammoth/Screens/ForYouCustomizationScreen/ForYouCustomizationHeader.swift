//
//  ForYouCustomizationHeader.swift
//  Mammoth
//
//  Created by Riley Howard on 10/31/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class ForYouCustomizationHeader: UIView {
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .custom.mediumContrast
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    
    init() {
        super.init(frame: .zero)
        self.setupUI()
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI
private extension ForYouCustomizationHeader {
    func setupUI() {
        self.backgroundColor = .custom.background
        self.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 5),
            label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 19),
            label.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -19),
        ])
    }
}

// MARK: - Configuration
extension ForYouCustomizationHeader {
    func configure(labelText: String) {
        self.label.text = labelText
    }
}

