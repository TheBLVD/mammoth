//
//  FollowButton.swift
//  Mammoth
//
//  Created by Benoit Nolens on 22/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

fileprivate extension FollowManager.FollowStatus {
    var title: String {
        switch self {
        case .notFollowing, .unknown, .unfollowRequested:
            return NSLocalizedString("profile.follow", comment: "")
        case .following, .followRequested:
            return NSLocalizedString("profile.unfollow", comment: "")
        case .followAwaitingApproval:
            return NSLocalizedString("profile.awaitingApproval", comment: "")
        case .inProgress:
            return NSLocalizedString("profile.follow", comment: "")
        }
    }
}

final class FollowButton: UIButton {
    
    enum ButtonType {
        case small
        case big
        
        var fontSize: CGFloat {
            switch self {
            case .small:
                return 13
            case .big:
                return 16
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

    public var user: UserCardModel? {
        didSet {
            if let user {
                self.updateButton(user: user)
            }
        }
    }
    
    init(user: UserCardModel, type: ButtonType = .small) {
        self.user = user
        super.init(frame: .zero)
        self.setupUI(type: type)
    }
    
    init() {
        self.user = nil
        super.init(frame: .zero)
        self.setupUI(type: .small)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI(type: ButtonType) {
        self.layer.cornerRadius = type.cornerRadius
        self.layer.cornerCurve = .continuous
        self.layer.isOpaque = true
        self.isOpaque = true
        self.contentEdgeInsets = UIEdgeInsets(top: 4.5, left: 11, bottom: 3.5, right: 11)
        self.titleLabel?.font = UIFont.systemFont(ofSize: type.fontSize, weight: .semibold)
        self.setTitle(self.user?.followStatus?.title, for: .normal)
        self.titleLabel?.isOpaque = true
        
        self.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        self.setContentCompressionResistancePriority(.required, for: .vertical)
        self.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        self.addTarget(self, action: #selector(self.onTapped), for: .touchUpInside)
        onThemeChange()
    }
    
    func onThemeChange() {
        self.layer.backgroundColor = UIColor.custom.followButtonBG.cgColor
        self.backgroundColor = .custom.followButtonBG
        self.setTitleColor(.custom.active, for: .normal)
        self.titleLabel?.backgroundColor = .custom.followButtonBG
        if #available(iOS 15.0, *) {
            self.tintColor = .custom.baseTint
        }
    }
    
    func updateButton(user: UserCardModel) {
        self.setTitle(user.followStatus?.title, for: .normal)
    }
}

// MARK: Actions
internal extension FollowButton {
    @objc func onTapped() {
        switch user?.followStatus {
        case .notFollowing, .unknown, .unfollowRequested, .inProgress:
            self.user?.forceFollowButtonDisplay = true
            self.followTapped()
        case .following, .followRequested, .followAwaitingApproval:
            self.unfollowTapped()
        default:
            log.error("unexpected case")
            break
        }
    }
    
    private func followTapped() {
        triggerHapticImpact(style: .light)
        
        if let user = self.user, let account = self.user?.account {
            self.setTitle(FollowManager.FollowStatus.followRequested.title, for: .normal)
            Task {
                do {
                    let _ = try await FollowManager.shared.followAccountAsync(account)
                    
                    await MainActor.run {
                        user.syncFollowStatus()
                        self.updateButton(user: user)
                    }
                    
                    AnalyticsManager.track(event: .follow)
                    
                    if user.followStatus != .followRequested {
                        await MainActor.run {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadTableSuggestions"), object: nil)
                        }
                    }
                } catch let error {
                    log.error("Follow error: \(error)")
                    self.setTitle(FollowManager.FollowStatus.notFollowing.title, for: .normal)
                }
            }
        }
    }
    
    private func unfollowTapped() {
        if let user = self.user, let account = self.user?.account {
            self.setTitle(FollowManager.FollowStatus.unfollowRequested.title, for: .normal)
            Task {
                do {
                    let _ = try await FollowManager.shared.unfollowAccountAsync(account)
                    
                    await MainActor.run {
                        user.syncFollowStatus()
                        self.updateButton(user: user)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadTableSuggestions"), object: nil)
                    }
                    
                    AnalyticsManager.track(event: .unfollow)

                } catch let error {
                    log.error("Unfollow error: \(error)")
                    self.setTitle(FollowManager.FollowStatus.following.title, for: .normal)
                }
            }
        }
    }
}

// MARK: Appearance changes
internal extension FollowButton {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 self.onThemeChange()
             }
         }
    }
}
