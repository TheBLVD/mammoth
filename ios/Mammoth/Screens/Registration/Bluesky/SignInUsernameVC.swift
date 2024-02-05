//
//  SignInUsernameVC.swift
//  Mastodon
//
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

protocol SignInUsernameVCDelegate: AnyObject {
    func onSelectContinue(identifier: String)
}

class SignInUsernameVC: UIViewController {
    
    weak var delegate: SignInUsernameVCDelegate?
    
    private let bodyView = SignInUsernameView()
    
    override func loadView() { view = bodyView }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bodyView.nextButton.addHandler { [weak self] in
            self?.onContinue()
        }
        
        bodyView.textField.becomeFirstResponder()
        bodyView.textField.delegate = self
    }
    
    private func onContinue() {
        guard let id = bodyView.textField.text,
            id != ""
        else { return }
        
        let adjustedID: String
        if id.hasPrefix("@") {
            adjustedID = String(id.dropFirst())
        } else {
            adjustedID = id
        }
        
        delegate?.onSelectContinue(identifier: adjustedID)
    }
    
}

extension SignInUsernameVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onContinue()
        return false
    }
    
}

class SignInUsernameView: UIView {
    
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
        textField.placeholder = "Username or email address"
        textField.textContentType = .username
        textField.keyboardType = .emailAddress
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        
        stack.addArrangedSubview(nextButton)
        nextButton.pinHeight(to: 56)
        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
}
