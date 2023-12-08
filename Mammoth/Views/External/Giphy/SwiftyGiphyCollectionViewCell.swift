//
//  SwiftyGiphyCollectionViewCell.swift
//  Pods
//
//  Created by Brendan Lee on 3/9/17.
//
//

import UIKit
import SDWebImage

class SwiftyGiphyCollectionViewCell: UICollectionViewCell {
    
    fileprivate(set) var imageView: UIImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    fileprivate func setup() {
        
        let backgroundRoundedCornerView = RoundedCornerView()
        backgroundRoundedCornerView.translatesAutoresizingMaskIntoConstraints = false
        backgroundRoundedCornerView.backgroundColor = .custom.quoteTint
        backgroundRoundedCornerView.clipsToBounds = true
        
        let foregroundRoundedCornerView = RoundedCornerView()
        foregroundRoundedCornerView.translatesAutoresizingMaskIntoConstraints = false
        foregroundRoundedCornerView.backgroundColor = .custom.quoteTint
        foregroundRoundedCornerView.clipsToBounds = true
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        
        backgroundRoundedCornerView.addSubview(foregroundRoundedCornerView)
        foregroundRoundedCornerView.addSubview(imageView)
        
        contentView.addSubview(backgroundRoundedCornerView)
        
        NSLayoutConstraint.activate([
                backgroundRoundedCornerView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
                backgroundRoundedCornerView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
                backgroundRoundedCornerView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
                backgroundRoundedCornerView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
            ])
        
        NSLayoutConstraint.activate([
                foregroundRoundedCornerView.leftAnchor.constraint(equalTo: backgroundRoundedCornerView.leftAnchor, constant: 1.0 / UIScreen.main.scale),
                foregroundRoundedCornerView.topAnchor.constraint(equalTo: backgroundRoundedCornerView.topAnchor, constant: 1.0 / UIScreen.main.scale),
                foregroundRoundedCornerView.bottomAnchor.constraint(equalTo: backgroundRoundedCornerView.bottomAnchor, constant: -(1.0 / UIScreen.main.scale)),
                foregroundRoundedCornerView.rightAnchor.constraint(equalTo: backgroundRoundedCornerView.rightAnchor, constant: -(1.0 / UIScreen.main.scale))
            ])
        
        NSLayoutConstraint.activate([
                imageView.leftAnchor.constraint(equalTo: foregroundRoundedCornerView.leftAnchor),
                imageView.topAnchor.constraint(equalTo: foregroundRoundedCornerView.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: foregroundRoundedCornerView.bottomAnchor),
                imageView.rightAnchor.constraint(equalTo: foregroundRoundedCornerView.rightAnchor)
            ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.sd_cancelCurrentImageLoad()
        imageView.sd_cancelCurrentImageLoad()
        imageView.sd_setImage(with: nil)
        imageView.image = nil
    
    }
    
    /// Configure the cell for a giphy image set
    ///
    /// - Parameter imageSet: The imageset to configure the cell with
    func configureFor(imageSet: GiphyImageSet)
    {
//        imageView.sd_cacheFLAnimatedImage = false
//        imageView.sd_setShowActivityIndicatorView(true)
//        imageView.sd_setIndicatorStyle(.gray)
        imageView.sd_setImage(with: imageSet.url)
    }
}
