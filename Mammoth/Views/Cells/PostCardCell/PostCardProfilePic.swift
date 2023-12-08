//
//  PostCardProfilePic.swift
//  Mammoth
//
//  Created by Benoit Nolens on 12/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

final class PostCardProfilePic: UIButton {
    
    enum ProfilePicSize {
        case small, regular, big
        
        func width() -> CGFloat {
            switch self {
            case .small:
                return 24
            case .regular:
                return 44
            case .big:
                return 109
            }
        }
        
        func height() -> CGFloat {
            return width() // height == width
        }
        
        func cornerRadius() -> CGFloat {
            if GlobalStruct.circleProfiles {
                return width() / 2
            } else {
                switch self {
                case .small:
                    return 4
                case .regular:
                    return 8
                case .big:
                    return 23
                }
            }
        }
    }
    
    // MARK: - Properties
    
    private(set) var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = UIImage()
        imageView.backgroundColor = .custom.OVRLYSoftContrast
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private lazy var badge: BlurredBackground = {
        let view = BlurredBackground()
        view.layer.cornerRadius = 11
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private var badgeContraints: [NSLayoutConstraint] = []
    
    private var user: UserCardModel?
    private var size: ProfilePicSize = ProfilePicSize.regular
    public var onPress: PostCardButtonCallback?
    public var isContextMenuEnabled = true
        
    init(withSize profilePicSize: ProfilePicSize) {
        super.init(frame: .zero)
        self.size = profilePicSize
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        self.user = nil
        self.onPress = nil
        self.profileImageView.sd_cancelCurrentImageLoad()
        self.profileImageView.image = nil
        
        if !self.badgeContraints.isEmpty {
            self.badge.subviews.first(where: {$0.tag == 11 })?.removeFromSuperview()
            self.badge.removeFromSuperview()
        }
        
        NSLayoutConstraint.deactivate(self.badgeContraints)
        self.badgeContraints = []
    }
}

// MARK: - Setup UI
private extension PostCardProfilePic {
    func setupUI() {
        self.addSubview(profileImageView)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.profileTapped))
        self.profileImageView.addGestureRecognizer(tapGesture)
        
        self.profileImageView.layer.cornerRadius = self.size.cornerRadius()
        
        let widthImageC = profileImageView.widthAnchor.constraint(equalToConstant: self.size.width())
        widthImageC.priority = .required
        
        let heightImageC = profileImageView.heightAnchor.constraint(equalToConstant: self.size.height())
        heightImageC.priority = .required
        
        NSLayoutConstraint.activate([
            widthImageC,
            heightImageC,
            profileImageView.topAnchor.constraint(equalTo: self.topAnchor),
            profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            profileImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
        
        let interaction = UIContextMenuInteraction(delegate: self)
        self.profileImageView.addInteraction(interaction)
    }
}

// MARK: - Configuration
extension PostCardProfilePic {
    func configure(user: UserCardModel, badgeIcon: UIImage? = nil) {
        self.user = user
        
        if let profileStr = user.imageURL, let profileURL = URL(string: profileStr) {
            let scale = UIScreen.main.scale
            let thumbnailSize = CGSize(width: self.size.width() * scale, height: self.size.width() * scale)
            // If the image is already in the sd cache, it will be set immediately
            // by calling sd_setImage. If there, use it as the placeholder.
            // (prevents flashing if the image is unchanged, and reloaded in place,
            // as is done in the Settings > Appearance view)
            let placeholderView =  UIImageView()
            placeholderView.sd_setImage(with: profileURL)
            let placeholderImage = placeholderView.image ?? self.profileImageView.image
            
            self.profileImageView.sd_setImage(with: profileURL, placeholderImage: placeholderImage, context: [.imageThumbnailPixelSize: thumbnailSize])
        }
        
        if let badgeIcon {
            self.addSubview(self.badge)
            
            let iconView = UIImageView(image: badgeIcon)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.contentMode = .scaleAspectFit
            iconView.tag = 11
            iconView.tintColor = .custom.linkText
            self.badge.addSubview(iconView)
            
            badgeContraints = [
                self.badge.widthAnchor.constraint(equalToConstant: 22),
                self.badge.heightAnchor.constraint(equalToConstant: 22),
                self.badge.leftAnchor.constraint(equalTo: self.leftAnchor, constant: -6),
                self.badge.topAnchor.constraint(equalTo: self.topAnchor, constant: -6),
                
                iconView.widthAnchor.constraint(equalToConstant: 10),
                iconView.heightAnchor.constraint(equalToConstant: 10),
                iconView.centerXAnchor.constraint(equalTo: self.badge.centerXAnchor),
                iconView.centerYAnchor.constraint(equalTo: self.badge.centerYAnchor)
            ]
            
            NSLayoutConstraint.activate(badgeContraints)
        }
    }
    
    func optimisticUpdate(image: UIImage) {
        self.profileImageView.image = image
    }
    
    func onThemeChange() {
        self.profileImageView.backgroundColor = .custom.OVRLYSoftContrast
        self.profileImageView.layer.cornerRadius = self.size.cornerRadius()
    }
    
    @objc func profileTapped() {
        if let account = user?.account {
            self.onPress?(.profile, true, .account(account))
        }
    }
}

// MARK: - Context menu creators
extension PostCardProfilePic {
    
    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard isContextMenuEnabled else { return nil }
        
        if let account = self.user?.account {
            FollowManager.shared.followStatusForAccount(account, requestUpdate: .whenUncertain)
        }
        
        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil,
            actionProvider: { _ in
                self.createContextMenu()
            })
    }
    
    func createContextMenu() -> UIMenu {
        guard let account = self.user?.account else { return UIMenu() }
        let isFollowing = FollowManager.shared.followStatusForAccount(account) == .following
        
        if let user = self.user {
            if user.isSelf {
                let options = [
                    createContextMenuAction("Mention", .mention, isActive: true, data: nil),
                    
                    UIMenu(title: "", options: [.displayInline], children: [
                        createContextMenuAction("Share Link", .share, isActive: true, data: nil),
                    ])
                ]

                return UIMenu(title: "", options: [.displayInline], children: options)
            }
            
            let options = [
                
                createContextMenuAction("Mention", .mention, isActive: true, data: nil),

                ( isFollowing
                  ? createContextMenuAction("Unfollow", .follow, isActive: false, data: nil)
                  : createContextMenuAction("Follow", .follow, isActive: true, data: nil)),
                
                ( isFollowing
                    ? UIMenu(title: "Manage Lists", image: MAMenu.list.image.withRenderingMode(.alwaysTemplate), options: [], children: [
                            UIMenu(title: MAMenu.addToList.title, image: MAMenu.addToList.image, options: [], children: ListManager.shared.allLists(includeTopFriends: false).map({
                                createContextMenuAction($0.title, .addToList, isActive: true, data: PostCardButtonCallbackData.list($0.id))
                            })),
                            UIMenu(title: MAMenu.removeFromList.title, image: MAMenu.removeFromList.image, options: [], children: ListManager.shared.allLists(includeTopFriends: false).map({
                                createContextMenuAction($0.title, .removeFromList, isActive: true, data: PostCardButtonCallbackData.list($0.id))
                            })),
                            createContextMenuAction("Create new List", .createNewList, isActive: true, data: nil)
                        ])
                    : nil),
                
                (user.isMuted
                 ? createContextMenuAction("Unmute", .unmute, isActive: true, data: nil)
                 : UIMenu(title: "Mute @\(user.username)", image: MAMenu.muteOneDay.image.withRenderingMode(.alwaysTemplate), options: [], children: [
                    createContextMenuAction("Mute 1 Day", .muteOneDay, isActive: true, data: nil),
                    createContextMenuAction("Mute Forever", .muteForever, isActive: true, data: nil)
                ])),
                
                (user.isBlocked
                 ? createContextMenuAction("Unblock", .unblock, isActive: true, data: nil)
                 : createContextMenuAction("Block", .block, isActive: true, data: nil)),
                
                UIMenu(title: "", options: [.displayInline], children: [
                    createContextMenuAction("Share Link", .share, isActive: true, data: nil),
                ])
            ].compactMap({$0})

            return UIMenu(title: "", options: [.displayInline], children: options)
        }
        
        log.error("[PostCardProfilePic]: created an empty UIMenu")
        return UIMenu()
    }

    private func createContextMenuAction(_ title: String, _ buttonType: PostCardButtonType, isActive: Bool, data: PostCardButtonCallbackData?) -> UIAction {
        var color: UIColor = .black
        if GlobalStruct.overrideTheme == 1 || self.traitCollection.userInterfaceStyle == .light {
            color = .black
        } else if GlobalStruct.overrideTheme == 2 || self.traitCollection.userInterfaceStyle == .dark  {
            color = .white
        }
        
        if buttonType == .block {
            color = UIColor.systemRed
        }
        
        let action = UIAction(title: title,
                                  image: buttonType.icon(symbolConfig: postCardSymbolConfig)?.withTintColor(color),
                                  identifier: nil, attributes: buttonType == .block ? .destructive : UIMenuElement.Attributes()) { _ in
            self.onPress?(buttonType, isActive, data)
        }
        action.accessibilityLabel = title
        return action
    }
}
