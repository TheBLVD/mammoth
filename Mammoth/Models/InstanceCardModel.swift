//
//  InstanceCardModel.swift
//  Mammoth
//
//  Created by Riley Howard on 9/13/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import SDWebImage

struct InstanceCardModel {
    let name: String
    let numberOfUsers: String?
    let languages: [String]?
    let description: String?
    let categories: [String]?
    let imageURL: String?
    var isPinned: Bool

    init(instance: tagInstance) {
        self.name = instance.name
        self.numberOfUsers = instance.users
        self.languages = instance.info?.languages
        self.description = instance.info?.shortDescription
        self.categories = instance.info?.categories
        self.imageURL = instance.thumbnail
        self.isPinned = InstanceManager.shared.pinnedStatusForInstance(instance.name) == .pinned
    }
            
    mutating func setPinnedStatus(_ pinned: Bool) {
        self.isPinned = pinned
    }
}

// MARK: - Preload
extension InstanceCardModel {
    func preloadImages() {
        
        let arrayOfURLS = [
            // Prefetch the profile picture
            self.imageURL,
        ]
        .filter({ !SDImageCache.shared.diskImageDataExists(withKey: $0) })
        .compactMap({URL(string: $0 ?? "")})
        
        if !arrayOfURLS.isEmpty {
            DispatchQueue.global(qos: .default).async {
                SDWebImagePrefetcher.shared.prefetchURLs(arrayOfURLS, progress: nil, completed: nil)
            }
        }
    }
}
