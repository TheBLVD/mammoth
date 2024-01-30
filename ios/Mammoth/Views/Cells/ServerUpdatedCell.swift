//
//  ServerUpdatedCell.swift
//  Mammoth
//
//  Created by Riley Howard on 10/23/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

protocol UpdatedCellDelegate: AnyObject {
    func didTapRefresh()
}

class ServerUpdatedCell: UITableViewCell {
    
    static let reuseIdentifier = "ServerUpdatedCell"
    
    private var bgView = UIView()
    private var topLineView = UIView()
    private var titleLabel = UILabel()
    private var refreshButton = UIButton()
    weak var delegate: UpdatedCellDelegate?

    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.isOpaque = true
        self.contentView.isOpaque = true
        self.contentView.backgroundColor = .custom.OVRLYSoftContrast
        self.backgroundColor = .custom.background
        
        bgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bgView)
        
        topLineView.translatesAutoresizingMaskIntoConstraints = false
        topLineView.backgroundColor = UITableView().separatorColor
        contentView.addSubview(topLineView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .left
        titleLabel.textColor = .custom.mediumContrast
        titleLabel.text = "Your changes are ready"
        titleLabel.font = .systemFont(ofSize: 15)
        bgView.addSubview(titleLabel)
        
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.setTitle("Refresh", for: .normal)
        refreshButton.setTitleColor(.custom.highContrast, for: .normal)
        let titleFont = UIFont.systemFont(ofSize: 15)
        let attributedTitle = NSAttributedString(string: "Refresh", attributes: [NSAttributedString.Key.font: titleFont])
        refreshButton.setAttributedTitle(attributedTitle, for: .normal)
        refreshButton.addTarget(self, action: #selector(self.refreshTap), for: .touchUpInside)
        bgView.addSubview(refreshButton)

        let viewsDict = [
            "bgView" : bgView,
            "topLineView" : topLineView,
            "titleLabel" : titleLabel,
            "refreshButton" : refreshButton
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
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[titleLabel]", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[titleLabel]-12-|", options: [], metrics: nil, views: viewsDict))
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[refreshButton]-20-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[refreshButton]-12-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func refreshTap() {
        self.delegate?.didTapRefresh()
    }

}
