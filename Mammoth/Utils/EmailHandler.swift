//
//  EmailHandler.swift
//  Mammoth
//
//  Created by Riley Howard on 10/11/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import MessageUI

class EmailHandler: NSObject {
    
    static let shared = EmailHandler()
    
    // Send the email as described. If using a third party email,
    // convert the first attachement to text, and append the first
    // 1,800 characters of it.
    public func sendEmail(destination: String, subject: String, body: String, attachmentData: [Data]? = nil, attachmentDataTitles: [String]? = nil) {
        let mailDestination = destination
        let mailSubject = subject
        
        var mailBody = body
        if MFMailComposeViewController.canSendMail() {
            let mailMessage = MFMailComposeViewController()
            mailMessage.mailComposeDelegate = self
            mailMessage.setToRecipients([mailDestination])
            mailMessage.setSubject(mailSubject)
            mailMessage.setMessageBody(mailBody, isHTML: false)
            if let attachmentData {
                for (index, data) in attachmentData.enumerated() {
                    mailMessage.addAttachmentData(data, mimeType: "text/plain", fileName: attachmentDataTitles![index])
                }
            }
            UIApplication.topViewController()?.present(mailMessage, animated: true)
        } else {
            // Apple Mail not set up; use a more generic URL setup
            
            // Append the file contents to the body. The mailto URL is limited to about 2,000
            // characters, so we limit the log file to the last 1,800 (triming back to the first
            // line break before that).
            if let firstAttachmentData = attachmentData?.first {
                let MaxChars = 1800
                var attachmentContents = String(decoding: firstAttachmentData, as: UTF8.self)
                if attachmentContents.count > MaxChars {
                    attachmentContents = String(attachmentContents.suffix(MaxChars))
                    //  Go back to the previous newline
                    if let indexOfFirstNL = attachmentContents.range(of: "\n")?.upperBound {
                        attachmentContents = String(attachmentContents.suffix(from: indexOfFirstNL))
                    }
                }
                mailBody += "\n\n\n" + attachmentContents
            }
            
            let destinationEncoded = mailDestination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let subjectEncoded = mailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let bodyEncoded = mailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

            openThirdPartyMailURLs(destinationEncoded: destinationEncoded, subjectEncoded: subjectEncoded, bodyEncoded: bodyEncoded)
        }
    }


    static var emailAppURLIndex = 0
    fileprivate func openThirdPartyMailURLs(destinationEncoded: String, subjectEncoded: String, bodyEncoded: String) {
        // After lots of searching and digging, it appears there's a bug where calling
        // UIApplication.shared.canOpenURL() to check often fails, even when the correct
        // app is installed.
        //
        // However, just calling UIApplication.shared.openURL() directly *does* work.
        
        let gmailPrefix = "googlegmail://co?to=\(destinationEncoded)&subject=\(subjectEncoded)&body=\(bodyEncoded)"
        let outlookPrefix = "ms-outlook://compose?to=\(destinationEncoded)&subject=\(subjectEncoded)&body=\(bodyEncoded)"
        let yahooMailPrefix = "ymail://mail/compose?to=\(destinationEncoded)&subject=\(subjectEncoded)&body=\(bodyEncoded)"
        let sparkPrefix = "readdle-spark://compose?recipient=\(destinationEncoded)&subject=\(subjectEncoded)&body=\(bodyEncoded)"
        let protonPrefix = "protonmail://mailto:\(destinationEncoded)?subject=\(subjectEncoded)&body=\(bodyEncoded)"
        let prefixesToTry = [gmailPrefix, outlookPrefix, yahooMailPrefix, sparkPrefix, protonPrefix]
        
        EmailHandler.emailAppURLIndex = 0
        tryNextAppPrefix()
        
        func tryNextAppPrefix() {
            Task {
                if EmailHandler.emailAppURLIndex < prefixesToTry.count {
                    log.debug("trying app URL index \(EmailHandler.emailAppURLIndex)")
                    let prefixToTry = prefixesToTry[EmailHandler.emailAppURLIndex]
                    if let urlToTry = URL(string: prefixToTry) {
                        DispatchQueue.main.sync {
                            UIApplication.shared.open(urlToTry) {success in
                                if success {
                                    log.debug("success emailing with app at index \(EmailHandler.emailAppURLIndex)")
                                } else {
                                    log.debug("failed emailing with app at index \(EmailHandler.emailAppURLIndex)")
                                    EmailHandler.emailAppURLIndex += 1
                                    tryNextAppPrefix()
                                }
                            }
                        }
                    } else {
                        log.error("invalid email app url at index \(EmailHandler.emailAppURLIndex)")
                        EmailHandler.emailAppURLIndex += 1
                        tryNextAppPrefix()
                    }
                } else {
                    log.error("done iterating through email apps; none successful")
                }
            }
        }
    }
}

extension EmailHandler: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
