//
//  DetailCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 27/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class DetailCell: UITableViewCell {
    
    var d = DetailView()
    
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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

