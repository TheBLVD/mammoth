//
//  CharacterSet+.swift
//  Mammoth
//
//  Created by Kern Jackson on 6/29/24
//  Copyright © 2024 The BLVD. All rights reserved.
//

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@"
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: generalDelimitersToEncode + subDelimitersToEncode)

        return allowed
    }()
}
