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
    private var stackHeightConstraint: NSLayoutConstraint? = nil

    private var iframeView: WKWebView = {
        let iframeConfig = WKWebViewConfiguration()
        iframeConfig.allowsInlineMediaPlayback = true
        iframeConfig.applicationNameForUserAgent = "Mammoth App"
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
        
        // soft background.
        let bg = UIView()
        bg.backgroundColor = .custom.OVRLYSoftContrast.withAlphaComponent(0.3)
        imageView.addSubview(bg)
        bg.pinEdges()
        
        // play button.
        let iconView = BlurredBackground(dimmed: false)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 18
        iconView.clipsToBounds = true
        imageView.addSubview(iconView)
        
        let icon = UIImageView(image: FontAwesome.image(fromChar: "\u{f04b}", color: .custom.linkText, size: 16, weight: .bold).withRenderingMode(.alwaysTemplate))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .center
        iconView.addSubview(icon)
        
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),
            iconView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            icon.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconView.centerYAnchor)
        ])
        
        return imageView
    }()
    
    private var titleTag: UILabel = {
        let tag = UILabel()
        tag.textColor = .custom.active
        tag.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        tag.numberOfLines = 1
        tag.layer.cornerCurve = .continuous
        tag.layer.cornerRadius = 7
        tag.clipsToBounds = true
        tag.isHidden = true
        tag.accessibilityElementsHidden = true
        tag.translatesAutoresizingMaskIntoConstraints = false
        return tag
    }()
    private var providerTag: UILabel = {
        let tag = UILabel()
        tag.textColor = .custom.active
        tag.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        tag.layer.cornerCurve = .continuous
        tag.layer.cornerRadius = 7
        tag.clipsToBounds = true
        tag.isHidden = true
        tag.accessibilityElementsHidden = true
        tag.translatesAutoresizingMaskIntoConstraints = false
        return tag
    }()
    
    private var urlRequest: URLRequest? = nil
    
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
        
        let bg = BlurredBackground(dimmed: false)
        imageView.addSubview(bg)
        imageView.addSubview(providerTag)
        
        bg.pinEdges(to: providerTag, padding: -2)
        bg.layer.cornerCurve = .continuous
        bg.layer.cornerRadius = 5
        bg.clipsToBounds = true
        
        let bg2 = BlurredBackground(dimmed: false)
        imageView.addSubview(bg2)
        imageView.addSubview(titleTag)
        
        bg2.pinEdges(to: titleTag, padding: -2)
        bg2.layer.cornerCurve = .continuous
        bg2.layer.cornerRadius = 5
        bg2.clipsToBounds = true
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            providerTag.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
            providerTag.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
            
            titleTag.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            titleTag.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
            titleTag.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -5),
            
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
        
        if let iframe = postCard.webview, let linkCard = postCard.linkCard {
            var inverseRatio = Double(iframe.height) / Double(iframe.width)
            // sometimes mastodon may give us a width/height of 0.
            if !(inverseRatio.isFinite && inverseRatio.isZero) {
                // default to 16:9.
                inverseRatio = 9.0/16.0
            }
                
            stackHeightConstraint = mainStackView.heightAnchor.constraint(equalTo: mainStackView.widthAnchor, multiplier: inverseRatio)
            stackHeightConstraint?.isActive = true
            var placeholder: UIImage? = nil
            if let blurhash = iframe.blurhash {
                placeholder = postCard.decodedBlurhashes[blurhash]
            }
            // setup preview image.
            imageView.sd_setImage(with: linkCard.image, placeholderImage: placeholder)
            imageView.isHidden = false
            
            // setup video title.
            titleTag.text = linkCard.title
            titleTag.isHidden = false
            
            // setup provider name.
            providerTag.text = linkCard.providerName
            providerTag.isHidden = false
            
            // setup url request.
            urlRequest = URLRequest(url: iframe.url)
            iframeView.isHidden = true
        }
    }
}

// MARK: - Handlers
extension PostCardWebview {
    @objc func onTapped() {
        if let urlRequest = urlRequest, imageView.isHidden == false {
            // setup webview only on tap so that there's no performance penalty.
            iframeView.load(urlRequest)
            
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
