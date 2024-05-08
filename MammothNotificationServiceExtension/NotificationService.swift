//
//  NotificationService.swift
//  MammothNotificationServiceExtension
//
//  Created by Shihab Mehboob on 06/12/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UserNotifications
import Intents

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var receivedRequest: UNNotificationRequest!
    var bestAttemptContent: UNMutableNotificationContent?

    
    // Iterate through the various accounts until one of the states
    // can decrypt the content, and provide a valid PushNotification
    private func decrypt(attemptContent: UNMutableNotificationContent) -> PushNotification? {
        let allStates = PushNotificationReceiver.getAllStates()
        log.debug("\(processID()) " + "iterating through \(allStates.count) states/accounts to decrypt")
        // See which push notification state can decrypt this
        for state in allStates {
            if let content = try? attemptContent.decrypt(state: state) {
                return content
            }
        }
        
        return nil
    }

    
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        log.debug("objectID: \(ObjectIdentifier(self))")
        log.debug("\(processID()) " + "did receive push notification: \(request.identifier)")
        self.receivedRequest = request
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        if let bestAttemptContent0 = bestAttemptContent {
            var bestAttemptContent = bestAttemptContent0
            
            // Handle customer.io notifications
            if let fromCustomerIO = bestAttemptContent.userInfo["CIO-Delivery-ID"] as? String, !fromCustomerIO.isEmpty {
                contentHandler(bestAttemptContent)
                return
            }
            
            // This will iterate through the various accounts until one
            // of them is able to decrypt the content.
            log.debug("\(processID()) " + "attempting to decrypt: \(request.identifier)")
            if let content = decrypt(attemptContent: bestAttemptContent) {
                log.debug("\(processID()) " + "able to decrypt: \(request.identifier)")
                // shared with the main app's AppDelegate
                DispatchQueue.main.async {
                    let userDefaults = UserDefaults(suiteName: "group.com.theblvd.mammoth.wormhole")
                    userDefaults?.set("\(content.notificationId)", forKey: "notificationId")
                }
                
                bestAttemptContent.userInfo["id"] = content.notificationId
                bestAttemptContent.title = content.title.replacingOccurrences(of: "favourited your post", with: "liked").replacingOccurrences(of: "favorited your post", with: "liked").replacingOccurrences(of: "boosted your post", with: "reposted").replacingOccurrences(of: "is now following you", with: "followed you").replacingOccurrences(of: "You were mentioned by ", with: "")
                bestAttemptContent.body = content.body.replacingOccurrences(of: "&#39;", with: "'").replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">").replacingOccurrences(of: "&amp;", with: "&").replacingOccurrences(of: "&quot;", with: "\"")
                
                bestAttemptContent.sound = UNNotificationSound.init(named: UNNotificationSoundName(rawValue: "soundPush.wav"))
                
                // remove custom emoji shortcodes
                bestAttemptContent.title =  bestAttemptContent.title.stripCustomEmojiShortcodes()
                
                var theType: String = ""
                if content.notificationType == .status {
                    theType = "status"
                } else if content.notificationType == .reblog {
                    theType = "reblog"
                } else if content.notificationType == .favourite {
                    theType = "favourite"
                } else if content.notificationType == .mention {
                    theType = "mention"
                } else if content.notificationType == .poll {
                    theType = "poll"
                } else {
                    theType = "follow"
                }
                bestAttemptContent.threadIdentifier = theType

                if #available(iOS 15.0, *) {
                    var personNameComponents = PersonNameComponents()
                    personNameComponents.nickname = content.title
                    
                    if let data = NSData(contentsOf: content.icon) as? Data {
                        let avatar = INImage(imageData: data)
                        
                        let senderPerson = INPerson(
                            personHandle: INPersonHandle(value: "1233211234", type: .unknown),
                            nameComponents: personNameComponents,
                            displayName: bestAttemptContent.title,
                            image: avatar,
                            contactIdentifier: nil,
                            customIdentifier: nil,
                            isMe: false,
                            suggestionType: .none
                        )
                        
                        let intent = INSendMessageIntent(
                            recipients: nil,
                            outgoingMessageType: .outgoingMessageText,
                            content: "Test",
                            speakableGroupName: INSpeakableString(spokenPhrase: "Sender Name"),
                            conversationIdentifier: "sampleConversationIdentifier",
                            serviceName: nil,
                            sender: senderPerson,
                            attachments: nil
                        )
                        
                        intent.setImage(avatar, forParameterNamed: \.sender)
                        
                        let interaction = INInteraction(intent: intent, response: nil)
                        interaction.direction = .incoming
                        
                        interaction.donate(completion: nil)
                        
                        do {
                            bestAttemptContent = try bestAttemptContent.updating(from: intent) as! UNMutableNotificationContent
                        } catch {
                            log.error("\(processID()) " + "unable to update \(request.identifier) from intent: \(error)")
                        }
                    } else {
                        log.error("\(processID()) " + "no content.icon data")
                    }
                } else {
                    if let data = NSData(contentsOf: content.icon) as? Data {
                        let path = NSTemporaryDirectory() + "attachment"
                        _ = FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
                        do {
                            let file = URL(fileURLWithPath: path)
                            let attachment = try UNNotificationAttachment(identifier: "attachment", url: file, options:[UNNotificationAttachmentOptionsTypeHintKey : "public.jpeg"])
                            bestAttemptContent.attachments = [attachment]
                        } catch {
                            log.error("\(processID()) " + "error trying to get attachment:\(error)")
                        }
                    }
                }
                log.debug("\(processID()) " + "push notification \(request.identifier) type: \(bestAttemptContent.threadIdentifier)")
            } else {
                log.debug("\(processID()) " + "unable to decrypt: \(request.identifier)")
                bestAttemptContent.body = bestAttemptContent.body + " (unable to decode)"
            }
            log.debug("\(processID()) " + "calling contentHandler: \(request.identifier)")
            contentHandler(bestAttemptContent)
        } else {
            log.error("\(processID()) " + "missing bestAttemptContent")
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        log.error("\(processID()) " + "push notification timer expired")
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            log.debug("\(processID()) " + "one last try at decrypting")
            if let content = decrypt(attemptContent: bestAttemptContent) {
                log.debug("\(processID()) " + "successfully decrypted")
                bestAttemptContent.userInfo["id"] = content.notificationId
                bestAttemptContent.title = content.title
                bestAttemptContent.body = content.body
                
                bestAttemptContent.sound = UNNotificationSound.init(named: UNNotificationSoundName(rawValue: "soundPush.wav"))
            } else {
                bestAttemptContent.body = bestAttemptContent.body + " (expired)"
            }
            contentHandler(bestAttemptContent)
        }
    }

}
