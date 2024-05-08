//
//  PostCardLinkPreview.swift
//  Mammoth
//
//  Created by Benoit Nolens on 31/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage

class PostCardLinkPreview: UIView {
    
    static private let largeImageHeight = 220.0
    static private let layoutMargins = UIEdgeInsets(top: 8, left: 10, bottom: 10, right: 10)
    
    // MARK: - Properties
    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.layer.borderWidth = 1.0 / UIScreen.main.scale
        stackView.layer.allowsEdgeAntialiasing = false
        stackView.layer.edgeAntialiasingMask = [.layerBottomEdge, .layerTopEdge, .layerLeftEdge, .layerRightEdge]
        stackView.layer.needsDisplayOnBoundsChange = false
        stackView.layer.rasterizationScale = UIScreen.main.scale
        stackView.layer.contentsScale = UIScreen.main.scale
        
        stackView.layer.borderColor = UIColor.custom.outlines.cgColor
        stackView.layer.masksToBounds = true
        stackView.layer.cornerRadius = 6
        
        return stackView
    }()
    
    private var imageStack: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.clipsToBounds = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var textStack: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.layoutMargins = PostCardLinkPreview.layoutMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return stackView
    }()
    
    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isOpaque = true
        imageView.contentMode = .scaleAspectFill
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.backgroundColor = .custom.background
        imageView.isOpaque = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    private var imageHeightConstraint: NSLayoutConstraint? = nil
    
    private var urlLabel: UILabel = {
        let label = UILabel()
        label.isOpaque = true
        label.textColor = .custom.feintContrast
        label.numberOfLines = 1
        label.isOpaque = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }()
    
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.isOpaque = true
        label.textColor = UIColor.label
        label.numberOfLines = 3
        label.isOpaque = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }()
    
    private var status: Status?
    public var onPress: PostCardButtonCallback?
    private var isPrivateMention = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.onTapped))
        self.mainStackView.addGestureRecognizer(tapGesture)
        
        let contextMenu = UIContextMenuInteraction(delegate: self)
        self.mainStackView.addInteraction(contextMenu)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        self.status = nil
        self.imageView.image = nil
        self.imageView.sd_cancelCurrentImageLoad()
        self.onPress = nil
    }
    
    func setupUIFromSettings() {
        urlLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        titleLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
    }
}


// MARK: - Setup UI
private extension PostCardLinkPreview {
    func setupUI() {
        self.isOpaque = true
        self.addSubview(mainStackView)
        
//        mainStackView.addArrangedSubview(imageStack)
        mainStackView.addArrangedSubview(textStack)
        textStack.addArrangedSubview(self.urlLabel)
        textStack.addArrangedSubview(self.titleLabel)
        
//        imageStack.addArrangedSubview(self.imageView)
//        imageHeightConstraint = imageHeightConstraint ?? self.imageView.heightAnchor.constraint(equalToConstant: PostCardLinkPreview.largeImageHeight)
//        imageHeightConstraint?.priority = .defaultHigh
//        imageHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 9),
            mainStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
//            imageStack.trailingAnchor.constraint(equalTo: self.trailingAnchor),
//            imageView.trailingAnchor.constraint(equalTo: self.imageStack.trailingAnchor),
        ])
        
        let urlLabelTrailing = urlLabel.trailingAnchor.constraint(equalTo: textStack.layoutMarginsGuide.trailingAnchor)
        let titleLabelTrailing = titleLabel.trailingAnchor.constraint(equalTo: textStack.layoutMarginsGuide.trailingAnchor)
        
        NSLayoutConstraint.activate([
            // Force urlLabel to fill the parent width
            urlLabelTrailing,
            // Force titleLabel to fill the parent width
            titleLabelTrailing
        ])
        
        setupUIFromSettings()
        onThemeChange()
    }
}

// MARK: - Estimated height
extension PostCardLinkPreview {
    static func estimatedHeight(width: CGFloat, postCard: PostCardModel) -> CGFloat {
        
        let marginTop = 9.0
        let urlFont = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        let titleFont = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        
        var height: CGFloat = marginTop
        height += PostCardLinkPreview.layoutMargins.top
        height += PostCardLinkPreview.layoutMargins.bottom
        
        height += ceil(postCard.formattedCardUrlStr?.height(width: width, font: urlFont) ?? postCard.linkCard?.url?.height(width: width, font: urlFont) ?? 0.0)
        height += ceil(postCard.linkCard?.title.height(width: width, font: titleFont) ?? 0.0)
        
        return height
    }
}

// MARK: - Configuration
extension PostCardLinkPreview {
    func configure(postCard: PostCardModel) {
        guard case .mastodon(let status) = postCard.data
        else { return }
        
        self.status = status
        
        let shouldChangeTheme = self.isPrivateMention != postCard.isPrivateMention
        self.isPrivateMention = postCard.isPrivateMention
        
        if let urlString = postCard.formattedCardUrlStr {
            self.urlLabel.text = urlString
        } else {
            self.urlLabel.text = postCard.linkCard?.url
        }
        
        self.titleLabel.text = postCard.linkCard?.title
       
//        // Display the link image if needed
//        if !postCard.hideLinkImage, let imageURL = postCard.linkCard?.image {
//            self.imageView.ma_setImage(with: imageURL,
//                                       cachedImage: postCard.decodedImages[imageURL.absoluteString] as? UIImage,
//                                       placeholder: nil,
//                                              imageTransformer: PostCardImage.transformer) { [weak self] image in
//                if self?.status == status {
//                    postCard.decodedImages[imageURL.absoluteString] = image
//                }
//            }
//            
//            self.imageView.isHidden = false
//            
//        } else if self.imageView.isHidden == false {
//            self.imageView.isHidden = true
//        }
        
        if shouldChangeTheme {
            self.onThemeChange()
        }
    }
    
    func onThemeChange() {
        self.mainStackView.layer.borderColor = UIColor.custom.outlines.cgColor
        self.urlLabel.textColor = .custom.feintContrast
        let backgroundColor: UIColor = self.isPrivateMention ? .custom.OVRLYSoftContrast : .custom.background
        self.urlLabel.backgroundColor = backgroundColor
        self.titleLabel.backgroundColor = backgroundColor
        self.backgroundColor = backgroundColor
        mainStackView.backgroundColor = backgroundColor
        imageStack.backgroundColor = backgroundColor
        textStack.backgroundColor = backgroundColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
       super.traitCollectionDidChange(previousTraitCollection)
       onThemeChange()
   }

}

// MARK: - Handlers
extension PostCardLinkPreview {
    @objc func onTapped() {
        if let urlStr = self.status?.reblog?.card?.url ?? self.status?.card?.url, let  url = URL(string: urlStr) {
            self.onPress?(.link, true, .url(url))
        }
    }
}

// MARK: - Context menu creators
extension PostCardLinkPreview: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        if let status = self.status, let onButtonPress = self.onPress {
            let postCard = PostCardModel(status: status)
            if let urlStr = postCard.linkCard?.url, let url = URL(string: urlStr) {
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
                    guard let self else { return UIMenu() }
                    
                    let options = [
                        self.createContextMenuAction(NSLocalizedString("post.openLink", comment: ""), .link, isActive: false, data: .url(url), onPress: onButtonPress),
                        self.createContextMenuAction(NSLocalizedString("generic.copy", comment: ""), .copy, isActive: false, data: .url(url), onPress: onButtonPress),
                        self.createContextMenuAction(NSLocalizedString("generic.share", comment: ""), .share, isActive: false, data: .url(url), onPress: onButtonPress),
                    ].compactMap({$0})
                    
                    return UIMenu(title: "", options: [.displayInline], children: options)
                })
            }
        }
        
        return nil
    }

    private func createContextMenuAction(_ title: String, _ buttonType: PostCardButtonType, isActive: Bool, data: PostCardButtonCallbackData?, onPress: @escaping PostCardButtonCallback) -> UIAction {
        let action = UIAction(title: title,
                                  image: buttonType.icon(symbolConfig: postCardSymbolConfig),
                                  identifier: nil) { _ in
            onPress(buttonType, isActive, data)
        }
        action.accessibilityLabel = title
        return action
    }
}
