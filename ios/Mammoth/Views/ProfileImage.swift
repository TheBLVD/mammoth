//
//  ProfileImage.swift
//  Mammoth
//
//  Created by Riley Howard on 6/22/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import SDWebImage

protocol ProfileImageDisplayer {
    func setProfileImage(image: UIImage?, selectedImage: UIImage?)
}

func currentProfileImages(image: UIImage? = nil, completion: @escaping ((_ image: UIImage?, _ selectedImage: UIImage?) -> Void)) {
    // Avatar is shown in the tabBar when ProfileIcon is on *and* there is more than one account signed in.
    // Otherwise the default profile icon is shown in the tabBar.
    if AccountsManager.shared.allAccounts.count > 1 {
        // It's *very* likely that SD_Image will have already cached the image from this URL.
        // We can take advantage of this to avoid flashing the generic 'person' image when
        // the user is switching accounts.
        var setImage = false
        if let image {
            setImage = true
            if GlobalStruct.circleProfiles {
                let resized = image.resize(targetSize: CGSize(width: 24, height: 24)).withRoundedCorners()?.withRenderingMode(.alwaysOriginal)
                completion(resized, resized)
            } else {
                let resized = image.resize(targetSize: CGSize(width: 24, height: 24)).withRoundedCorners(5)?.withRenderingMode(.alwaysOriginal)
                completion(resized, resized)
            }
        }
        // Use the backup method if SD_Image did not have the image.
        if !setImage {
            if let url = URL(string: AccountsManager.shared.currentAccount?.avatar ?? "") {
                URLSession.shared.dataTask(with: url) { data, response, error in
                    guard
                        let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                        let data = data, error == nil,
                        let _ = UIImage(data: data)
                    else {
                        log.error("Unable to get avatar from url: \(url)")
                        DispatchQueue.main.async() {
                            completion(FontAwesome.image(fromChar: "\u{f007}").withRenderingMode(.alwaysTemplate),
                                       FontAwesome.image(fromChar: "\u{f007}", weight: .bold).withRenderingMode(.alwaysTemplate))
                        }
                        return
                    }
                    DispatchQueue.main.async() {
                        let image = UIImage(data: data)!
                        if GlobalStruct.circleProfiles {
                            let resized = image.resize(targetSize: CGSize(width: 24, height: 24)).withRoundedCorners()?.withRenderingMode(.alwaysOriginal)
                            completion(resized, resized)
                        } else {
                            let resized = image.resize(targetSize: CGSize(width: 24, height: 24)).withRoundedCorners(5)?.withRenderingMode(.alwaysOriginal)
                            completion(resized, resized)
                        }
                    }
                }.resume()
            } else {
                completion(FontAwesome.image(fromChar: "\u{f007}").withRenderingMode(.alwaysTemplate),
                           FontAwesome.image(fromChar: "\u{f007}", weight: .bold).withRenderingMode(.alwaysTemplate))
            }
        }
    } else {
        completion(FontAwesome.image(fromChar: "\u{f007}").withRenderingMode(.alwaysTemplate),
                   FontAwesome.image(fromChar: "\u{f007}", weight: .bold).withRenderingMode(.alwaysTemplate))
    }
}
