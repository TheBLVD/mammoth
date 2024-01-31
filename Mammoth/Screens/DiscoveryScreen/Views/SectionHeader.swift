//
//  SectionHeader.swift
//  Mammoth
//
//  Created by Benoit Nolens on 12/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

protocol SectionHeaderDelegate: AnyObject {
    func userTappedButton(context: Int)
}

class SectionHeader: UIView {
    
    weak var delegate: SectionHeaderDelegate? = nil
    var delegateContext: Int = 0
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .medium)
        label.textColor = .custom.mediumContrast
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Optional button
    lazy var button: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.custom.softContrast, for: .normal)
        return button
    }()
    
    // a nil title implies no button
    init(buttonTitle: String?) {
        super.init(frame: .zero)
        self.setupUI(buttonTitle: buttonTitle)
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI
private extension SectionHeader {
    func setupUI(buttonTitle: String?) {
        self.backgroundColor = .custom.OVRLYSoftContrast
        self.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -12),
        ])
        
        if buttonTitle != nil {
            self.button.setTitle(buttonTitle, for: .normal)
            self.addSubview(button)
            NSLayoutConstraint.activate([
                button.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                button.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
                button.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: 12),
            ])
            button.addTarget(self, action: #selector(self.buttonTapped), for: .touchUpInside)
        }
    }
}

// MARK: - Configuration
extension SectionHeader {
    func configure(labelText: String) {
        self.label.text = labelText
    }
}

// MARK: - Actions

extension SectionHeader {
    @objc func buttonTapped() {
        triggerHapticImpact(style: .light)
        delegate?.userTappedButton(context: delegateContext)
    }
}

// MARK: - Appearance changes
internal extension SectionHeader {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 self.backgroundColor = .custom.OVRLYSoftContrast
                 label.textColor = .custom.mediumContrast
                 button.setTitleColor(.custom.softContrast, for: .normal)
             }
         }
    }
}
