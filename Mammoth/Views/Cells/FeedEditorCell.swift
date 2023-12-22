//
//  FeedEditorCell.swift
//  Mammoth
//
//  Created by Benoit Nolens on 14/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class FeedEditorCell: UITableViewCell {
    static let reuseIdentifier = "FeedEditorCell"
    
    public enum FeedEditorCellButtonActions {
        case enable
        case disable
        case delete
    }
    
    typealias FeedEditorCellButtonCallback = (_ item: FeedTypeItem,
                                        _ action: FeedEditorCellButtonActions) -> Void
    
    // MARK: - Properties
    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.isBaselineRelativeArrangement = true
        stackView.spacing = 20.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.image = UIImage()
        iconView.contentMode = .left
        iconView.translatesAutoresizingMaskIntoConstraints = false
        return iconView
    }()
    
    private var rightAccessories: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .trailing
        stackView.isBaselineRelativeArrangement = true
        stackView.distribution = .fill
        stackView.semanticContentAttribute = .forceRightToLeft
        stackView.spacing = 3.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()
    
    private var feedTypeItem: FeedTypeItem?
    private var onButtonPress: FeedEditorCellButtonCallback?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.feedTypeItem = nil
        self.onButtonPress = nil
        self.titleLabel.text = nil
        self.iconView.alpha = 1
        setupUIFromSettings()
        
        rightAccessories.arrangedSubviews.forEach({
            rightAccessories.removeArrangedSubview($0)
            $0.removeFromSuperview()
        })
    }
}

// MARK: - Setup UI
private extension FeedEditorCell {
    func setupUI() {
        self.selectionStyle = .none
        self.separatorInset = .zero
        self.layoutMargins = .zero
        self.contentView.preservesSuperviewLayoutMargins = false
        self.contentView.backgroundColor = .custom.background
        self.tintColor = .custom.highContrast
        self.contentView.layoutMargins = .init(top: 16, left: 13, bottom: 16, right: 13)
        
        mainStackView.backgroundColor = .clear
        self.contentView.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor)
        ])
        
        mainStackView.addArrangedSubview(iconView)
        mainStackView.addArrangedSubview(titleLabel)
        mainStackView.addArrangedSubview(rightAccessories)
        
        // Don't compress but let siblings fill the space
        rightAccessories.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
        rightAccessories.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 752), for: .horizontal)
        
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 12)
        ])
        
        iconView.image = FontAwesome.image(fromChar: "\u{e411}").withRenderingMode(.alwaysTemplate)
        iconView.tintColor = .custom.softContrast
        
        setupUIFromSettings()
    }
    
    func setupUIFromSettings() {
        titleLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .regular)
    }
}

// MARK: - Configuration
extension FeedEditorCell {
    func configure(feedTypeItem: FeedTypeItem, onButtonPress: @escaping FeedEditorCellButtonCallback) {
        self.feedTypeItem = feedTypeItem
        self.onButtonPress = onButtonPress
        
        if !feedTypeItem.isDraggable {
            self.iconView.alpha = 0
        }
        
        if feedTypeItem.isEnabled {
            if self.titleLabel.textColor != nil {
                self.titleLabel.textColor = nil
                self.titleLabel.attributedText = feedTypeItem.type.attributedTitle()
            }
            
            if feedTypeItem.isDraggable {
                // only draggable items can be disabled
                let button = UIButton(type: .custom)
                button.contentEdgeInsets = .init(top: 0, left: 6, bottom: 0, right: 6)
                button.contentMode = .center
                button.setImage(FontAwesome.image(fromChar: "\u{f056}", size: 21, weight: .regular).withRenderingMode(.alwaysTemplate), for: .normal)
                button.tintColor = .custom.highContrast
                rightAccessories.addArrangedSubview(button)

                button.addHandler { [weak self] in
                    guard let self, let feedTypeItem = self.feedTypeItem else { return }
                    self.onButtonPress?(feedTypeItem, .disable)
                }
            }
        } else {
            self.titleLabel.attributedText = feedTypeItem.type.attributedTitle()
            self.titleLabel.textColor = .custom.softContrast
            
            let button = UIButton(type: .custom)
            button.contentEdgeInsets = .init(top: 0, left: 6, bottom: 0, right: 6)
            button.contentMode = .center
            button.setImage(FontAwesome.image(fromChar: "\u{f055}", size: 21, weight: .bold).withRenderingMode(.alwaysTemplate), for: .normal)
            button.tintColor = .custom.highContrast
            rightAccessories.addArrangedSubview(button)

            button.addHandler { [weak self] in
                guard let self, let feedTypeItem = self.feedTypeItem else { return }
                self.onButtonPress?(feedTypeItem, .enable)
            }
                        
            switch feedTypeItem.type {
            case .community(let instance):
                if instance != AccountsManager.shared.currentUser()?.server {
                    fallthrough
                }
            case .hashtag, .list, .channel:
                let button = UIButton(type: .custom)
                button.contentEdgeInsets = .init(top: 0, left: 6, bottom: 0, right: 6)
                button.contentMode = .center
                button.setImage(FontAwesome.image(fromChar: "\u{e12e}", size: 21, weight: .bold).withRenderingMode(.alwaysTemplate), for: .normal)
                button.tintColor = .custom.destructive
                rightAccessories.addArrangedSubview(button)
                
                button.addHandler { [weak self] in
                    guard let self, let feedTypeItem = self.feedTypeItem else { return }
                    self.onButtonPress?(feedTypeItem, .delete)
                }
                
            default:
                break
            }
        }
        
        self.onThemeChange()
    }
    
    
    func onThemeChange() {
        self.contentView.backgroundColor = .custom.background
    }
    
    func showLoader() {
        rightAccessories.arrangedSubviews.forEach({
            rightAccessories.removeArrangedSubview($0)
            $0.removeFromSuperview()
        })
        
        let loader = UIActivityIndicatorView()
        loader.startAnimating()
        rightAccessories.addArrangedSubview(loader)
    }
}

// MARK: Actions
internal extension FeedEditorCell {
    
}

// MARK: Appearance changes
internal extension FeedEditorCell {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if (traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection)) {
                 self.onThemeChange()
             }
         }
    }
}

