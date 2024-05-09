//
//  PostCardMetadata.swift
//  Mammoth
//
//  Created by Benoit Nolens on 27/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class PostCardMetadata: UIView {
    
    private enum MetricButtons: Int {
        case likes
        case reposts
        case replies
    }
    
    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 8
        stackView.isOpaque = true
        stackView.layoutMargins = .zero
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return stackView
    }()
    var heightConstraint: NSLayoutConstraint?
    
    private let metricsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        return stack
    }()
    
    private static func createLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        label.textColor = UIColor.custom.feintContrast
        label.isUserInteractionEnabled = true
        label.isOpaque = true
        return label
    }
    
    private var likesLabel: UILabel = createLabel()
    private var repostsLabel: UILabel = createLabel()
    private var repliesLabel: UILabel = createLabel()
    private var applicationLabel: UILabel = {
        let label = PostCardMetadata.createLabel()
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()
    private var viewDetailsLabel: UILabel = createLabel()
    
    private var onButtonPress: PostCardButtonCallback?
    private var isPrivateMention = false
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        self.onButtonPress = nil
    }
    
    func setupUIFromSettings() {
        self.likesLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        self.repostsLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        self.repliesLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        self.applicationLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        self.viewDetailsLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
    }
    
    private func setupUI() {
        self.addSubview(mainStackView)
        self.layoutMargins = .zero
        
        heightConstraint = mainStackView.heightAnchor.constraint(equalToConstant: 23)
        heightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
        ])
        
        mainStackView.addArrangedSubview(metricsStackView)
        
        likesLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        likesLabel.tag = MetricButtons.likes.rawValue
        repostsLabel.tag = MetricButtons.reposts.rawValue
        repliesLabel.tag = MetricButtons.replies.rawValue
        
        likesLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onMetricPress)))
        repostsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onMetricPress)))
        repliesLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onMetricPress)))
        
        metricsStackView.addArrangedSubview(likesLabel)
        metricsStackView.addArrangedSubview(repostsLabel)
        metricsStackView.addArrangedSubview(repliesLabel)
        
        viewDetailsLabel.text = NSLocalizedString("post.viewDetails", comment: "Shows up under a post in the timeline.")
        metricsStackView.addArrangedSubview(viewDetailsLabel)
        
        self.setupUIFromSettings()
        self.onThemeChange()
    }
    
    func configure(postCard: PostCardModel, type: PostCardCell.PostCardCellType = .regular, onButtonPress: @escaping PostCardButtonCallback) {
        self.onButtonPress = onButtonPress
        let shouldUpdateTheme = self.isPrivateMention != postCard.isPrivateMention
        self.isPrivateMention = postCard.isPrivateMention
        
        if type.shouldShowSourceAndApplicationName {
            heightConstraint?.isActive = false
            var description = postCard.source
            if !description.isEmpty {
                description += " - "
            }
            description += String.localizedStringWithFormat(NSLocalizedString("post.via", comment: "'via Mammoth' or other apps"), postCard.applicationName ?? NSLocalizedString("post.via.unknown", comment: "placeholder for when the app name wasn't found."), postCard.visibility ?? "")
            self.applicationLabel.text = description
            if !self.mainStackView.arrangedSubviews.contains(applicationLabel) {
                self.mainStackView.insertArrangedSubview(applicationLabel, at: 0)
            }
        } else {
            if self.mainStackView.arrangedSubviews.contains(applicationLabel) {
                self.mainStackView.removeArrangedSubview(applicationLabel)
                applicationLabel.removeFromSuperview()
            }
        }
        
        let like_localized = postCard.likeCount == "1" ? "post.likeCount.singular" : "post.likeCount.plural"
        likesLabel.text = String.localizedStringWithFormat(NSLocalizedString(like_localized, comment: ""), postCard.likeCount)
        let reply_localized = postCard.replyCount == "1" ? "post.replyCount.singular" : "post.replyCount.plural"
        repliesLabel.text = String.localizedStringWithFormat(NSLocalizedString(reply_localized, comment: ""), postCard.replyCount)
        let repost_localized = postCard.repostCount == "1" ? "post.repostCount.singular" : "post.repostCount.plural"
        repostsLabel.text = String.localizedStringWithFormat(NSLocalizedString(repost_localized, comment: ""), postCard.repostCount)
        
        if postCard.likeCount == "0" {
            likesLabel.isHidden = true
        } else {
            likesLabel.isHidden = false
        }
        
        if postCard.replyCount == "0" {
            repliesLabel.isHidden = true
        } else {
            repliesLabel.isHidden = false
        }
        
        if postCard.repostCount == "0" {
            repostsLabel.isHidden = true
        } else {
            repostsLabel.isHidden = false
        }
        
        // show "view details" label if needed
        if type.shouldShowDetailedMetrics && type != .detail {
            if postCard.likeCount == "0" && postCard.replyCount == "0" && postCard.repostCount == "0" {
                viewDetailsLabel.isHidden = false
            } else {
                viewDetailsLabel.isHidden = true
            }
        } else {
            viewDetailsLabel.isHidden = true
        }
        
        if shouldUpdateTheme {
            self.onThemeChange()
        }
    }
    
    @objc private func onMetricPress(recognizer: UIGestureRecognizer) {
        if recognizer.view?.tag == MetricButtons.likes.rawValue {
            self.onButtonPress?(.likes, false, nil)
        }
        
        if recognizer.view?.tag == MetricButtons.reposts.rawValue {
            self.onButtonPress?(.reposts, false, nil)
        }
        
        if recognizer.view?.tag == MetricButtons.replies.rawValue {
            self.onButtonPress?(.replies, false, nil)
        }
    }
    
    public func onThemeChange() {
        let backgroundColor: UIColor = isPrivateMention ? .custom.OVRLYSoftContrast : .custom.background
        likesLabel.textColor = .custom.feintContrast
        likesLabel.backgroundColor = backgroundColor
        repostsLabel.textColor = .custom.feintContrast
        repostsLabel.backgroundColor = backgroundColor
        repliesLabel.textColor = .custom.feintContrast
        repliesLabel.backgroundColor = backgroundColor
        applicationLabel.textColor = .custom.feintContrast
        applicationLabel.backgroundColor = backgroundColor
        viewDetailsLabel.textColor = .custom.feintContrast
        viewDetailsLabel.backgroundColor = backgroundColor
        mainStackView.backgroundColor = backgroundColor
        metricsStackView.backgroundColor = backgroundColor
        self.backgroundColor = backgroundColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Update all items that use .custom colors
        self.onThemeChange()
    }

}

// MARK: - Estimated height
extension PostCardMetadata {
    static func estimatedHeight() -> CGFloat {
        return 23
    }
}
