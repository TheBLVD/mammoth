//
//  PostCardMediaGallery.swift
//  Mammoth
//
//  Created by Benoit Nolens on 17/01/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit
import SDWebImage
import UnifiedBlurHash

fileprivate let PostCardMediaGalleryHeight = 180.0

final class PostCardMediaGallery: UIView {

    private let scrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = false
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    
    private let stackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .equalSpacing
        stackView.spacing = 8.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private var attachments: [Attachment]?
    private var postCard: PostCardModel?
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.addSubview(scrollView)
        scrollView.pinEdges()
        
        scrollView.addSubview(stackView)
        stackView.pinEdges()
        
        let scrollViewHeight = scrollView.heightAnchor.constraint(equalToConstant: PostCardMediaGalleryHeight)
        scrollViewHeight.isActive = true
        scrollViewHeight.priority = .required
        
        let stackViewHeight = stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        stackViewHeight.isActive = true
        stackViewHeight.priority = .required
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let expendedBounds = self.bounds.insetBy(dx: -86, dy: 0)
        if expendedBounds.contains(point) {
            let convertedPoint = self.stackView.convert(point, from: self)
            // Accept touches outside the scrollview bounds,
            // if it's hitting scrollview content
            return self.stackView.hitTest(convertedPoint, with: event)
        }
        
        return nil
    }
}

extension PostCardMediaGallery {
    func prepareForReuse() {
        self.attachments = nil
        self.postCard = nil
        self.stackView.arrangedSubviews.forEach({
            self.stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        })
    }
    
    public func configure(postCard: PostCardModel) {
        let shouldUpdate = self.attachments == nil || postCard.mediaAttachments != self.attachments!
        self.attachments = postCard.mediaAttachments
        self.postCard = postCard
        
        if shouldUpdate {
            self.attachments?.forEach({ media in
                if media.type == .image {
                    let image = PostCardImage()
                    image.configure(image: media, postCard: postCard)
                    self.stackView.addArrangedSubview(image)
                }
                
                if media.type == .video || media.type == .gifv || media.type == .audio {
                    let video = PostCardVideo()
                    video.configure(video: media, postCard: postCard)
                    video.pause()
                    self.stackView.addArrangedSubview(video)
                }
            })
        }
    }
}
