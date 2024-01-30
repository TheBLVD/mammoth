//
//  SignInPasswordVC.swift
//  Mammoth
//
//  Created by Adam Shin on 7/3/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

@available(iOS 16.0, *)
let appPasswordRegex = /^[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}$/

protocol SignInPasswordVCDelegate: AnyObject {
    func onSelectContinue(identifier: String, password: String)
}

class SignInPasswordVC: UIViewController {
    
    weak var delegate: SignInPasswordVCDelegate?
    
    private let bodyView = SignInPasswordView()
    
    private let identifier: String
    
    init(identifier: String) {
        self.identifier = identifier
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func loadView() { view = bodyView }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bodyView.nextButton.addHandler { [weak self] in
            self?.onContinue()
        }
        
        bodyView.textField.becomeFirstResponder()
        bodyView.textField.delegate = self
    }
    
    @objc private func onContinue() {
        guard let password = bodyView.textField.text, password != ""
        else { return }
        
        if #available(iOS 16.0, *),
           !password.contains(appPasswordRegex) {
            
            showPasswordWarningAlert(
                cancel: {
                    self.bodyView.textField.text = ""
                },
                submit: {
                    self.delegate?.onSelectContinue(
                        identifier: self.identifier,
                        password: password)
                })
                
        } else {
            delegate?.onSelectContinue(
                identifier: identifier,
                password: password)
        }
    }
    
    private func showPasswordWarningAlert(
        cancel: @escaping () -> Void,
        submit: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: "You've entered your main account password.",
            message: "For security, it's recommended to use an app password instead.",
            preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(
            title: "Use App Password",
            style: .default,
            handler: { _ in cancel() }))
        alert.addAction(UIAlertAction(
            title: "Continue Anyway",
            style: .destructive,
            handler: { _ in submit() }))
        
        present(alert, animated: true)
    }
    
}

extension SignInPasswordVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onContinue()
        return false
    }
    
}

class SignInPasswordView: UIView {
    
    let textField = RoundedTextField()
    let nextButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        addSubview(stack)
        stack.pinEdges([.horizontal], padding: 24)
        stack.pinEdges(.top)
        
        stack.addArrangedSubview(textField)
        textField.pinHeight(to: 56)
        textField.backgroundColor = .secondarySystemBackground
        textField.textColor = .label
        textField.font = .systemFont(ofSize: 18, weight: .medium)
        textField.placeholder = "Password"
        textField.textContentType = .password
        textField.isSecureTextEntry = true
        
        stack.addArrangedSubview(nextButton)
        nextButton.pinHeight(to: 56)
        nextButton.setTitle("Sign in", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        
        let warningLabel = UILabel()
        stack.addArrangedSubview(warningLabel)
        stack.setCustomSpacing(24, after: nextButton)
        warningLabel.numberOfLines = 0
        warningLabel.font = .systemFont(ofSize: 16, weight: .regular)
        warningLabel.text = ""
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
}
