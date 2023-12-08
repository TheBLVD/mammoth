//
//  ForYouChannelCell.swift
//  Mammoth
//
//  Created by Riley Howard on 10/2/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class ForYouChannelCell: UITableViewCell {
    static let reuseIdentifier = "ForYouChannelCell"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkmarkImage: UIImageView!
    @IBOutlet weak var trayView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        self.selectionStyle = .none
        trayView.layer.cornerRadius = 10
        checkmarkImage.image = FontAwesome.image(fromChar: "\u{f00c}", size: 14).withRenderingMode(.alwaysTemplate)
    }
    
    public func configure(forYouRowInfo: ForYouRowInfo, index: Int, isBottomCell: Bool) {
        
        let title = NSMutableAttributedString(string: "/", attributes: [.baselineOffset: 1])
        title.addAttribute(.font, value: UIFont.systemFont(ofSize: 16, weight: .semibold), range: NSMakeRange(0, title.length))
        
        let spacerImage = NSTextAttachment()
        spacerImage.image = UIImage()
        spacerImage.bounds = CGRect.init(x: 0, y: 0, width: 1.5, height: 0.0001)

        title.append(NSAttributedString(attachment: spacerImage))
        title.append(NSAttributedString(string: forYouRowInfo.title))
        
        title.addAttribute(.foregroundColor, value: UIColor.custom.highContrast, range: NSMakeRange(0, 1))
        title.addAttribute(.foregroundColor, value: UIColor.custom.highContrast, range: NSMakeRange(1, title.length-1))
        title.addAttribute(.baselineOffset, value: 0.5, range: .init(location: 0, length: 1))
        title.addAttribute(.baselineOffset, value: 0.5, range: .init(location: 2, length: forYouRowInfo.title.count))
        
        titleLabel.attributedText = title
        checkmarkImage.isHidden = !forYouRowInfo.isOn
        self.tag = index
        let cornerMask: CACornerMask
        if isBottomCell {
            cornerMask = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            cornerMask = CACornerMask(rawValue: 0)
        }
        trayView.layer.maskedCorners = cornerMask
    }
}


