//
//  UIViewController+Share.swift
//  Mammoth
//
//  Created by Nathan Liu on 9/18/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

protocol ShareableViewController {
    func subscribeToShareNotifications()
    func composerFromShare(notification: Notification)
}
extension ShareableViewController where Self : UIViewController {

    func subscribeToShareNotifications(){
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "composerFromShareImage"), object: nil, queue: nil) { [weak self] (notification) in
            guard let self else { return }
            self.composerFromShare(notification: notification)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "composerFromShareVideo"), object: nil, queue: nil) { [weak self] (notification) in
            guard let self else { return }
            self.composerFromShare(notification: notification)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "composerFromShareText"), object: nil, queue: nil) { [weak self] (notification) in
            guard let self else { return }
            self.composerFromShare(notification: notification)
        }
    }
    
    func composerFromShare(notification: Notification) {
        self.dismiss(animated: true)
        let vc0 = NewPostViewController()
        if notification.name.rawValue == "composerFromShareImage" {
            vc0.fromShare = true
        } else if notification.name.rawValue == "composerFromShareVideo" {
            vc0.fromShareV = true
        } else if notification.name.rawValue == "composerFromShareText" {
            vc0.fromShare2 = true
        }
        let vc = UINavigationController(rootViewController: vc0)
        vc.isModalInPresentation = true
        self.present(vc, animated: true, completion: nil)
    }
    
}
