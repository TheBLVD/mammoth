//
//  PollCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 09/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class PollCell: UITableViewCell {
    
    var pollItem = UITextField()
    var charCount = UILabel()
    var addButton = UIButton()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        pollItem.translatesAutoresizingMaskIntoConstraints = false
        pollItem.placeholder = "Option 1"
        pollItem.accessibilityLabel = "Option 1"
        pollItem.backgroundColor = .clear
        pollItem.text = ""
        pollItem.textColor = UIColor.label
        pollItem.isUserInteractionEnabled = true
        pollItem.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        pollItem.smartDashesType = .no
        contentView.addSubview(pollItem)
        
        charCount.translatesAutoresizingMaskIntoConstraints = false
        charCount.text = "25"
        charCount.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        charCount.textAlignment = .right
        charCount.textColor = .custom.baseTint
        contentView.addSubview(charCount)
        
        let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.backgroundColor = .clear
        addButton.layer.cornerRadius = 13
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: symbolConfig0)?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal), for: .normal)
        contentView.addSubview(addButton)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "pollItem" : pollItem,
            "charCount" : charCount,
            "addButton" : addButton,
        ]
        let metricsDict = [
            "width" : UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 32
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[pollItem]-15-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[pollItem(50)]-0-|", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=15)-[charCount]-16-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=15)-[addButton(26)]-(width)-|", options: [], metrics: metricsDict, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[charCount]", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-13-[addButton(26)]", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class PollCell2: UITableViewCell {
    
    var pollItem = UITextField()
    var charCount = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        pollItem.translatesAutoresizingMaskIntoConstraints = false
        pollItem.placeholder = "Option 1"
        pollItem.accessibilityLabel = "Option 1"
        pollItem.backgroundColor = .clear
        pollItem.text = ""
        pollItem.textColor = UIColor.label
        pollItem.isUserInteractionEnabled = true
        pollItem.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        pollItem.smartDashesType = .no
        contentView.addSubview(pollItem)
        
        charCount.translatesAutoresizingMaskIntoConstraints = false
        charCount.text = "25"
        charCount.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        charCount.textAlignment = .right
        charCount.textColor = .custom.baseTint
        charCount.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(charCount)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "pollItem" : pollItem,
            "charCount" : charCount,
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[pollItem]-(>=15)-[charCount]-16-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[pollItem(50)]-0-|", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[charCount]", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class PollDurationCell: UITableViewCell {
    
    var bgButton = UIButton()
    var titleText = UILabel()
    var valueText = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        bgButton.translatesAutoresizingMaskIntoConstraints = false
        bgButton.backgroundColor = .custom.quoteTint
        contentView.addSubview(bgButton)
        
        titleText.translatesAutoresizingMaskIntoConstraints = false
        titleText.text = "Duration"
        titleText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        titleText.textAlignment = .left
        titleText.textColor = .white
        contentView.addSubview(titleText)
        
        valueText.translatesAutoresizingMaskIntoConstraints = false
        valueText.text = "5 mins"
        valueText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .bold)
        valueText.textAlignment = .right
        valueText.textColor = .white
        contentView.addSubview(valueText)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "bgButton" : bgButton,
            "titleText" : titleText,
            "valueText" : valueText,
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[bgButton]-16-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-6-[bgButton]-6-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[titleText]-(>=15)-[valueText]-15-|", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[titleText]-8-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[valueText]-8-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class PollDurationCell2: UITableViewCell {
    
    var bgButton = UIButton()
    var image = UIImageView()
    var titleText = UILabel()
    var valueText = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        bgButton.translatesAutoresizingMaskIntoConstraints = false
        bgButton.backgroundColor = .custom.quoteTint
        contentView.addSubview(bgButton)
        
        image.translatesAutoresizingMaskIntoConstraints = false
        image.backgroundColor = .clear
        image.contentMode = .scaleAspectFit
        contentView.addSubview(image)
        
        titleText.translatesAutoresizingMaskIntoConstraints = false
        titleText.text = "Duration"
        titleText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        titleText.textAlignment = .left
        titleText.textColor = .white
        contentView.addSubview(titleText)
        
        valueText.translatesAutoresizingMaskIntoConstraints = false
        valueText.text = "5 mins"
        valueText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .bold)
        valueText.textAlignment = .right
        valueText.textColor = .white
        contentView.addSubview(valueText)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "bgButton" : bgButton,
            "image" : image,
            "titleText" : titleText,
            "valueText" : valueText,
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[bgButton]-16-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-6-[bgButton]-6-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[image(28)]-14-[titleText]-(>=15)-[valueText]-15-|", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[image]-8-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[titleText]-8-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[valueText]-8-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class ProfileFieldsCell: UITableViewCell {
    
    var title = ActiveLabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        title.translatesAutoresizingMaskIntoConstraints = false
        title.backgroundColor = .clear
        title.text = ""
        title.textColor = .custom.mainTextColor
        title.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        title.numberOfLines = 0
        title.enabledTypes = [.mention, .hashtag, .url, .email]
        title.mentionColor = .custom.mainTextColor
        title.hashtagColor = .custom.mainTextColor
        title.URLColor = .custom.mainTextColor
        title.emailColor = .custom.mainTextColor
        title.urlMaximumLength = 30
        contentView.addSubview(title)
        
        contentView.layer.masksToBounds = false
        
        let viewsDict = [
            "title" : title,
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[title]-15-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[title]-12-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
