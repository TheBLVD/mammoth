//
//  ChannelPic.swift
//  Mammoth
//
//  Created by Riley Howard on 9/27/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class ChannelPic: StaticPic {
    
    // MARK: - Configuration
    func configure(channel: Channel) {
        let imageChar = channel.icon ?? "\u{f03a}"
        setImage(FontAwesome.image(fromChar: imageChar, size: 15, weight: .bold).withRenderingMode(.alwaysTemplate))
    }
}

