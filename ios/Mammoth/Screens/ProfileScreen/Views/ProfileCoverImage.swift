//
//  ProfileCoverImage.swift
//  Mammoth
//
//  Created by Benoit Nolens on 14/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import SDWebImage

class ProfileCoverImage: UIView {
    
    // MARK: - Properties
    private let coverImage = UIImageView()
    private let gradient = UIView()
    private var user: UserCardModel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        
        // Define the gradient colors
        let transparentColor = UIColor.clear.cgColor
        let blackColor = UIColor.black.cgColor
        gradientLayer.colors = [blackColor, transparentColor]
        
        // Define the gradient locations
        gradientLayer.locations = [0, 1.0]
        
        // Define the gradient direction
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        self.layer.mask = gradientLayer
    }
}

// MARK: - Setup UI
private extension ProfileCoverImage {
    func setupUI() {
        self.isOpaque = true
        self.backgroundColor = .custom.background
        self.addSubview(coverImage)
        self.addSubview(gradient)
        
        coverImage.translatesAutoresizingMaskIntoConstraints = false
        gradient.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            coverImage.topAnchor.constraint(equalTo: self.topAnchor),
            coverImage.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            coverImage.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            coverImage.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            gradient.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            gradient.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            gradient.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            gradient.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
}

// MARK: - Configuration
extension ProfileCoverImage {
    func configure(user: UserCardModel) {
        // Only re-configure if the header URL changed
        guard self.user?.account?.headerStatic != user.account?.headerStatic else { return }
        
        self.user = user
        
        if let headerImageStr = user.account?.headerStatic, let headerImageURL = URL(string: headerImageStr) {
            self.coverImage.contentMode = .scaleAspectFill
            self.coverImage.sd_imageTransition = .fade
            self.coverImage.sd_setImage(with: headerImageURL, placeholderImage: self.coverImage.image, context: [.storeCacheType : SDImageCacheType.memory.rawValue])
        }
    }
    
    func optimisticUpdate(image: UIImage) {
        self.coverImage.contentMode = .scaleAspectFill
        self.coverImage.image = image
    }
    
    func onThemeChange() {
        self.backgroundColor = .custom.background
    }
    
    func didScroll(scrollView: UIScrollView) {
        let maxOffset = 120.0 - scrollView.safeAreaInsets.top
        if scrollView.contentOffset.y < maxOffset {
            self.coverImage.layer.opacity = 1 - Float(min(max(scrollView.contentOffset.y / maxOffset, 0), 1))
        } else if self.coverImage.layer.opacity > 0 {
            self.coverImage.layer.opacity = 0
        }
    }
}
