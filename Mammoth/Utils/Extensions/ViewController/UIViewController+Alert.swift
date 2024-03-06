//
//  UIViewController+Alert.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showAlert(title: String?, message: String?, callback: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: title, message: message,
            preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("generic.ok", comment: ""), style: .cancel,
            handler: { _ in callback?() }))
        
        present(alert, animated: true)
    }
    
}
