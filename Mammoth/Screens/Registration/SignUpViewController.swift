//
//  SignUpViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 22/12/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class SignUpViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var username: FloatLabelTextField!
    @IBOutlet var usernameFooter: UILabel!
    
    @IBOutlet var email: FloatLabelTextField!
    @IBOutlet var emailFooter: UILabel!

    @IBOutlet var password: FloatLabelTextField!
    @IBOutlet var passwordFooter: UILabel!

    @IBOutlet var signUpButton: UIButton!

    @IBOutlet var scrollView: UIScrollView!

    var usernameText: String = ""
    var emailText: String = ""
    var passwordText: String = ""
    var validUsername: Bool = true
    var validEmail: Bool = true
    var keyboardHeight = 0.0
    
    var canSignUp: Bool = false {
        didSet {
            self.signUpButton.isUserInteractionEnabled = canSignUp
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .custom.backgroundTint
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        username.backgroundColor = .custom.OVRLYSoftContrast
        username.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        username.titleActiveTextColour = UIColor(named: "Feint Contrast") // while typing in text field
        username.titleTextColour = UIColor(named: "Feint Contrast")! // after exiting field, with text in it
        username.titleYPadding = 7.0 // move floating title down a bit

        email.backgroundColor = .custom.OVRLYSoftContrast
        email.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        email.titleActiveTextColour = UIColor(named: "Feint Contrast")
        email.titleTextColour = UIColor(named: "Feint Contrast")!
        email.titleYPadding = 7.0

        password.backgroundColor = .custom.OVRLYSoftContrast
        password.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        password.titleActiveTextColour = UIColor(named: "Feint Contrast")
        password.titleTextColour = UIColor(named: "Feint Contrast")!
        password.titleYPadding = 7.0

        // set up nav bar
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        self.navigationController?.navigationBar.standardAppearance = navApp
        self.navigationController?.navigationBar.scrollEdgeAppearance = navApp
        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }
        
        self.signUpButton.setTitleColor(UIColor(named: "Feint Contrast"), for: .normal)
        self.signUpButton.backgroundColor = UIColor(named: "OVRLY Med Contrast")
        self.signUpButton.layer.cornerRadius = 8
        self.signUpButton.addTarget(self, action: #selector(self.login), for: .touchUpInside)
        self.signUpButton.isUserInteractionEnabled = false
        
        // Have background taps end editing
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.viewBackgroundTapped))
        view.addGestureRecognizer(tap)
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    // registration flow
    
    func registerOnServer() {
        GlobalStruct.newInstance = InstanceData()
        GlobalStruct.newClient = Client(baseURL: "https://\(GlobalHostServer())")
        let request = Clients.register(
            clientName: "Mammoth",
            redirectURI: "mammoth://addNewInstance2",
            scopes: [.read, .write, .follow, .push],
            website: "https://getmammoth.app"
        )
        GlobalStruct.newClient.run(request) { (application) in
            DispatchQueue.main.async {
                if application.value == nil {} else {
                    if let application = application.value {
                        GlobalStruct.newInstance?.clientID = application.clientID
                        GlobalStruct.newInstance?.clientSecret = application.clientSecret
                        GlobalStruct.newInstance?.returnedText = GlobalHostServer()
                        GlobalStruct.newInstance?.redirect = "mammoth://addNewInstance2".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                        self.register2()
                    }
                }
            }
        }
    }
    
    func register2() {
        guard let newInstance = GlobalStruct.newInstance else {
            log.error("newInstance does not exist")
            return
        }
        var request = URLRequest(url: URL(string: "https://\(newInstance.returnedText)/oauth/token?grant_type=client_credentials&redirect_uri=\(newInstance.redirect)&client_id=\(newInstance.clientID)&client_secret=\(newInstance.clientSecret)&scope=read%20write%20follow%20push")!)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else { log.error("Error in login request: \(error!)"); return }
            guard let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    if let access1 = (json["access_token"] as? String) {
                        GlobalStruct.newInstance?.accessToken = access1
                        GlobalStruct.newClient.accessToken = access1
                        newInstance.accessToken = access1
                        self.registerAccount(newInstance)
                    }
                }
            } catch {
                log.error("error registering1 - \(error.localizedDescription)")
            }
        })
        task.resume()
    }
    
    func registerAccount(_ newInstance: InstanceData) {
        // test account stuff
        let request = Accounts.registerAccount(username: self.usernameText, email: self.emailText, password: self.passwordText, agreement: true, locale: "en")
        GlobalStruct.newClient.run(request) { (statuses) in
            if let error = statuses.error {
                DispatchQueue.main.async {
                    self.canSignUp = true
                    log.error("error registering - \(error)")
                    triggerHapticNotification(feedback: .warning)
                    
                    self.signUpButton.setTitle("Sign up", for: .normal)
                    // output what the errors are
                    
                    if "\(error)".lowercased().contains("forbidden") {
                        let alert = UIAlertController(title: "We're full!", message: "moth.social is currently at max capacity, please check back soon.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
                        }))
                        if let presenter = alert.popoverPresentationController {
                            presenter.sourceView = getTopMostViewController()?.view
                            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                        }
                        getTopMostViewController()?.present(alert, animated: true, completion: nil)
                    } else if "\(error)".lowercased().contains("username") {
                        // if username error: (ERR_TAKEN, ERR_RESERVED)
                        self.usernameFooter.text = "Username is taken"
                        self.usernameFooter.textColor = UIColor(named: "Destructive")
                        self.username.becomeFirstResponder()
                        self.adjustScrollViewForView(self.username)
                    } else {
                        // if email error: (ERR_BLOCKED, ERR_UNREACHABLE, ERR_TAKEN)
                        self.emailFooter.text = "Email address is taken"
                        self.emailFooter.textColor = UIColor(named: "Destructive")
                        self.email.becomeFirstResponder()
                        self.adjustScrollViewForView(self.email)
                    }
                }
            }
            if let stat = (statuses.value) {
                DispatchQueue.main.async {
                    self.canSignUp = false
                    log.debug("success registering")
                    triggerHapticNotification()
                                        
                    // show email prompt
                    
                    let vc = EmailVerificationViewController(emailAddress: self.email.text!, accessToken: stat.accessToken)
                    self.navigationController?.setViewControllers([vc], animated: true)
                }
            }
        }
    }
    
    // UI
    
    @objc func keyboardWillChange(notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            self.keyboardHeight = keyboardRectangle.height - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) - 4
            self.adjustScrollViewForView(nil)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        self.navigationController?.navigationBar.standardAppearance = navApp
        self.navigationController?.navigationBar.scrollEdgeAppearance = navApp
        self.navigationController?.navigationBar.compactAppearance = navApp
        if #available(iOS 15.0, *) {
            self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
        }
        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }
    }
    
    
    @objc func viewBackgroundTapped(_ sender: Any) {
        self.view.endEditing(true)
        scrollView.setContentOffset(CGPointZero, animated: true)
    }

    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }

    
    @objc func login(_ sender: Any) {
        // register the user with the available details
        if self.canSignUp {
            triggerHapticImpact()
            self.canSignUp = false
            self.signUpButton.setTitle("Signing Up...", for: .normal)
            self.registerOnServer()
        } else {
            self.canSignUp = true
            self.updateFooterText()
        }
    }
    

    @IBAction func didEndOnExit(_ textField: UITextField) {
        if textField == email {
            password.becomeFirstResponder()
            self.adjustScrollViewForView(nil)
        }
        if textField == password {
            username.becomeFirstResponder()
            self.adjustScrollViewForView(self.username)
        }
        if textField == username {
            username.resignFirstResponder()
            self.adjustScrollViewForView(self.password)
        }
    }
    
    
    @IBAction func textFieldDidChange(_ textField: UITextField) {
        if textField == username {
            var z = username.text ?? ""
            if z.first == "@" {
                z = "\(z.dropFirst())"
            }
            self.usernameText = "\(z)"
            
            let st = username.text ?? ""
            let r = st.startIndex ..< st.endIndex
            let pattern = "([\\w]+)"
            let r2 = st.range(of: pattern, options: .regularExpression)
            if (r2 == r) || (z == "") {
                self.validUsername = true
                usernameFooter.text = "Pick something fun or use your real name"
                usernameFooter.textColor = UIColor.secondaryLabel
            } else {
                self.validUsername = false
                usernameFooter.text = "Username can only contain letters, numbers, and underscores"
                usernameFooter.textColor = UIColor(named: "Destructive")
            }
        }
        if textField == email {
            self.emailText = email.text ?? ""
            if self.isValidEmail(email.text ?? "") || (self.emailText == "") {
                self.validEmail = true
                emailFooter.text = "We will send a confirmation email to this address"
                emailFooter.textColor = UIColor.secondaryLabel
            } else {
                self.validEmail = false
                emailFooter.text = "Please enter a valid email address"
                emailFooter.textColor = UIColor(named: "Destructive")
            }
        }
        if textField == password {
            self.passwordText = password.text ?? ""
            let passwordIsValid = self.passwordText.count >= 8
            passwordFooter.textColor = passwordIsValid ? .secondaryLabel : .custom.destructive
        }

        var allFieldsFilled: Bool = false
        if self.usernameText != "" && self.emailText != "" && self.passwordText != "" {
            allFieldsFilled = true
        }
        var passwordLength: Bool = false
        if self.passwordText.count >= 8 {
            passwordLength = true
        }
        if allFieldsFilled && passwordLength && self.validEmail && self.validUsername {
            // allow posting, fill in sign up button
            self.canSignUp = true            
            self.signUpButton.setTitleColor(.custom.highContrast, for: .normal)
        } else {
            // prevent posting, grey out sign up button
            self.canSignUp = false
            
            self.signUpButton.setTitleColor(.custom.feintContrast, for: .normal)
        }
    }
    
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    

    @IBAction func textFieldDidBeginEditing(_ textField: UITextField) {
        self.adjustScrollViewForView(textField)
    }

    
    func adjustScrollViewForView(_ view: UIView?) {
        // Ideally, contentOffset is zero, but can adjust as needed for the text field
        // to be visible.
        //
        // If view is nil, try to adjust based on current first responder.
        var viewToAdjustFor = view
        if viewToAdjustFor == nil {
            if username.isFirstResponder {
                viewToAdjustFor = username
            } else if email.isFirstResponder {
                viewToAdjustFor = email
            } else if password.isFirstResponder {
                viewToAdjustFor = password
            }
        }
        if viewToAdjustFor == nil {
            scrollView.setContentOffset(CGPointZero, animated: true)
        } else {
            // First see if the view would be visible if the scrollrect
            // content offset is zero; if so, use that
            let viewFrame = viewToAdjustFor!.frame
            var visibleArea = scrollView.bounds
            visibleArea.size.height -= keyboardHeight
            if keyboardHeight > 0.0 {
                visibleArea.size.height -= 70.0 // keyboard buffer area to allow for the text field footer
            }
            if CGRectContainsRect(visibleArea, viewFrame) {
                // viewFrame is already visible; no need to scroll
            } else {
                // Need to calculate how much to scroll
                let visibleHeight = CGRectGetHeight(visibleArea)
                let bottomOfView = CGRectGetMaxY(viewFrame)
                let minOffset = bottomOfView - visibleHeight
                if minOffset > 0 {
                    scrollView.setContentOffset(CGPointMake(0, minOffset), animated: true)
                } else {
                    scrollView.setContentOffset(CGPointZero, animated: true)
                }
            }
            
        }
    }
    
    
    func updateFooterText() {
        usernameFooter.text = "Pick something fun or use your real name"
        emailFooter.text = self.validEmail ?
            "We will send a confirmation email to this address" :
            "Please enter a valid email address"
    }
 
    
}
