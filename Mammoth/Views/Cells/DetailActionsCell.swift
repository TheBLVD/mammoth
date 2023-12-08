//
//  DetailActionsCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 28/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class DetailActionsCell: UITableViewCell {
    
    var bgView = UIView()
    let replies = CustomButton()
    var repostsImage = UIImageView()
    let repostsText = UILabel()
    let repostsStack = CustomStackView()
    let reposts = UIButton(type: .custom)
    let likes = CustomButton()
    let bookmark = CustomButton()
    let stackView = UIStackView()
    var data: Status?
    
    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        bgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bgView)
        
        // replies
        replies.setImage(UIImage(systemName: "arrowshape.turn.up.left", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal), for: .normal)
        replies.bounds.size.width = 80
        replies.bounds.size.height = 80
        replies.accessibilityLabel = "Reply"
        
        // reposts
        repostsImage.image = UIImage(systemName: "arrow.2.squarepath", withConfiguration: symbolConfig)?.withTintColor(.custom.actionButtons, renderingMode: .alwaysOriginal)
        repostsImage.contentMode = .scaleAspectFit
        replies.bounds.size.width = 80
        replies.bounds.size.height = 80
        repostsText.accessibilityLabel = "Repost or Quote Post"

        // Put the repost icon and count in a stack view,
        // and then put that inside the repostsB button
        repostsStack.addArrangedSubview(repostsImage)
        repostsStack.addArrangedSubview(repostsText)
        repostsStack.alignment = .center
        repostsStack.axis = .horizontal
        repostsStack.distribution = .equalSpacing
        repostsStack.spacing = 4
        repostsStack.isUserInteractionEnabled = false
        repostsStack.isAccessibilityElement = false
        repostsStack.translatesAutoresizingMaskIntoConstraints = false
        reposts.addSubview(repostsStack)
        // Line up the edges of the button with the stack inside it
        reposts.translatesAutoresizingMaskIntoConstraints = false
        reposts.addConstraints( [
            reposts.leftAnchor.constraint(equalTo: repostsStack.leftAnchor),
            reposts.topAnchor.constraint(equalTo: repostsStack.topAnchor),
            reposts.bottomAnchor.constraint(equalTo: repostsStack.bottomAnchor),
            reposts.rightAnchor.constraint(equalTo: repostsStack.rightAnchor)
        ])
        
        // likes
        likes.setImage(UIImage(systemName: "heart", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal), for: .normal)
        likes.bounds.size.width = 80
        likes.bounds.size.height = 80
        likes.accessibilityLabel = "Like"
        
        // bookmark
        bookmark.setImage(FontAwesome.image(fromChar: "\u{f02e}").withConfiguration(symbolConfig).withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal), for: .normal)
        bookmark.bounds.size.width = 80
        bookmark.bounds.size.height = 80
        bookmark.accessibilityLabel = "Bookmark"
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(replies)
        stackView.addArrangedSubview(reposts)
        stackView.addArrangedSubview(likes)
        stackView.addArrangedSubview(bookmark)
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = 2
        bgView.addSubview(stackView)
        
        let viewsDict = [
            "bgView" : bgView,
            "stackView" : self.stackView,
        ]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
#if targetEnvironment(macCatalyst)
        if GlobalStruct.singleColumn {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-85-[bgView]-85-|", options: [], metrics: nil, views: viewsDict))
        } else {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        }
#elseif !targetEnvironment(macCatalyst)
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && self.window?.traitCollection.horizontalSizeClass != .compact {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-85-[bgView]-85-|", options: [], metrics: nil, views: viewsDict))
        } else {
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        }
#endif
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-30-[stackView]-30-|", options: [], metrics: nil, views: viewsDict))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[stackView]-12-|", options: [], metrics: nil, views: viewsDict))
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.data = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
