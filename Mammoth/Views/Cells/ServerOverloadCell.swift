//
//  ServerOverloadCell.swift
//  Mammoth
//
//  Created by Riley Howard on 11/27/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class ServerOverloadCell: ServerUpdatingCell {
    
    override class var reuseIdentifier: String{ return "ServerOverloadCell" }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel.text = "Servers are busy, we're on it!"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
