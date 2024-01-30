//
//  ComposeQuotePostCell.swift
//  Mammoth
//
//  Created by Riley Howard on 4/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

// Hosts a QuotePostView that shows either a muted or fully formed quote post.
class ComposeQuotePostCell: UITableViewCell {
    
    var quotePostURL: URL? = nil
    let quotePostHostView = QuotePostHostView()
    let quoteBackgroundView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .custom.quoteTint
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 0.4
        view.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        view.layer.masksToBounds = true
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // background is inset a bit from self
        self.contentView.addSubview(quoteBackgroundView)
        
        // quotePostHostView is lined up with the background
        self.quotePostHostView.translatesAutoresizingMaskIntoConstraints = false
        self.quoteBackgroundView.addSubview(quotePostHostView)
        
        NSLayoutConstraint.activate([
            self.quoteBackgroundView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 85),
            self.quoteBackgroundView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -15),
            self.quoteBackgroundView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10),
            self.quoteBackgroundView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            
            self.quotePostHostView.leadingAnchor.constraint(equalTo: self.quoteBackgroundView.leadingAnchor, constant: 12),
            self.quotePostHostView.trailingAnchor.constraint(equalTo: self.quoteBackgroundView.trailingAnchor, constant: -12),
            self.quotePostHostView.topAnchor.constraint(equalTo: self.quoteBackgroundView.topAnchor, constant: 8),
            self.quotePostHostView.bottomAnchor.constraint(equalTo: self.quoteBackgroundView.bottomAnchor, constant: -10),
        ])

        self.isUserInteractionEnabled = false
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    public func updateForQuotePost(_ qpURL: URL?) {
        if qpURL != quotePostURL {
            quotePostURL = qpURL
            self.quotePostHostView.updateForQuotePost(qpURL)
        }
    }
    
}
