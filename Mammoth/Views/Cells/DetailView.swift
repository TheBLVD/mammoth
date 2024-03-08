//
//  DetailView.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 27/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Vision
import NaturalLanguage
import Photos
import AVKit
import LinkPresentation
import Kingfisher

class DetailView: UIView, SKPhotoBrowserDelegate, UIActivityItemSource, UIContextMenuInteractionDelegate {
    
    var pipView = UIPiPView()
    var profileIcon = UIButton()
    var lockedBadge = UIImageView()
    var lockedBackground = UIView()
    var userTag = UILabel()
    var userName = UILabel()
    var postText = ActiveLabel()
    var followsYou = UIButton()
    // a post with a URL/link in it
    let linkStackViewHorizontal = UIStackView()
    let linkUsername = UILabel()
    let linkUsertag = UILabel()
    let linkDate = UILabel()
    let linkPost = ActiveLabel()       // this is the body of the above
    let linkStackView0 = UIStackView()
    let linkStackView = UIStackView()
    var id: String = ""
    var lpImage = UIImageView()
    // actual quote post view; can be either...
    //  (A) full post content (Plain), or
    //  (B) more muted/shorter content (Muted)
    var quotePostHostView: QuotePostHostView?
    // poll
    var pollStack = UIStackView()
    // constraints
    var conLP1: NSLayoutConstraint? // large image cards
    var conLP2: NSLayoutConstraint? // smaller image cards
    
    // Valid constraint sets are:
    //      - must have one of either quotePostConstraints - OR - nonQuoteConstraints
    //      - linkStackViewContraints (required)
    //      - can add pollConstraints if this has a poll
    var quotePostConstraints: [NSLayoutConstraint] = []
    var nonQuoteConstraints: [NSLayoutConstraint] = []
    var linkStackViewContraints: [NSLayoutConstraint] = []
    var nonLinkStackViewContraints: [NSLayoutConstraint] = []
    var linkStackViewWithPollContraints: [NSLayoutConstraint] = []
    var nonLinkStackViewWithPollContraints: [NSLayoutConstraint] = []
    var pollConstraints: [NSLayoutConstraint] = []

    // other
    var topThreadLine = UIView()
    var fromFeed: Bool = false
    var tmpIndex: Int = 0
    
    var isQuotedPostPreview: Bool = false
    
    func prepareForReuse() {
        self.topThreadLine.alpha = 0
        self.lpImage.image = UIImage()
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    init(isQuotedPostPreview: Bool) {
        super.init(frame: CGRectZero)
        self.isQuotedPostPreview = isQuotedPostPreview
        self.commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        if !isQuotedPostPreview {
            self.quotePostHostView = QuotePostHostView()
        }
        
        self.accessibilityIdentifier = "DetailView"
        self.pipView.accessibilityIdentifier = "DetailCellPipView"
        pipView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(pipView)
        
        // thread lines
        
        topThreadLine.translatesAutoresizingMaskIntoConstraints = false
        topThreadLine.backgroundColor = .custom.quoteTint
        topThreadLine.alpha = 0
        pipView.addSubview(topThreadLine)
        
        profileIcon.translatesAutoresizingMaskIntoConstraints = false
        profileIcon.backgroundColor = .custom.quoteTint
        profileIcon.contentMode = .scaleAspectFill
        profileIcon.layer.masksToBounds = true
        profileIcon.imageView?.contentMode = .scaleAspectFill
        profileIcon.contentMode = .scaleAspectFill
        profileIcon.accessibilityLabel = NSLocalizedString("navigator.profile", comment: "")
        pipView.addSubview(profileIcon)
        
        let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .title2).pointSize + GlobalStruct.customTextSize, weight: .bold)
        lockedBadge.translatesAutoresizingMaskIntoConstraints = false
        lockedBadge.backgroundColor = .clear
        lockedBadge.image = UIImage(systemName: "checkmark.seal.fill", withConfiguration: symbolConfig0)?.withTintColor(UIColor.label, renderingMode: .alwaysOriginal)
        lockedBadge.alpha = 0
        pipView.addSubview(lockedBadge)
        lockedBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        lockedBackground.translatesAutoresizingMaskIntoConstraints = false
        lockedBackground.backgroundColor = .custom.backgroundTint
        lockedBackground.layer.cornerRadius = (UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 6) / 2
        lockedBackground.alpha = 0
        pipView.insertSubview(lockedBackground, belowSubview: lockedBadge)
        
        userName.translatesAutoresizingMaskIntoConstraints = false
        userName.textAlignment = .left
        userName.textColor = UIColor.label
        userName.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        pipView.addSubview(userName)
        
        userTag.translatesAutoresizingMaskIntoConstraints = false
        userTag.textAlignment = .left
        userTag.textColor = UIColor.secondaryLabel
        userTag.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
        pipView.addSubview(userTag)
        
        followsYou.translatesAutoresizingMaskIntoConstraints = false
        followsYou.setTitle("Follows You", for: .normal)
        followsYou.setTitleColor(UIColor.label.withAlphaComponent(0.5), for: .normal)
        followsYou.titleLabel?.textAlignment = .center
        followsYou.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular)
        followsYou.backgroundColor = .custom.quoteTint
        followsYou.layer.cornerRadius = 8
        followsYou.layer.cornerCurve = .continuous
        followsYou.contentEdgeInsets = UIEdgeInsets(top: 2, left: 9, bottom: 2, right: 9)
        followsYou.alpha = 0
        self.addSubview(followsYou)
        followsYou.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        postText.translatesAutoresizingMaskIntoConstraints = false
        postText.accessibilityIdentifier = "postText"
        postText.commitUpdates {
            postText.numberOfLines = 0
            postText.textColor = .custom.mainTextColor
            postText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
            postText.enabledTypes = [.mention, .hashtag, .url, .email]
            postText.mentionColor = .custom.baseTint
            postText.hashtagColor = .custom.baseTint
            postText.URLColor = .custom.baseTint
            postText.emailColor = .custom.baseTint
            postText.lineSpacing = GlobalStruct.customLineSize
            postText.urlMaximumLength = 30
        }
        pipView.addSubview(postText)
        
        // create stack for quote
        
        linkUsername.text = ""
        linkUsername.textColor = .label
        linkUsername.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        linkUsername.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        linkUsername.numberOfLines = 1
        
        linkUsertag.text = ""
        linkUsertag.textColor = .secondaryLabel
        linkUsertag.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        linkUsertag.sizeToFit()
        linkUsertag.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        linkDate.text = ""
        linkDate.textColor = .secondaryLabel
        linkDate.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
        linkDate.textAlignment = .right
        linkDate.sizeToFit()
        linkDate.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let spacer2 = UIView()
        spacer2.isUserInteractionEnabled = false
        spacer2.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        spacer2.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        
        linkStackViewHorizontal.translatesAutoresizingMaskIntoConstraints = false
        linkStackViewHorizontal.addArrangedSubview(linkUsername)
        linkStackViewHorizontal.addArrangedSubview(linkUsertag)
        linkStackViewHorizontal.addArrangedSubview(spacer2)
        linkStackViewHorizontal.addArrangedSubview(linkDate)
        linkStackViewHorizontal.axis = .horizontal
        linkStackViewHorizontal.distribution = .fill
        linkStackViewHorizontal.spacing = 5
        linkStackViewHorizontal.isUserInteractionEnabled = true
        linkStackViewHorizontal.backgroundColor = .custom.quoteTint
        linkStackViewHorizontal.layer.masksToBounds = true
        linkStackViewHorizontal.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        pipView.addSubview(linkStackViewHorizontal)
        
        linkPost.text = ""
        linkPost.textColor = .secondaryLabel
        linkPost.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        linkPost.numberOfLines = 0
        linkPost.enabledTypes = [.mention, .hashtag, .url, .email]
        linkPost.mentionColor = .custom.baseTint
        linkPost.hashtagColor = .custom.baseTint
        linkPost.emailColor = .custom.baseTint
        linkPost.URLColor = .custom.baseTint
        linkPost.lineSpacing = GlobalStruct.customLineSize
        linkPost.urlMaximumLength = 30
        
        linkUsername.setContentCompressionResistancePriority(.required, for: .vertical)
        
        linkStackView0.accessibilityIdentifier = "linkStackView0"
        linkStackView0.addArrangedSubview(linkStackViewHorizontal)
        linkStackView0.addArrangedSubview(linkPost)
        
        if let quotePostHostView = self.quotePostHostView {
            linkStackView0.addArrangedSubview(quotePostHostView)
        }
        
        linkStackView0.axis = .vertical
        linkStackView0.distribution = .fill
        linkStackView0.spacing = 1
        linkStackView0.isUserInteractionEnabled = true
        linkStackView0.backgroundColor = .custom.quoteTint
        linkStackView0.isLayoutMarginsRelativeArrangement = true
        linkStackView0.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        linkStackView0.layer.masksToBounds = true
        linkStackView0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        pipView.addSubview(linkStackView0)
        
        lpImage.image = UIImage()
        lpImage.translatesAutoresizingMaskIntoConstraints = false
        conLP1 = self.lpImage.heightAnchor.constraint(equalToConstant: 170)
        conLP2 = self.lpImage.heightAnchor.constraint(equalToConstant: 65)
        lpImage.backgroundColor = .custom.quoteTint
        lpImage.contentMode = .scaleAspectFill
        pipView.addSubview(lpImage)
        conLP1?.isActive = true
        
        linkStackView.translatesAutoresizingMaskIntoConstraints = false
        linkStackView.addArrangedSubview(lpImage)
        linkStackView.addArrangedSubview(linkStackView0)
        linkStackView.axis = .vertical
        linkStackView.distribution = .fill
        linkStackView.spacing = 0
        linkStackView.isUserInteractionEnabled = true
        linkStackView.backgroundColor = .custom.quoteTint
        linkStackView.accessibilityIdentifier = "quote stack"
        linkStackView.layer.borderWidth = 0.4
        linkStackView.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        linkStackView.layer.masksToBounds = true
        linkStackView.layer.cornerRadius = 10
        linkStackView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
        pipView.addSubview(linkStackView)
        
        let qGesture = UITapGestureRecognizer(target: self, action: #selector(self.quoteTapped))
        linkStackView.addGestureRecognizer(qGesture)
        
        let interaction = UIContextMenuInteraction(delegate: self)
        linkStackView.addInteraction(interaction)
        
        let viewsDict = [
            "pipView" : pipView,
            "profileIcon" : profileIcon,
            "lockedBackground" : lockedBackground,
            "lockedBadge" : lockedBadge,
            "userName" : userName,
            "userTag" : userTag,
            "followsYou" : followsYou,
            "postText" : postText,
            "linkStackView" : linkStackView,
            "topThreadLine" : topThreadLine,
        ] as [String : Any]
        let metricsDict = [
            "fontSize" : UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 6,
            "padCo" : CGFloat(GlobalStruct.padColWidth - 92)
        ]
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-2-[pipView]-2-|", options: [], metrics: nil, views: viewsDict))
        
#if targetEnvironment(macCatalyst)
        let horizontalPadding = self.isQuotedPostPreview ? 2 : 20
        
        if GlobalStruct.singleColumn {
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(horizontalPadding)-[pipView]-\(horizontalPadding)-|", options: [], metrics: nil, views: viewsDict))
            self.linkStackViewContraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(horizontalPadding)-[linkStackView(padCo)]-(>=\(horizontalPadding)-|", options: [], metrics: metricsDict, views: viewsDict))

        } else {
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[pipView]-0-|", options: [], metrics: nil, views: viewsDict))
             self.linkStackViewContraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(horizontalPadding)-[linkStackView]-\(horizontalPadding)-|", options: [], metrics: nil, views: viewsDict))

        }
#elseif !targetEnvironment(macCatalyst)
        let horizontalPadding = self.isQuotedPostPreview ? 2 : 20
        
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && self.window?.traitCollection.horizontalSizeClass != .compact {
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(horizontalPadding)-[pipView]-\(horizontalPadding)-|", options: [], metrics: nil, views: viewsDict))
             self.linkStackViewContraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(horizontalPadding)-[linkStackView(padCo)]-(>=\(horizontalPadding))-|", options: [], metrics: metricsDict, views: viewsDict))
            
        } else {
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[pipView]-0-|", options: [], metrics: nil, views: viewsDict))
             self.linkStackViewContraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(horizontalPadding)-[linkStackView]-\(horizontalPadding)-|", options: [], metrics: nil, views: viewsDict))
        }
#endif
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-40-[topThreadLine(2)]", options: [], metrics: nil, views: viewsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[topThreadLine(18)]", options: [], metrics: nil, views: viewsDict))
        
        
        // Only one of the constraint sets below should be active at any time
        

        // Used for self.isQuotedPostPreview
        //
        // horizontal
        self.quotePostConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[profileIcon(18)]-6-[userName]-6-[userTag]", options: [], metrics: metricsDict, views: viewsDict))
        self.quotePostConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[postText]-(>=4)-|", options: [], metrics: nil, views: viewsDict))
        // vertical down to the postText
        self.quotePostConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[profileIcon(18)]", options: [], metrics: nil, views: viewsDict))
        self.quotePostConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[userName]", options: [], metrics: nil, views: viewsDict))
        self.quotePostConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[userTag]", options: [], metrics: nil, views: viewsDict))
        self.quotePostConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[userTag]-(>=6)-[postText]", options: [], metrics: nil, views: viewsDict))

        // Used for NOT self.isQuotedPostPreview
        //
        // horizontal
        self.nonQuoteConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[profileIcon(50)]-12-[userName]", options: [], metrics: metricsDict, views: viewsDict))
        self.nonQuoteConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[userName]-9-[lockedBackground(fontSize)]", options: [], metrics: metricsDict, views: viewsDict))
        self.nonQuoteConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[userName]-5-[lockedBadge]-(>=16)-|", options: [], metrics: nil, views: viewsDict))
        self.nonQuoteConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[profileIcon]-12-[userTag]-6-[followsYou]-(>=16)-|", options: [], metrics: nil, views: viewsDict))
        self.nonQuoteConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[postText]-20-|", options: [], metrics: nil, views: viewsDict))
        // vertical down to the postText
        self.nonQuoteConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[profileIcon(50)]", options: [], metrics: nil, views: viewsDict))
        self.nonQuoteConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-20-[lockedBackground(fontSize)]", options: [], metrics: metricsDict, views: viewsDict))
        self.nonQuoteConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[lockedBadge]", options: [], metrics: nil, views: viewsDict))
        self.nonQuoteConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userName]-0-[userTag]-(>=4)-[postText]", options: [], metrics: nil, views: viewsDict))
        self.nonQuoteConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[profileIcon]-(>=6)-[postText]", options: [], metrics: nil, views: viewsDict))
        self.nonQuoteConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[userName]-(-1.4)-[followsYou]", options: [], metrics: nil, views: viewsDict))
        
        // Used when link is present
        self.linkStackViewContraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[postText]-10-[linkStackView]|", options: [], metrics: nil, views: viewsDict))
        // Used when no link is present
        self.nonLinkStackViewContraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[postText]|", options: [], metrics: nil, views: viewsDict))
        
    }
                                        
    override func updateConstraints() {

        let viewsDict = [
            "postText" : postText,
            "linkStackView" : linkStackView,
            "pollStack" : pollStack
        ] as [String : Any]
        
        // Create the poll constraints if needed.
        // These are created lazily as pollStack is not
        let containsPoll = !pollStack.isHidden && pollStack.superview != nil
        if containsPoll && self.pollConstraints.isEmpty{
            if self.pollConstraints.isEmpty {
                self.pollConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[pollStack]-20-|", options: [], metrics: nil, views: viewsDict))
                
                // Used when link is present and a poll
                self.linkStackViewWithPollContraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[postText]-10-[linkStackView]-10-[pollStack]-14-|", options: [], metrics: nil, views: viewsDict))
                // Used when no link is present and a poll
                self.nonLinkStackViewWithPollContraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[postText]-10-[pollStack]-14-|", options: [], metrics: nil, views: viewsDict))
            }
        }
        
        // Enable one of the other sets of constraints
        if self.isQuotedPostPreview {
            NSLayoutConstraint.deactivate(self.nonQuoteConstraints)
            NSLayoutConstraint.activate(self.quotePostConstraints)
        } else {
            NSLayoutConstraint.deactivate(self.quotePostConstraints)
            NSLayoutConstraint.activate(self.nonQuoteConstraints)
        }
        
        // 4 Scenerios are possible. Deactivate the other 3 when selecting:
        // NonLinkStack with a Poll
        // LinkStack with a Poll
        // NonLinkStack
        // LinkStack
        if containsPoll {
            // There is a Poll present
            NSLayoutConstraint.activate(self.pollConstraints)
            if linkStackView.isHidden {
                NSLayoutConstraint.deactivate(self.linkStackViewContraints)
                NSLayoutConstraint.deactivate(self.nonLinkStackViewWithPollContraints)
                NSLayoutConstraint.deactivate(self.nonLinkStackViewContraints)
                // Showing nonLinkStack with polls
                NSLayoutConstraint.activate((self.nonLinkStackViewWithPollContraints))
            } else {
                NSLayoutConstraint.deactivate(self.nonLinkStackViewContraints)
                NSLayoutConstraint.deactivate(self.nonLinkStackViewWithPollContraints)
                NSLayoutConstraint.deactivate(self.nonLinkStackViewWithPollContraints)
                // Showing linkStack with polls
                NSLayoutConstraint.activate((self.linkStackViewWithPollContraints))
            }
        } else {
            // There is no poll present
            NSLayoutConstraint.deactivate(self.pollConstraints)
            if linkStackView.isHidden {
                NSLayoutConstraint.deactivate(self.linkStackViewContraints)
                NSLayoutConstraint.deactivate(self.linkStackViewWithPollContraints)
                NSLayoutConstraint.deactivate(self.nonLinkStackViewWithPollContraints)
                // Showing nonLinkStack without polls
                NSLayoutConstraint.activate((self.nonLinkStackViewContraints))
            } else {
                NSLayoutConstraint.deactivate(self.nonLinkStackViewContraints)
                NSLayoutConstraint.deactivate(self.nonLinkStackViewWithPollContraints)
                NSLayoutConstraint.deactivate(self.linkStackViewWithPollContraints)
                // Showing linkStack without polls
                NSLayoutConstraint.activate((self.linkStackViewContraints))
            }
        }

        super.updateConstraints()
    }
    

    public func updateFromStat(_ stat: Status?) {
                
        if let profileURL = URL(string: stat?.reblog?.account?.avatar ?? stat?.account?.avatar ?? "") {
            self.profileIcon.sd_setImage(with: profileURL, for: .normal, completed: nil)
        }

        var linkStr = stat?.reblog?.card ?? stat?.card ?? nil
        if GlobalStruct.linkPreviewCards2 == false {
            linkStr = nil
        }
        self.postText.commitUpdates {
            if self.isQuotedPostPreview {
                self.postText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular)
            } else {
                self.postText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
            }
            
            self.postText.textColor = .custom.mainTextColor
            self.linkPost.textColor = .custom.mainTextColor2
            if isQuotedPostPreview {
                let text = stat?.reblog?.content ?? stat?.content
                self.postText.text = text?.stripHTML()
            }
            self.postText.numberOfLines = 0
            self.postText.mentionColor = .custom.baseTint
            self.postText.hashtagColor = .custom.baseTint
            self.postText.URLColor = .custom.baseTint
            self.postText.emailColor = .custom.baseTint
            self.postText.sizeToFit()
            
            let userName = stat?.reblog?.account?.displayName ?? stat?.account?.displayName ?? ""
            self.userName.text = userName
            
            self.userName.sizeToFit()
            
            let userTag = stat?.reblog?.account?.acct ?? stat?.account?.acct ?? ""
            self.userTag.text = "@\(userTag)"
            self.userTag.sizeToFit()
        }
        
        if stat?.reblog?.account?.locked ?? stat?.account?.locked ?? false == false {
            self.lockedBadge.alpha = 0
            self.lockedBackground.alpha = 0
        } else {
            let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: GlobalStruct.smallerFontSize, weight: .bold)
            self.lockedBadge.image = UIImage(systemName: "lock.circle.fill", withConfiguration: symbolConfig0)?.withTintColor(UIColor.label, renderingMode: .alwaysOriginal)
            self.lockedBadge.alpha = 1
            self.lockedBackground.alpha = 1
            self.lockedBackground.backgroundColor = .custom.backgroundTint
        }
        
        var containsPoll: Bool = false
        if let _ = stat?.reblog?.poll ?? stat?.poll {
            containsPoll = true
        }
        let quotePostCard = stat?.quotePostCard()
        self.updateContent(quotePostCard: quotePostCard, containsPoll: containsPoll, pollOptions: stat?.reblog?.poll ?? stat?.poll ?? nil, link: linkStr, stat: stat)
        
        (self.superview as? UITableViewCell)?.separatorInset = .zero
        let bgColorView = UIView()
        bgColorView.backgroundColor = .clear
        (self.superview as? UITableViewCell)?.selectedBackgroundView = bgColorView
//        self.setNeedsLayout()
    }
    
    var hasImage: Bool = false
    func containsImage() {
        hasImage = true
    }
    
    func updateContent(quotePostCard: Card?, containsPoll: Bool, pollOptions: Poll?, link: Card? = nil, stat: Status? = nil) {
        var pollOptions = pollOptions
        
        if GlobalStruct.circleProfiles {
            if self.isQuotedPostPreview {
                profileIcon.layer.cornerRadius = 9

            } else {
                profileIcon.layer.cornerRadius = 25
            }
        } else {
            profileIcon.layer.cornerRadius = 8
        }
        
        // remove spaces within posts
        if (postText.text ?? "").suffix(3) == "\n\n " {
            postText.text = String(String(String((postText.text ?? "").dropLast()).dropLast()).dropLast())
        }
        if (postText.text ?? "").suffix(2) == "\n\n" {
            postText.text = String(String((postText.text ?? "").dropLast()).dropLast())
        }
        
        if stat?.reblog?.emojis.isEmpty ?? stat?.emojis.isEmpty ?? false {

        } else {
            let attributedString = NSMutableAttributedString(string: "\(stat?.reblog?.content.stripHTML() ?? stat?.content.stripHTML() ?? "")", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.custom.mainTextColor.withAlphaComponent(0.85)])
            if let z = stat?.reblog?.emojis ?? stat?.emojis {
                let _ = z.map({
                    let textAttachment = NSTextAttachment()
                    textAttachment.kf.setImage(with: $0.url, attributedView: self.postText, completionHandler:  { r in
                        self.postText.setNeedsDisplay()
                    })
                    textAttachment.bounds = CGRect(x:0, y: Int(-2), width: Int(self.postText.font.lineHeight - 6), height: Int(self.postText.font.lineHeight - 6))
                    let attrStringWithImage = NSAttributedString(attachment: textAttachment)
                    while attributedString.mutableString.contains(":\($0.shortcode):") {
                        let range: NSRange = (attributedString.mutableString as NSString).range(of: ":\($0.shortcode):")
                        attributedString.replaceCharacters(in: range, with: attrStringWithImage)
                    }
                })
#if !targetEnvironment(macCatalyst)
                self.postText.attributedText = attributedString
#endif
            }
        }

        if stat?.reblog?.account?.emojis.isEmpty ?? stat?.account?.emojis.isEmpty ?? false {

        } else {
            let attributedString = NSMutableAttributedString(string: "\(stat?.reblog?.account?.displayName ?? stat?.account?.displayName ?? "")", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.custom.mainTextColor.withAlphaComponent(0.85)])
            if let z = stat?.reblog?.account?.emojis ?? stat?.account?.emojis {
                let _ = z.map({
                    let textAttachment = NSTextAttachment()
                    textAttachment.kf.setImage(with: $0.url, attributedView: self.userName, completionHandler:  { r in
                        self.userName.setNeedsDisplay()
                    })
                    textAttachment.bounds = CGRect(x:0, y: Int(-2), width: Int(self.userName.font.lineHeight - 6), height: Int(self.userName.font.lineHeight - 6))
                    let attrStringWithImage = NSAttributedString(attachment: textAttachment)
                    while attributedString.mutableString.contains(":\($0.shortcode):") {
                        let range: NSRange = (attributedString.mutableString as NSString).range(of: ":\($0.shortcode):")
                        attributedString.replaceCharacters(in: range, with: attrStringWithImage)
                    }
                })
#if !targetEnvironment(macCatalyst)
                self.userName.attributedText = attributedString
#endif
            }
        }
        
        self.userName.textColor = UIColor.label
        
        if containsPoll {
            // poll
            if GlobalStruct.votedOnPolls[self.pollId] != nil {
                if pollOptions?.voted ?? false && (pollOptions?.id ?? "" == self.pollId) {
                    pollOptions = GlobalStruct.votedOnPolls[self.pollId]
                }
            }
            
            self.pollId = pollOptions?.id ?? ""
            
            for x in pollStack.arrangedSubviews {
                pollStack.removeArrangedSubview(x)
            }
            for x in pollStack.subviews {
                x.removeFromSuperview()
            }
            pollStack.removeFromSuperview()

            if let pOp = pollOptions?.options {
                var totalVotes = 0
                _ = pOp.map({ x in
                    totalVotes += x.votesCount ?? 0
                })

                // add poll end or ended time

                var tVote = "\(totalVotes.withCommas()) votes"
                if totalVotes == 1 {
                    tVote = "\(totalVotes.withCommas()) vote"
                }

                let date1 = pollOptions?.expiresAt ?? ""
                var tText = "ends in"
                var tText2 = ""
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = GlobalStruct.dateFormat
                let date = dateFormatter.date(from: date1)
                
                var diff = getMinutesDifferenceFromTwoDates(start: Date(), end: date ?? Date())
                var mVote = "\(diff) minutes"
                if diff == 1 {
                    mVote = "\(diff) minute"
                }
                if diff > 60 {
                    diff = diff/60
                    mVote = "\(diff) hours"
                    if diff == 1 {
                        mVote = "\(diff) hour"
                    }
                } else if diff < 0 {
                    tText = "ended"
                    tText2 = "ago"
                    diff = diff * -1
                    mVote = "\(diff) minutes"
                    if diff == 1 {
                        mVote = "\(diff) minute"
                    }
                    if diff > 60 {
                        diff = diff/60
                        mVote = "\(diff) hours"
                        if diff == 1 {
                            mVote = "\(diff) hour"
                        }
                        if diff > 24 {
                            diff = diff/24
                            mVote = "\(diff) days"
                            if diff == 1 {
                                mVote = "\(diff) day"
                            }
                            if diff > 30 {
                                diff = diff/30
                                mVote = "\(diff) months"
                                if diff == 1 {
                                    mVote = "\(diff) month"
                                }
                            }
                        }
                    }
                }
                
                for (c,x) in pOp.enumerated() {
                    let barText = UIButton()
                    barText.frame = CGRect(x: 0, y: 0, width: self.bounds.width - 80, height: 40)
                    barText.backgroundColor = .clear
                    barText.setTitle("  \(x.title)  ", for: .normal)
                    barText.setTitleColor(.label, for: .normal)
                    barText.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
                    barText.titleLabel?.textAlignment = .left
                    barText.contentHorizontalAlignment = .left
                    barText.layer.cornerRadius = 6
                    barText.layer.masksToBounds = true
                    barText.tag = c
                    if tText != "ended" {
                        let bGesture = UITapGestureRecognizer(target: self, action: #selector(self.pollOptionsTap(_:)))
                        barText.addGestureRecognizer(bGesture)
                    }
                    barText.titleLabel?.lineBreakMode = .byTruncatingTail

                    let underlay = UIView()
                    underlay.layer.cornerRadius = 6
                    underlay.layer.masksToBounds = true
                    if (pollOptions?.voted ?? false) || (tText == "ended") || ((pollOptions?.voted ?? false) && GlobalStruct.votedOnPolls[self.pollId] != nil) {
                        if let own = pollOptions?.ownVotes, own.contains(c) {
                            underlay.backgroundColor = .custom.baseTint
                        } else {
                            underlay.backgroundColor = .custom.baseTint.withAlphaComponent(0.5)
                        }
                        if totalVotes == 0 {
                            underlay.frame = CGRect(x: 0, y: 0, width: 0, height: 32)
                        } else {
                            let diff = (Double(x.votesCount ?? 0)/Double(totalVotes))
                            var wid9 = UIScreen.main.bounds.size.width
                            if GlobalStruct.isCompact || UIDevice.current.userInterfaceIdiom == .phone {} else {
                                wid9 = CGFloat(GlobalStruct.padColWidth)
                            }
                            underlay.frame = CGRect(x: 0, y: 0, width: CGFloat((((wid9) - 40) * (diff))), height: 32)
                        }
                    } else {
                        underlay.backgroundColor = .custom.backgroundTint
                        var wid9 = UIScreen.main.bounds.size.width
                        if GlobalStruct.isCompact || UIDevice.current.userInterfaceIdiom == .phone {} else {
                            wid9 = CGFloat(GlobalStruct.padColWidth)
                        }
                        underlay.frame = CGRect(x: 0, y: 0, width: CGFloat(wid9), height: 32)
                    }
                    underlay.removeFromSuperview()
                    barText.insertSubview(underlay, at: 0)

                    let barDetail = UILabel()
                    barDetail.frame = CGRect(x: 0, y: 0, width: 30, height: 40)
                    if pollOptions?.voted ?? false {
                        if totalVotes == 0 {
                            barDetail.text = "0%"
                        } else {
                            let diff = Int((Double(x.votesCount ?? 0)/Double(totalVotes))*100)
                            barDetail.text = "\(diff)%"
                        }
                    } else {
                        barDetail.text = ""
                    }
                    barDetail.textColor = .label
                    barDetail.font = UIFont.systemFont(ofSize: 16, weight: .regular)
                    barDetail.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

                    let bar1 = UIStackView()
                    bar1.addArrangedSubview(barText)
                    bar1.addArrangedSubview(barDetail)
                    bar1.alignment = .center
                    bar1.axis = .horizontal
                    bar1.distribution = .fill
                    bar1.spacing = 10

                    pollStack.addArrangedSubview(bar1)
                }

                let endPoll = UILabel()
                endPoll.frame = CGRect(x: 0, y: 0, width: 30, height: 40)
                endPoll.text = "\(tVote) • Poll \(tText) \(mVote) \(tText2)"
                endPoll.textColor = .secondaryLabel
                endPoll.textAlignment = .center
                endPoll.font = UIFont.systemFont(ofSize: 14, weight: .regular)

                pollStack.addArrangedSubview(endPoll)

            }

            pollStack.translatesAutoresizingMaskIntoConstraints = false
            pollStack.alignment = .fill
            pollStack.axis = .vertical
            pollStack.distribution = .equalSpacing
            pollStack.spacing = 8
            pollStack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            pollStack.isLayoutMarginsRelativeArrangement = true
            pollStack.backgroundColor = .custom.quoteTint
            pollStack.layer.cornerRadius = 8
            pollStack.layer.masksToBounds = true
            pollStack.layer.borderWidth = 0.4
            pollStack.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
            self.pipView.addSubview(pollStack)

            pollStack.isHidden = false
            linkStackView.isHidden = true
            
        } else {
            
            pollStack.isHidden = true
            
            linkPost.numberOfLines = 0
            self.linkStr = link
            
            
            if let link = link {
                self.setupLinkPreview(link, stat: stat)
            } else {
                self.linkStackView.isHidden = true
            }
            if let quotePostCard = quotePostCard {
                // This is a quote post; use the quotePostDetailCell to display it
                self.setupQuotePostPreview(quotePostCard)
            } else {
                self.quotePostHostView?.isHidden = true
            }
        }
        self.updateConstraints()
    }
    
    
    var pollId: String = ""
    @objc func pollOptionsTap(_ sender: UITapGestureRecognizer) {
        triggerHapticImpact(style: .light)
        let alert = UIAlertController(title: "Vote for '\((sender.view as? UIButton)?.titleLabel?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")'?", message: "You cannot change your vote once you have voted.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Vote", style: .default , handler:{ (UIAlertAction) in
            self.voteOnThis(sender.view?.tag ?? 0)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
            
        }))
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = getTopMostViewController()?.view
            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
        }
        getTopMostViewController()?.present(alert, animated: true, completion: nil)
    }
    
    func voteOnThis(_ sender: Int) {
        let request = Polls.vote(id: self.pollId, choices: [sender])
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let err = statuses.error {
                if "\(err)".contains("ended") {
                    DispatchQueue.main.async {
                        triggerHapticNotification(feedback: .warning)
                        let alert = UIAlertController(title: "Poll Ended", message: "You can't vote on this poll as it has already ended.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
                            
                        }))
                        if let presenter = alert.popoverPresentationController {
                            presenter.sourceView = getTopMostViewController()?.view
                            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                        }
                        getTopMostViewController()?.present(alert, animated: true, completion: nil)
                    }
                } else {
                    if "\(err)".contains("already voted") {
                        DispatchQueue.main.async {
                            triggerHapticNotification(feedback: .warning)
                            let alert = UIAlertController(title: "Already Voted", message: "You can't vote on this poll as you have already voted on it.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
                                
                            }))
                            if let presenter = alert.popoverPresentationController {
                                presenter.sourceView = getTopMostViewController()?.view
                                presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                            }
                            getTopMostViewController()?.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
            if let poll = statuses.value {
                print("vote sent")
                DispatchQueue.main.async {
                    triggerHapticNotification()
                    GlobalStruct.votedOnPolls[self.pollId] = poll
                    do {
                        try Disk.save(GlobalStruct.votedOnPolls, to: .documents, as: "votedOnPolls.json")
                    } catch {
                        log.error("error saving votedOnPolls to Disk")
                    }
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "postUpdated"), object: nil)
                }
            }
        }
    }
    
    var linkStr: Card? = nil
    @objc func quoteTapped() {
        // open url
        if let x = self.linkStr?.url {
            if let ur = URL(string: x) {
                PostActions.openLink(ur)
            }
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
            return self.makeContextMenu()
        })
    }
    
    func makeContextMenu() -> UIMenu {
        let openLink = UIAction(title: "Open Link", image: UIImage(systemName: "safari"), identifier: nil) { action in
            if let x = self.linkStr?.url {
                if let ur = URL(string: x) {
                    PostActions.openLink(ur)
                }
            }
        }
        let copy = UIAction(title: NSLocalizedString("generic.copy", comment: ""), image: UIImage(systemName: "doc.on.doc"), identifier: nil) { action in
            if let x = self.linkStr?.url {
                UIPasteboard.general.string = x
            }
        }
        let share = UIAction(title: NSLocalizedString("generic.share", comment: ""), image: UIImage(systemName: "square.and.arrow.up"), identifier: nil) { action in
            if let x = self.linkStr?.url {
                let linkToShare = [x]
                let activityViewController = UIActivityViewController(activityItems: linkToShare,  applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self
                activityViewController.popoverPresentationController?.sourceRect = self.bounds
                getTopMostViewController()?.present(activityViewController, animated: true, completion: nil)
            }
        }
        return UIMenu(title: "", image: nil, identifier: nil, children: [openLink, copy, share])
    }
    
    func setupLinkPreview(_ link2: Card, stat: Status?) {
        
        self.linkStackView.isHidden = false

        if GlobalStruct.linkPreviewCardsLarge == false {
            self.linkPost.isHidden = true
            self.conLP1?.isActive = false
            self.conLP2?.isActive = true
            lpImage.widthAnchor.constraint(equalToConstant: 65).isActive = true
            linkStackView.axis = .horizontal
        } else {
            self.linkPost.isHidden = false
            self.conLP1?.isActive = true
            self.conLP2?.isActive = false
            lpImage.widthAnchor.constraint(equalToConstant: 65).isActive = false
            linkStackView.axis = .vertical
        }

        linkUsertag.text = ""
        linkPost.numberOfLines = 2
        linkUsername.numberOfLines = 2
        if link2.title == "" {
            linkUsername.text = link2.authorName
        } else {
            linkUsername.text = link2.title.replacingOccurrences(of: "\n", with: " ")
        }
        if link2.description == "" {
            if let x = link2.url {
                linkPost.text = x
            }
        } else {
            linkPost.text = link2.description.replacingOccurrences(of: "\n", with: " ")
        }
        linkPost.URLColor = .secondaryLabel
        linkDate.text = ""
        self.lpImage.isHidden = false
        
        // If we are showing an image from the post, don't show the
        // image associated with the opengraph link.
        if DetailImageCell.willDisplayContentForStat(stat) {
            self.lpImage.isHidden = true
        } else {
            if let x = link2.image?.absoluteString {
                if let profileURL = URL(string: x) {
                    self.lpImage.sd_setImage(with: profileURL, completed: nil)
                } else {
                    self.lpImage.isHidden = true
                }
            } else {
                self.lpImage.isHidden = true
            }
        }
    }
    
    func setupQuotePostPreview(_ link2: Card) {
        self.quotePostHostView?.isHidden = false
        self.linkStackView.isHidden = false
        
        // Detail header is already display via QuotePostHostView > DetailView
        if !self.isQuotedPostPreview {
            UIView.setAnimationsEnabled(false)
            self.lpImage.isHidden = true
            self.linkPost.isHidden = true
            self.linkStackViewHorizontal.isHidden = true
            UIView.setAnimationsEnabled(true)
        }

        let cardURL = URL(string: link2.url ?? "")
        self.quotePostHostView?.updateForQuotePost(cardURL)
    }

    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }

    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return nil
    }

    public func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let image: UIImage = UIImage()
        let imageProvider = NSItemProvider(object: image)
        let metadata = LPLinkMetadata()
        metadata.imageProvider = imageProvider
        return metadata
    }
    
    func makeContextMenu2(_ index: Int) -> UIMenu {
        return UIMenu(title: "", image: nil, identifier: nil, children: [])
    }
    
}

