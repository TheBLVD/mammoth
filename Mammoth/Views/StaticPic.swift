//
//  StaticPic.swift
//  Mammoth
//
//  Created by Riley Howard on 9/27/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class StaticPic: UIImageView {
    
    enum StaticPicSize {
        case small, regular
        
        func width() -> CGFloat {
            switch self {
            case .small:
                return 24
            case .regular:
                return 44
            }
        }
        
        func height() -> CGFloat {
            return width() // height == width
        }
        
        func cornerRadius() -> CGFloat {
            if GlobalStruct.circleProfiles {
                return width() / 2
            } else {
                switch self {
                case .small:
                    return 4
                case .regular:
                    return 8
                }
            }
        }
    }
    
    // MARK: - Properties
    
    private(set) var glyphView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.clipsToBounds = false
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    private var size: StaticPicSize = StaticPicSize.regular
        
    init(withSize StaticPicSize: StaticPicSize) {
        super.init(frame: .zero)
        self.size = StaticPicSize
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        self.glyphView.image = nil
    }
}

// MARK: - Setup UI
private extension StaticPic {
    func setupUI() {
        self.addSubview(glyphView)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .custom.OVRLYSoftContrast
        self.layer.borderColor = UIColor.custom.outlines.cgColor
        self.layer.borderWidth = 0.5
        self.layer.cornerRadius = self.size.cornerRadius()
        
        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalToConstant: self.size.width()),
            self.heightAnchor.constraint(equalToConstant: self.size.height()),
            glyphView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            glyphView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
}

// MARK: - Configuration
extension StaticPic {
    
    func setImage(_ image: UIImage) {
        self.glyphView.image = image
    }
    
    func onThemeChange() {
        self.backgroundColor = .custom.OVRLYSoftContrast
        self.layer.borderColor = UIColor.custom.outlines.cgColor
        self.glyphView.backgroundColor = .custom.OVRLYSoftContrast
        self.glyphView.layer.cornerRadius = self.size.cornerRadius()
    }
}

// MARK: Appearance changes
internal extension StaticPic {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 self.onThemeChange()
             }
         }
    }
}

