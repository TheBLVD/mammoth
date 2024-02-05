//
//  BlueskySignInViewController.swift
//  Mammoth
//
//  Created by Adam Shin on 7/3/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

protocol BlueskySignInViewControllerDelegate: AnyObject {
    func onSignIn(authResponse: BlueskyAPI.AuthResponse)
}

class BlueskySignInViewController: UIViewController {
    
    weak var delegate: BlueskySignInViewControllerDelegate?
    
    private let bodyView = BlueskySignInView()
    private let containerVC = ContainerViewController()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .currentContext
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func loadView() {
        view = bodyView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        add(containerVC, to: bodyView.contentContainer)
        bodyView.cancelButton.addHandler { [weak self] in
            self?.dismiss(animated: true)
        }
        
        let usernameVC = SignInUsernameVC()
        usernameVC.delegate = self
        containerVC.show(usernameVC)
    }
    
    private func signIn(identifier: String, password: String) {
        let api = BlueskyAPI(tokenSet: .init(
            accessToken: "",
            refreshToken: ""))
        
        Task {
            do {
                let response = try await api.createSession(
                    identifier: identifier,
                    password: password)
                
                dismiss(animated: true) {
                    self.delegate?.onSignIn(authResponse: response)
                }

            } catch HTTP.Error.statusCode {
                showAlert(
                    title: "Unable to sign in",
                    message: "Incorrect username or password.")
            }
        }
    }
    
}

extension BlueskySignInViewController: SignInUsernameVCDelegate {
    
    func onSelectContinue(identifier: String) {
        let passwordVC = SignInPasswordVC(identifier: identifier)
        passwordVC.delegate = self
        containerVC.show(passwordVC)
    }
    
}

extension BlueskySignInViewController: SignInPasswordVCDelegate {
    
    func onSelectContinue(identifier: String, password: String) {
        signIn(identifier: identifier, password: password)
    }
    
}

class BlueskySignInView: UIView {
    
    let cancelButton = UIButton(type: .system)
    let contentContainer = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        let stack = UIStackView()
        stack.axis = .vertical
        addSubview(stack)
        stack.pinEdges(.all, to: safeAreaLayoutGuide)
        
        let topBar = UIView()
        stack.addArrangedSubview(topBar)
        topBar.pinHeight(to: 44)
        
        topBar.addSubview(cancelButton)
        cancelButton.pinEdges(.leading, padding: 24)
        cancelButton.pinEdges(.vertical)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.label, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(
            ofSize: 18, weight: .medium)
        
        let titleContainer = UIView()
        stack.addArrangedSubview(titleContainer)
        
        let titleLabel = UILabel()
        titleLabel.text = "Sign in to Bluesky"
        titleLabel.textColor = .label
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleContainer.addSubview(titleLabel)
        titleLabel.pinEdges(.leading, padding: 24)
        titleLabel.pinEdges(.top, padding: 24)
        titleLabel.pinEdges(.bottom, padding: 16)
        
        stack.addArrangedSubview(contentContainer)
        
        onThemeChange()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func onThemeChange() {
        backgroundColor = .custom.backgroundTint
    }
    
}

