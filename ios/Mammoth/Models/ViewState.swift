//
//  ViewState.swift
//  Mammoth
//
//  Created by Benoit Nolens on 11/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

enum ViewState {
    case idle
    case loading
    case success
    case error(Error)
}

extension ViewState: Equatable {
    static func ==(lhs: ViewState, rhs: ViewState) -> Bool {
        switch(lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.success, .success):
            return true
        default:
            return false
        }
    }
}
