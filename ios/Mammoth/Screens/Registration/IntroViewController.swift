//
//  IntroViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 22/12/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class IntroViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var titleText: UILabel!
    @IBOutlet weak var descriptionText: UILabel!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var miniIcon: UIImageView!
    
    @IBOutlet weak var tealBox: UIView!     // the area available to center the mammoth in
    @IBOutlet weak var orangeBox: UIView!   // vertically centered in the tealBox
    @IBOutlet weak var yellowBox: UIView!   // horizontally centered in orangeBox
                                            // note that the mammoth trunk is beyond the box
    
    var fromPlus: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .custom.backgroundTint
        
        self.setupUI()
        SignInViewController.loadInstances(isFromSignIn: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        self.navigationController?.navigationBar.standardAppearance = navApp
        self.navigationController?.navigationBar.scrollEdgeAppearance = navApp
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
        super.viewDidDisappear(animated)
    }
        
    func setupUI() {
        self.titleText.textColor = .custom.highContrast
        self.descriptionText.textColor = .custom.mediumContrast
        self.miniIcon.image = self.miniIcon.image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        self.miniIcon.tintColor = .custom.highContrast
        
        self.signUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        self.signUpButton.setTitleColor(.custom.highContrast, for: .normal)
        self.signUpButton.backgroundColor = .custom.OVRLYMedContrast
        self.signUpButton.layer.cornerRadius = 8
        self.signUpButton.addTarget(self, action: #selector(self.signUpTapped), for: .touchUpInside)

        self.signInButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        self.signInButton.setTitleColor(.custom.highContrast, for: .normal)
        self.signInButton.backgroundColor = .clear
        self.signInButton.layer.cornerRadius = 8
        self.signInButton.layer.borderColor = UIColor.custom.OVRLYMedContrast.cgColor
        self.signInButton.layer.borderWidth = 1
        self.signInButton.addTarget(self, action: #selector(self.signInTapped), for: .touchUpInside)

        if !fromPlus {
            closeButton.isHidden = true
        }

        let backItem = UIBarButtonItem()
        backItem.title = "Login"
        self.navigationItem.backBarButtonItem = backItem

        tealBox.backgroundColor = .clear
        orangeBox.backgroundColor = .clear
        yellowBox.backgroundColor = .clear
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        triggerHapticImpact(style: .light)
        dismiss(animated: true)
    }

    @objc func signUpTapped() {
        triggerHapticImpact()
        let vc = SignUpViewController()
        vc.isModalInPresentation = true
        self.navigationController?.pushViewController(vc, animated: true)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @objc func signInTapped() {
        triggerHapticImpact(style: .light)
        showMastodonSignIn()
    }
    
    private func showMastodonSignIn() {
        let vc = SignInViewController()
        vc.fromPlus = self.fromPlus
        self.navigationController?.pushViewController(vc, animated: true)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
     
    private func showBlueskySignIn() {
        let vc = BlueskySignInViewController()
        vc.delegate = self
        present(vc, animated: true)
    }
}

extension IntroViewController: BlueskySignInViewControllerDelegate {
    
    func onSignIn(authResponse: BlueskyAPI.AuthResponse) {
        Task {
            try await AccountsManager.shared
                .addExistingBlueskyAccount(authResponse: authResponse)
            
            dismiss(animated: false)
        }
    }
    
}
