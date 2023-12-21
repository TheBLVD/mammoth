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
    
    var bgButton = UIButton()
    var txtLabel = UILabel()
    var txtLabel2 = UILabel()
    var imageV = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        bgButton.translatesAutoresizingMaskIntoConstraints = false
        bgButton.backgroundColor = .custom.quoteTint
        contentView.addSubview(bgButton)
        
        txtLabel.translatesAutoresizingMaskIntoConstraints = false
        txtLabel.textColor = UIColor.label
        txtLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
        txtLabel.backgroundColor = UIColor.clear
        contentView.addSubview(txtLabel)
        
        txtLabel2.translatesAutoresizingMaskIntoConstraints = false
        txtLabel2.textColor = UIColor.secondaryLabel
        txtLabel2.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
        txtLabel2.backgroundColor = UIColor.clear
        contentView.addSubview(txtLabel2)
        
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .title1).pointSize, weight: .regular)
        imageV.translatesAutoresizingMaskIntoConstraints = false
        imageV.image = UIImage(systemName: "mappin.and.ellipse", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
        imageV.backgroundColor = UIColor.clear
        imageV.contentMode = .scaleAspectFill
        contentView.addSubview(imageV)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "bgButton" : bgButton,
            "txtLabel" : txtLabel,
            "txtLabel2" : txtLabel2,
            "imageV" : imageV,
        ]
        let metricsDict = [
            "height" : UIFont.preferredFont(forTextStyle: .body).pointSize + 16
        ]
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[bgButton]-16-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-6-[bgButton]-6-|", options: [], metrics: metricsDict, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[imageV]-16-[txtLabel]-(>=16)-[txtLabel2]-16-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[txtLabel]-8-|", options: [], metrics: metricsDict, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[txtLabel2]-8-|", options: [], metrics: metricsDict, views: viewsDict))
        
        self.imageV.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

