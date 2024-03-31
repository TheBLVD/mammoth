//
//  PostCardWebview.swift
//  Mammoth
//
//  Created by Joey Despiuvas on 29/03/24
//  Copyright © 2024 The BLVD. All rights reserved.
//

import Foundation
import WebKit
import UnifiedBlurHash

class PostCardWebview: UIView {
    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
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
    private var stackHeightConstraint: NSLayoutConstraint? = nil

    private var iframeView: WKWebView = {
        let iframeConfig = WKWebViewConfiguration()
        iframeConfig.allowsInlineMediaPlayback = true
        iframeConfig.allowsPictureInPictureMediaPlayback = true
        let iframeView = WKWebView(frame: .zero, configuration: iframeConfig)
        iframeView.isOpaque = true
        return iframeView
    }()
    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isOpaque = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .custom.background
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // both of these are borrowed from PostCardVideo:
    private var pauseIcon: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = BlurredBackground(dimmed: false)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 18
        iconView.clipsToBounds = true
        
        button.insertSubview(iconView, aboveSubview: button.imageView!)
        
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),
        ])
        
        let icon = UIImageView(image: FontAwesome.image(fromChar: "\u{f04b}", color: .custom.linkText, size: 16, weight: .bold).withRenderingMode(.alwaysTemplate))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .center
        iconView.addSubview(icon)
        
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconView.centerXAnchor, constant: 1),
            icon.centerYAnchor.constraint(equalTo: iconView.centerYAnchor)
        ])

        let bg = UIView()
        bg.backgroundColor = .custom.OVRLYSoftContrast.withAlphaComponent(0.3)
        button.insertSubview(bg, belowSubview: button.imageView!)
        bg.pinEdges()
        
        return button

    }()
    private var providerTag: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(.custom.active, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        button.layer.cornerCurve = .continuous
        button.layer.cornerRadius = 7
        button.clipsToBounds = true
        button.isHidden = true
        button.accessibilityElementsHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = .init(top: 3, left: 5, bottom: 2, right: 5)
        
        let bg = BlurredBackground(dimmed: false)
        button.insertSubview(bg, belowSubview: button.titleLabel!)
        bg.pinEdges()
        
        return button
    }()
    
    func prepareForReuse() {
        self.status = nil
        
        self.isHidden = true
        
        self.iframeView.isHidden = true
        self.iframeView.stopLoading()
        
        self.imageView.isHidden = true
        self.imageView.image = nil
        self.imageView.sd_cancelCurrentImageLoad()
        self.onPress = nil
        stackHeightConstraint?.isActive = false
    }
    
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
    
    private var status: Status?
    public var onPress: PostCardButtonCallback?
}

private extension PostCardWebview {
    func setupUI() {
        self.isOpaque = true
        self.addSubview(mainStackView)
        
        mainStackView.addArrangedSubview(iframeView)
        iframeView.isHidden = true
        mainStackView.addArrangedSubview(imageView)
        imageView.isHidden = true
        imageView.addSubview(pauseIcon)
        imageView.addSubview(providerTag)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 9),
            mainStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            providerTag.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
            providerTag.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
            
            pauseIcon.topAnchor.constraint(equalTo: imageView.topAnchor),
            pauseIcon.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            pauseIcon.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            pauseIcon.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            
            iframeView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
    }
}

extension PostCardWebview {
    func configure(postCard: PostCardModel) {
        guard case .mastodon(let status) = postCard.data
        else { return }
        
        self.status = status
        
        if let iframe = postCard.webview, let image = postCard.linkCard?.image, let provider = postCard.linkCard?.providerName {
            let inverse_ratio = Double(iframe.height) / Double(iframe.width)
            stackHeightConstraint = mainStackView.heightAnchor.constraint(equalTo: mainStackView.widthAnchor, multiplier: inverse_ratio)
            stackHeightConstraint?.isActive = true
            
            // setup preview image.
            imageView.sd_setImage(with: image)
            imageView.isHidden = false
            
            // setup provider name.
            providerTag.setTitle(provider, for: .normal)
            providerTag.isHidden = false
            
            // setup webview.
            let url_request = URLRequest(url: iframe.url)
            iframeView.load(url_request)
            iframeView.isHidden = false
        }
    }
}

// MARK: - Handlers
extension PostCardWebview {
    @objc func onTapped() {
        if imageView.isHidden == false {
            imageView.isHidden = true
            iframeView.isHidden = false
        }
    }
}

// MARK: - Context menu creators
extension PostCardWebview: UIContextMenuInteractionDelegate {
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
