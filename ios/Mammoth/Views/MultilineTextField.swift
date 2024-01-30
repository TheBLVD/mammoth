//
//  MultilineTextField.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 07/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

/// Text field with support for multiple lines.
/// - NOTE: Under the hood this is just a `UITextView` which aims to provide
///   many of the functionalities currently available in the `UITextField` class.
///   Currently the following functionalities are supported:
/// + Multiple lines
/// + Customizable left view
/// + Customizable placeholder
///
/// - TODO: The following features are still missing:
/// + Add support for displaying a right view
/// + Configure when left/right views will be shown using `UITextField.leftViewMode`
public class MultilineTextField: UITextView {
    private let placeholderView: UITextView
    
    public override var text: String! {
        didSet {
            self.textViewDidChange(self)
        }
    }
    
    public override var attributedText: NSAttributedString! {
        didSet {
            self.textViewDidChange(self)
        }
    }
    
    /// The string that is displayed when there is no other text in the text field.
    /// This value is nil by default. The placeholder string is drawn using the color
    /// stored in `self.placeholderColor`.
    @IBInspectable
    public var placeholder: String? {
        didSet {
            placeholderView.text = placeholder
        }
    }
    
    /// Color to use to draw the placeholder string.
    public var placeholderColor: UIColor = .black {
        didSet {
            placeholderView.textColor = placeholderColor
        }
    }
    
    /// Alignment for placeholder
    public var placeholderAlignment: NSTextAlignment = .left {
        didSet {
            placeholderView.textAlignment = placeholderAlignment
        }
    }
    
    /// A Boolean value that determines whether scrolling is enabled
    /// for the placeholder content.
    public var isPlaceholderScrollEnabled: Bool = true {
        didSet {
            placeholderView.isScrollEnabled = isPlaceholderScrollEnabled
        }
    }
    
    /// Point used as the origin for displaying the left view.
    public var leftViewOrigin: CGPoint = CGPoint(x: 0, y: 6) {
        didSet {
            invalidateLeftView()
        }
    }
    
    private var leftExclusionPath: UIBezierPath?
    
    
    /// Convenience property to set an image directly instead of a left view
    @IBInspectable
    public var leftImage: UIImage? {
        get {
            return (self.leftView as? UIImageView)?.image
        }
        set {
            if let image = newValue {
                self.leftView = UIImageView(image: image)
            }
            else {
                self.leftView = nil
            }
        }
    }
    
    /// The overlay view displayed in the left side of the text field.
    public var leftView: UIView? {
        willSet {
            if let view = self.leftView {
                view.removeFromSuperview()
            }
        }
        didSet {
            if let view = self.leftView {
                self.addSubview(view)
            }
            
            invalidateLeftView()
        }
    }
    
    private var fieldObservations: [NSKeyValueObservation] = []
    
    public override init(frame: CGRect, textContainer: NSTextContainer? = nil) {
        placeholderView = UITextView(frame: frame, textContainer: textContainer)
        super.init(frame: frame, textContainer: textContainer)
        initializeUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        placeholderView = UITextView()
        super.init(coder: aDecoder)
        initializeUI()
    }
    
    deinit {
        removeObservers()
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            removeObservers()
        }
    }
    
    func initializeUI() {
        self.textContainer.lineFragmentPadding = 0
        
        self.insertSubview(placeholderView, at: 0)
        
        placeholderView.frame = self.bounds
        placeholderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        placeholderView.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        placeholderView.text = ""
        placeholderView.isEditable = false
        placeholderView.textColor = UIColor(white: 0.7, alpha: 1)
        placeholderView.backgroundColor = .clear
        
        // observe `UITextView` property changes to react accordinly
        #if swift(>=4.2)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewDidChange(notification:)),
            name: UITextView.textDidChangeNotification,
            object: self
        )
        #else
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewDidChange(notification:)),
            name: Notification.Name.UITextViewTextDidChange,
            object: self
        )
        #endif
        
        fieldObservations.append(
            self.observe(\.font, options: [.initial, .new]) { [weak self] (textField, change) in
                self?.placeholderView.font = textField.font
            }
        )

        fieldObservations.append(
            self.observe(\.textContainerInset, options: [.initial, .new]) { [weak self] (textField, change) in

                guard let strongSelf = self else { return }

                strongSelf.placeholderView.textContainerInset = textField.textContainerInset
                strongSelf.invalidateLeftView()
            }
        )

        fieldObservations.append(
            self.textContainer.observe(\.lineFragmentPadding, options: [.initial, .new]) { [weak self] (textContainer, changes) in
                self?.placeholderView.textContainer.lineFragmentPadding = textContainer.lineFragmentPadding
            }
        )
    }
    
    private func removeObservers() {
        fieldObservations.forEach { $0.invalidate() }
        fieldObservations.removeAll()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func textViewDidChange(notification: Notification) {
        guard let textView = notification.object as? MultilineTextField else {
            return
        }
        
        textViewDidChange(textView)
    }
    
    @objc private func textViewDidChange(_ textView: MultilineTextField) {
        placeholderView.isHidden = !textView.text.isEmpty
            || !textView.attributedText.string.isEmpty
        
        // handling scrolling of placeholder view
        placeholderView.setContentOffset(.zero, animated: false)
        
        if let left = leftView {
            if placeholderView.isHidden {
                self.addSubview(left)
            }
            else {
                placeholderView.addSubview(left)
            }
        }
    }
    
    private func invalidateLeftView() {
        if let path = self.leftExclusionPath {
            remove(exlusionPath: path)
        }
        
        if let view = self.leftView {
            let size = view.bounds.size
            let frame = CGRect(origin: leftViewOrigin, size: size)
            view.frame = frame
            
            let exclusionRect = CGRect(
                origin: CGPoint(
                    x: leftViewOrigin.x - textContainerInset.left,
                    y: leftViewOrigin.y - textContainerInset.top
                ),
                size: size
            )
            
            let exclusionPath = UIBezierPath(rect: exclusionRect)
            add(exclusionPath: exclusionPath)
            
            self.leftExclusionPath = exclusionPath
        }
    }
    
    private func add(exclusionPath: UIBezierPath) {
        self.textContainer.exclusionPaths.append(exclusionPath)
        placeholderView.textContainer.exclusionPaths.append(exclusionPath)
    }
    
    private func remove(exlusionPath: UIBezierPath) {
        #if swift(>=5)
        if let index = self.textContainer.exclusionPaths.firstIndex(of: exlusionPath) {
            self.textContainer.exclusionPaths.remove(at: index)
        }
        
        if let index = placeholderView.textContainer.exclusionPaths.firstIndex(of: exlusionPath) {
            placeholderView.textContainer.exclusionPaths.remove(at: index)
        }
        #else
        if let index = self.textContainer.exclusionPaths.index(of: exlusionPath) {
            self.textContainer.exclusionPaths.remove(at: index)
        }
        
        if let index = placeholderView.textContainer.exclusionPaths.index(of: exlusionPath) {
            placeholderView.textContainer.exclusionPaths.remove(at: index)
        }
        #endif
    }
}

