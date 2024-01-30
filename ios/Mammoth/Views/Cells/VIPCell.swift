//
//  VIPCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 15/12/3622.
//

import Foundation
import UIKit

class VIPCell: UITableViewCell {
    
    var titleText = UILabel()
    var valueText = UILabel()
    
    var profile1 = UIButton()
    var profile2 = UIButton()
    var profile3 = UIButton()
    var profile4 = UIButton()
    var profile5 = UIButton()
    var profile6 = UIButton()
    
    var profileMore = UIButton()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        titleText.translatesAutoresizingMaskIntoConstraints = false
        titleText.text = ""
        titleText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        titleText.textAlignment = .left
        titleText.textColor = .label
        contentView.addSubview(titleText)
        
        valueText.translatesAutoresizingMaskIntoConstraints = false
        valueText.text = ""
        valueText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular)
        valueText.textAlignment = .left
        valueText.textColor = .secondaryLabel
        valueText.numberOfLines = 0
        contentView.addSubview(valueText)
        
        profile1.translatesAutoresizingMaskIntoConstraints = false
        profile1.backgroundColor = .custom.quoteTint
        profile1.layer.cornerRadius = 18
        profile1.layer.masksToBounds = true
        contentView.addSubview(profile1)
        
        profile2.translatesAutoresizingMaskIntoConstraints = false
        profile2.backgroundColor = .custom.quoteTint
        profile2.layer.cornerRadius = 18
        profile2.layer.masksToBounds = true
        contentView.addSubview(profile2)
        
        profile3.translatesAutoresizingMaskIntoConstraints = false
        profile3.backgroundColor = .custom.quoteTint
        profile3.layer.cornerRadius = 18
        profile3.layer.masksToBounds = true
        contentView.addSubview(profile3)
        
        profile4.translatesAutoresizingMaskIntoConstraints = false
        profile4.backgroundColor = .custom.quoteTint
        profile4.layer.cornerRadius = 18
        profile4.layer.masksToBounds = true
        contentView.addSubview(profile4)
        
        profile5.translatesAutoresizingMaskIntoConstraints = false
        profile5.backgroundColor = .custom.quoteTint
        profile5.layer.cornerRadius = 18
        profile5.layer.masksToBounds = true
        contentView.addSubview(profile5)
        
        profile6.translatesAutoresizingMaskIntoConstraints = false
        profile6.backgroundColor = .custom.quoteTint
        profile6.layer.cornerRadius = 18
        profile6.layer.masksToBounds = true
        contentView.addSubview(profile6)
        
        profileMore.translatesAutoresizingMaskIntoConstraints = false
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        profileMore.setImage(UIImage(systemName: "plus", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysTemplate), for: .normal)
        profileMore.backgroundColor = .custom.backgroundTint
        profileMore.layer.cornerRadius = 18
        profileMore.layer.masksToBounds = true
        contentView.addSubview(profileMore)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "titleText" : titleText,
            "valueText" : valueText,
            "profile1" : profile1,
            "profile2" : profile2,
            "profile3" : profile3,
            "profile4" : profile4,
            "profile5" : profile5,
            "profile6" : profile6,
            "profileMore" : profileMore,
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-18-[titleText]-18-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-18-[valueText]-18-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-18-[profile1(36)]-5-[profile2(36)]-5-[profile3(36)]-5-[profile4(36)]-5-[profile5(36)]-5-[profile6(36)]-5-[profileMore(36)]-(>=18)-|", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[titleText]-2-[valueText]-6-[profile1(36)]-8-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[titleText]-2-[valueText]-6-[profile2(36)]-8-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[titleText]-2-[valueText]-6-[profile3(36)]-8-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[titleText]-2-[valueText]-6-[profile4(36)]-8-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[titleText]-2-[valueText]-6-[profile5(36)]-8-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[titleText]-2-[valueText]-6-[profile6(36)]-8-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[titleText]-2-[valueText]-6-[profileMore(36)]-8-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
