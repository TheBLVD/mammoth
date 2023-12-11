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
        
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.custom.outlines.cgColor
        
        let buttonSize = (UIDevice.current.userInterfaceIdiom == .phone) ? 24.0 : 48.0
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
    }
    
    
    @objc func updateImageAndMenu(notification: Notification) {
        let image = notification.userInfo?["image"] as? UIImage
        let acctData = notification.userInfo?["account"] as? any AcctDataType

        DispatchQueue.main.async {
            self.updateButtonImage(updatedImage: image, updatedAcctData: acctData)
            self.updateButtonMenu(updatedImage: image, updatedAcctData: acctData)
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
                self.sd_setImage(with: avatarURL, for: .normal)
            } else {
                self.sd_cancelCurrentImageLoad()
            }
        }
    }
    
    
    private func updateButtonMenu(updatedImage: UIImage? = nil, updatedAcctData: (any AcctDataType)? = nil) {
        self.menu = accountSwitcherMenu(updatedImage: updatedImage, updatedAcctData: updatedAcctData)
    }
    
    
    private func accountSwitcherMenu(updatedImage: UIImage? = nil, updatedAcctData: (any AcctDataType)? = nil) -> UIMenu {
        let acctForNewImage = updatedAcctData ?? AccountsManager.shared.currentAccount
        var allActions: [UIAction] = []
        for index in 0..<AccountsManager.shared.allAccounts.count {
            let im = UIImage(systemName: "person.crop.circle")
            let imV = UIImageView()
            imV.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            imV.layer.cornerRadius = 10
            imV.layer.masksToBounds = true
            let acctData = AccountsManager.shared.allAccounts[index]
            
            // Use the passed in image for the current account if possible
            let useUpdatedImage = (acctData.uniqueID == acctForNewImage?.uniqueID) && updatedImage != nil
            if useUpdatedImage {
                imV.image = updatedImage
            } else {
                // Use the image from the cache if possible
                if let cachedImage = SDImageCache.shared.imageFromCache(forKey: acctData.avatar) {
                    imV.image = cachedImage
                }
                // Regardless, request an update
                let a = acctData.avatar
                if let ur = URL(string: a) {
                    imV.sd_setImage(with: ur)
                }
            }
            let accountAction = UIAction(title: "@\(AccountsManager.shared.allAccounts[index].fullAcct)", image: imV.image?.withRoundedCorners()?.resize(targetSize: CGSize(width: 20, height: 20)) ?? im, identifier: nil) { action in
                // switch account
                DispatchQueue.main.async {
                    let account = AccountsManager.shared.allAccounts[index]
                    // Only switch if not already the current account
                    if account.uniqueID != AccountsManager.shared.currentAccount?.uniqueID {
                        AccountsManager.shared.switchToAccount(account)
                    }
                }
            }
            accountAction.state = (AccountsManager.shared.currentAccount?.uniqueID == acctData.uniqueID) ? .on : .off
            allActions.append(accountAction)
        }
        return UIMenu(title: "", options: [], children: allActions)
    }
    
    
}
