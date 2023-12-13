//
//  LoadMoreCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 16/12/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class LoadMoreCell: UITableViewCell {
    
    static let reuseIdentifier = "LoadMoreCell"
    
    private var bgView = UIView()
    public var titleLabel = UILabel()
    public var loadingIndicator = UIActivityIndicatorView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.isOpaque = true
        self.contentView.isOpaque = true
        self.contentView.backgroundColor = .custom.background
        self.backgroundColor = .custom.background
        
        bgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bgView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        titleLabel.textColor = .custom.mediumContrast
        titleLabel.isOpaque = true
        titleLabel.backgroundColor = .custom.background
        bgView.addSubview(titleLabel)
        
        self.configure()
        titleLabel.isHidden = false
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.isHidden = true
        bgView.addSubview(loadingIndicator)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "bgView" : bgView,
            "titleLabel" : titleLabel,
            "loadingIndicator" : loadingIndicator,
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[titleLabel]-20-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[titleLabel]-12-|", options: [], metrics: nil, views: viewsDict))
        
        loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[loadingIndicator]-12-|", options: [], metrics: nil, views: viewsDict))
    }
    
    public func configure(label: String = "Load older posts") {
        titleLabel.text = label
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            titleLabel.isHidden = true
            loadingIndicator.isHidden = false
            loadingIndicator.startAnimating()
        } else {
            titleLabel.isHidden = false
            loadingIndicator.isHidden = true
            loadingIndicator.stopAnimating()
        }
    }
}
