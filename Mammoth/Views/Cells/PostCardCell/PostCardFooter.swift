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
    private let likeButton = PostFooterButton(type: .like)
    private let moreButton = PostFooterButton(type: .more)
    
    public var onButtonPress: PostCardButtonCallback? {
        didSet {
            replyButton.onPress = onButtonPress
            repostButton.onPress = onButtonPress
            likeButton.onPress = onButtonPress
            moreButton.onPress = onButtonPress
        }
    }
    
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
        self.backgroundColor = .custom.background
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
        mainStackView.addArrangedSubview(moreButton)
    }
}

// MARK: - Configuration
extension PostCardFooter {
    func configure(postCard: PostCardModel, includeMetrics: Bool = true) {
        replyButton.configure(buttonText: includeMetrics ? postCard.replyCount : nil)
        repostButton.configure(buttonText: includeMetrics ? postCard.repostCount : nil, isActive: postCard.isReposted, postCard: postCard)
        likeButton.configure(buttonText: includeMetrics ? postCard.likeCount : nil, isActive: postCard.isLiked)
        moreButton.configure(buttonText: nil, isActive: postCard.isBookmarked, postCard: postCard)
    }
    
    func onThemeChange() {
        replyButton.onThemeChange()
        repostButton.onThemeChange()
        likeButton.onThemeChange()
        moreButton.onThemeChange()
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
        stackView.backgroundColor = .custom.background
        return stackView
    }()
    
    private var icon: UIImageView = {
        let image = UIImageView()
        image.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        image.contentMode = .left
        image.isOpaque = true
        image.backgroundColor = .custom.background
        return image
    }()
    
    private var label: UILabel = {
        let label = UILabel()
        label.frame = CGRect(x: 30, y: 0, width: 30, height: 20)
        label.textColor = .custom.actionButtons
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.isOpaque = true
        label.backgroundColor = .custom.background
        return label
    }()
    
    private let symbolConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
    private let postButtonType: PostCardButtonType
    private var isActive = false
    
    public var onPress: PostCardButtonCallback?
    
    init(type: PostCardButtonType, isActive active: Bool = false) {
        postButtonType = type
        isActive = active
        
        super.init(frame: .zero)
        self.setupUI()

        if [.like, .reply].contains(where: { $0 == type }) {
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap))
            self.addGestureRecognizer(tap)
        }
        self.accessibilityLabel = String(describing: type)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.isOpaque = true
        self.backgroundColor = .custom.background
        self.addSubview(container)
        self.layoutMargins = .init(top: 0, left: 12, bottom: 0, right: 12)
        
        self.container.layoutMargins = .zero
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor),
            container.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
        ])
        
        icon.image = self.postButtonType.icon(symbolConfig: symbolConfig)?.withTintColor(.custom.actionButtons,
                             renderingMode: .alwaysOriginal)
        
        icon.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        icon.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        container.addArrangedSubview(icon)
    }
}

// MARK: - Configuration
extension PostFooterButton {
    func configure(buttonText: String?, isActive: Bool = false, postCard: PostCardModel? = nil) {
        self.isActive = isActive
        
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
            case .repost:
                self.menu = self.createRepostMenu(postCard: postCard)
                self.showsMenuAsPrimaryAction = true
            case .more:
                self.menu = self.createMoreMenu(postCard: postCard)
                self.showsMenuAsPrimaryAction = true
            default:
                self.showsMenuAsPrimaryAction = false
                break;
            }
        }
    }
    
    func onThemeChange() {
        self.label.textColor = .custom.actionButtons
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
                self.icon.image = self.postButtonType.activeIcon(symbolConfig: symbolConfig)?.withTintColor(UIColor.systemPink, renderingMode: .alwaysOriginal)
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
    private func createContextMenuAction(_ title: String, _ buttonType: PostCardButtonType, isActive: Bool) -> UIAction {
        let action = UIAction(title: title,
                              image: isActive
                              ? buttonType.activeIcon(symbolConfig: postCardSymbolConfig)?.withRenderingMode(.alwaysTemplate)
                              : buttonType.icon(symbolConfig: postCardSymbolConfig)?.withRenderingMode(.alwaysTemplate),
                                  identifier: nil) { [weak self] _ in
            guard let self else { return }
            if buttonType == .repost {
                self.handleTap()
            } else {
                self.onPress?(buttonType, isActive, nil)
            }
        }
        action.accessibilityLabel = title
        return action
    }
    
    func createRepostMenu(postCard: PostCardModel) -> UIMenu {
        let repostItem =  createContextMenuAction("Repost", .repost, isActive: false)
        let quotePostItem =  createContextMenuAction("Quote Post", .quote, isActive: false)
        return UIMenu(title: "", options: [.displayInline], children: [repostItem, quotePostItem])
    }
    
    func createMoreMenu(postCard: PostCardModel) -> UIMenu {
        let bookmarkItem = postCard.isBookmarked
        ? createContextMenuAction("Remove Bookmark", .unbookmark, isActive: true)
            : createContextMenuAction("Bookmark", .bookmark, isActive: false)
        
        let translateItem = createContextMenuAction("Translate Post", .translate, isActive: false)
        let inBrowserItem = createContextMenuAction("View in Browser", .viewInBrowser, isActive: false)
        let shareItem = createContextMenuAction("Share", .share, isActive: false)
        let pinItem = postCard.isPinned
            ? createContextMenuAction("Unpin post", .pinPost, isActive: true)
            : createContextMenuAction("Pin post", .pinPost, isActive: false)
        
        let editPostItem = createContextMenuAction("Edit Post", .editPost, isActive: false)
        let deletePostItem = createContextMenuAction("Delete Post", .deletePost, isActive: false)
        deletePostItem.attributes = .destructive
        
        let modifyMenu = UIMenu(title: "Modify Post", options: [], children: [pinItem, editPostItem, deletePostItem])
        
        return UIMenu(title: "", options: [.displayInline], children: [bookmarkItem,
                                                                       translateItem,
                                                                       inBrowserItem,
                                                                       shareItem,
                                                                       postCard.isOwn ? modifyMenu : nil
                                                                      ].compactMap({ $0 }))
    }
}
