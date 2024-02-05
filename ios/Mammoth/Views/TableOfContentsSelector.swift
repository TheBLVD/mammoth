//
//  TableOfContentsSelector.swift
//  TableOfContents
//
//  Created by Christian Selig on 2021-04-24.
//

import UIKit

/// A similar style control to the section index title selector optionally to the right of UITableView, but with more flexibility.
class TableOfContentsSelector: UIView {
    var font: UIFont = UIFont.systemFont(ofSize: 12.0, weight: .semibold) {
        didSet {
            setLabel()
        }
    }
    
    let label: UILabel = UILabel()
    let longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: nil, action: nil)
    let overlayView = TableOfContentsSelectionOverlay()
    
    weak var selectionDelegate: TableOfContentsSelectionDelegate?
    
    // MARK: - Constants
    
    private let itemHeight: CGFloat
    private let lineSpacing: CGFloat = 1.0
    private let sidePadding: CGFloat = 2.0
    private let verticalPadding: CGFloat = 7.0
    private let overlaySize: CGSize = CGSize(width: 110.0, height: 110.0)
        
    // MARK: - Model
    
    private var items: [TableOfContentsItem] = []
    private var itemsShown: [TableOfContentsItem] = []
    private var mostRecentSelection: TableOfContentsItem?
    
    let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.systemUltraThinMaterial))
    
    init() {
        self.itemHeight = font.lineHeight + lineSpacing
        
        super.init(frame: .zero)
        
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(blurEffectView)
        blurEffectView.alpha = 0
        
        label.numberOfLines = 0
        addSubview(label)
        
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 10.0
        label.layer.cornerCurve = .continuous
        label.backgroundColor = .clear
        
        blurEffectView.frame = label.bounds
        blurEffectView.layer.masksToBounds = true
        blurEffectView.layer.cornerRadius = 10.0
        blurEffectView.layer.cornerCurve = .continuous
        
        // We're going to twist UILongPressGR to be more of a UIPanGR to make delaying the gesture easier
        label.isUserInteractionEnabled = true
        longPressGestureRecognizer.minimumPressDuration = 0.3
        longPressGestureRecognizer.addTarget(self, action: #selector(labelLongPressed(gestureRecognizer:)))
        label.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("\(#file) does not implement coder.") }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        setLabel()
    }
    
    private func setLabel() {
//        let totalItemsFittable = Int(bounds.height / itemHeight)
        
//        if totalItemsFittable >= items.count {
            // We can fit all of them, so just show all, hurrah!
            showAllItemsInLabel()
//        } else {
            // Can't fit all, mimic UITableView and have • characters spaced between to show that the 'visualization' is incomplete
//            showIncompleteAmountOfItemsInLabel(totalItemsFittable)
//        }
        
        let labelHeight = label.sizeThatFits(.zero).height + verticalPadding * 2.0
        label.frame = CGRect(x: 0.0, y: (bounds.height - labelHeight) / 2.0, width: bounds.width, height: labelHeight)
        
        blurEffectView.frame = label.frame
    }
    
    private func showAllItemsInLabel() {
        self.itemsShown = self.items
        showItemsInLabel(self.items)
    }
        
    private func showIncompleteAmountOfItemsInLabel(_ totalItemsFittable: Int) {
        // Only accept odd numbers of items to get the correct amount of • placeholders
        let isOddNumber = totalItemsFittable % 2 == 1
        var totalItemsToShow = isOddNumber ? totalItemsFittable : totalItemsFittable - 1
        
        // Subtract two so we can fit the first and last items the user provided
        totalItemsToShow -= 2
        
        // Since it's an odd number, this will integer round down so that there is 1 less index shown than placeholders
        let totalUserItemsToShow = totalItemsToShow / 2
        
        let showEveryNthCharacter = CGFloat(self.items.count - 2) / CGFloat(totalUserItemsToShow)
        
        var userItemsToShow: [TableOfContentsItem] = []
        
        // Drop the first and last index because we have them covered by the user-provided items
        for i in stride(from: CGFloat(1), to: CGFloat(self.items.count - 1), by: showEveryNthCharacter) {
            userItemsToShow.append(self.items[Int(i.rounded())])
            
            if userItemsToShow.count == totalUserItemsToShow {
                // Since we're incrementing by fractional numbers ensure we don't grab one too many and go beyond our indexes
                break
            }
        }
        
        var itemsToShow: [TableOfContentsItem] = [self.items.first!]
        
        // Every second one show a placeholder
        for item in userItemsToShow {
            itemsToShow.append(.letter(letter: "•"))
            itemsToShow.append(item)
        }
        
        // The finishing touches… 🍒
        itemsToShow.append(.letter(letter: "•"))
        itemsToShow.append(self.items.last!)
        
        self.itemsShown = itemsToShow
        showItemsInLabel(itemsToShow)
    }
    
    private func showItemsInLabel(_ items: [TableOfContentsItem]) {
        let mainAttributedString = NSMutableAttributedString()
        
        for item in items {
            switch item {
            case let .letter(letter):
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = lineSpacing
                paragraphStyle.alignment = .center
                
                mainAttributedString.append(NSAttributedString(string: "\(letter)\n", attributes: [.font: font, .paragraphStyle: paragraphStyle]))
            case let .symbol(symbolName, isCustom):
                // For symbols, we increase the line spacing slightly as well as shrinking the font's point size, which just makes them visually 'fit' better with normal letters. Note that this ever so slightly has an effect on touch point tracking, but given that this is an imprecise control anyway, it's more than within the realm of acceptable
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = lineSpacing + 2.0
                paragraphStyle.alignment = .center
                
                let symbolAttributedString = NSMutableAttributedString()
                
                let imageAttachment = NSTextAttachment()
                let font = UIFont(descriptor: self.font.fontDescriptor, size: self.font.pointSize - 1.0)
                let config = UIImage.SymbolConfiguration(font: font)
                
                let image: UIImage = {
                    if isCustom {
                        return UIImage(named: symbolName, in: nil, with: config)!.withTintColor(UIColor.secondaryLabel.withAlphaComponent(0.7))
                    } else {
                        return UIImage(systemName: symbolName, withConfiguration: config)!.withTintColor(UIColor.secondaryLabel.withAlphaComponent(0.7))
                    }
                }()
                
                imageAttachment.image = image
                
                symbolAttributedString.append(NSAttributedString(attachment: imageAttachment))
                symbolAttributedString.append(NSAttributedString(string: "\n"))
                symbolAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: symbolAttributedString.length))
                                
                mainAttributedString.append(symbolAttributedString)
            }
        }
        
        // Remove last newline
        mainAttributedString.mutableString.deleteCharacters(in: NSRange(location: mainAttributedString.mutableString.length - 1, length: 1))
        
        let fullRange = NSRange(location: 0, length: mainAttributedString.length)
        mainAttributedString.addAttribute(.font, value: font, range: fullRange)
        mainAttributedString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel.withAlphaComponent(0.7), range: fullRange)
        
        label.attributedText = mainAttributedString
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let labelSize = label.sizeThatFits(.zero)
        return CGSize(width: labelSize.width + sidePadding * 2.0, height: labelSize.height + verticalPadding * 2.0)
    }
    
    @objc private func labelLongPressed(gestureRecognizer: UILongPressGestureRecognizer) {
        let state = gestureRecognizer.state
        
        let percent = (gestureRecognizer.location(in: label).y - verticalPadding) / (label.bounds.height - verticalPadding * 2.0)
        let itemIndex = max(0, min(self.items.count - 1, Int((CGFloat(self.items.count) * percent))))
        let selectedItem = self.items[itemIndex]
        
        if state == .began {
            triggerKeyHapticImpact()
            selectionDelegate?.beganSelection()
            blurEffectView.alpha = 1
            
            if let viewToOverlayIn = selectionDelegate?.viewToShowOverlayIn() {
                viewToOverlayIn.addSubview(overlayView)
                positionAndSizeOverlayView()
            }
        }
        
        showSelectedItem(selectedItem)
        selectionDelegate?.selectedItem(selectedItem)

        if state == .changed {
            if mostRecentSelection != selectedItem {
                triggerHapticSelectionChanged()
            }
            
            mostRecentSelection = selectedItem
        }
        
        if [.ended, .cancelled, .failed].contains(state) {
            label.backgroundColor = .clear
            blurEffectView.alpha = 0
            selectionDelegate?.endedSelection()
            overlayView.removeFromSuperview()
        }
    }
    
    private func showSelectedItem(_ selectedItem: TableOfContentsItem) {
        overlayView.updateSelectionTo(selectedItem)
    }
    
    func positionAndSizeOverlayView() {
        guard let viewToOverlayIn = selectionDelegate?.viewToShowOverlayIn(), let overlaySuperview = viewToOverlayIn.superview else {
            fatalError("Both should be available at this point")
        }
        
        overlayView.frame.size = overlaySize
        overlayView.frame.origin = CGPoint(x: (overlaySuperview.bounds.width - overlaySize.width) / 2.0, y: (overlaySuperview.bounds.height - overlaySize.height) / 2.0)
        overlayView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
    }

    // MARK: - Public API
    
    /// Update the Table of Contents with a list of items, supporting either letters or SF Symbols (or a combination therein)
    func updateWithItems(_ items: [TableOfContentsItem]) {
        self.items = items
        setLabel()
    }
    
    static var alphanumericItems: [TableOfContentsItem] = {
        return ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"].map { .letter(letter: $0) }
    }()
    
    static var alphanumericItems2: [TableOfContentsItem] = {
        return ["Z", "Y", "X", "W", "V", "U", "T", "S", "R", "Q", "P", "O", "N", "M", "L", "K", "J", "I", "H", "G", "F", "E", "D", "C", "B", "A"].map { .letter(letter: $0) }
    }()
}

class TableOfContentsSelectionOverlay: UIVisualEffectView {
    let label: UILabel = UILabel()
    let imageView: UIImageView = UIImageView()
    
    let labelFontSize: CGFloat = 55.0
    let imageFontSize: CGFloat = 44.0
    
    init() {
        super.init(effect: UIBlurEffect(style: .systemMaterial))
        
        layer.masksToBounds = true
        layer.cornerRadius = 20.0
        layer.cornerCurve = .continuous
        
        let overlayTextColor = UIColor(white: 0.3, alpha: 1.0)
        
        label.font = UIFont.systemFont(ofSize: labelFontSize, weight: .medium)
        label.textAlignment = .center
        label.textColor = overlayTextColor
        label.isHidden = true
        contentView.addSubview(label)
        
        imageView.contentMode = .center
        imageView.tintColor = overlayTextColor
        imageView.isHidden = true
        contentView.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("\(#file) does not implement coder.") }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.frame = bounds
        imageView.frame = bounds
    }
    
    func updateSelectionTo(_ newSelection: TableOfContentsItem) {
        switch newSelection {
        case let .letter(letter):
            label.text = "\(letter)"
            label.isHidden = false
            imageView.isHidden = true
        case let .symbol(name, isCustom):
            imageView.image = {
                // Symbols look a little different than letters, so we make them a little smaller and heavier weight in order to keep visual consistency between both
                let font = UIFont.systemFont(ofSize: imageFontSize, weight: .semibold)
                let config = UIImage.SymbolConfiguration(font: font)
                
                if isCustom {
                    return UIImage(named: name, in: nil, with: config)
                } else {
                    return UIImage(systemName: name, withConfiguration: config)
                }
            }()
            
            label.isHidden = true
            imageView.isHidden = false
        }
    }
}

enum TableOfContentsItem: Equatable {
    /// A standard letter
    case letter(letter: Character)
    
    /// An SF Symbol, either iOS-provided or custom. Can optionally specificy a font size modifier if size in standard font is not optimal.
    case symbol(name: String, isCustom: Bool)
}

protocol TableOfContentsSelectionDelegate: AnyObject {
    func viewToShowOverlayIn() -> UIView?
    func selectedItem(_ item: TableOfContentsItem)
    func beganSelection()
    func endedSelection()
}
