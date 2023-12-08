//
//  ServerUpdatingCell.swift
//  Mammoth
//
//  Created by Riley Howard on 10/23/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class ServerUpdatingCell: UITableViewCell {
    
    class var reuseIdentifier: String{ return "ServerUpdatingCell" }
    private var bgView = UIView()
    private var topLineView = UIView()
    var titleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.isOpaque = true
        self.contentView.isOpaque = true
        self.contentView.backgroundColor = .custom.background
        self.backgroundColor = .custom.background
        
        bgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bgView)
        
        topLineView.translatesAutoresizingMaskIntoConstraints = false
        topLineView.backgroundColor = UITableView().separatorColor
        contentView.addSubview(topLineView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        titleLabel.textColor = .custom.feintContrast
        titleLabel.text = "Updating your timeline…"
        titleLabel.font = .systemFont(ofSize: 15)
        bgView.addSubview(titleLabel)
        
        let viewsDict = [
            "bgView" : bgView,
            "topLineView" : topLineView,
            "titleLabel" : titleLabel,
        ]
        let contentViewFrame = contentView.frame
        let metricsDict = [
            "sideMargin" : -contentViewFrame.origin.x,
            "topMargin" : -contentViewFrame.origin.y
        ]
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-sideMargin-[topLineView]-sideMargin-|", options: [], metrics: metricsDict, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-topMargin-[topLineView(0.5)]", options: [], metrics: metricsDict, views: viewsDict))

        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-13-[titleLabel]-13-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-18-[titleLabel]-18-|", options: [], metrics: nil, views: viewsDict))
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
