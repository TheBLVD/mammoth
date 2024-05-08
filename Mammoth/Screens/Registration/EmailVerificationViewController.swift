//
//  EmailVerificationViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 22/12/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class EmailVerificationViewController: UIViewController {
    
    var timer: Timer?
    var tempAccessToken: String = ""
    var emailAddress: String = ""
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var resendEmailButton: UIButton!
    @IBOutlet weak var envelopeImageView: UIImageView!

    convenience init(emailAddress: String, accessToken: String) {
        self.init()
        self.emailAddress = emailAddress
        self.tempAccessToken = accessToken
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        
        // Substitute the user's email address for %@
        instructionsLabel.text = instructionsLabel.text?.replacingOccurrences(of: "%@", with: emailAddress)
        // Color the email address "Medium Contrast"
        let instructions = NSMutableAttributedString(attributedString: instructionsLabel.attributedText!)
        let emailRange = instructionsLabel.text!.range(of: emailAddress)
        let emailNSRange = NSRange(emailRange!, in: instructionsLabel.text!)
        instructions.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.custom.mediumContrast, range: emailNSRange)
        instructionsLabel.attributedText = instructions
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .custom.backgroundTint
        
        self.setupUI()
        self.startPolling()
    }
    
    deinit {
        self.timer?.invalidate()
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
    
    func startPolling() {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] _ in
                guard let self else { return }                
                // Use GlobalStruct.newInstance
                self.newInstanceLogged()
            })
        }
    }
    
    func setupUI() {
        envelopeImageView.image = FontAwesome.image(fromChar: "\u{f0e0}", size: 28, weight: .bold).withRenderingMode(.alwaysTemplate)
        let title = NSAttributedString(string: (resendEmailButton.titleLabel?.text)!, attributes: [NSAttributedString.Key.foregroundColor: UIColor.custom.mediumContrast, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .semibold)])
        resendEmailButton.setAttributedTitle(title, for: .normal)
    }
    
    @IBAction func resendEmail(_ sender: Any) {
        log.debug("resending email")
        resendEmailConfirmation()
        let alert = UIAlertController(title: "Email Sent", message: "A confirmation email has been resent.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.ok", comment: ""), style: .default , handler:{ (UIAlertAction) in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    private func resendEmailConfirmation() {

        //        Task {
        //            do {
        //                try await EmailService.confirmation(accessToken: tempAccessToken)
        //            } catch {
        //                log.error("error resending confirmation email: \(error)")
        //            }
        //        }

        
        // This doesn't appear to work; it's returning a 404
        
        let urlStr = "https://moth.social/api/v1/emails/confirmation"
        let url: URL = URL(string: urlStr)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(tempAccessToken)", forHTTPHeaderField: "Authorization")
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let task = session.dataTask(with: request) { (data, response, err) in
            log.debug("email request sent")
            if let err {
                log.error("email resend request err - \(err)")
            }
            if let response {
                log.debug("email resend request response - \(response)")
            }
        }
        task.resume()
    }
    
    
    @objc func newInstanceLogged() {
        self.timer?.invalidate()
        if let newInstance = GlobalStruct.newInstance {
            let client = Client(
                baseURL: "https://\(newInstance.returnedText)",
                accessToken: newInstance.accessToken
            )
            newInstance.accessToken = self.tempAccessToken
            AccountsManager.shared.addNewMastodonAccount(instanceData: newInstance, client: client) { [weak self] error in
                guard let self else { return }
                
                guard error == nil else {
                    // Just reschedule the timer...
                    log.error("error adding new Mastodon account: \(String(describing: error))")
                    self.startPolling()
                    return
                }
                
                // Channels don't work if logged in account is not copied to moth.social.
                // To fix this, we ping `v4/timelines/for_you/me` after login.
                // This will trigger the right backend event to copy the user's account to moth.social.
                Task {
                    if case .Mastodon = AccountsManager.shared.currentAccount?.acctType {
                        do {
                            let _ = try await TimelineService.forYouMe(remoteFullOriginalAcct: AccountsManager.shared.currentAccount!.remoteFullOriginalAcct)
                        } catch {}
                    }
                    
                    await MainActor.run {
                        // The new account is valid; proceed to allow setting a display name/photo
                        let vc = SetupProfileController()
                        vc.isModalInPresentation = true
                        self.navigationController?.setViewControllers([vc], animated: true)
                    }
                }
            }
        } else {
            // Just reschedule the timer...
            self.startPolling()
        }
    }

}

