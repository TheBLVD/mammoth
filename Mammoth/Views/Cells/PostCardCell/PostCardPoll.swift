//
//  PostCardPoll.swift
//  Mammoth
//
//  Created by Benoit Nolens on 06/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class PostCardPoll: UIView {
    
    // MARK: - Properties
    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 12.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.layer.borderWidth = 1.0 / UIScreen.main.scale
        stackView.layer.borderColor = UIColor.custom.outlines.cgColor
        stackView.layer.masksToBounds = true
        stackView.layer.cornerRadius = 6
        stackView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 11, leading: 10, bottom: 9, trailing: 10)
        
        return stackView
    }()
    
    private var optionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .equalSpacing
        stackView.spacing = 12.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var footerLabel: UILabel = {
        let label = UILabel()
        label.textColor = .custom.softContrast
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()
    
    private var optionsTrailingConstraints: [NSLayoutConstraint] = []
    
    private var postCard: PostCardModel? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        self.optionsStackView.arrangedSubviews.forEach {
            self.optionsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        NSLayoutConstraint.deactivate(self.optionsTrailingConstraints)
        self.optionsTrailingConstraints = []
    }
}

// MARK: - Setup UI
private extension PostCardPoll {
    func setupUI() {
        self.isHidden = true
        self.isOpaque = true
        self.addSubview(mainStackView)
        
        mainStackView.addArrangedSubview(optionsStackView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 9),
            mainStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            optionsStackView.widthAnchor.constraint(equalTo: self.mainStackView.widthAnchor, constant: -(mainStackView.directionalLayoutMargins.leading + mainStackView.directionalLayoutMargins.trailing))
        ])
        
        mainStackView.addArrangedSubview(footerLabel)
    }
}

// MARK: - Configuration
extension PostCardPoll {
    func configure(postCard: PostCardModel) {
        self.postCard = postCard
        
        if let poll = postCard.poll {
            // sanity check if an option was removed
            while poll.options.count < self.optionsStackView.arrangedSubviews.count {
                self.optionsStackView.removeArrangedSubview(optionsStackView.arrangedSubviews.last!)
                self.optionsTrailingConstraints.removeLast()
            }
            
            // update every poll option.
            poll.options.enumerated().forEach { (index, pollOption) in
                let data = PostCardPollOption.PollOption(index: index,
                                                         title: pollOption.title.trimmingCharacters(in: .whitespacesAndNewlines),
                                                         percentage: Float(pollOption.votesCount ?? 0) / Float(max(poll.votesCount, 1)),
                                                         isActive: !poll.expired
                )
                
                let optionView = PostCardPollOption(option: data, onTap: { [weak self] option in
                    // On vote tap
                    PostActions.onVote(postCard: postCard, choices: [option.index])
                    
                    guard let self else { return }
                    self.updateOnVote(voteOptionIndex: data.index)
                })
                
                // sanity check if an option was added
                if index < optionsStackView.arrangedSubviews.count {
                    // update poll
                    for (otherIndex, view) in optionsStackView.arrangedSubviews.enumerated() {
                        if let currentOptionView = view as? PostCardPollOption, index == otherIndex  {
                            currentOptionView.update(option: data)
                        }
                    }
                } else {
                    optionsStackView.addArrangedSubview(optionView)
                    self.optionsTrailingConstraints.append(optionView.trailingAnchor.constraint(equalTo: optionsStackView.trailingAnchor))
                }
            }
            
            NSLayoutConstraint.activate(self.optionsTrailingConstraints)
            
            let numOfVotesString = "\(poll.votesCount.withCommas()) vote\(poll.votesCount == 1 ? "" : "s")"
            footerLabel.text = "\(numOfVotesString) • Poll \(self.readableDate(withDateString: poll.expiresAt ?? ""))"
            
            self.isHidden = false
        }
    }
    
    private func updateOnVote(voteOptionIndex: Int) {
        self.optionsStackView.arrangedSubviews.enumerated().forEach { (index, view) in
            if let optionView = view as? PostCardPollOption,
                let poll = self.postCard?.poll,
                poll.options.count >= index {
                
                let option = poll.options[index]
                // Optimistically add 1 vote to the right poll option for animation
                let data = PostCardPollOption.PollOption(index: index,
                                                         title: option.title.trimmingCharacters(in: .whitespacesAndNewlines),
                                                         percentage: Float(((option.votesCount ?? 0) + (voteOptionIndex == index ? 1 : 0))) / Float((poll.votesCount + 1)),
                                                           isActive: !poll.expired
                )
                
                optionView.update(option: data)
            }
        }
    }
    
    func onThemeChange() {
        self.mainStackView.layer.borderColor = UIColor.custom.outlines.cgColor
        
        self.optionsStackView.subviews.forEach { option in
            if let option = option as? PostCardPollOption {
                option.onThemeChange()
            }
        }
    }
}

// MARK: - Formatters
private extension PostCardPoll {
    func readableDate(withDateString dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = GlobalStruct.dateFormat
        let date = dateFormatter.date(from: dateString)
        
        var diff = getMinutesDifferenceFromTwoDates(start: Date(), end: date ?? Date())
        var mVote = "\(diff) minutes"
        var tText = "ends in"
        var tText2 = ""
        
        if diff == 1 {
            mVote = "\(diff) minute"
        }
        if diff > 60 {
            diff /= 60
            mVote = "\(diff) hours"
            if diff == 1 {
                mVote = "\(diff) hour"
            }
        } else if diff < 0 {
            tText = "ended"
            tText2 = "ago"
            diff *= -1
            mVote = "\(diff) minutes"
            if diff == 1 {
                mVote = "\(diff) minute"
            }
            if diff > 60 {
                diff /= 60
                mVote = "\(diff) hours"
                if diff == 1 {
                    mVote = "\(diff) hour"
                }
                if diff > 24 {
                    diff /= 24
                    mVote = "\(diff) days"
                    if diff == 1 {
                        mVote = "\(diff) day"
                    }
                    if diff > 30 {
                        diff /= 30
                        mVote = "\(diff) months"
                        if diff == 1 {
                            mVote = "\(diff) month"
                        }
                    }
                }
            }
        }
        
        return "\(tText) \(mVote) \(tText2)"
    }
}

fileprivate class PostCardPollOption: UIStackView {
    
    private var optionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.setTitleColor( .custom.pollBarText, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        button.titleLabel?.textAlignment = .left
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var optionResult: UILabel = {
        let label = UILabel()
        label.textColor = .custom.softContrast
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .right
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isOpaque = true
        label.backgroundColor = .custom.background
        
        return label
    }()
    
    private var optionBar: UIView = {
        let bar = UIView()
        bar.backgroundColor = .custom.pollBars
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.isUserInteractionEnabled = false
        bar.layer.cornerRadius = 6
        bar.layer.masksToBounds = true
        return bar
    }()
    
    private var barWidthConstraint: NSLayoutConstraint? = nil
    
    struct PollOption {
        var index: Int
        var title: String
        var percentage: Float
        var isActive: Bool
    }
    
    typealias PollOptionTapCallback = (_ option: PollOption) -> Void
    private let option: PollOption?
    private let tapCallback: PollOptionTapCallback?
    
    init(option: PollOption, onTap: @escaping PollOptionTapCallback) {
        self.option = option
        self.tapCallback = onTap
        super.init(frame: .zero)
        self.setupUI()
    }
    
    override init(frame: CGRect) {
        self.option = nil
        self.tapCallback = nil
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.axis = .horizontal
        self.alignment = .center
        self.distribution = .fill
        self.spacing = 10.0
        self.isLayoutMarginsRelativeArrangement = true
        self.translatesAutoresizingMaskIntoConstraints = false
        
        if let option = self.option, option.isActive {
            self.optionButton.addTarget(self, action: #selector(self.onTapped), for: .touchUpInside)
        } else {
            self.optionButton.isUserInteractionEnabled = false
        }
        
        // Don't compress but let siblings fill the space
        optionResult.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
        optionResult.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        
        // Set a minimum width to the option result
        optionResult.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        
        self.optionButton.setTitle(self.option?.title ?? "", for: .normal)
        self.optionResult.text = "\(Int((self.option?.percentage ?? 0) * 100))%"
        
        self.optionButton.insertSubview(self.optionBar, at: 0)
        self.optionBar.heightAnchor.constraint(equalTo: self.optionButton.heightAnchor).isActive = true
        
        self.barWidthConstraint = self.optionBar.widthAnchor.constraint(equalTo: self.optionButton.widthAnchor, multiplier: CGFloat(self.option?.percentage ?? 0), constant: 0)
        self.barWidthConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            self.optionBar.centerYAnchor.constraint(equalTo: self.optionButton.centerYAnchor),
            self.optionBar.leadingAnchor.constraint(equalTo: self.optionButton.leadingAnchor)
        ])
        
        self.addArrangedSubview(optionButton)
        self.addArrangedSubview(optionResult)
    }
    
    func update(option: PollOption) {
        
        if self.barWidthConstraint != nil {
            self.barWidthConstraint?.isActive = false
            self.barWidthConstraint = nil
        }
        
        self.barWidthConstraint = self.optionBar.widthAnchor.constraint(equalTo: self.optionButton.widthAnchor, multiplier: CGFloat(option.percentage), constant: 0)
        self.barWidthConstraint?.isActive = true
        self.optionResult.text = "\(Int(option.percentage * 100))%"
        
        UIView.animate(withDuration: 0.5) {
            self.layoutIfNeeded()
        }
    }
    
    func onThemeChange() {}
    
    @objc func onTapped() {
        if let option = self.option, let callback = self.tapCallback {
            triggerHapticImpact(style: .light)
            
            let alert = UIAlertController(title: "Vote for '\(option.title)'?",
                                          message: "You cannot change your vote once you have voted.",
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Vote", style: .default , handler:{ (UIAlertAction) in
                callback(option)
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler: nil))
            
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = getTopMostViewController()?.view
                presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
            }
            getTopMostViewController()?.present(alert, animated: true, completion: nil)
        }
    }
}
