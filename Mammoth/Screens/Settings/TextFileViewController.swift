//
//  TextFileViewController.swift
//  Mammoth
//
//  Created by Riley Howard on 11/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class TextFileViewController : UIViewController {
    private var filename: String
    private var attributedText: NSAttributedString? = nil
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.backgroundColor = .custom.background
        return textView
    }()
    
    init(filename: String) {
        self.filename = filename
        super.init(nibName: nil, bundle: nil)
        var mutableFileContent: NSMutableAttributedString? = nil
        if let rtfURL = Bundle.main.url(forResource: filename, withExtension: "rtf") {
            if #available(iOS 15, *) {
                var options = AttributedString.MarkdownParsingOptions.init()
                options.allowsExtendedAttributes = true
                mutableFileContent = try? NSMutableAttributedString(url: rtfURL, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
            }
            if mutableFileContent == nil {
                mutableFileContent = try? NSMutableAttributedString(url: rtfURL, documentAttributes: nil)
            }
            // Set the font color
            if mutableFileContent != nil {
                mutableFileContent!.addAttribute(.foregroundColor, value: UIColor.label, range: NSMakeRange(0, mutableFileContent!.length))
            }
            attributedText = mutableFileContent
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.filename
        self.view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: self.view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])
        textView.attributedText = attributedText
    }
}


