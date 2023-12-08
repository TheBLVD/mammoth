//
//  LatestPill.swift
//  Mammoth
//
//  Created by Benoit Nolens on 12/07/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class LatestPill: UIButton {
    // MARK: - Properties
    
    private var unreadCount: Int = 0
    private var picUrls: [URL] = []
    private static let picSize: CGFloat = 21.0
    private static let picBorderWidth: CGFloat = 1
    
    private var blurEffectView: UIVisualEffectView
    private var animatedIn: Bool = false
    
    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = -8
        stackView.distribution = .fill
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var picContainer1: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var picContainer2: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var picContainer3: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var picContainer4: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var arrowContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var pic1: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = UIImage()
        imageView.layer.backgroundColor = UIColor.custom.backgroundTint.cgColor
        imageView.layer.cornerRadius = picSize / 2.0
        imageView.layer.cornerCurve = .continuous
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var pic2: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = UIImage()
        imageView.layer.backgroundColor = UIColor.custom.quoteTint.cgColor
        imageView.layer.cornerRadius = picSize / 2.0
        imageView.layer.cornerCurve = .continuous
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var pic3: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = UIImage()
        imageView.layer.backgroundColor = UIColor.custom.quoteTint.cgColor
        imageView.layer.cornerRadius = picSize / 2.0
        imageView.layer.cornerCurve = .continuous
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var pic4: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = UIImage()
        imageView.backgroundColor = .custom.quoteTint
        imageView.layer.backgroundColor = UIColor.custom.quoteTint.cgColor
        imageView.layer.cornerRadius = picSize / 2.0
        imageView.layer.cornerCurve = .continuous
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var arrow: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = UIImage()
        imageView.backgroundColor = .white
        imageView.layer.backgroundColor = UIColor.white.cgColor
        imageView.layer.cornerRadius = picSize / 2.0
        imageView.layer.cornerCurve = .continuous
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var picBorder1: CALayer = {
        let border = CALayer()
        border.frame = CGRectMake(-picBorderWidth, -picBorderWidth, picSize+(2*picBorderWidth), picSize + (2*picBorderWidth))
        border.backgroundColor = UIColor.custom.quoteTint.cgColor
        border.borderColor = UIColor.custom.quoteTint.cgColor
        border.borderWidth = picBorderWidth
        border.cornerRadius = (picSize + 2*picBorderWidth) / 2
        border.masksToBounds = true
        border.cornerCurve = .continuous
        return border
    }()
    
    private var picBorder2: CALayer = {
        let border = CALayer()
        border.frame = CGRectMake(-picBorderWidth, -picBorderWidth, picSize+(2*picBorderWidth), picSize + (2*picBorderWidth))
        border.backgroundColor = UIColor.custom.quoteTint.cgColor
        border.borderColor = UIColor.custom.quoteTint.cgColor
        border.borderWidth = picBorderWidth
        border.cornerRadius = (picSize + 2*picBorderWidth) / 2
        border.masksToBounds = true
        border.cornerCurve = .continuous
        return border
    }()
    
    private var picBorder3: CALayer = {
        let border = CALayer()
        border.frame = CGRectMake(-picBorderWidth, -picBorderWidth, picSize+(2*picBorderWidth), picSize + (2*picBorderWidth))
        border.backgroundColor = UIColor.custom.quoteTint.cgColor
        border.borderColor = UIColor.custom.quoteTint.cgColor
        border.borderWidth = picBorderWidth
        border.cornerRadius = (picSize + 2*picBorderWidth) / 2
        border.masksToBounds = true
        border.cornerCurve = .continuous
        return border
    }()
    
    private var picBorder4: CALayer = {
        let border = CALayer()
        border.frame = CGRectMake(-picBorderWidth, -picBorderWidth, picSize+(2*picBorderWidth), picSize + (2*picBorderWidth))
        border.backgroundColor = UIColor.custom.quoteTint.cgColor
        border.borderColor = UIColor.custom.quoteTint.cgColor
        border.borderWidth = picBorderWidth
        border.cornerRadius = (picSize + 2*picBorderWidth) / 2
        border.masksToBounds = true
        border.cornerCurve = .continuous
        return border
    }()
    
    private var arrowBorder: CALayer = {
        let border = CALayer()
        border.frame = CGRectMake(-picBorderWidth, -picBorderWidth, picSize+(2*picBorderWidth), picSize + (2*picBorderWidth))
        border.backgroundColor = UIColor.custom.quoteTint.cgColor
        border.borderColor = UIColor.custom.quoteTint.cgColor
        border.borderWidth = picBorderWidth
        border.cornerRadius = (picSize + 2*picBorderWidth) / 2
        border.masksToBounds = true
        border.cornerCurve = .continuous
        return border
    }()
    
    override init(frame: CGRect) {
        let blurEffect = UIBlurEffect(style: .prominent)
        self.blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setupUI()
    }
    
    public override var isEnabled: Bool {
        didSet {
            if isEnabled && unreadCount > 0 {
                self.animateIn()
            } else if !isEnabled {
                self.animateOut()
            }
        }
    }

    // Increase the tap target
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -20, dy: -20).contains(point)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI
private extension LatestPill {
    func setupUI() {

        self.blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        self.blurEffectView.layer.cornerRadius = 16
        self.blurEffectView.layer.cornerCurve = .continuous
        self.blurEffectView.clipsToBounds = true
        self.addSubview(self.blurEffectView)
        self.addSubview(self.mainStackView)

        self.alpha = 0
        self.isEnabled = true
        self.transform = CGAffineTransform(translationX: 0, y: -50)
        
        mainStackView.addArrangedSubview(self.picContainer1)
        mainStackView.addArrangedSubview(self.picContainer2)
        mainStackView.addArrangedSubview(self.picContainer3)
        mainStackView.addArrangedSubview(self.picContainer4)
        mainStackView.addArrangedSubview(self.arrowContainer)
        
        self.picContainer1.layer.addSublayer(self.picBorder1)
        self.picContainer2.layer.addSublayer(self.picBorder2)
        self.picContainer3.layer.addSublayer(self.picBorder3)
        self.picContainer4.layer.addSublayer(self.picBorder4)
        self.arrowContainer.layer.addSublayer(self.arrowBorder)
        
        self.picContainer1.addSubview(self.pic1)
        self.picContainer2.addSubview(self.pic2)
        self.picContainer3.addSubview(self.pic3)
        self.picContainer4.addSubview(self.pic4)
        self.arrowContainer.addSubview(self.arrow)
        
        self.pic1.pinCenter()
        self.pic2.pinCenter()
        self.pic3.pinCenter()
        self.pic4.pinCenter()
        self.arrow.pinCenter()
        
        let widthImage1 = pic1.widthAnchor.constraint(equalToConstant: Self.picSize)
        let heightImage1 = pic1.heightAnchor.constraint(equalToConstant: Self.picSize)
        let widthImage2 = pic2.widthAnchor.constraint(equalToConstant: Self.picSize)
        let heightImage2 = pic2.heightAnchor.constraint(equalToConstant: Self.picSize)
        let widthImage3 = pic3.widthAnchor.constraint(equalToConstant: Self.picSize)
        let heightImage3 = pic3.heightAnchor.constraint(equalToConstant: Self.picSize)
        let widthImage4 = pic4.widthAnchor.constraint(equalToConstant: Self.picSize)
        let heightImage4 = pic4.heightAnchor.constraint(equalToConstant: Self.picSize)
        let widthImage5 = arrow.widthAnchor.constraint(equalToConstant: Self.picSize)
        let heightImage5 = arrow.heightAnchor.constraint(equalToConstant: Self.picSize)

        widthImage1.priority = .required
        heightImage1.priority = .required
        widthImage2.priority = .required
        heightImage2.priority = .required
        widthImage3.priority = .required
        heightImage3.priority = .required
        widthImage4.priority = .required
        heightImage4.priority = .required
        widthImage5.priority = .required
        widthImage5.priority = .required
        
        self.mainStackView.pinCenter(to: self)
        
        self.arrow.image = FontAwesome.image(fromChar: "\u{f062}", color: .black, size: 11, weight: .bold)
        self.arrow.contentMode = .center
        
        NSLayoutConstraint.activate([
            self.picContainer1.widthAnchor.constraint(equalToConstant: Self.picSize+(2*Self.picBorderWidth)),
            self.picContainer1.heightAnchor.constraint(equalToConstant: Self.picSize+(2*Self.picBorderWidth)),
            self.picContainer2.widthAnchor.constraint(equalToConstant: Self.picSize+(2*Self.picBorderWidth)),
            self.picContainer2.heightAnchor.constraint(equalToConstant: Self.picSize+(2*Self.picBorderWidth)),
            self.picContainer3.widthAnchor.constraint(equalToConstant: Self.picSize+(2*Self.picBorderWidth)),
            self.picContainer3.heightAnchor.constraint(equalToConstant: Self.picSize+(2*Self.picBorderWidth)),
            self.picContainer4.widthAnchor.constraint(equalToConstant: Self.picSize+(2*Self.picBorderWidth)),
            self.picContainer4.heightAnchor.constraint(equalToConstant: Self.picSize+(2*Self.picBorderWidth)),
            self.arrowContainer.widthAnchor.constraint(equalToConstant: Self.picSize+(2*Self.picBorderWidth)),
            self.arrowContainer.heightAnchor.constraint(equalToConstant: Self.picSize+(2*Self.picBorderWidth)),
            widthImage1,
            heightImage1,
            widthImage2,
            heightImage2,
            widthImage3,
            heightImage3,
            widthImage4,
            heightImage4,
            widthImage5,
            heightImage5,
        ])

        NSLayoutConstraint.activate([
            self.blurEffectView.centerXAnchor.constraint(equalTo: self.mainStackView.centerXAnchor, constant: -Self.picBorderWidth),
            self.blurEffectView.centerYAnchor.constraint(equalTo: self.mainStackView.centerYAnchor, constant: -Self.picBorderWidth),
            self.blurEffectView.widthAnchor.constraint(equalTo: self.mainStackView.widthAnchor, constant: 8),
            self.blurEffectView.heightAnchor.constraint(equalTo: self.mainStackView.heightAnchor, constant: 8)
        ])
    }
    
    func animateIn() {
        self.animatedIn = true
        UIView.animate(withDuration: 0.72, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.44, options: .curveEaseOut, animations: {
            let translateY = CGAffineTransform(translationX: 0, y: 0)
            self.transform = translateY
            self.alpha = 1
        })
    }
    
    func animateOut() {
        self.animatedIn = false
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            let translateY = CGAffineTransform(translationX: 0, y: -50)
            self.transform = translateY
        })
    }
}

// MARK: - Configure
extension LatestPill {
    func configure(unreadCount: Int, picUrls: [URL]) {
        guard self.unreadCount != unreadCount else { return }
        self.unreadCount = unreadCount
        
        if unreadCount == 0 && self.isEnabled && animatedIn {
            self.isEnabled = false
        } else if unreadCount > 0 && !self.isEnabled {
            self.isEnabled = true
        }
        
        
        guard self.picUrls != picUrls else { return }
        self.picUrls = picUrls

        self.pic1.sd_cancelCurrentImageLoad()
        self.pic2.sd_cancelCurrentImageLoad()
        self.pic3.sd_cancelCurrentImageLoad()
        self.pic4.sd_cancelCurrentImageLoad()
        
        if picUrls.count > 0 {
            self.pic1.sd_setImage(with: picUrls[0], placeholderImage: UIImage(named: "missing"))
        } else {
           self.pic1.image = UIImage(named: "missing")
        }
        if picUrls.count > 1 {
            self.pic2.sd_setImage(with: picUrls[1], placeholderImage: UIImage(named: "missing"))
        } else {
           self.pic2.image = UIImage(named: "missing")
        }
        if picUrls.count > 2 {
            self.pic3.sd_setImage(with: picUrls[2], placeholderImage: UIImage(named: "missing"))
        } else {
            self.pic3.image = UIImage(named: "missing")
        }
        if picUrls.count > 3 {
            self.pic4.sd_setImage(with: picUrls[3], placeholderImage: UIImage(named: "missing"))
        } else {
            self.pic4.image = UIImage(named: "missing")
        }
        
    }
}

// MARK: Appearance changes
internal extension LatestPill {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if (traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection)) {
                 self.picBorder1.borderColor = UIColor.custom.quoteTint.cgColor
                 self.picBorder1.backgroundColor = UIColor.custom.quoteTint.cgColor
                 
                 self.picBorder2.borderColor = UIColor.custom.quoteTint.cgColor
                 self.picBorder2.backgroundColor = UIColor.custom.quoteTint.cgColor
                 
                 self.picBorder3.borderColor = UIColor.custom.quoteTint.cgColor
                 self.picBorder3.backgroundColor = UIColor.custom.quoteTint.cgColor
                 
                 self.picBorder4.borderColor = UIColor.custom.quoteTint.cgColor
                 self.picBorder4.backgroundColor = UIColor.custom.quoteTint.cgColor
                 
                 self.arrowBorder.borderColor = UIColor.custom.quoteTint.cgColor
                 self.arrowBorder.backgroundColor = UIColor.custom.quoteTint.cgColor
            }
         }
    }
}
