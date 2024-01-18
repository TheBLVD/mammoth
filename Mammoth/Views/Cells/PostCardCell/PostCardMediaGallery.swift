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
    
    private lazy var collectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.clipsToBounds = false
        collectionView.isPagingEnabled = false
        collectionView.register(PostCardMediaGalleryItem.self, forCellWithReuseIdentifier: PostCardMediaGalleryItem.reuseIdentifier)
        collectionView.accessibilityIdentifier = "mediaGallery"
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    private lazy var layout = PostCardMediaGalleryFlowLayout()
    
    private var cellWidths: [Float] {
        self.postCard?.mediaAttachments.enumerated().map({
            let index = $0.offset
            return Float(self.calculateCellWidth(for: IndexPath(item: index, section: 0)))
        }) ?? []
    }
    
    fileprivate var cellOffsets: [Float] {
        calculateOffsets(for: self.cellWidths, additionalItemOffset: Float(self.layout.minimumLineSpacing))
    }
    private let cellHeight: CGFloat = 180.0
    private let targetAspectRatio: CGFloat = 16.0 / 9.0
    
    private var media: Attachment?
    private var postCard: PostCardModel?
    
    public var leftInset: CGFloat = 0 {
        didSet {
            self.layout.sectionInset = UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: 13)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.addSubview(collectionView)
        self.collectionView.pinEdges()
        
        NSLayoutConstraint.activate([
            self.collectionView.heightAnchor.constraint(equalToConstant: PostCardMediaGalleryHeight)
        ])
    }
}

extension PostCardMediaGallery {
    func prepareForReuse() {
        self.media = nil
        self.postCard = nil
    }
    
    public func configure(postCard: PostCardModel) {
        let shouldUpdate = self.media == nil || postCard.mediaAttachments.first != self.media!
        self.media = postCard.mediaAttachments.first
        self.postCard = postCard
        
        if shouldUpdate {
            if let media = self.media {
                if media.type == .image {
                    
                }
                
                if media.type == .video || media.type == .gifv || media.type == .audio {
                    
                }
                
                self.collectionView.reloadData()
            }
        }
    }
}

extension PostCardMediaGallery: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.postCard?.mediaAttachments.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostCardMediaGalleryItem.reuseIdentifier, for: indexPath) as? PostCardMediaGalleryItem, let postCard = self.postCard, let model = self.postCard?.mediaAttachments[indexPath.item] {
            cell.configure(attachment: model, postCard: postCard)
            return cell
        }
        
        log.error("Unable to configure PostCardMediaGallery item")
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = calculateCellWidth(for: indexPath)
        return CGSize(width: width, height: cellHeight)
    }
    
    private func calculateCellWidth(for indexPath: IndexPath) -> CGFloat {
        if let attachment = self.postCard?.mediaAttachments[indexPath.item] {
            // the aspect value might be nil
            if attachment.meta?.original?.aspect == nil {
                attachment.meta?.original?.aspect = Double(attachment.meta?.original?.width ?? 10) / Double(attachment.meta?.original?.height ?? 10)
            }
            
            if let ratio = attachment.meta?.original?.aspect {
                if fabs(ratio - 1.0) < 0.01 {
                    return PostCardMediaGalleryHeight
                }
                
                // landscape
                else if ratio > 1 {
                    return PostCardMediaGalleryHeight * ratio
                }
                
                // portrait
                else if ratio < 1 {
                    return PostCardMediaGalleryHeight * ratio
                }
            }
        }
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
}

fileprivate class PostCardMediaGalleryFlowLayout: UICollectionViewFlowLayout {
    
    override init() {
        super.init()
        
        self.minimumLineSpacing = 8
        self.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.scrollDirection = .horizontal
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let _ = collectionView else { return proposedContentOffset }
        if let mediaGallery = self.collectionView?.superview as? PostCardMediaGallery {
            let offsets = mediaGallery.cellOffsets
            if let index = findClosestIndex(array: offsets, target: Float(proposedContentOffset.x)) {
                return CGPoint(x: Int(offsets[index]), y: 0)
            }
        }

        return proposedContentOffset
    }
    
}


fileprivate class PostCardMediaGalleryItem: UICollectionViewCell {
    
    static let reuseIdentifier: String = "PostCardMediaGalleryItem"
    
    private let imageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 8
        imageView.layer.cornerCurve = .continuous
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .red
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private var dynamicWidthConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.sd_cancelCurrentImageLoad()
        self.imageView.image = nil
        self.dynamicWidthConstraint?.isActive = false
        
    }
    
    private func setupUI() {
        self.contentView.addSubview(imageView)
        self.contentView.layoutMargins = .zero
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.bottomAnchor),
            imageView.heightAnchor.constraint(equalToConstant: PostCardMediaGalleryHeight)
        ])
    }
}

extension PostCardMediaGalleryItem {
    public func configure(attachment: Attachment, postCard: PostCardModel) {
        
        var placeholder: UIImage?
        if let blurhash = attachment.blurhash {
            placeholder = UnifiedImage(blurHash: blurhash, size: .init(width: 32, height: 32))
        }
        
        self.imageView.ma_setImage(with: URL(string: attachment.previewURL!)!,
                                          cachedImage: postCard.decodedImages[attachment.previewURL!] as? UIImage,
                                          placeholder: placeholder,
                                          imageTransformer: PostCardImage.transformer) { image in
            postCard.decodedImages[attachment.previewURL!] = image
        }
        
//        self.dynamicWidthConstraint = self.imageView.widthAnchor.constraint(equalTo: self.imageView.heightAnchor, multiplier: 16.0/9.0)
//        self.dynamicWidthConstraint?.isActive = true
//        self.dynamicWidthConstraint?.priority = .required
    }
}

// MARK: - Helper functions

func calculateOffsets(for inputArray: [Float], additionalItemOffset: Float = 0) -> [Float] {
    var outputArray: [Float] = []

    for (index, value) in inputArray.enumerated() {
        if index == 0 {
            outputArray.append(0)
        } else {
            let previousWidth = inputArray[index - 1]
            let previousSum = outputArray[index - 1]
            let currentSum = previousSum + additionalItemOffset + previousWidth
            outputArray.append(currentSum)
        }
    }

    return outputArray
}

func findClosestIndex(array: [Float], target: Float) -> Int? {
    guard !array.isEmpty else {
        return nil
    }

    var closestIndex = 0
    var closestDifference = abs(array[0] - target)

    for (index, width) in array.enumerated() {
        let difference = abs(width - target)
        if difference < closestDifference {
            closestIndex = index
            closestDifference = difference
        }
    }

    return closestIndex
}
