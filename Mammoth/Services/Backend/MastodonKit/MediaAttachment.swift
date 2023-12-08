//
//  MediaAttachment.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 5/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public enum MediaAttachment {
    /// JPEG (Joint Photographic Experts Group) image
    case jpeg(Data?)
    /// GIF (Graphics Interchange Format) image
    case gif(Data?)
    /// Video
    case video(Data?)
    /// PNG (Portable Network Graphics) image
    case png(Data?)
    /// MP3
    case mp3(Data?)
    /// Other media file
    case other(Data?, fileExtension: String, mimeType: String)
}

extension MediaAttachment {
    var data: Data? {
        switch self {
        case .jpeg(let data): return data
        case .gif(let data): return data
        case .video(let data): return data
        case .png(let data): return data
        case .mp3(let data): return data
        case .other(let data, _, _): return data
        }
    }

    var fileName: String {
        if OtherStruct.medType == 0 {
            switch self {
            case .jpeg: return "file.jpeg"
            case .gif: return "file.gif"
            case .video: return "file.mp4"
            case .png: return "file.png"
            case .mp3: return "file.mp3"
            case .other(_, let fileExtension, _): return "file.\(fileExtension)"
            }
        } else if OtherStruct.medType == 1 {
            switch self {
            case .jpeg: return "avatar.jpeg"
            case .gif: return ".gif"
            case .video: return "avatar.mp4"
            case .png: return "avatar.png"
            case .mp3: return "avatar.mp3"
            case .other(_, let fileExtension, _): return "avatar.\(fileExtension)"
            }
        } else {
            switch self {
            case .jpeg: return "header.jpeg"
            case .gif: return "header.gif"
            case .video: return "header.mp4"
            case .png: return "header.png"
            case .mp3: return "header.mp3"
            case .other(_, let fileExtension, _): return "header.\(fileExtension)"
            }
        }
    }

    var mimeType: String {
        switch self {
        case .jpeg: return "image/jpg"
        case .gif: return "image/gif"
        case .video: return "video/mp4"
        case .png: return "image/png"
        case .mp3: return "audio/mpeg"
        case .other(_, _, let mimeType): return mimeType
        }
    }

    var base64EncondedString: String? {
        return data.map { "data:" + mimeType + ";base64," + $0.base64EncodedString() }
    }
}
