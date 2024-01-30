//
//  UserCardActionButton.swift
//  Mammoth
//
//  Created by Benoit Nolens on 10/10/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class UserCardActionButton: UIButton {
    
    enum ButtonType {
        case block
        case unblock
        case mute
        case unmute
        case addToList
        case removeFromList
        
        var title: String {
            switch self {
            case .mute:
                return "Mute"
            case .unmute:
                return "Unmute"
            case .block:
                return "Block"
            case .unblock:
                return "Unblock"
            case .addToList:
                return "Add"
            case .removeFromList:
                return "Remove"
            }
        }
    }
    
    enum ButtonSize {
        case small
        case big
        
        var fontSize: CGFloat {
            switch self {
            case .small:
                return 13
            case .big:
                return 15
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small:
                return 6
            case .big:
                return 8
            }
        }
    }

    public var user: UserCardModel
    
    private var type: ButtonType {
        didSet {
            self.updateButton(user: user)
        }
    }
    
    public var onPress: PostCardButtonCallback?
    
    init(user: UserCardModel, type: ButtonType, size: ButtonSize = .small) {
        self.user = user
        self.type = type
        super.init(frame: .zero)
        self.setupUI(type: type, size: size)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI(type: ButtonType, size: ButtonSize) {
        self.layer.cornerRadius = size.cornerRadius
        self.clipsToBounds = true
        self.layer.cornerCurve = .continuous
        self.backgroundColor = .custom.followButtonBG
        self.setTitleColor(.custom.active, for: .normal)
        self.contentEdgeInsets = UIEdgeInsets(top: 4.5, left: 11, bottom: 3.5, right: 11)
        self.titleLabel?.font = UIFont.systemFont(ofSize: size.fontSize, weight: .semibold)
        self.setTitle(type.title, for: .normal)
        
        self.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        self.setContentCompressionResistancePriority(.required, for: .vertical)
        self.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        self.addTarget(self, action: #selector(self.onTapped), for: .touchUpInside)
        
        if #available(iOS 15.0, *) {
            self.tintColor = .custom.baseTint
        }
    }
    
    func updateButton(user: UserCardModel) {
        self.setTitle(type.title, for: .normal)
    }
}

// MARK: Actions
internal extension UserCardActionButton {
    @objc func onTapped() {
        triggerHapticImpact(style: .light)
        switch self.type {
        case .block:
            self.onPress?(.block, true, Optional.none)
            self.type = .unblock
        case .unblock:
            self.onPress?(.unblock, true, Optional.none)
            self.type = .block
        case .mute:
            self.onPress?(.muteForever, true, Optional.none)
            self.type = .unmute
        case .unmute:
            self.onPress?(.unmute, true, Optional.none)
            self.type = .mute
        case .addToList:
            self.onPress?(.addToList, true, Optional.none)
            self.type = .removeFromList
        case .removeFromList:
            self.onPress?(.removeFromList, true, Optional.none)
            self.type = .addToList
        }
    }
}
