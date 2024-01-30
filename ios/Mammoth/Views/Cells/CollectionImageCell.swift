//
//  CollectionImageCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 27/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class CollectionImageCell: UICollectionViewCell {
    
    var bgImage = UIImageView()
    var image = UIImageView()
    let gradient: CAGradientLayer = CAGradientLayer()
    var videoOverlay = UIImageView()
    var duration = UILabel()
    var altTextButton = UIButton()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    public func configure() {
        self.bgImage.backgroundColor = .custom.quoteTint
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            self.bgImage.frame = CGRect(x: 80, y: 0, width: CGFloat(GlobalStruct.padColWidth - 100), height: 220)
        } else {
#if targetEnvironment(macCatalyst)
            self.bgImage.frame = CGRect(x: 80, y: 0, width: CGFloat(GlobalStruct.padColWidth - 100), height: 220)
#elseif !targetEnvironment(macCatalyst)
            self.bgImage.frame = CGRect(x: 80, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 100, height: 220)
#endif
        }
        self.bgImage.layer.cornerRadius = 10
        contentView.addSubview(bgImage)
        
        self.image.layer.borderWidth = 0.4
        self.image.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        
        self.image.frame.origin.x = 80
        self.image.frame.origin.y = 0
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            self.image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 100)
        } else {
#if targetEnvironment(macCatalyst)
            self.image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 100)
#elseif !targetEnvironment(macCatalyst)
            self.image.frame.size.width = (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 100
#endif
        }
        self.image.frame.size.height = 220
        self.image.backgroundColor = .custom.quoteTint
        self.image.layer.cornerRadius = 10
        contentView.addSubview(image)
        
        self.altTextButton.frame = CGRect(x: 85, y: 190, width: 40, height: 25)
        self.altTextButton.setTitle("ALT", for: .normal)
        self.altTextButton.setTitleColor(UIColor.white, for: .normal)
        self.altTextButton.backgroundColor = .black
        self.altTextButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        self.altTextButton.layer.cornerCurve = .continuous
        self.altTextButton.layer.cornerRadius = 8
        self.altTextButton.alpha = 0
        self.altTextButton.accessibilityElementsHidden = true
        contentView.addSubview(self.altTextButton)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitView = super.hitTest(point, with: event) {
            if point.x > 80 {
                return hitView
            } else {
                return self.superview?.superview
            }
        } else {
            return nil
        }
    }
}

class CollectionImageCellActivity: UICollectionViewCell {
    
    var bgImage = UIImageView()
    var image = UIImageView()
    let gradient: CAGradientLayer = CAGradientLayer()
    var videoOverlay = UIImageView()
    var duration = UILabel()
    var altTextButton = UIButton()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    public func configure() {
        self.bgImage.backgroundColor = .custom.quoteTint
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            self.bgImage.frame = CGRect(x: 118, y: 0, width: CGFloat(GlobalStruct.padColWidth - 100 - 38), height: 220)
        } else {
#if targetEnvironment(macCatalyst)
            self.bgImage.frame = CGRect(x: 118, y: 0, width: CGFloat(GlobalStruct.padColWidth - 100 - 38), height: 220)
#elseif !targetEnvironment(macCatalyst)
            self.bgImage.frame = CGRect(x: 118, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 100 - 38, height: 220)
#endif
        }
        self.bgImage.layer.cornerRadius = 10
        contentView.addSubview(bgImage)
        
        self.image.layer.borderWidth = 0.4
        self.image.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        
        self.image.frame.origin.x = 118
        self.image.frame.origin.y = 0
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            self.image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 100) - 38
        } else {
#if targetEnvironment(macCatalyst)
            self.image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 100) - 38
#elseif !targetEnvironment(macCatalyst)
            self.image.frame.size.width = (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 100 - 38
#endif
        }
        self.image.frame.size.height = 220
        self.image.backgroundColor = .custom.quoteTint
        self.image.layer.cornerRadius = 10
        contentView.addSubview(image)
        
        self.altTextButton.frame = CGRect(x: 123, y: 190, width: 40, height: 25)
        self.altTextButton.setTitle("ALT", for: .normal)
        self.altTextButton.setTitleColor(UIColor.white, for: .normal)
        self.altTextButton.backgroundColor = .black
        self.altTextButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        self.altTextButton.layer.cornerCurve = .continuous
        self.altTextButton.layer.cornerRadius = 8
        self.altTextButton.alpha = 0
        self.altTextButton.accessibilityElementsHidden = true
        contentView.addSubview(self.altTextButton)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitView = super.hitTest(point, with: event) {
            if point.x > 80 {
                return hitView
            } else {
                return self.superview?.superview
            }
        } else {
            return nil
        }
    }
}

class CollectionImageCellS: UICollectionViewCell {
    
    var bgImage = UIImageView()
    var image = UIImageView()
    let gradient: CAGradientLayer = CAGradientLayer()
    var videoOverlay = UIImageView()
    var duration = UILabel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    public func configure() {
        self.bgImage.backgroundColor = .custom.quoteTint
        self.bgImage.frame = CGRect(x: 0, y: 0, width: 66, height: 66)
        self.bgImage.layer.cornerRadius = 8
        contentView.addSubview(bgImage)
        
        self.image.layer.borderWidth = 0.4
        self.image.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        
        self.image.frame.origin.x = 0
        self.image.frame.origin.y = 0
        self.image.frame.size.width = 66
        self.image.frame.size.height = 66
        self.image.backgroundColor = .custom.quoteTint
        self.image.layer.cornerRadius = 8
        contentView.addSubview(image)
    }
}

class CollectionImageCellD: UICollectionViewCell {
    
    var bgImage = UIImageView()
    var image = UIImageView()
    let gradient: CAGradientLayer = CAGradientLayer()
    var videoOverlay = UIImageView()
    var duration = UILabel()
    var altTextButton = UIButton()
    var preferredWidth: CGFloat?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    public func configure() {
        self.bgImage.backgroundColor = .custom.quoteTint
        self.bgImage.layer.cornerRadius = 0
        contentView.addSubview(bgImage)
        
        self.image.layer.borderWidth = 0.4
        self.image.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        
        self.image.frame.origin.x = 0
        self.image.frame.origin.y = 0
        self.image.backgroundColor = .custom.quoteTint
        self.image.layer.cornerRadius = 0
        contentView.addSubview(image)
        
        let windowFrame = UIApplication.shared.connectedScenes
                        .compactMap({ scene -> UIWindow? in
                            (scene as? UIWindowScene)?.windows.first
                        }).first?.frame
        
        var fullWidth = preferredWidth ?? UIScreen.main.bounds.size.width - 87
        #if targetEnvironment(macCatalyst)
        fullWidth = preferredWidth ?? windowFrame?.size.width ?? 0
        #endif
        
#if targetEnvironment(macCatalyst)
        if GlobalStruct.singleColumn {
            self.bgImage.frame = CGRect(x: 0, y: 0, width: fullWidth, height: 400)
            self.image.frame.size.width = fullWidth
            self.image.frame.size.height = 400
        } else {
            self.bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth), height: 280)
            self.image.frame.size.width = CGFloat(GlobalStruct.padColWidth)
            self.image.frame.size.height = 280
        }
#elseif !targetEnvironment(macCatalyst)
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            self.bgImage.frame = CGRect(x: 0, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 87, height: 400)
            self.image.frame.size.width = preferredWidth ?? ((UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 87)
            self.image.frame.size.height = 400
        } else {
            if UIDevice.current.userInterfaceIdiom == .pad {
                self.bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth), height: 280)
                self.image.frame.size.width = CGFloat(GlobalStruct.padColWidth)
            } else {
                self.bgImage.frame = CGRect(x: 0, y: 0, width: preferredWidth ?? CGFloat(UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width), height: 280)
                self.image.frame.size.width = preferredWidth ?? CGFloat(UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width)
            }
            self.image.frame.size.height = 280
        }
#endif
        
        self.altTextButton.frame = CGRect(x: 5, y: 250, width: 40, height: 25)
        self.altTextButton.setTitle("ALT", for: .normal)
        self.altTextButton.setTitleColor(UIColor.white, for: .normal)
        self.altTextButton.backgroundColor = .black
        self.altTextButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        self.altTextButton.layer.cornerCurve = .continuous
        self.altTextButton.layer.cornerRadius = 8
        self.altTextButton.alpha = 0
        self.altTextButton.accessibilityElementsHidden = true
        contentView.addSubview(self.altTextButton)
    }
}

class CollectionImageCell2: UICollectionViewCell {
    
    var bgImage = UIImageView()
    var image = UIImageView()
    let gradient: CAGradientLayer = CAGradientLayer()
    var videoOverlay = UIImageView()
    var duration = UILabel()
    var altTextButton = UIButton()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    public func configure() {
        self.bgImage.backgroundColor = .custom.quoteTint
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            self.bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth - 100), height: 190)
        } else {
#if targetEnvironment(macCatalyst)
            self.bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth - 100), height: 190)
#elseif !targetEnvironment(macCatalyst)
            self.bgImage.frame = CGRect(x: 0, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 100, height: 190)
#endif
        }
        self.bgImage.layer.cornerRadius = 0
        contentView.addSubview(bgImage)
        
        self.image.layer.borderWidth = 0.4
        self.image.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        
        self.image.frame.origin.x = 0
        self.image.frame.origin.y = 0
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            self.image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 100)
        } else {
#if targetEnvironment(macCatalyst)
            self.image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 100)
#elseif !targetEnvironment(macCatalyst)
            self.image.frame.size.width = (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 100
#endif
        }
        self.image.frame.size.height = 190
        self.image.backgroundColor = .custom.quoteTint
        self.image.layer.cornerRadius = 0
        contentView.addSubview(image)
        
        self.altTextButton.frame = CGRect(x: 5, y: 160, width: 40, height: 25)
        self.altTextButton.setTitle("ALT", for: .normal)
        self.altTextButton.setTitleColor(UIColor.white, for: .normal)
        self.altTextButton.backgroundColor = .black
        self.altTextButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        self.altTextButton.layer.cornerCurve = .continuous
        self.altTextButton.layer.cornerRadius = 8
        self.altTextButton.alpha = 0
        self.altTextButton.accessibilityElementsHidden = true
        contentView.addSubview(self.altTextButton)
    }
}

class CollectionImageCell3: UICollectionViewCell {
    
    var bgImage = UIImageView()
    var image = UIImageView()
    let gradient: CAGradientLayer = CAGradientLayer()
    var videoOverlay = UIImageView()
    var duration = UILabel()
    var altTextButton = UIButton()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    public func configure() {
        self.bgImage.backgroundColor = .custom.quoteTint
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            self.bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth - 40), height: 190)
        } else {
#if targetEnvironment(macCatalyst)
            self.bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth - 40), height: 190)
#elseif !targetEnvironment(macCatalyst)
            self.bgImage.frame = CGRect(x: 0, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 40, height: 190)
#endif
        }
        self.bgImage.layer.cornerRadius = 0
        contentView.addSubview(bgImage)
        
        self.image.layer.borderWidth = 0.4
        self.image.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        
        self.image.frame.origin.x = 0
        self.image.frame.origin.y = 0
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            self.image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 40)
        } else {
#if targetEnvironment(macCatalyst)
            self.image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 40)
#elseif !targetEnvironment(macCatalyst)
            self.image.frame.size.width = (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 40
#endif
        }
        self.image.frame.size.height = 190
        self.image.backgroundColor = .custom.quoteTint
        self.image.layer.cornerRadius = 0
        contentView.addSubview(image)
        
        self.altTextButton.frame = CGRect(x: 5, y: 160, width: 40, height: 25)
        self.altTextButton.setTitle("ALT", for: .normal)
        self.altTextButton.setTitleColor(UIColor.white, for: .normal)
        self.altTextButton.backgroundColor = .black
        self.altTextButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        self.altTextButton.layer.cornerCurve = .continuous
        self.altTextButton.layer.cornerRadius = 8
        self.altTextButton.alpha = 0
        self.altTextButton.accessibilityElementsHidden = true
        contentView.addSubview(self.altTextButton)
    }
}

class CollectionImageCell4: UICollectionViewCell {
    
    var bgImage = UIImageView()
    var image = UIImageView()
    let gradient: CAGradientLayer = CAGradientLayer()
    var videoOverlay = UIImageView()
    var duration = UILabel()
    var postButton = UIButton()
    var altTextButton = UIButton()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    public func configure() {
        var minusDiff: CGFloat = 32
        if (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) > 400 {
            minusDiff = 40
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            minusDiff = 32
        }
        
        var fullWidth = UIScreen.main.bounds.size.width - 87
#if targetEnvironment(macCatalyst)
        fullWidth = UIApplication.shared.windows.first?.frame.size.width ?? 0
#endif
        
        self.bgImage.backgroundColor = .custom.quoteTint
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            if GlobalStruct.singleColumn {
                self.bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(fullWidth) - minusDiff, height: 230)
            } else {
                self.bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth) - minusDiff, height: 230)
            }
        } else {
#if targetEnvironment(macCatalyst)
            self.bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth) - minusDiff, height: 230)
#elseif !targetEnvironment(macCatalyst)
            self.bgImage.frame = CGRect(x: 0, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - minusDiff, height: 230)
#endif
        }
        contentView.addSubview(bgImage)
        
        self.image.layer.borderWidth = 0.4
        self.image.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        
        self.image.frame.origin.x = 0
        self.image.frame.origin.y = 0
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            if GlobalStruct.singleColumn {
                self.image.frame.size.width = CGFloat(fullWidth) - minusDiff
            } else {
                self.image.frame.size.width = CGFloat(GlobalStruct.padColWidth) - minusDiff
            }
        } else {
#if targetEnvironment(macCatalyst)
            self.image.frame.size.width = CGFloat(GlobalStruct.padColWidth) - minusDiff
#elseif !targetEnvironment(macCatalyst)
            self.image.frame.size.width = (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - minusDiff
#endif
        }
        self.image.frame.size.height = 230
        self.image.backgroundColor = .custom.quoteTint
        contentView.addSubview(image)
        
        self.altTextButton.frame = CGRect(x: 25, y: 160, width: 40, height: 25)
        self.altTextButton.setTitle("ALT", for: .normal)
        self.altTextButton.setTitleColor(UIColor.white, for: .normal)
        self.altTextButton.backgroundColor = .black
        self.altTextButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        self.altTextButton.layer.cornerCurve = .continuous
        self.altTextButton.layer.cornerRadius = 8
        self.altTextButton.alpha = 0
        self.altTextButton.accessibilityElementsHidden = true
        contentView.addSubview(self.altTextButton)
        
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            if GlobalStruct.singleColumn {
                postButton.frame = CGRect(x: 0, y: 0, width: CGFloat(fullWidth) - minusDiff, height: 230)
            } else {
                postButton.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth) - minusDiff, height: 230)
            }
        } else {
#if targetEnvironment(macCatalyst)
            postButton.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth) - minusDiff, height: 230)
#elseif !targetEnvironment(macCatalyst)
            postButton.frame = CGRect(x: 0, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - minusDiff, height: 230)
#endif
        }
        postButton.backgroundColor = .clear
        postButton.setTitleColor(.white, for: .normal)
        postButton.layer.cornerCurve = .continuous
        postButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        postButton.titleLabel?.textAlignment = .left
        postButton.contentHorizontalAlignment = .left
        postButton.titleLabel?.lineBreakMode = .byTruncatingTail
        postButton.titleLabel?.numberOfLines = 0
        postButton.layer.masksToBounds = true
        postButton.isUserInteractionEnabled = true
        postButton.contentVerticalAlignment = .bottom
        postButton.titleLabel?.numberOfLines = 4
        contentView.addSubview(postButton)
    }
}

class CollectionImageCell5: UICollectionViewCell {
    
    var bgImage = UIImageView()
    var image = UIImageView()
    let gradient: CAGradientLayer = CAGradientLayer()
    var videoOverlay = UIImageView()
    var duration = UILabel()
    var altTextButton = UIButton()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    public func configure() {
        self.bgImage.backgroundColor = .custom.quoteTint
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            self.bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth - 40), height: 240)
        } else {
#if targetEnvironment(macCatalyst)
            self.bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth - 40), height: 240)
#elseif !targetEnvironment(macCatalyst)
            self.bgImage.frame = CGRect(x: 0, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 40, height: 240)
#endif
        }
        self.bgImage.layer.cornerRadius = 0
        contentView.addSubview(bgImage)
        
        self.image.layer.borderWidth = 0.4
        self.image.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        
        self.image.frame.origin.x = 0
        self.image.frame.origin.y = 0
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            self.image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 40)
        } else {
#if targetEnvironment(macCatalyst)
            self.image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 40)
#elseif !targetEnvironment(macCatalyst)
            self.image.frame.size.width = (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 40
#endif
        }
        self.image.frame.size.height = 240
        self.image.backgroundColor = .custom.quoteTint
        self.image.layer.cornerRadius = 0
        contentView.addSubview(image)
        
        self.altTextButton.frame = CGRect(x: 5, y: 210, width: 40, height: 25)
        self.altTextButton.setTitle("ALT", for: .normal)
        self.altTextButton.setTitleColor(UIColor.white, for: .normal)
        self.altTextButton.backgroundColor = .black
        self.altTextButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        self.altTextButton.layer.cornerCurve = .continuous
        self.altTextButton.layer.cornerRadius = 8
        self.altTextButton.alpha = 0
        self.altTextButton.accessibilityElementsHidden = true
        contentView.addSubview(self.altTextButton)
    }
}

class CollectionImageCellIAP: UICollectionViewCell {
    
    var image = UIImageView()
    var titleText = UILabel()
    let gradient: CAGradientLayer = CAGradientLayer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    public func configure(_ tex: String, im: UIImage?) {
        self.image.layer.cornerCurve = .continuous
        self.image.layer.cornerRadius = 12
        self.image.frame.origin.x = 18
        self.image.frame.origin.y = 0
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            self.image.frame.size.width = CGFloat(120)
        } else {
#if targetEnvironment(macCatalyst)
            self.image.frame.size.width = CGFloat(120)
#elseif !targetEnvironment(macCatalyst)
            self.image.frame.size.width = 120
#endif
        }
        self.image.frame.size.height = 240
        self.image.backgroundColor = .custom.quoteTint
        self.image.layer.masksToBounds = true
        self.image.image = im ?? UIImage()
        contentView.addSubview(image)
        
        self.gradient.frame = CGRect(x: 0, y: 120, width: 120, height: 120)
        self.gradient.colors = [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.withAlphaComponent(0.18).cgColor]
        self.image.layer.addSublayer(gradient)
        
        self.titleText.textColor = UIColor.white
        self.titleText.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        self.titleText.textAlignment = .left
        self.titleText.numberOfLines = 0
        self.titleText.frame = CGRect(x: 31, y: 10, width: 94, height: 100)
        self.titleText.text = tex
        self.titleText.sizeToFit()
        self.titleText.frame.origin.y = 240 - (self.titleText.frame.size.height) - 7
        contentView.addSubview(titleText)
    }
}
