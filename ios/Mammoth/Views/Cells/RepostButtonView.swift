//
//  RepostButtonView.swift
//  Mammoth
//
//  Created by Jesse Tomchak on 4/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit


class RepostButtonView: UIView {
    // repost / quote post button
    let repostOverlayButton = UIButton(type: .custom)
    let repostIcon = UIImageView()
    let repostProfileIcon = UIImageView()
    let repostText = UILabel()
    
    override init(frame: CGRect) {
              super.init(frame: frame)
              commonInit()
         }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
                   commonInit()
    }
    
    private func commonInit(){
        // reposts
        let symbolConfig2 = UIImage.SymbolConfiguration(pointSize: GlobalStruct.smallerFontSize - 2, weight: .semibold)
        repostIcon.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        repostIcon.image = UIImage(systemName: "arrow.2.squarepath", withConfiguration: symbolConfig2)?.withTintColor(.custom.actionButtons, renderingMode: .alwaysOriginal)
        repostIcon.contentMode = .scaleAspectFit
        repostIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        repostIcon.accessibilityIdentifier = "repostIcon"

        repostProfileIcon.translatesAutoresizingMaskIntoConstraints = false
        repostProfileIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        repostProfileIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true
        repostProfileIcon.contentMode = .scaleAspectFit
        repostProfileIcon.layer.masksToBounds = true
        repostProfileIcon.layer.cornerRadius = 8
        repostProfileIcon.layer.masksToBounds = true
        repostProfileIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        repostProfileIcon.accessibilityIdentifier = "repostProfileIcon"

        repostText.frame = CGRect(x: 30, y: 0, width: 30, height: 20)
        repostText.text = ""
        repostText.textColor = .custom.actionButtons
        repostText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        repostText.sizeToFit()
        repostText.lineBreakMode = .byTruncatingTail
        repostText.accessibilityIdentifier = "repostText"

        let spacer = UIView()
        spacer.isUserInteractionEnabled = false
        spacer.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)

        // Create a stack view to put inside the button
        let stackInButton = UIStackView()
        stackInButton.translatesAutoresizingMaskIntoConstraints = false
        stackInButton.addArrangedSubview(repostIcon)
        stackInButton.addArrangedSubview(repostProfileIcon)
        stackInButton.addArrangedSubview(repostText)
        stackInButton.addArrangedSubview(spacer)
        stackInButton.axis = .horizontal
        stackInButton.distribution = .fill
        stackInButton.spacing = 4
        stackInButton.isUserInteractionEnabled = false
        repostOverlayButton.addSubview(stackInButton)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.isUserInteractionEnabled = true

        // Add the button to the container
        self.addSubview(repostOverlayButton)
        
        // Line up the edges of the button with the stack inside it
        repostOverlayButton.translatesAutoresizingMaskIntoConstraints = false
        repostOverlayButton.addConstraints( [
            repostOverlayButton.leftAnchor.constraint(equalTo: stackInButton.leftAnchor),
            repostOverlayButton.topAnchor.constraint(equalTo: stackInButton.topAnchor),
            repostOverlayButton.bottomAnchor.constraint(equalTo: stackInButton.bottomAnchor),
            repostOverlayButton.rightAnchor.constraint(equalTo: stackInButton.rightAnchor)
        ])

        // The existing repostView has a specfific height/layout in the existing cell
        // UI, so let's not modify its constraints. We just want the button to feel
        // bigger whem the user does a tap / tap-and-hold.
        self.addConstraints( [
            self.leftAnchor.constraint(equalTo: repostOverlayButton.leftAnchor, constant: 8),
            self.topAnchor.constraint(equalTo: repostOverlayButton.topAnchor, constant: 8),
            self.bottomAnchor.constraint(equalTo: repostOverlayButton.bottomAnchor, constant: -8),
            self.rightAnchor.constraint(equalTo: repostOverlayButton.rightAnchor, constant: -8)
        ])
    }
    
}
