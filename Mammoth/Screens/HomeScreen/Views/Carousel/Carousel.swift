//
//  Carousel.swift
//  Mammoth
//
//  Created by Benoit Nolens on 24/08/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

protocol CarouselDelegate: AnyObject {
    func carouselItemPressed(withIndex index: Int)
    func carouselActiveItemDoublePressed()
    func contextMenuForItem(withIndex index: Int) -> UIMenu?
}

class Carousel: UIView {
    
    private let flowLayout = CarouselFlowLayout()
    private let collectionView: CarouselCollectionView
    public let contextButton = UIButton(type: .custom)
    private(set) var selectedIndexPath = IndexPath(row: 0, section: 0)
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .clear
        return stackView
    }()
    
    weak var delegate: CarouselDelegate?
    
    public var content: [String?] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    public var richContent: [NSAttributedString?] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    init(withContextButton: Bool = true) {
        collectionView = CarouselCollectionView(frame: .zero, collectionViewLayout: flowLayout)
        super.init(frame: .zero)
        setupUI(withContextButton: withContextButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI(withContextButton: Bool) {
        self.layoutMargins = .zero
        self.clipsToBounds = false
        
        stackView.addArrangedSubview(collectionView)
        self.addSubview(stackView)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = .zero
        collectionView.decelerationRate = .fast
        collectionView.contentInset.right = 18
        collectionView.clipsToBounds = false
        
        collectionView.register(CarouselItem.self, forCellWithReuseIdentifier: CarouselItem.reuseIdentifier)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear

        // Make separate singleTap and doubleTap handlers for the collectionView.
        // Making only a doubleTap handler for each cell is swallowing the system-level single
        // taps (but only when running the iPadOS build on the Mac).
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(onSingleTap))
        singleTap.numberOfTapsRequired = 1
        collectionView.addGestureRecognizer(singleTap)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delaysTouchesBegan = false
        collectionView.addGestureRecognizer(doubleTap)
                
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor),

            collectionView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
        
        if withContextButton {
            let imageAttachment = NSTextAttachment()
            let image = FontAwesome.image(fromChar: "\u{f141}", size: UIFont.preferredFont(forTextStyle: .body).pointSize + 2, weight: .bold)
            imageAttachment.image = image.withRenderingMode(.alwaysTemplate)
            if UIDevice.current.userInterfaceIdiom == .phone {
                imageAttachment.bounds = CGRect(x: -2, y: 4, width: image.size.width, height: image.size.height)
            } else {
                imageAttachment.bounds = CGRect(x: -2, y: -5, width: image.size.width, height: image.size.height)
            }
            let imageString = NSAttributedString(attachment: imageAttachment)
            let buttonLabel = NSMutableAttributedString(attributedString: imageString)
            
            self.contextButton.setAttributedTitle(buttonLabel, for: .normal)
            self.contextButton.showsMenuAsPrimaryAction = true
            stackView.addArrangedSubview(contextButton)
        }
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Set everything that is using a custom color
        collectionView.reloadData()
    }

        
    override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    }

    @objc func onSingleTap(recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizer.State.ended {
            let tapLocation = recognizer.location(in: self.collectionView)
            if let tapIndexPath = self.collectionView.indexPathForItem(at: tapLocation) {
                self.collectionView(self.collectionView, didSelectItemAt: tapIndexPath)
            }
        }
    }

    @objc func onDoubleTap(recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizer.State.ended {
            self.delegate?.carouselActiveItemDoublePressed()
        }
    }
    
    private func selectCell(atIndexPath indexPath: IndexPath) {
        collectionView.visibleCells.forEach({
            let cell = $0 as! CarouselItem
            cell.titleLabel.textColor = .custom.softContrast.withAlphaComponent(GlobalStruct.overrideThemeHighContrast ? 0.65 : 1)
            cell.isSelected = false
        })
        
        if let cell = collectionView.cellForItem(at: indexPath) as? CarouselItem {
            
            let richContent: NSAttributedString? = self.richContent.count > indexPath.item ? self.richContent[indexPath.item] : nil
            
            if richContent == nil {
                cell.titleLabel.textColor = .custom.highContrast
            } else {
                cell.titleLabel.textColor = nil
                cell.titleLabel.attributedText = richContent
            }  
            
            cell.isSelected = true
        }
    }
    
    public func cellAtIndexPath(indexPath: IndexPath) -> CarouselItem? {
        return self.collectionView.cellForItem(at: indexPath) as? CarouselItem
    }
    
    public func selectItem(atIndex index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        self.selectedIndexPath = indexPath
        self.selectCell(atIndexPath: indexPath)
    }
    
    public func scrollTo(index: Int, animated: Bool = true) {
        let indexPath = IndexPath(row: index, section: 0)
        self.selectItem(atIndex: index)
        self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }
    
    public func adjustScrollOffset(withPercentageToNextItem offset: CGFloat, isDragging: Bool = true) {
        
        if offset > 0 {
            let nextIndexPath = IndexPath(row: self.selectedIndexPath.item + 1, section: 0)
            if let previousItem = collectionView.layoutAttributesForItem(at: selectedIndexPath),
                let nextItem = collectionView.layoutAttributesForItem(at: nextIndexPath) {
                
                let previousCenter = previousItem.center
                let nextCenter = nextItem.center
                let contentWidth = collectionView.collectionViewLayout.collectionViewContentSize.width

                let currentCenter = CGPoint(x: previousCenter.x + (nextCenter.x - previousCenter.x) * offset, y: nextCenter.y)
                let rectSize = CGSize(width: min(collectionView.frame.size.width - collectionView.contentInset.right, contentWidth), height: collectionView.frame.size.height)
                let currentVisibleRect = CGRect(x: currentCenter.x - (rectSize.width / 2.0), y: 0, width: rectSize.width, height: rectSize.height)
                                
                UIView.performWithoutAnimation {
                    collectionView.scrollRectToVisible(currentVisibleRect, animated: false)
                    collectionView.contentOffset.x = min(collectionView.contentOffset.x, contentWidth - rectSize.width)
                    
                    if isDragging {
                        if offset >= 0.5 {
                            self.selectCell(atIndexPath: nextIndexPath)
                        } else {
                            self.selectCell(atIndexPath: self.selectedIndexPath)
                        }
                    }
                }
            }
        } else if offset < 0 {
            let nextIndexPath = IndexPath(row: self.selectedIndexPath.item - 1, section: 0)
            if let previousItem = collectionView.layoutAttributesForItem(at: selectedIndexPath),
                let nextItem = collectionView.layoutAttributesForItem(at: nextIndexPath) {
                
                let previousCenter = previousItem.center
                let nextCenter = nextItem.center
                let contentWidth = collectionView.collectionViewLayout.collectionViewContentSize.width

                let currentCenter = CGPoint(x: nextCenter.x + (previousCenter.x - nextCenter.x) * (1.0 - abs(offset)), y: nextCenter.y)
                let rectSize = CGSize(width: min(collectionView.frame.size.width - collectionView.contentInset.right, contentWidth), height: collectionView.frame.size.height)
                let currentVisibleRect = CGRect(x: currentCenter.x - (rectSize.width / 2.0), y: 0, width: rectSize.width, height: rectSize.height)
                                
                UIView.performWithoutAnimation {
                    collectionView.scrollRectToVisible(currentVisibleRect, animated: false)
                    collectionView.contentOffset.x = min(collectionView.contentOffset.x, contentWidth - rectSize.width)
                    
                    if isDragging {
                        if 1 - abs(offset) < 0.5 {
                            self.selectCell(atIndexPath: nextIndexPath)
                        } else {
                            self.selectCell(atIndexPath: self.selectedIndexPath)
                        }
                    }
                }
            }
        }
    }
}

extension Carousel: UICollectionViewDelegate {
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.carouselItemPressed(withIndex: indexPath.item)
        self.selectedIndexPath = indexPath
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        
        // Setting the item color here instead of in cellForItemAt.
        // Calling reloadData creates an animation glitch.
        self.selectCell(atIndexPath: indexPath)
    }
}

extension Carousel: UICollectionViewDataSource {
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return !richContent.isEmpty ? richContent.count : content.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CarouselItem.reuseIdentifier, for: indexPath) as! CarouselItem
        if !richContent.isEmpty {
            cell.titleLabel.attributedText = richContent[indexPath.row]
        } else {
            cell.titleLabel.text = content[indexPath.row]
        }
        
        if indexPath == self.selectedIndexPath {
            let richContent =  self.richContent.count > indexPath.item ? self.richContent[indexPath.item] : nil
            
            if richContent == nil {
                cell.titleLabel.textColor = .custom.highContrast
            } else {
                cell.titleLabel.textColor = nil
                cell.titleLabel.attributedText = richContent
            }
        } else {
            cell.titleLabel.textColor = .custom.softContrast.withAlphaComponent(GlobalStruct.overrideThemeHighContrast ? 0.65 : 1)
        }
                
        return cell
    }
}

// MARK: UIContextMenuInteractionDelegate
extension Carousel: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let cell = collectionView.cellForItem(at: indexPath), cell.isSelected else { return nil }
        guard let menu = self.delegate?.contextMenuForItem(withIndex: indexPath.item) else { return nil }
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil, actionProvider: { suggestedActions in
            return menu
        })
    }
}
