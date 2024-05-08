//
//  Media.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 5/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public struct Media {
    /// Uploads a media attachment.
    ///
    /// - Parameter mediaAttachment: The media attachment to upload.
    /// - Returns: Request for `Attachment`.
    public static func upload(media mediaAttachment: MediaAttachment) -> Request<Attachment> {
        let method = HTTPMethod.post(.media(mediaAttachment))
        return Request<Attachment>(path: "/api/v2/media", method: method)
    }
    
    public static func updateDescription(description: String, id: String) -> Request<Attachment> {
        let parameters = [
            Parameter(name: "description", value: description)
        ]
        
        let method = HTTPMethod.put(.parameters(parameters))
        return Request<Attachment>(path: "/api/v1/media/\(id)", method: method)
    }
}
