//
//  AccountSwitcherButton.swift
//  Mammoth
//
//  Created by Riley Howard on 7/7/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import SDWebImage

class AccountSwitcherButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true

        NotificationCenter.default.addObserver(self, selector: #selector(self.updateImageAndMenu), name: didSwitchCurrentAccountNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateImageAndMenu), name: didUpdateAccountAvatar, object: nil)

        updateButtonImage()
        updateButtonMenu()
        self.showsMenuAsPrimaryAction = true
        
        self.layer.borderWidth = (UIDevice.current.userInterfaceIdiom == .phone) ? 3.0 : 0.5
        self.layer.borderColor = (UIDevice.current.userInterfaceIdiom == .phone)
        ? UIColor.clear.cgColor
        : UIColor.custom.outlines.cgColor
        
        let blurredBG = BlurredBackground()
        blurredBG.translatesAutoresizingMaskIntoConstraints = false
        self.insertSubview(blurredBG, belowSubview: self.imageView!)
        blurredBG.pinEdges()
        
        self.contentEdgeInsets = (UIDevice.current.userInterfaceIdiom == .phone) ? .init(top: 3, left: 3, bottom: 3, right: 3) : .zero
        
        let buttonSize = (UIDevice.current.userInterfaceIdiom == .phone) ? 36.0 : 48.0
        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalToConstant: buttonSize),
            self.heightAnchor.constraint(equalToConstant: buttonSize)
            ])
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.height / 2.0
        self.imageView?.layer.cornerRadius = self.frame.height / 2.0 - self.layer.borderWidth
    }
    
    private func onThemeChange() {
        self.layer.borderColor = (UIDevice.current.userInterfaceIdiom == .phone)
        ? UIColor.clear.cgColor
        : UIColor.custom.outlines.cgColor
    }
    
    
    @objc func updateImageAndMenu(notification: Notification) {
        let image = notification.userInfo?["image"] as? UIImage
        let acctData = notification.userInfo?["account"] as? any AcctDataType

        DispatchQueue.main.async {
            self.updateButtonImage(updatedImage: image, updatedAcctData: acctData)
            self.updateButtonMenu()
        }
    }
    
    
    private func updateButtonImage(updatedImage: UIImage? = nil, updatedAcctData: (any AcctDataType)? = nil) {
        let currentAccount = AccountsManager.shared.currentAccount
        let isCurrentAccount = (updatedAcctData == nil) || (updatedAcctData?.uniqueID == currentAccount?.uniqueID)
        guard isCurrentAccount else {
            log.warning("ignoring new avatar image since account has changed")
            return
        }
        
        if let updatedImage {
            if isCurrentAccount {
                self.setImage(updatedImage, for: .normal)
            }
        } else {
            if let avatar = currentAccount?.avatar,
               let avatarURL = URL(string: avatar) {
                self.sd_setImage(
                    with: avatarURL,
                    for: .normal,
                    placeholderImage: nil,
                    progress: nil
                )
            } else {
                self.sd_cancelCurrentImageLoad()
            }
        }
    }
    
    
    private func updateButtonMenu() {
        self.menu = accountSwitcherMenu()
    }
    
    
    private func accountSwitcherMenu() -> UIMenu {
        let accountsMenu = UIMenu(title: "", options: [.displayInline], children: AccountsManager.shared.allAccounts.map({ item in
            let isSelected = AccountsManager.shared.currentAccount?.uniqueID == item.uniqueID
            let accountAction = UIAction(title: "@\(item.fullAcct)", image: isSelected ? FontAwesome.image(fromChar: "\u{f00c}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate) : nil, identifier: nil) { action in
                // switch account
                DispatchQueue.main.async {
                    triggerHapticImpact(style: .light)
                    let account = item
                    // Only switch if not already the current account
                    if account.uniqueID != AccountsManager.shared.currentAccount?.uniqueID {
                        AccountsManager.shared.switchToAccount(account)
                    }
                }
            }
            return accountAction
        }))
        
        let addAccount = UIAction(title: NSLocalizedString("profile.addAccount", comment: ""), image: FontAwesome.image(fromChar: "\u{2b}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { _ in
            DispatchQueue.main.async {
                triggerHapticImpact(style: .light)
                let vc = IntroViewController()
                vc.fromPlus = true
                if vc.isBeingPresented {} else {
                    getTopMostViewController()?.present(UINavigationController(rootViewController: vc), animated: true)
                }
            }
        }
        
        let accountSettings = UIAction(title: NSLocalizedString("settings.accountSettings", comment: ""), image: FontAwesome.image(fromChar: "\u{f013}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { _ in
            DispatchQueue.main.async {
                triggerHapticImpact(style: .light)
                let vc = AccountsSettingsViewController()
                if vc.isBeingPresented {} else {
                    getTopMostViewController()?.present(UINavigationController(rootViewController: vc), animated: true)
                }
            }
        }
        
        let settingsMenu = UIMenu(title: "", options: [.displayInline], children: [
            addAccount,
            AccountsManager.shared.allAccounts.count > 1 ? accountSettings : nil
        ].compactMap({$0}))
        
        if DeviceHelpers.isiOSAppOnMac() {
            var menuItems: [UIMenuElement] = accountsMenu.children
            menuItems.append(settingsMenu)
            return UIMenu(title: "", children: menuItems)
        } else {
            return UIMenu(title: "", options: [.displayInline], children: [accountsMenu, settingsMenu])
        }
    }
    
    
}

internal extension AccountSwitcherButton {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 self.onThemeChange()
            }
         }
    }
}
