//
//  SetupProfileController.swift
//  Mammoth
//
//  Created by Riley Howard on 1/18/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class SetupProfileController: UIViewController {

    @IBOutlet weak var pictureButton: UIButton!
    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    
    var displayName: String? = nil
    var photoImage: UIImage? = nil
    var compressionQuality: CGFloat = 1
    var photoPicker = PhotoPicker()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        updateDisplayNameField()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .custom.backgroundTint
        
        // Photo picker
        photoPicker.photoType = .Avatar
        photoPicker.delegate = self

        // Photo button
        pictureButton.layer.masksToBounds = true
        pictureButton.layer.cornerRadius = pictureButton.bounds.width / 2

        // Pick a random app icon to use, and scale it appropriately
        let iconName = ["Icon1-400", "Icon3-400", "Icon4-400", "Icon5-400", "Icon6-400", "IconBlack-400"].randomElement()!
        if let iconImage = UIImage(named: iconName) {
            UIGraphicsBeginImageContext(CGSizeMake(pictureButton.bounds.width, pictureButton.bounds.height))
            iconImage.draw(in: CGRectMake(0, 0, pictureButton.bounds.width, pictureButton.bounds.height))
            photoImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            pictureButton.setImage(photoImage, for: .normal)
        }

        // Camera image
        cameraImageView.image = FontAwesome.image(fromChar: "\u{f030}", size: 19.5, weight: .bold)
        cameraImageView.layer.masksToBounds = true
        cameraImageView.layer.cornerRadius = cameraImageView.bounds.width / 2
        cameraImageView.layer.backgroundColor = UIColor.custom.blurredOVRLYMed.cgColor
        
        displayNameTextField.backgroundColor = .custom.blurredOVRLYMed
        displayNameTextField.layer.borderColor = UIColor.clear.cgColor
        displayNameTextField.layer.cornerRadius = 8
        displayNameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        // Done button
        let attributedTitle = NSMutableAttributedString(attributedString: (doneButton.titleLabel?.attributedText)!)
        attributedTitle.addAttribute(.font, value: UIFont.systemFont(ofSize: 18, weight: .medium), range: NSMakeRange(0, attributedTitle.length))
        doneButton.setAttributedTitle(attributedTitle, for: .normal)
        doneButton.layer.cornerRadius = 8
        
        // Give these a chance to preload
        SetupChannelsViewModel.preload()
        SetupAccountsViewModel.preload()
        SetupMammothViewModel.preload()
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        displayNameTextField.becomeFirstResponder()
    }
    
    func updateDisplayNameField() {
        // Concatenate the display name and the email address
        let currentDisplayName = (displayName?.isEmpty ?? true) ? NSLocalizedString("d8T-wc-Ss7.placeholder", comment: "display name") : displayName!
        let attributedDisplayName = NSAttributedString(string: currentDisplayName, attributes: [NSAttributedString.Key.foregroundColor : UIColor.custom.highContrast,
             NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18, weight: .bold)])
        
        var accountName = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.account.remoteFullOriginalAcct ?? ""
        // Drop the leading @
        let suffixIndex = accountName.index(accountName.startIndex, offsetBy: 1)
        accountName = accountName.hasPrefix("@") ? String(accountName.suffix(from: suffixIndex)) : accountName
        let attributedAccountName = NSAttributedString(string: accountName, attributes: [NSAttributedString.Key.foregroundColor : UIColor.custom.softContrast,
             NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18)])
        
        let attributedDisplay = NSMutableAttributedString(attributedString: attributedDisplayName)
        attributedDisplay.append(NSAttributedString(string: " "))
        attributedDisplay.append(attributedAccountName)

        displayNameLabel.attributedText = attributedDisplay
    }
    
        
    @IBAction func photoButtonAction(_ sender: Any) {
        photoPicker.presentPicker(hostViewController: self, animated: true)
    }
    
    
    @IBAction func doneButtonAction(_ sender: Any) {
        
        if displayName == "" {
            displayName = nil
        }
        
        if displayName != nil || photoImage != nil {
            compressionQuality = 1
            updateAvatarAndUserName()
        }
        
        let vc = SetupChannelsViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func updateAvatarAndUserName() {
        if let photoImage {
            AccountsManager.shared.updateCurrentAccountAvatar(photoImage)
        }
        if let displayName {
            AccountsManager.shared.updateCurrentAccountDisplayName(displayName)
        }
    }

    
}


extension SetupProfileController: PhotoPickerDelegate {

    func didUpdateImage(image: UIImage) {
        photoImage = image
        pictureButton.setImage(photoImage, for: .normal)
    }
    
}


extension SetupProfileController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        displayName = textField.text
        updateDisplayNameField()
    }
    
}
