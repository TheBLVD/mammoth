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

fileprivate let PostCardMediaGalleryHeight =  min((UIScreen.main.bounds.width * 0.76) * (9.0/16.0), 260)

protocol PostCardMediaGalleryDelegate: AnyObject {
    func galleryItemForPhoto(withIndex index: Int) -> PostCardImage?
    func scrollGalleryToItem(atIndex index: Int, animated: Bool)
}

final class PostCardMediaGallery: UIView {

    private let scrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = false
        view.layoutMargins = .zero
        view.isDirectionalLockEnabled = true
        view.delaysContentTouches = false
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
        stackView.layoutMargins = .zero
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
        stackView.pinEdges(to: scrollView)
        
        let scrollViewHeight = scrollView.heightAnchor.constraint(equalToConstant: PostCardMediaGalleryHeight)
        scrollViewHeight.isActive = true
        scrollViewHeight.priority = .defaultHigh
        
        let stackViewHeight = stackView.heightAnchor.constraint(equalToConstant: PostCardMediaGalleryHeight)
        stackViewHeight.isActive = true
        stackViewHeight.priority = .required
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard self.isHidden == false, self.alpha == 1, self.attachments != nil else { return nil }
        let leadingInset = -86.0 // Inset needs to be >= leading inset from the edge of the cell to the gallery
        let trailingOffset = 800.0 // Offset needs to be >= trailing offset from the trailing edge of the gallery to the trailing edge of the cell
        let expendedBounds = CGRect.init(origin: self.bounds.insetBy(dx: leadingInset, dy: 0).origin,
                                         size: .init(width: self.bounds.width + trailingOffset, height: self.bounds.height))
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
    func prepareForReuse() {}
    
    public func configure(postCard: PostCardModel) {
        let shouldUpdate = self.attachments == nil || postCard.mediaAttachments != self.attachments!
        self.attachments = postCard.mediaAttachments
        self.postCard = postCard
        
        if shouldUpdate {
            self.scrollView.setContentOffset(.zero, animated: false)
            self.stackView.arrangedSubviews.forEach({
                self.stackView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            })
                
            self.attachments?.forEach({ media in
                if media.type == .image {
                    let image = PostCardImage(inGallery: true)
                    image.configure(image: media, postCard: postCard)
                    image.galleryDelegate = self
                    self.stackView.addArrangedSubview(image)
                    
                    let ratio = Double(media.meta?.small?.width ?? 16) / Double(media.meta?.small?.height ?? 9)
                    
                    let heightAnchor = image.heightAnchor.constraint(equalToConstant: PostCardMediaGalleryHeight)
                    heightAnchor.priority = .defaultHigh
                    heightAnchor.isActive = true
                    let widthAnchor = image.widthAnchor.constraint(equalTo: image.heightAnchor, multiplier: ratio)
                    widthAnchor.isActive = true
                    widthAnchor.priority = .defaultHigh
                }
                
                if media.type == .video || media.type == .gifv || media.type == .audio {
                    let video = PostCardVideo(inGallery: true)
                    video.configure(video: media, postCard: postCard)
                    video.pause()
                    self.stackView.addArrangedSubview(video)
                    
                    let heightAnchor = video.heightAnchor.constraint(equalToConstant: PostCardMediaGalleryHeight)
                    heightAnchor.priority = .defaultHigh
                    heightAnchor.isActive = true
                }
            })
        }
    }
}

extension PostCardMediaGallery: PostCardMediaGalleryDelegate {
    func galleryItemForPhoto(withIndex index: Int) -> PostCardImage? {
        if let item = self.stackView.arrangedSubviews[index] as? PostCardImage {
            return item
        }
        
        return nil
    }
    
    func scrollGalleryToItem(atIndex index: Int, animated: Bool) {
        if let activeItem = self.stackView.arrangedSubviews[index] as? PostCardImage {
            guard self.scrollView.contentSize.width > self.scrollView.frame.size.width else { return }
            let maxOffset = self.scrollView.contentSize.width - self.scrollView.frame.size.width
            self.scrollView.setContentOffset(.init(x: min(activeItem.frame.origin.x, maxOffset), y: 0), animated: animated)
        } else {
            self.scrollView.setContentOffset(.zero, animated: animated)
        }
    }
}
