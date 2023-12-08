//
//  DetailImageCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 28/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class DetailImageCell: UITableViewCell {
    
    var d = DetailImageView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.d.prepareForReuse()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.initialSetup()
    }
    
    func initialSetup() {
        self.contentView.addSubview(self.d)
        self.d.addFillConstraints(with: self.contentView)
        
        self.separatorInset = .zero
        let bgColorView = UIView()
        bgColorView.backgroundColor = .clear
        self.selectedBackgroundView = bgColorView
        self.backgroundColor = .custom.quoteTint
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static func willDisplayContentForStat(_ stat: Status?) -> Bool {
        return DetailImageView.willDisplayContentForStat(stat)
    }
}
