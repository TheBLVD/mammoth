//
//  FailableDecodable.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

struct FailableDecodable<T: Decodable> : Decodable {

    let value: T?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        do {
            self.value = try container.decode(T.self)
        } catch {
            log.error(error.localizedDescription)
            self.value = nil
        }
    }
    
}
