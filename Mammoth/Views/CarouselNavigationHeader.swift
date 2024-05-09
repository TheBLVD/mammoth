//
//  CarouselNavigationHeader.swift
//  Mammoth
//
//  Created by Benoit Nolens on 12/10/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

import UIKit

class CarouselNavigationHeader: UIView {

    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.backgroundColor = .clear
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.isBaselineRelativeArrangement = true
        stackView.distribution = .fill
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    public let title: NavigationBarTitle
    public let carousel: Carousel = Carousel(withContextButton: false)

    init(title: String) {
        self.title = NavigationBarTitle(title: title)
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI
private extension CarouselNavigationHeader {
    func setupUI() {
        self.backgroundColor = .clear

        title.translatesAutoresizingMaskIntoConstraints = false
        title.clipsToBounds = false
        carousel.translatesAutoresizingMaskIntoConstraints = false
        
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
        } else {
            self.layoutMargins = .init(top: 9, left: 16, bottom: 0, right: 16)
        }
        
        if let text = self.title.titleLabel.text, !text.isEmpty {
            titleStackView.addArrangedSubview(title)
            mainStackView.addArrangedSubview(titleStackView)
            
            NSLayoutConstraint.activate([
                title.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor),
                title.heightAnchor.constraint(equalToConstant: 28),
            ])
        }
        
        mainStackView.addArrangedSubview(carousel)

        self.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
            mainStackView.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor),

            carousel.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor, constant: -3),
            carousel.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor, constant:  3),
            carousel.heightAnchor.constraint(equalToConstant: 36),
        ])
    }
}
