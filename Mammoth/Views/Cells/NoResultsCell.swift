//
//  NoResultsCell.swift
//  Mammoth
//
//  Created by Riley Howard on 9/29/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class NoResultsCell: UITableViewCell {
    static let reuseIdentifier = "NoResultsCell"
    
    // MARK: - Properties
    
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("generic.noResults", comment: "")
        label.textColor = .custom.feintContrast
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.selectionStyle = .none
        self.separatorInset = .zero
        self.layoutMargins = .zero
        self.contentView.preservesSuperviewLayoutMargins = false
        self.contentView.backgroundColor = .custom.background
        
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor, constant: 3),
        ])
        setupUIFromSettings()
    }
    
    func setupUIFromSettings() {
        titleLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize - 2 + GlobalStruct.customTextSize, weight: .semibold)
    }
    
}

