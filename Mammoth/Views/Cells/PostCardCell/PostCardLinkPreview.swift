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
    
    // MARK: - Properties
    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.layer.borderWidth = 0.4
        stackView.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        stackView.layer.masksToBounds = true
        stackView.layer.cornerRadius = 6
        
        return stackView
    }()
    
    private var imageStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var textStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 10, bottom: 10, right: 10)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return stackView
    }()
    
    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.backgroundColor = .custom.background
        imageView.isOpaque = true
        return imageView
    }()
    private var imageHeightConstraint: NSLayoutConstraint? = nil
    
    private var urlLabel: UILabel = {
        let label = UILabel()
        label.textColor = .custom.actionButtons
        label.numberOfLines = 1
        label.isOpaque = true
        label.backgroundColor = .custom.background
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.label
        label.numberOfLines = 3
        label.isOpaque = true
        label.backgroundColor = .custom.background
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    private var status: Status?
    public var onPress: PostCardButtonCallback?
    
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
        self.imageStack.removeArrangedSubview(self.imageView)
        self.imageView.image = nil
        self.imageView.removeFromSuperview()
        self.imageHeightConstraint?.isActive = false
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
        
        mainStackView.addArrangedSubview(imageStack)
        mainStackView.addArrangedSubview(textStack)
        textStack.addArrangedSubview(self.urlLabel)
        textStack.addArrangedSubview(self.titleLabel)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 9),
            mainStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
        
        let urlLabelTrailing = urlLabel.trailingAnchor.constraint(equalTo: textStack.trailingAnchor)
        urlLabelTrailing.priority = .defaultLow
        urlLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        let titleLabelTrailing = titleLabel.trailingAnchor.constraint(equalTo: textStack.trailingAnchor)
        titleLabelTrailing.priority = .defaultLow
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        NSLayoutConstraint.activate([
            // Force urlLabel to fill the parent width
            urlLabelTrailing,
            // Force titleLabel to fill the parent width
            titleLabelTrailing
        ])
        
        setupUIFromSettings()
    }
}

// MARK: - Configuration
extension PostCardLinkPreview {
    func configure(postCard: PostCardModel) {
        guard case .mastodon(let status) = postCard.data
        else { return }
        
        self.status = status
        
        if let urlString = postCard.formattedCardUrlStr {
            self.urlLabel.text = urlString
        } else {
            self.urlLabel.text = postCard.linkCard?.url
        }
        
        self.titleLabel.text = postCard.linkCard?.title
        
        // Display the link image if needed
        if !postCard.hideLinkImage, let imageURL = postCard.linkCard?.image {
            let scale = UIScreen.main.scale
            let transformer = SDImageResizingTransformer(size: CGSize(width: self.frame.width * scale, height: self.frame.width / 1.697 * scale), scaleMode: .aspectFill)
            self.imageView.sd_setImage(with: imageURL, placeholderImage: nil, context: [.imageTransformer: transformer])
            
            imageStack.addArrangedSubview(self.imageView)
            imageHeightConstraint = imageHeightConstraint ?? self.imageView.heightAnchor.constraint(equalToConstant: PostCardLinkPreview.largeImageHeight)
            imageHeightConstraint?.priority = .defaultHigh
            imageHeightConstraint?.isActive = true
        }
    }
    
    func onThemeChange() {
        self.mainStackView.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        self.imageView.backgroundColor = .custom.quoteTint
        self.urlLabel.textColor = .custom.actionButtons
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
                        self.createContextMenuAction("Open link", .link, isActive: false, data: .url(url), onPress: onButtonPress),
                        self.createContextMenuAction("Copy", .copy, isActive: false, data: .url(url), onPress: onButtonPress),
                        self.createContextMenuAction("Share", .share, isActive: false, data: .url(url), onPress: onButtonPress),
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
