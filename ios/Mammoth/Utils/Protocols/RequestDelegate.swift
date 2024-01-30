//
//  RequestDelegate.swift
//  Mammoth
//
//  Created by Benoit Nolens on 11/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

protocol RequestDelegate: AnyObject {
    func didUpdate(with state: ViewState)
    func didUpdateCard(at indexPath: IndexPath)
    func didDeleteCard(at indexPath: IndexPath)
}
