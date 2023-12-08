//
//  ProfileSectionHeader.swift
//  Mammoth
//
//  Created by Benoit Nolens on 13/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

protocol ProfileSectionHeaderDelegate: AnyObject {
    func didChangeSegment(with selectedSegment: ProfileViewModel.ViewTypes)
}

class ProfileSectionHeader: UITableViewHeaderFooterView {
    static let reuseIdentifier = "ProfileSectionHeader"
    
    private let segmentedControl = UISegmentedControl(items: ProfileViewModel.ViewTypes.allCases.map({ $0.labelText() }))
    weak var delegate: ProfileSectionHeaderDelegate?
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.segmentedControl.frame.size.height = 38.0
    }
}

// MARK: - Setup UI
private extension ProfileSectionHeader {
    func setupUI() {
        self.isOpaque = true
        self.contentView.backgroundColor = .custom.background
        
        self.segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        self.segmentedControl.selectedSegmentIndex = 0
        self.segmentedControl.tintColor = .custom.baseTint
        
        self.addSubview(self.segmentedControl)
        self.segmentedControl.addTarget(self, action: #selector(self.segmentedValueChanged(_:)), for: .valueChanged)

        NSLayoutConstraint.activate([
            segmentedControl.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -1),
            segmentedControl.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 14),
            segmentedControl.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -14)
        ])
    }
}

// MARK: - Configuration
extension ProfileSectionHeader {
    func configure(labelText: String) {
        
    }
    
    func onThemeChange() {
        self.contentView.backgroundColor = .custom.background
        self.segmentedControl.tintColor = .custom.baseTint
    }
}

// MARK: - Handlers
extension ProfileSectionHeader {
    @objc func segmentedValueChanged(_ sender:UISegmentedControl!) {
        if let selected = ProfileViewModel.ViewTypes(rawValue: sender.selectedSegmentIndex) {
            self.delegate?.didChangeSegment(with: selected)
        }
    }
}
