//
//  CardType.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 14/03/2019.
//  Copyright © 2019 Shihab Mehboob. All rights reserved.
//

import Foundation

public enum CardType: String, Codable {
    /// The card contains a link.
    case link
    /// The attachment contains a photo.
    case photo
    /// The attachment contains a video.
    case video
    /// The attachment contains rich text.
    case rich
}
