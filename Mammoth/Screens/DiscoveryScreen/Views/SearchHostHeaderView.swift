//
//  SearchHostHeaderView.swift
//  Mammoth
//
//  Created by Riley Howard on 8/31/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class SearchHostHeaderView: UIView {

    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 4.0
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    lazy var carousel: Carousel = {
        let carousel = Carousel(withContextButton: false)
        return carousel
    }()
    
    lazy var searchBar: UISearchBar = {
        return UISearchBar()
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI
private extension SearchHostHeaderView {
    func setupUI() {
        self.backgroundColor = .clear

        searchBar.placeholder = NSLocalizedString("discover.search", comment: "")
        searchBar.searchBarStyle = .minimal

        mainStackView.addArrangedSubview(searchBar)
        mainStackView.addArrangedSubview(carousel)

        self.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            mainStackView.topAnchor.constraint(equalTo: self.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            searchBar.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 50),

            carousel.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor, constant: 16),
            carousel.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor, constant:  -16),
            carousel.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
}

extension SearchHostHeaderView {
    
    func hideCarousel(_ hideCarousel: Bool) {
        carousel.isHidden = hideCarousel
    }
    
}
