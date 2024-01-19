//
//  SelectionCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 22/04/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class SelectionCell: UITableViewCell {
    
    let backgroundButton: UIButton = {
        let backgroundButton = UIButton()
        backgroundButton.translatesAutoresizingMaskIntoConstraints = true
        backgroundButton.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundButton.backgroundColor = .custom.quoteTint
        backgroundButton.showsMenuAsPrimaryAction = true
        backgroundButton.backgroundColor = .clear
        return backgroundButton
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .custom.OVRLYSoftContrast
        self.selectionStyle = .none
        self.textLabel?.numberOfLines = 0
        self.detailTextLabel?.numberOfLines = 0
        self.addSubview(backgroundButton)
        self.backgroundButton.frame = self.backgroundButton.superview!.bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

