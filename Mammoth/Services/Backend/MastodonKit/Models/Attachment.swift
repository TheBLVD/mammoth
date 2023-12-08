//
//  Attachment.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Attachment: Codable, Equatable {
    /// ID of the attachment.
    public let id: String
    /// Type of the attachment.
    public let type: AttachmentType
    /// URL of the locally hosted version of the image.
    public let url: String
    /// For remote images, the remote URL of the original image.
    public let remoteURL: String?
    /// URL of the preview image.
    public let previewURL: String?
    /// Shorter URL for the image, for insertion into text (only present on local images).
    public let textURL: String?
    /// A description of the image for the visually impaired.
    public let description: String?
    /// Image meta data.
    public let meta: AttachmentMeta?
    /// Blur hash
    public let blurhash: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case url
        case remoteURL = "remote_url"
        case previewURL = "preview_url"
        case textURL = "text_url"
        case description
        case meta
        case blurhash
    }
    
    init(image: Model.Embed.Images.ViewImage) {
        id = ""
        type = .image
        url = ""
        remoteURL = image.fullsize
        previewURL = image.thumb
        textURL = nil
        description = image.alt
        meta = nil
        blurhash = nil
    }
    
    public static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        return lhs.id != rhs.id &&
        lhs.url == rhs.url
    }
    
}

public class AttachmentMeta: Codable {
    public let small: AttachmentMeta2?
    public let original: AttachmentMeta2?

    private enum CodingKeys: String, CodingKey {
        case small
        case original
    }
}

public class AttachmentMeta2: Codable {
    public let width: Int?
    public let height: Int?
    public let size: String?
    public var aspect: Double?
//    public let frameRate: Int?
    public let duration: TimeInterval?
//    public let bitrate: String?

    private enum CodingKeys: String, CodingKey {
        case width
        case height
        case size
        case aspect
//        case frameRate = "frame_rate"
        case duration
//        case bitrate
    }
}
