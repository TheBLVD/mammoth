//
//  IntentsStruct.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 29/09/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import AppIntents

@available(iOS 16, macCatalyst 16, *)
struct FocusFilterIntent: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "Focus"
    static var description: LocalizedStringResource? = "Display a streamlined view that focuses on the feed timeline"

    var displayRepresentation: DisplayRepresentation {
        let title = LocalizedStringResource("App Layout")
        let txt = "Streamlined Layout"
        let subtitle = LocalizedStringResource("\(txt)")
        return DisplayRepresentation(title: title, subtitle: subtitle)
    }

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
 
