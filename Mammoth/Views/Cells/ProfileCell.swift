//
//  ProfileCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 26/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit


class SpinnerButton: UIButton {
    
    var originalButtonText: String?
    var activityIndicator: UIActivityIndicatorView!
    var showingSpinner = false
    
    func showSpinner(_ show: Bool) {
        if show != showingSpinner {
            showingSpinner = show
            if show {
                super.setTitle("", for: .normal)
                if (activityIndicator == nil) {
                    activityIndicator = UIActivityIndicatorView()
                    activityIndicator.hidesWhenStopped = true
                    activityIndicator.color = UIColor.white
                    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
                    self.superview?.insertSubview(activityIndicator, aboveSubview: self)
                    let xCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: activityIndicator, attribute: .centerX, multiplier: 1, constant: 0)
                    self.superview!.addConstraint(xCenterConstraint)
                    let yCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: activityIndicator, attribute: .centerY, multiplier: 1, constant: 0)
                    self.superview!.addConstraint(yCenterConstraint)
                }
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
                self.setTitle(self.originalButtonText, for: .normal)
            }
        }
    }
    
    func prepareForReuse() {
        // iOS will stop all animations in the cell,
        // so we need to 'manually' restart it here every time.
        if showingSpinner {
            activityIndicator.startAnimating()
        }
    }
    
    override func setTitle(_ title: String?, for state: UIControl.State) {
        if showingSpinner {
            originalButtonText = title
        } else {
            super.setTitle(title, for: state)
        }
    }
    
}


class ProfileCell: UITableViewCell, SKPhotoBrowserDelegate {
    
    enum FollowButtonState {
        case unknown      // show the spinner
        case toFollow     // show "Follow"
        case toUnfollow   // show "Unfollow"
        case requested    // show "Requested"
    }
    
    let profileBackLayer = UIView()
    var profileIcon = UIButton()
    var headerImage = UIButton()
    var follow = SpinnerButton()
    var userName = UILabel()
    var userTag = UIButton()
    var followsYou = UIButton()
    var lockedBadge = UIImageView()
    var lockedBackground = UIView()
    var bioText = ActiveLabel()
    var privateNoteText = ActiveLabel()
    var fieldsText = UIButton()
    let stackView = UIStackView()
    var createdAtText = UILabel()
    let stackView2 = UIStackView()
    var blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))
    var constraints0: [NSLayoutConstraint] = []
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        headerImage.translatesAutoresizingMaskIntoConstraints = false
        headerImage.backgroundColor = .custom.backgroundTint
        headerImage.layer.masksToBounds = true
        headerImage.addTarget(self, action: #selector(self.headerTapped), for: .touchUpInside)
        headerImage.imageView?.contentMode = .scaleAspectFill
        headerImage.contentMode = .scaleAspectFill
        contentView.addSubview(headerImage)
        
#if targetEnvironment(macCatalyst)
        if GlobalStruct.singleColumn {
            profileBackLayer.frame = CGRect(x: 40, y: 38, width: 120, height: 120)
        } else {
            profileBackLayer.frame = CGRect(x: 20, y: 38, width: 120, height: 120)
        }
#elseif !targetEnvironment(macCatalyst)
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && self.window?.traitCollection.horizontalSizeClass != .compact {
            profileBackLayer.frame = CGRect(x: 20, y: 38, width: 120, height: 120)
        } else {
            profileBackLayer.frame = CGRect(x: 20, y: 38, width: 120, height: 120)
        }
#endif
        profileBackLayer.backgroundColor = .custom.backgroundTint
        profileBackLayer.isUserInteractionEnabled = false
        contentView.addSubview(profileBackLayer)
        
        profileIcon.translatesAutoresizingMaskIntoConstraints = false
        profileIcon.backgroundColor = .custom.quoteTint
        profileIcon.layer.borderColor = UIColor.custom.quoteTint.cgColor
        profileIcon.layer.borderWidth = 3
        profileIcon.layer.masksToBounds = true
        profileIcon.imageView?.contentMode = .scaleAspectFill
        profileIcon.contentMode = .scaleAspectFill
        profileIcon.addTarget(self, action: #selector(self.profileTapped), for: .touchUpInside)
        profileIcon.accessibilityLabel = NSLocalizedString("navigator.profile", comment: "")
        contentView.addSubview(profileIcon)
        
        follow.translatesAutoresizingMaskIntoConstraints = false
        follow.titleLabel?.textAlignment = .center
        follow.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        follow.layer.cornerRadius = 10
        follow.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        follow.isHidden = true
        // Ensure the button is wide even with just the spinner showing
        follow.widthAnchor.constraint(greaterThanOrEqualToConstant: 71).isActive = true
        contentView.addSubview(follow)
        follow.addInteraction(UIPointerInteraction(delegate: nil))
        
        userName.translatesAutoresizingMaskIntoConstraints = false
        userName.textAlignment = .left
        userName.textColor = .label
        userName.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .title2).pointSize + GlobalStruct.customTextSize + 2, weight: .bold)
        userName.numberOfLines = 0
        contentView.addSubview(userName)
        
        let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .title2).pointSize + GlobalStruct.customTextSize, weight: .bold)
        lockedBadge.translatesAutoresizingMaskIntoConstraints = false
        lockedBadge.backgroundColor = .clear
        lockedBadge.image = UIImage(systemName: "checkmark.seal.fill", withConfiguration: symbolConfig0)?.withTintColor(.custom.appCol, renderingMode: .alwaysOriginal)
        lockedBadge.alpha = 0
        contentView.addSubview(lockedBadge)
        lockedBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        lockedBackground.translatesAutoresizingMaskIntoConstraints = false
        lockedBackground.backgroundColor = .custom.backgroundTint
        lockedBackground.layer.cornerRadius = (UIFont.preferredFont(forTextStyle: .title2).pointSize + GlobalStruct.customTextSize - 4) / 2
        lockedBackground.alpha = 0
        self.contentView.insertSubview(lockedBackground, belowSubview: lockedBadge)
        
        userTag.translatesAutoresizingMaskIntoConstraints = false
        userTag.titleLabel?.textAlignment = .left
        userTag.contentHorizontalAlignment = .left
        userTag.setTitleColor(UIColor.secondaryLabel, for: .normal)
        userTag.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        contentView.addSubview(userTag)
        
        followsYou.translatesAutoresizingMaskIntoConstraints = false
        followsYou.setTitle("Follows You", for: .normal)
        followsYou.setTitleColor(UIColor.label.withAlphaComponent(0.5), for: .normal)
        followsYou.titleLabel?.textAlignment = .center
        followsYou.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular)
        followsYou.backgroundColor = .custom.backgroundTint
        followsYou.layer.cornerRadius = 8
        followsYou.layer.cornerCurve = .continuous
        followsYou.contentEdgeInsets = UIEdgeInsets(top: 2, left: 9, bottom: 2, right: 9)
        followsYou.alpha = 0
        contentView.addSubview(followsYou)
        followsYou.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        bioText.translatesAutoresizingMaskIntoConstraints = false
        bioText.numberOfLines = 0
        bioText.textColor = .custom.mainTextColor
        bioText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        bioText.enabledTypes = [.mention, .hashtag, .url, .email]
        bioText.mentionColor = .custom.baseTint
        bioText.hashtagColor = .custom.baseTint
        bioText.URLColor = .custom.baseTint
        bioText.emailColor = .custom.baseTint
        bioText.urlMaximumLength = 30
        
        privateNoteText.translatesAutoresizingMaskIntoConstraints = false
        privateNoteText.numberOfLines = 0
        privateNoteText.textColor = .secondaryLabel
        privateNoteText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        privateNoteText.enabledTypes = [.mention, .hashtag, .url, .email]
        privateNoteText.mentionColor = .custom.baseTint
        privateNoteText.hashtagColor = .custom.baseTint
        privateNoteText.URLColor = .custom.baseTint
        privateNoteText.emailColor = .custom.baseTint
        privateNoteText.urlMaximumLength = 30
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(bioText)
        stackView.alignment = .fill
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 6
        contentView.addSubview(stackView)
        
        fieldsText.translatesAutoresizingMaskIntoConstraints = false
        fieldsText.alpha = 0
        fieldsText.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        fieldsText.backgroundColor = .custom.backgroundTint
        fieldsText.layer.cornerRadius = 8
        fieldsText.layer.cornerCurve = .continuous
        fieldsText.layer.masksToBounds = true
        fieldsText.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        
        let attachment1 = NSTextAttachment()
        let symbolConfig1 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize - 4, weight: .semibold)
        let downImage1 = UIImage(systemName: "chevron.right", withConfiguration: symbolConfig1) ?? UIImage()
        attachment1.image = downImage1.withTintColor(UIColor.label.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
        let attStringNewLine000 = NSMutableAttributedString()
        let attStringNewLine00 = NSMutableAttributedString(string: "Info and Links ", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold), NSAttributedString.Key.foregroundColor : UIColor.label.withAlphaComponent(0.6)])
        let attString00 = NSAttributedString(attachment: attachment1)
        attStringNewLine000.append(attStringNewLine00)
        attStringNewLine000.append(attString00)
        fieldsText.setAttributedTitle(attStringNewLine000, for: .normal)
        
        contentView.addSubview(fieldsText)
        
        createdAtText.translatesAutoresizingMaskIntoConstraints = false
        createdAtText.text = ""
        createdAtText.textAlignment = .left
        createdAtText.numberOfLines = 0
        createdAtText.textColor = UIColor.secondaryLabel
        createdAtText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular)
        
        stackView2.translatesAutoresizingMaskIntoConstraints = false
        stackView2.addArrangedSubview(createdAtText)
        stackView2.alignment = .fill
        stackView2.axis = .vertical
        stackView2.distribution = .equalSpacing
        stackView2.spacing = 0
        contentView.addSubview(stackView2)
        
        blurEffectView.frame = headerImage.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.alpha = 0
        headerImage.addSubview(blurEffectView)
        
        let viewsDict = [
            "headerImage" : headerImage,
            "profileIcon" : profileIcon,
            "userName" : userName,
            "lockedBackground" : lockedBackground,
            "lockedBadge" : lockedBadge,
            "userTag" : userTag,
            "followsYou" : followsYou,
            "stackView" : stackView,
            "stackView2" : stackView2,
            "fieldsText" : fieldsText,
        ]
        let metricsDict = [
            "fontSize" : UIFont.preferredFont(forTextStyle: .title2).pointSize + GlobalStruct.customTextSize - 4
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[headerImage]-0-|", options: [], metrics: nil, views: viewsDict))
        
#if targetEnvironment(macCatalyst)
        if GlobalStruct.singleColumn {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-40-[profileIcon(120)]", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-40-[userName]-10-[lockedBackground(fontSize)]-(>=40)-|", options: [], metrics: metricsDict, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-40-[userName]-5-[lockedBadge]-(>=40)-|", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-40-[userTag]-(>=6)-[followsYou]-(40)-|", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-40-[stackView]-40-|", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-40-[stackView2]-40-|", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-40-[fieldsText]", options: [], metrics: nil, views: viewsDict))
        } else {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[profileIcon(120)]", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[userName]-10-[lockedBackground(fontSize)]-(>=20)-|", options: [], metrics: metricsDict, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[userName]-5-[lockedBadge]-(>=20)-|", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[userTag]-(>=6)-[followsYou]-(20)-|", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[stackView]-20-|", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[stackView2]-20-|", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[fieldsText]", options: [], metrics: nil, views: viewsDict))
        }
#elseif !targetEnvironment(macCatalyst)
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && self.window?.traitCollection.horizontalSizeClass != .compact {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[profileIcon(120)]", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[userName]-10-[lockedBackground(fontSize)]-(>=20)-|", options: [], metrics: metricsDict, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[userName]-5-[lockedBadge]-(>=20)-|", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[userTag]-(>=6)-[followsYou]-(20)-|", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[stackView]-20-|", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[stackView2]-20-|", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[fieldsText]", options: [], metrics: nil, views: viewsDict))
        } else {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[profileIcon(120)]", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[userName]-10-[lockedBackground(fontSize)]-(>=20)-|", options: [], metrics: metricsDict, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[userName]-5-[lockedBadge]-(>=20)-|", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[userTag]-(>=6)-[followsYou]-(20)-|", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[stackView]-20-|", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[stackView2]-20-|", options: [], metrics: nil, views: viewsDict))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[fieldsText]", options: [], metrics: nil, views: viewsDict))
        }
#endif
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[headerImage(115)]", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-38-[profileIcon(120)]", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[userName]-(-1.4)-[followsYou]", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[lockedBackground(fontSize)]-1-[userTag]", options: [], metrics: metricsDict, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[lockedBadge]-(-4)-[userTag]", options: [], metrics: nil, views: viewsDict))
        
        self.constraints0 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-166-[userName]-(-8)-[userTag]-3-[stackView]-8-[stackView2]-8-|", options: [], metrics: nil, views: viewsDict)
        self.contentView.addConstraints(constraints0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupPrivateNote() {
        stackView.addArrangedSubview(privateNoteText)
    }
    
    func setupFields(_ enabled: Bool = false) {
        let viewsDict = [
            "userName" : userName,
            "userTag" : userTag,
            "stackView" : stackView,
            "stackView2" : stackView2,
            "fieldsText" : fieldsText,
        ]
        let _ = self.constraints0.map ({ x in
            x.isActive = false
        })
        if enabled {
            self.fieldsText.alpha = 1
            self.constraints0 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-166-[userName]-(-8)-[userTag]-3-[stackView]-10-[stackView2]-10-[fieldsText]-20-|", options: [], metrics: nil, views: viewsDict)
            let _ = self.constraints0.map ({ x in
                x.isActive = true
            })
        } else {
            self.fieldsText.alpha = 0
            self.constraints0 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-166-[userName]-(-8)-[userTag]-3-[stackView]-8-[stackView2]-20-|", options: [], metrics: nil, views: viewsDict)
            let _ = self.constraints0.map ({ x in
                x.isActive = true
            })
        }
    }
    
    func setupFollowButton(followState: FollowButtonState) {
        followsYou.backgroundColor = .custom.backgroundTint
        
        var title: String
        var titleColor: UIColor
        var backgroundColor: UIColor
        var showSpinner: Bool
        
        switch followState {
        case .unknown:
            title = ""
            titleColor = UIColor.white
            backgroundColor = .custom.spinnerBG.withAlphaComponent(0.75)
            showSpinner = true

        case .toFollow:
            title = "Follow"
            titleColor = UIColor.white
            backgroundColor = .custom.baseTint
            showSpinner = false

        case .toUnfollow:
            title = "Following"
            titleColor = UIColor.label.withAlphaComponent(0.5)
            backgroundColor = .custom.backgroundTint
            showSpinner = false
        
        case .requested:
            title = "Requested"
            titleColor = UIColor.label.withAlphaComponent(0.5)
            backgroundColor = .custom.backgroundTint
            showSpinner = false
        }

        follow.setTitle(title, for: .normal)
        follow.backgroundColor = backgroundColor
        follow.setTitleColor(titleColor, for: .normal)
        follow.showSpinner(showSpinner)
        
        if follow.isHidden {
            follow.isHidden = false
            let viewsDict = [
                "follow" : follow,
            ]
#if targetEnvironment(macCatalyst)
            if GlobalStruct.singleColumn {
                self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=10)-[follow]-20-|", options: [], metrics: nil, views: viewsDict))
            } else {
                self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=10)-[follow]-20-|", options: [], metrics: nil, views: viewsDict))
            }
#elseif !targetEnvironment(macCatalyst)
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=10)-[follow]-20-|", options: [], metrics: nil, views: viewsDict))
#endif
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-124-[follow]", options: [], metrics: nil, views: viewsDict))
        }
    }
    
    func setupStack() {
        if bioText.text == "" {
            bioText.isHidden = true
        } else {
            bioText.isHidden = false
        }
    }
    
    @objc func profileTapped() {
        var images = [SKPhoto]()
        if let x = profileIcon.imageView?.image {
            let photo = SKPhoto.photoWithImage(x)
            photo.shouldCachePhotoURLImage = true
            images.append(photo)
            let originImage = profileIcon.imageView?.image ?? UIImage()
            let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: profileIcon, imageText: "", imageText2: 0, imageText3: 0, imageText4: "")
            browser.delegate = self
            SKPhotoBrowserOptions.enableSingleTapDismiss = false
            SKPhotoBrowserOptions.displayCounterLabel = false
            SKPhotoBrowserOptions.displayBackAndForwardButton = false
            SKPhotoBrowserOptions.displayAction = false
            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
            SKPhotoBrowserOptions.displayCloseButton = true
            SKPhotoBrowserOptions.displayStatusbar = false
            browser.initializePageIndex(0)
            getTopMostViewController()?.present(browser, animated: true, completion: {})
        }
    }
    
    @objc func headerTapped() {
        var images = [SKPhoto]()
        if let x = headerImage.imageView?.image {
            let photo = SKPhoto.photoWithImage(x)
            photo.shouldCachePhotoURLImage = true
            images.append(photo)
            let originImage = x
            let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: headerImage, imageText: "", imageText2: 0, imageText3: 0, imageText4: "")
            browser.delegate = self
            SKPhotoBrowserOptions.enableSingleTapDismiss = false
            SKPhotoBrowserOptions.displayCounterLabel = false
            SKPhotoBrowserOptions.displayBackAndForwardButton = false
            SKPhotoBrowserOptions.displayAction = false
            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
            SKPhotoBrowserOptions.displayCloseButton = true
            SKPhotoBrowserOptions.displayStatusbar = false
            browser.initializePageIndex(0)
            getTopMostViewController()?.present(browser, animated: true, completion: {})
        }
    }
    
    func setupConstraints(_ stat: Account? = nil) {
        if GlobalStruct.circleProfiles {
            profileBackLayer.layer.cornerRadius = 60
            profileIcon.layer.cornerRadius = 60
        } else {
            profileBackLayer.layer.cornerRadius = 20
            profileIcon.layer.cornerRadius = 20
        }
        
        if stat?.emojis.isEmpty ?? false {

        } else {
            let attributedString = NSMutableAttributedString(string: "\(stat?.note.stripHTML() ?? "")", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.custom.mainTextColor.withAlphaComponent(0.85)])
            if let z = stat?.emojis {
                let _ = z.map({
                    let textAttachment = NSTextAttachment()
                    textAttachment.kf.setImage(with: $0.url, attributedView: self.bioText, completionHandler:  { r in
                        self.bioText.setNeedsDisplay()
                    })
                    textAttachment.bounds = CGRect(x:0, y: Int(-2), width: Int(self.bioText.font.lineHeight - 6), height: Int(self.bioText.font.lineHeight - 6))
                    let attrStringWithImage = NSAttributedString(attachment: textAttachment)
                    while attributedString.mutableString.contains(":\($0.shortcode):") {
                        let range: NSRange = (attributedString.mutableString as NSString).range(of: ":\($0.shortcode):")
                        attributedString.replaceCharacters(in: range, with: attrStringWithImage)
                    }
                })
#if !targetEnvironment(macCatalyst)
                self.bioText.attributedText = attributedString
#endif
            }
        }

        if stat?.emojis.isEmpty ?? false {

        } else {
            let attributedString = NSMutableAttributedString(string: "\(stat?.displayName ?? "")", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .title2).pointSize + GlobalStruct.customTextSize + 2, weight: .bold), NSAttributedString.Key.foregroundColor: UIColor.custom.mainTextColor.withAlphaComponent(0.85)])
            if let z = stat?.emojis {
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
    }
 
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Give the spinner a chance to animate if needed
        follow.prepareForReuse()
    }
    
}
