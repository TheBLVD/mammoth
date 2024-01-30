//
//  LoadingCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 21/12/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class LoadingCell: UITableViewCell {
    static let reuseIdentifier = "LoadingCell"
    
    var loadingIndicator = UIActivityIndicatorView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        self.separatorInset = .zero
        self.layoutMargins = .zero
        self.contentView.preservesSuperviewLayoutMargins = false
        
        self.backgroundColor = .custom.background
        self.contentView.backgroundColor = .custom.background
        self.isOpaque = true
        self.contentView.isOpaque = true
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        contentView.addSubview(loadingIndicator)
                
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            loadingIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            loadingIndicator.widthAnchor.constraint(equalToConstant: 20),
        ])
    }
    
    func startAnimation() {
        self.backgroundColor = .custom.background
        self.contentView.backgroundColor = .custom.background
        loadingIndicator.startAnimating()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
