//
//  ForYouCustomizationCell.swift
//  Mammoth
//
//  Created by Riley Howard on 10/2/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

protocol ForYouCustomizationCellDelegate: AnyObject {
    func setForYouRowInfoOn(section: ForYouCustomizationViewModel.Section, betaItem: ForYouCustomizationViewModel.BetaItem?, value: Bool)
}

class ForYouCustomizationCell: UITableViewCell {
    static let reuseIdentifier = "ForYouCustomizationCell"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var enabledSwitch: UISwitch!
    @IBOutlet weak var trayView: UIView!

    var section: ForYouCustomizationViewModel.Section?
    var betaItem: ForYouCustomizationViewModel.BetaItem?
    weak var delegate: ForYouCustomizationCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        trayView.layer.cornerRadius = 10
    }
    
    public func configure(forYouRowInfo: ForYouRowInfo, section: ForYouCustomizationViewModel.Section, betaItem: ForYouCustomizationViewModel.BetaItem? = nil, hasChildCells: Bool) {
        self.section = section
        self.betaItem = betaItem
        titleLabel.text = forYouRowInfo.title
        descriptionLabel.text = forYouRowInfo.description
        titleLabel.numberOfLines = 2
        enabledSwitch.isOn = forYouRowInfo.isOn
        var cornerMask: CACornerMask
        if hasChildCells {
            cornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            cornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        trayView.layer.maskedCorners = cornerMask
    }
    
    @IBAction func toggleSwitch(_ sender: UISwitch) {
        self.delegate?.setForYouRowInfoOn(section: section!, betaItem: betaItem, value: self.enabledSwitch.isOn)
    }
}


