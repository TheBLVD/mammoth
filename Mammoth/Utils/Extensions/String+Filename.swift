//
//  String+Filename.swift
//  Mammoth
//
//  Created by Benoit Nolens on 11/07/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

extension String {
    var sanitizedFileName: String {
        return components(separatedBy: .init(charactersIn: "\\/:*?\"<>|")).joined()
    }
}
