//
//  EmptyFeedCell.swift
//  Mammoth
//
//  Created by Benoit Nolens on 23/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class EmptyFeedCell: UITableViewCell {
    static let reuseIdentifier = "EmptyFeedCell"
    
    private let mainStack: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.spacing = 30
        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let backgroundGraphic = UIImageView(image: UIImage(systemName: "sparkles",
                                                                withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular))?.withTintColor(UIColor.secondaryLabel.withAlphaComponent(0.18), renderingMode: .alwaysOriginal))
    
    private var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 3, weight: .light)
        label.textColor = UIColor.secondaryLabel
        label.numberOfLines = 3
        label.textAlignment = .center
        label.isOpaque = true
        return label
    }()
    
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
        
        contentView.addSubview(mainStack)
        
        backgroundGraphic.translatesAutoresizingMaskIntoConstraints = false
        
        mainStack.addArrangedSubview(backgroundGraphic)
        mainStack.addArrangedSubview(label)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 70),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            backgroundGraphic.widthAnchor.constraint(equalToConstant: 80),
            backgroundGraphic.heightAnchor.constraint(equalToConstant: 80),
        ])
    }
    
    func configure(label: String? = nil) {
        self.backgroundColor = .custom.background
        self.contentView.backgroundColor = .custom.background
        
        if let label = label {
            self.label.text = label
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
