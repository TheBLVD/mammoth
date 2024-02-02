//
//  PostCardView.swift
//  Mammoth
//
//  Created by Benoit Nolens on 01/02/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit

@objc class PostCardView: UIView {
    
    @objc public var viewHeight: CGFloat {
        self.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    }
    
    private let label: UILabel  = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension PostCardView {
    func setupUI() {
        self.addSubview(label)
        label.pinEdges()
    }
}

@objc extension PostCardView {
    func configure(text: String) {
        DispatchQueue.main.async {
            self.label.text = text
        }
    }
}
