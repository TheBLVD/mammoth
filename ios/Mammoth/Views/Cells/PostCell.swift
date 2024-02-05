//
//  PostCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 26/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class PostCell: UITableViewCell {
    static let reuseIdentifier = "PostCell"
    
    var p = PostView()
    var data: Status?

    override func prepareForReuse() {
        super.prepareForReuse()
        self.data = nil
        self.p.prepareForReuse()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.initialSetup()
    }

    func initialSetup() {
        self.contentView.addSubview(self.p)
        self.p.addFillConstraints(with: self.contentView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Cell configuration for DiscoveryVC
extension PostCell {
    func configure(status: Status) {
        self.data = status
        
        self.separatorInset = .zero
        self.selectionStyle = .none
        
        if (self.traitCollection.userInterfaceStyle == .light) {
            self.contentView.backgroundColor = .custom.backgroundTint.darker(by: 2)
        } else {
            self.contentView.backgroundColor = .custom.backgroundTint.lighter(by: 4)
        }
        
        let cell = self.p
        
        cell.userName.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        cell.userTag.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
        cell.dateTime.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
        cell.postText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        cell.postText.lineSpacing = GlobalStruct.customLineSize
        cell.linkUsername.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        cell.linkUsertag.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        cell.linkPost.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        cell.linkPost.lineSpacing = GlobalStruct.customLineSize
        cell.repostView.repostText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
        cell.postText.textColor = .custom.mainTextColor
        cell.linkPost.textColor = .custom.mainTextColor2
//        cell.backgroundColor = .custom.backgroundTint
        
        cell.linkStackView.backgroundColor = .custom.quoteTint
        cell.linkStackView0.backgroundColor = .custom.quoteTint
        cell.linkStackViewHorizontal.backgroundColor = .custom.quoteTint
        
        cell.linkPost.mentionColor = .custom.baseTint
        cell.linkPost.hashtagColor = .custom.baseTint
        cell.linkPost.emailColor = .custom.baseTint
        cell.linkPost.URLColor = .custom.baseTint
        cell.cwOverlay.backgroundColor = .custom.quoteTint
        
        if let profileURL = URL(string: status.reblog?.account?.avatar ?? status.account?.avatar ?? "") {
            cell.profileIcon.sd_setImage(with: profileURL, for: .normal, completed: nil)
        }
            var rt: Bool = false
            if let _ = status.reblog {
                rt = true
            }
            
            if GlobalStruct.showCW {
                if (status.reblog?.spoilerText ?? status.spoilerText != "") && !(GlobalStruct.allCW.contains(status.id ?? "")) {
                    cell.cwOverlay.alpha = 1
                    var st = status.reblog?.spoilerText.stripHTML() ?? status.spoilerText.stripHTML()
                    if st.count > (status.reblog?.content.stripHTML().count ?? status.content.stripHTML().count) {
                        let co = (status.reblog?.content.stripHTML().count ?? status.content.stripHTML().count) - 3
                        if co < 0 {} else {
                            if co > 38 {
                                st = "\(st.prefix(co))..."
                            }
                        }
                        cell.cwOverlay.setTitle(st, for: .normal)
                    } else {
                        cell.cwOverlay.setTitle(st, for: .normal)
                    }
                } else {
                    cell.cwOverlay.alpha = 0
                    cell.cwOverlay.setTitle("Sensitive Content", for: .normal)
                }
            } else {
                cell.cwOverlay.alpha = 0
                cell.cwOverlay.setTitle("Sensitive Content", for: .normal)
            }
            
            let text = status.reblog?.content ?? status.content
            var linkStr = status.reblog?.card ?? status.card ?? nil
            if GlobalStruct.linkPreviewCards1 == false {
                linkStr = nil
            }
            cell.postText.commitUpdates {
                cell.postText.textColor = .custom.mainTextColor
                cell.linkPost.textColor = .custom.mainTextColor2
                cell.postText.text = text.stripHTML()
                cell.postText.numberOfLines = GlobalStruct.maxLines
                if GlobalStruct.maxLines != 0 {
                    cell.postText.text = (cell.postText.text ?? "").replacingOccurrences(of: "\n", with: " ")
                }
                cell.postText.mentionColor = .custom.baseTint
                cell.postText.hashtagColor = .custom.baseTint
                cell.postText.URLColor = .custom.baseTint
                cell.postText.emailColor = .custom.baseTint
                
                let userName = status.reblog?.account?.displayName ?? status.account?.displayName ?? ""
                cell.userName.text = userName
                
                let userTag = status.reblog?.account?.acct ?? status.account?.acct ?? ""
                cell.userTag.text = "@\(userTag)"
                
                let time1 = (status.reblog?.createdAt ?? status.createdAt)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = GlobalStruct.dateFormat
                var time = dateFormatter.date(from: time1)?.toStringWithRelativeTime() ?? ""
                if GlobalStruct.originalPostTimeStamp == false {
                    let time1 = status.createdAt
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = GlobalStruct.dateFormat
                    time = dateFormatter.date(from: time1)?.toStringWithRelativeTime() ?? ""
                }
                if GlobalStruct.timeStampStyle == 1 {
                    let time1 = (status.reblog?.createdAt ?? status.createdAt)
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = GlobalStruct.dateFormat
                    time = dateFormatter.date(from: time1)?.toString(dateStyle: .short, timeStyle: .short) ?? ""
                    if GlobalStruct.originalPostTimeStamp == false {
                        let time1 = (status.createdAt)
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = GlobalStruct.dateFormat
                        time = dateFormatter.date(from: time1)?.toString(dateStyle: .short, timeStyle: .short) ?? ""
                    }
                } else if GlobalStruct.timeStampStyle == 2 {
                    time = ""
                }
                cell.dateTime.text = time
            }
            
            if status.reblog?.account?.locked ?? status.account?.locked ?? false == false {
                cell.lockedBadge.alpha = 0
                cell.lockedBackground.alpha = 0
            } else {
                let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: GlobalStruct.smallerFontSize, weight: .bold)
                cell.lockedBadge.image = UIImage(systemName: "lock.circle.fill", withConfiguration: symbolConfig0)?.withTintColor(UIColor.label, renderingMode: .alwaysOriginal)
                cell.lockedBadge.alpha = 1
                cell.lockedBackground.alpha = 1
                cell.lockedBackground.backgroundColor = .custom.backgroundTint
            }
            
            // indicators
            if status.reblog?.inReplyToID ?? status.inReplyToID != nil {
                cell.indicator.alpha = 1
            } else {
                cell.indicator.alpha = 0
            }
            
            var containsPoll: Bool = false
            if let _ = status.reblog?.poll ?? status.poll {
                containsPoll = true
            }
            // images
            var alt: [String] = []
            if status.reblog?.mediaAttachments.count ?? status.mediaAttachments.count > 0 {
                let z = status.reblog?.mediaAttachments ?? status.mediaAttachments
                var isVideo: Bool = false
                let mediaItems = z[0].previewURL
                if let a = z.first?.description {
                    alt.append(a)
                }
                
                if z.first?.type == .video || z.first?.type == .gifv || z.first?.type == .audio {
                    isVideo = true
                    cell.playerController.view.isHidden = false
                    if z.first?.type == .audio {
                        cell.setupPlayButton(z.first?.url ?? "", isAudio: true)
                    } else {
                        cell.setupPlayButton(z.first?.url ?? "")
                    }
                } else {
                    cell.playerController.view.isHidden = true
                    cell.setupPlayButton("")
                }
                
                var mediaItems1: String?
                if z.count > 1 {
                    mediaItems1 = z[1].previewURL
                    if let a = z[1].description {
                        alt.append(a)
                    }
                }
                
                var mediaItems2: String?
                if z.count > 2 {
                    mediaItems2 = z[2].previewURL
                    if let a = z[2].description {
                        alt.append(a)
                    }
                }
                
                var mediaItems3: String?
                if z.count > 3 {
                    mediaItems3 = z[3].previewURL
                    if let a = z[3].description {
                        alt.append(a)
                    }
                }
                
                cell.setupImages(url1: mediaItems ?? "", url2: mediaItems1, url3: mediaItems2, url4: mediaItems3, isVideo: isVideo, altText: alt, fullImages: z)
                cell.setupConstraints(containsImages: true, quotePostCard: nil, containsRepost: rt, containsPoll: containsPoll, pollOptions: status.reblog?.poll ?? status.poll ?? nil, link: linkStr, stat: status)
            } else {
                // Check if this is a quote post
                let quotePostCard = status.quotePostCard()
                cell.setupConstraints(containsImages: false, quotePostCard: quotePostCard, containsRepost: rt, containsPoll: containsPoll, pollOptions: status.reblog?.poll ?? status.poll ?? nil, link: linkStr, stat: status)
            }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
       super.traitCollectionDidChange(previousTraitCollection)
       
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                if (self.traitCollection.userInterfaceStyle == .light) {
                    self.contentView.backgroundColor = .custom.backgroundTint.darker(by: 2)
                } else {
                    self.contentView.backgroundColor = .custom.backgroundTint.lighter(by: 4)
                }
           }
        }
   }
}
