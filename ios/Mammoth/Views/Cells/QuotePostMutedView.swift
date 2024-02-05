//
//  QuotePostMutedView.swift
//  Mammoth
//
//  Created by Riley Howard on 4/20/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class QuotePostMutedView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet var quotesImageView: UIImageView!
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var accountLabel: UILabel!
    @IBOutlet var chevronImageView: UIImageView!
    @IBOutlet weak var nameLabelLeftConstrait: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("QuotePostMutedView", owner: self, options: nil)
        self.addSubview(contentView)
        contentView.frame = self.frame
        contentView.addFillConstraints(with: self)
        
        // Avatar
        if GlobalStruct.circleProfiles {
            avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2.0
        } else {
            avatarImageView.layer.cornerRadius = 5
        }
        
        nameLabel.text = ""
        accountLabel.text = ""
        
        nameLabel.font = UIFont.systemFont(ofSize: nameLabel.font.pointSize, weight: .semibold)
        accountLabel.textColor = .secondaryLabel
        
        quotesImageView.image = FontAwesome.image(fromChar: "\u{f10d}", color: .secondaryLabel, size: 15, weight: .bold)
        chevronImageView.image = FontAwesome.image(fromChar: "\u{f054}", color: .secondaryLabel, size: 15)
    }
    
    public func updateFromStat(_ stat: Status?) {
        
        if stat == nil {
            nameLabel.isHidden = true
            avatarImageView.isHidden = true
            accountLabel.text = "Post could not be found"
            
            chevronImageView.image = FontAwesome.image(fromChar: "\u{f05a}", color: .custom.baseTint, size: 15)
            
            if let constrait = self.self.nameLabelLeftConstrait {
                NSLayoutConstraint.deactivate([constrait])
                self.accountLabel.leadingAnchor.constraint(equalTo: self.quotesImageView.trailingAnchor, constant: 8).isActive = true
            }
            
        } else {
            // Avatar
            var avatarURL: URL? = nil
            avatarURL = URL(string: stat?.reblog?.account?.avatar ?? stat?.account?.avatar ?? "")
            if let avatarURL {
                // If sd_image already has this cached, then it will be used
                // as the placeholder.
                //
                // Otherwise, the placeholder image will be nil, and thus clear
                // the view (as desired).
                let placeholder =  UIImageView()
                placeholder.sd_setImage(with: avatarURL)
                avatarImageView.sd_setImage(with: avatarURL, placeholderImage: placeholder.image)
            }
            
            var needsLayout = false
            if nameLabel.text != stat?.account?.displayName {
                nameLabel.text = stat?.account?.displayName
                needsLayout = true
            }
            var acctLabelText = ""
            if let acct = stat?.account?.acct, !acct.isEmpty {
                acctLabelText = "@" + acct
            }
            if accountLabel.text != acctLabelText {
                accountLabel.text = acctLabelText
                needsLayout = true
            }
            if needsLayout {
                self.setNeedsLayout()
            }
        }
        
    }

}
