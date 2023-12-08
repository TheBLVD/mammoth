//
//  QuotePostHostView.swift
//  Mammoth
//
//  Created by Riley Howard on 4/26/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

public let didUpdateQuotePostNotification = Notification.Name("didUpdateQuotePostNotification")

class QuotePostHostView: UIView {
    
    enum QuotePostType {
        case text
        case image
        case notFound
    }
    
   let contentStack: UIView = {
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        return content
    }()
    
    let detailCell: DetailView = DetailView(isQuotedPostPreview: true)
    let detailImageCell: DetailImageView = DetailImageView(isQuotedPostPreview: true)
    let notFoundCell: QuotePostMutedView = QuotePostMutedView()
    let loadingIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
    
    var currentStatUrl: URL?
    var quotedStatus: Status? = nil
    let overlayButton = UIButton()
    
    var conditionalConstraints: [NSLayoutConstraint] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.contentStack)
        
        self.detailCell.translatesAutoresizingMaskIntoConstraints = false
        self.detailCell.isHidden = true
        self.contentStack.addSubview(self.detailCell)
        
        self.detailImageCell.translatesAutoresizingMaskIntoConstraints = false
        self.detailImageCell.isHidden = true
        self.contentStack.addSubview(self.detailImageCell)
        
        self.notFoundCell.translatesAutoresizingMaskIntoConstraints = false
        self.notFoundCell.isHidden = true
        self.contentStack.addSubview(self.notFoundCell)
        
        self.loadingIndicator.startAnimating()
        self.loadingIndicator.hidesWhenStopped = true
        self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.contentStack.addSubview(loadingIndicator)
        
        self.overlayButton.backgroundColor = UIColor.clear
        self.overlayButton.addTarget(self, action: #selector(self.didTapOverlay), for: .touchUpInside)
        self.contentStack.addSubview(overlayButton)
        self.overlayButton.translatesAutoresizingMaskIntoConstraints = false
        self.overlayButton.addFillConstraints(with: self)
        self.bringSubviewToFront(overlayButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            self.contentStack.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.contentStack.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.contentStack.topAnchor.constraint(equalTo: self.topAnchor),
            self.contentStack.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4),
            self.contentStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
            
            self.loadingIndicator.centerXAnchor.constraint(equalTo: self.contentStack.centerXAnchor),
            self.loadingIndicator.centerYAnchor.constraint(equalTo: self.contentStack.centerYAnchor),
        ])
    }
    
    func setConstraints(forType type: QuotePostType) {
        NSLayoutConstraint.deactivate(self.conditionalConstraints)
        
        switch type {
        case QuotePostType.text:
            conditionalConstraints = [
                self.detailCell.leadingAnchor.constraint(equalTo: self.contentStack.leadingAnchor),
                self.detailCell.trailingAnchor.constraint(equalTo: self.contentStack.trailingAnchor),
                self.detailCell.topAnchor.constraint(equalTo: self.contentStack.topAnchor),
                self.detailCell.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ]
        case QuotePostType.image:
            conditionalConstraints = [
                self.detailCell.leadingAnchor.constraint(equalTo: self.contentStack.leadingAnchor),
                self.detailCell.trailingAnchor.constraint(equalTo: self.contentStack.trailingAnchor),
                self.detailCell.topAnchor.constraint(equalTo: self.contentStack.topAnchor),
                
                self.detailImageCell.leadingAnchor.constraint(equalTo: self.contentStack.leadingAnchor),
                self.detailImageCell.trailingAnchor.constraint(equalTo: self.contentStack.trailingAnchor),
                self.detailImageCell.topAnchor.constraint(equalTo: self.detailCell.bottomAnchor, constant: 6),
                self.detailImageCell.bottomAnchor.constraint(equalTo: self.contentStack.bottomAnchor)
            ]
        case QuotePostType.notFound:
            conditionalConstraints = [
                self.notFoundCell.leadingAnchor.constraint(equalTo: self.contentStack.leadingAnchor),
                self.notFoundCell.trailingAnchor.constraint(equalTo: self.contentStack.trailingAnchor),
                self.notFoundCell.topAnchor.constraint(equalTo: self.contentStack.topAnchor),
                self.notFoundCell.bottomAnchor.constraint(equalTo: self.contentStack.bottomAnchor)
            ]
        }
        
        NSLayoutConstraint.activate(self.conditionalConstraints)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public func updateForQuotePost(_ qpURL: URL?) {
        // Typical URL: https://moth.social/@bart/110231660759681860
        
        if let cardURL = qpURL {
            self.currentStatUrl = cardURL
            StatusCache.shared.cacheStatusForURL(url: cardURL, completion: { url, _stat in
                guard self.currentStatUrl == url else {
                    log.warning("StatusCache: URL changed for view while doing a lookup from:\(self.currentStatUrl?.absoluteString ?? "nil") to:\(url) ")
                    return
                }
                
                DispatchQueue.main.async {
                    UIView.setAnimationsEnabled(false)
                    
                    if let stat = _stat {
                        self.quotedStatus = stat
                        self.detailCell.isHidden = false
                        self.notFoundCell.isHidden = true
                        self.detailCell.updateFromStat(stat)
                        
                        let showImage = DetailImageCell.willDisplayContentForStat(stat)
                        self.detailImageCell.isHidden = !showImage
                        if showImage {
                            self.detailImageCell.isHidden = false
                            self.detailImageCell.updateFromStat(stat)
                            self.setConstraints(forType: .image)
                        } else {
                            self.detailImageCell.isHidden = true
                            self.setConstraints(forType: .text)
                        }
                        
                        NotificationCenter.default.post(name: didUpdateQuotePostNotification, object: nil)
                        
                    } else {
                        // stat is nil
                        self.notFoundCell.updateFromStat(nil)
                        self.notFoundCell.isHidden = false
                        self.detailCell.isHidden = true
                        self.detailImageCell.isHidden = true
                        self.setConstraints(forType: .notFound)
                    }
                    
                    UIView.setAnimationsEnabled(true)
                    self.loadingIndicator.stopAnimating()
                }
            })
        } else {
            UIView.setAnimationsEnabled(false)
            self.notFoundCell.isHidden = true
            self.detailCell.isHidden = true
            self.detailImageCell.isHidden = true
            UIView.setAnimationsEnabled(true)
            self.loadingIndicator.stopAnimating()
        }
    }
    
    @objc func didTapOverlay() {
        if let status = self.quotedStatus {
            let vc = DetailViewController(post: PostCardModel(status: status))
            self.findViewController()?.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}

