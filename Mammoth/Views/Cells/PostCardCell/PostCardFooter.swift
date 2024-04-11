//
//  PostCardFooter.swift
//  Mammoth
//
//  Created by Benoit Nolens on 25/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

final class PostCardFooter: UIView {
    
    // MARK: - Properties
    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .equalSpacing
        stackView.spacing = 0.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: -12, bottom: 0, trailing: 0)
        return stackView
    }()
    
    private let replyButton = PostFooterButton(type: .reply)
    private let repostButton = PostFooterButton(type: .repost)
    private let quoteButton = PostFooterButton(type: .quote)
    private let likeButton = PostFooterButton(type: .like)
    private let moreButton = PostFooterButton(type: .more)
    
    public var onButtonPress: PostCardButtonCallback? {
        didSet {
            replyButton.onPress = onButtonPress
            repostButton.onPress = onButtonPress
            quoteButton.onPress = onButtonPress
            likeButton.onPress = onButtonPress
            moreButton.onPress = onButtonPress
        }
    }
    private var isPrivateMention = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI
private extension PostCardFooter {
    func setupUI() {
        self.isOpaque = true
        self.addSubview(mainStackView)
        self.layoutMargins = .init(top: 0, left: 0, bottom: 7, right: 0)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
        ])
        
        mainStackView.addArrangedSubview(likeButton)
        mainStackView.addArrangedSubview(replyButton)
        mainStackView.addArrangedSubview(repostButton)
        mainStackView.addArrangedSubview(quoteButton)
        mainStackView.addArrangedSubview(moreButton)
    }
}

// MARK: - Estimated height
extension PostCardFooter {
    static func estimatedHeight() -> CGFloat {
        return 43
    }
}

// MARK: - Configuration
extension PostCardFooter {
    func configure(postCard: PostCardModel, includeMetrics: Bool = true) {
        let shouldUpdateTheme = self.isPrivateMention != postCard.isPrivateMention
        self.isPrivateMention = postCard.isPrivateMention
        
        replyButton.configure(buttonText: includeMetrics ? postCard.replyCount : nil, postCard: postCard)
        repostButton.configure(buttonText: includeMetrics ? postCard.repostCount : nil, isActive: postCard.isReposted, postCard: postCard)
        quoteButton.configure(buttonText: nil, isActive: false, postCard: postCard)
        likeButton.configure(buttonText: includeMetrics ? postCard.likeCount : nil, isActive: postCard.isLiked, postCard: postCard)
        moreButton.configure(buttonText: nil, isActive: postCard.isBookmarked, postCard: postCard)
        
        if shouldUpdateTheme {
            self.onThemeChange()
        }
    }
    
    func onThemeChange() {
        if self.isPrivateMention {
            self.backgroundColor = .custom.OVRLYSoftContrast
            mainStackView.backgroundColor = .custom.OVRLYSoftContrast
        } else {
            self.backgroundColor = .custom.background
            mainStackView.backgroundColor = .custom.background
        }
        
        replyButton.onThemeChange()
        repostButton.onThemeChange()
        quoteButton.onThemeChange()
        likeButton.onThemeChange()
        moreButton.onThemeChange()
    }
}

extension PostCardFooter {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let pointForTargetView = self.likeButton.convert(point, from: self)
        if CGRectContainsPoint(self.likeButton.bounds, pointForTargetView) {
            return self.likeButton
        }
        
        return super.hitTest(point, with: event)
    }
}

// MARK: Appearance changes
internal extension PostCardFooter {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 if self.isPrivateMention {
                     self.backgroundColor = .custom.OVRLYSoftContrast
                 } else {
                     self.backgroundColor = .custom.background
                 }
             }
         }
    }
}





// MARK: - PostFooterButton
fileprivate class PostFooterButton: UIButton {
    
    private var container: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 3.0
        stackView.isBaselineRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isOpaque = true
        return stackView
    }()
    
    private var icon: UIImageView = {
        let image = UIImageView()
        image.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        image.contentMode = .left
        image.isOpaque = true
        return image
    }()
    
    private var label: UILabel = {
        let label = UILabel()
        label.frame = CGRect(x: 30, y: 0, width: 30, height: 20)
        label.textColor = .custom.actionButtons
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.isOpaque = true
        return label
    }()
    
    private let symbolConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
    private let postButtonType: PostCardButtonType
    private var isActive = false
    private var isPrivateMention = false
    
    public var onPress: PostCardButtonCallback?
    
    init(type: PostCardButtonType, isActive active: Bool = false) {
        postButtonType = type
        isActive = active
        
        super.init(frame: .zero)
        self.setupUI()

        if [.like, .reply, .repost, .quote].contains(where: { $0 == type }) {
            self.addTarget(self, action: #selector(self.handleTap), for: .touchUpInside)
        }
        
        self.accessibilityLabel = String(describing: type)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.isOpaque = true
        self.isUserInteractionEnabled = true
        self.addSubview(container)
        self.layoutMargins = .init(top: 0, left: 12, bottom: 0, right: 12)
        
        self.container.layoutMargins = .zero
        self.container.isUserInteractionEnabled = false
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor),
            container.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor)
        ])
        
        icon.image = self.postButtonType.icon(symbolConfig: symbolConfig)?.withTintColor(.custom.actionButtons,
                             renderingMode: .alwaysOriginal)
        
        icon.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        icon.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        container.addArrangedSubview(icon)
        
        NSLayoutConstraint.activate([
            icon.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
}

// MARK: - Configuration
extension PostFooterButton {
    func configure(buttonText: String?, isActive: Bool = false, postCard: PostCardModel? = nil) {
        self.isActive = isActive
        
        let shouldChangeTheme = self.isPrivateMention != (postCard?.isPrivateMention ?? false)
        self.isPrivateMention = postCard?.isPrivateMention ?? false
        
        if let buttonText = buttonText {
            label.text = buttonText
            
            if !container.arrangedSubviews.contains(label) {
                label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                container.addArrangedSubview(label)
            }
        } else {
            if container.arrangedSubviews.contains(label) {
                container.removeArrangedSubview(label)
                label.removeFromSuperview()
            }
        }

        if !isActive {
            self.icon.image = self.postButtonType.icon(symbolConfig: symbolConfig)?.withTintColor(self.postButtonType.tintColor(isActive: isActive), renderingMode: .alwaysOriginal)
            
        } else {
            self.icon.image = self.postButtonType.activeIcon(symbolConfig: symbolConfig)?.withTintColor(self.postButtonType.tintColor(isActive: isActive), renderingMode: .alwaysOriginal)
        }
        
        // Create context menus
        if let postCard = postCard {
            switch (self.postButtonType) {
            case .more:
                DispatchQueue.main.async { [weak self] in
                    self?.menu = self?.createMoreMenu(postCard: postCard)
                }
                self.showsMenuAsPrimaryAction = true
            default:
                self.showsMenuAsPrimaryAction = false
                break;
            }
        }
        
        if shouldChangeTheme {
            self.onThemeChange()
        }
    }
    
    func onThemeChange() {
        self.label.textColor = .custom.actionButtons
        let backgroundColor: UIColor = self.isPrivateMention ? .custom.OVRLYSoftContrast : .custom.background
        self.backgroundColor = backgroundColor
        container.backgroundColor = backgroundColor
        label.textColor = .custom.actionButtons
        label.backgroundColor = backgroundColor
        icon.backgroundColor = backgroundColor
        if !isActive {
            self.icon.image = self.postButtonType.icon(symbolConfig: symbolConfig)?.withTintColor(self.postButtonType.tintColor(isActive: isActive), renderingMode: .alwaysOriginal)
            
        } else {
            self.icon.image = self.postButtonType.activeIcon(symbolConfig: symbolConfig)?.withTintColor(self.postButtonType.tintColor(isActive: isActive), renderingMode: .alwaysOriginal)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        onThemeChange()
    }

}

// MARK: - Handlers
private extension PostFooterButton {
    @objc func handleTap() {
        triggerHapticImpact(style: .light)
        
        self.isActive = !self.isActive
        
        switch(self.postButtonType) {
        case .like:
            // Update button appearance
            if !self.isActive {
                self.icon.image = self.postButtonType.icon(symbolConfig: symbolConfig)?.withTintColor(.custom.actionButtons, renderingMode: .alwaysOriginal)
            } else {
                self.icon.image = self.postButtonType.activeIcon(symbolConfig: symbolConfig)?.withTintColor(self.postButtonType.tintColor(isActive: true), renderingMode: .alwaysOriginal)
            }
            
        case .repost:
            // Update button appearance
            if !self.isActive {
                self.icon.image = self.postButtonType.icon(symbolConfig: symbolConfig)?.withTintColor(.custom.actionButtons, renderingMode: .alwaysOriginal)
            } else {
                self.icon.image = self.postButtonType.activeIcon(symbolConfig: symbolConfig)?.withTintColor(self.postButtonType.tintColor(isActive: true), renderingMode: .alwaysOriginal)
            }
            
        default:
            break
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.onPress?(self.postButtonType, !self.isActive, nil)
        }
    }
}

// MARK: - Context menu creators
private extension PostFooterButton {
    private func createContextMenuAction(_ title: String, _ buttonType: PostCardButtonType, isActive: Bool, attributes:  UIMenuElement.Attributes = []) -> UIAction {
        
        var color: UIColor = .black
        if GlobalStruct.overrideTheme == 1 || self.traitCollection.userInterfaceStyle == .light {
            color = .black
        } else if GlobalStruct.overrideTheme == 2 || self.traitCollection.userInterfaceStyle == .dark  {
            color = .white
        }
        
        if attributes.contains(.destructive) {
            color = UIColor.systemRed
        }
        
        let action = UIAction(title: title,
                              image: isActive
                              ? buttonType.activeIcon(symbolConfig: postCardSymbolConfig)?.withTintColor(color).withRenderingMode(.alwaysTemplate)
                              : buttonType.icon(symbolConfig: postCardSymbolConfig)?.withTintColor(color).withRenderingMode(.alwaysTemplate),
                                  identifier: nil) { [weak self] _ in
            guard let self else { return }
            if buttonType == .repost {
                self.handleTap()
            } else {
                self.onPress?(buttonType, isActive, nil)
            }
        }
        
        action.attributes = attributes
        action.accessibilityLabel = title
        return action
    }
    
    func createMoreMenu(postCard: PostCardModel) -> UIMenu {
        let bookmarkItem = postCard.isBookmarked
        ? createContextMenuAction(NSLocalizedString("post.bookmark.undo", comment: ""), .unbookmark, isActive: true)
            : createContextMenuAction(NSLocalizedString("post.bookmark", comment: ""), .bookmark, isActive: false)
        
        let translateItem = createContextMenuAction(NSLocalizedString("post.translatePost", comment: ""), .translate, isActive: false)
        let inBrowserItem = createContextMenuAction(NSLocalizedString("post.viewInBrowser", comment: ""), .viewInBrowser, isActive: false)
        let report = createContextMenuAction(NSLocalizedString("post.report", comment: ""), .reportPost, isActive: false, attributes: .destructive)
        
        let shareItem = createContextMenuAction(NSLocalizedString("post.sharePost", comment: ""), .share, isActive: false)
        let pinItem = postCard.isPinned
            ? createContextMenuAction(NSLocalizedString("post.pin.undo", comment: ""), .pinPost, isActive: true)
            : createContextMenuAction(NSLocalizedString("post.pin", comment: ""), .pinPost, isActive: false)
        
        let editPostItem = createContextMenuAction(NSLocalizedString("post.edit", comment: ""), .editPost, isActive: false)
        let deletePostItem = createContextMenuAction(NSLocalizedString("post.delete", comment: ""), .deletePost, isActive: false, attributes: .destructive)
        
        let modifyMenu = UIMenu(title: NSLocalizedString("post.modify", comment: ""), options: [], children: [pinItem, editPostItem, deletePostItem])
        
        return UIMenu(title: "", options: [.displayInline], children: [bookmarkItem,
                                                                       translateItem,
                                                                       inBrowserItem,
                                                                       !postCard.isOwn ? report : nil,
                                                                       shareItem,
                                                                       postCard.isOwn ? modifyMenu : nil
                                                                      ].compactMap({ $0 }))
    }
}
