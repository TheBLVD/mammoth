//
//  LinkOpener.swift
//  Mammoth
//
//  Created by Kern Jackson on 6/29/24
//  Copyright © 2024 The BLVD. All rights reserved.
//

//
//  LinkOpener.swift
//  Proton Mail - Created on 16/09/2019.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import UIKit

enum LinkOpener: String, CaseIterable {
    
    case safari = "Safari"
    case mammoth = "In-app browser"
    case brave = "Brave"
    case chrome = "Chrome"
    case duckDuckGo = "DuckDuckGo"
    case edge = "Edge"
    case firefox = "Firefox"
    case firefoxFocus = "Firefox Focus"
    case operaMini = "Opera Mini"
    case operaTouch = "Opera Touch"
    
    private var scheme: String {
        switch self {
        case .safari, .mammoth: return "https"
        case .chrome: return "googlechrome"
        case .firefox: return "firefox"
        case .firefoxFocus: return "firefox-focus"
        case .operaMini: return "opera-http"
        case .operaTouch: return "touch-http"
        case .brave: return "brave"
        case .edge: return "microsoft-edge-http"
        case .duckDuckGo: return "ddgQuickLink"
        }
    }

    var title: String {
        switch self {
        case .safari: return "System Default"
        case .mammoth: return "In-app browser"
        case .brave: return "Brave"
        case .chrome: return "Chrome"
        case .duckDuckGo: return "DuckDuckGo"
        case .edge: return "Edge"
        case .firefox: return "Firefox"
        case .firefoxFocus: return "Firefox Focus"
        case .operaMini: return "Opera Mini"
        case .operaTouch: return "Opera Touch"
        }
    }

    var isInstalled: Bool {
        guard let scheme = URL(string: "\(self.scheme)://") else {
            return false
        }
        return ProcessInfo.isRunningUnitTests || UIApplication.shared.canOpenURL(scheme)
    }

    static func checkInstalledBrowsers() -> [String] {
        var installedBrowsers = [String]()

        for browser in LinkOpener.allCases where browser.isInstalled {
            installedBrowsers.append(browser.title)
        }
        return installedBrowsers
    }

    static func getSelectedBrowser() -> LinkOpener {
        if let rawValue = UserDefaults.standard.string(forKey: "PreferredBrowser") {
            return LinkOpener(rawValue: rawValue) ?? .safari
        }
        return .safari
    }

    func deeplink(to url: URL) -> URL {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           components.scheme == "tel" {
            return url
        }

        guard isInstalled else {
            return url
        }

        var specificURL: URL?
        switch self {
        case .chrome, .edge, .operaMini, .operaTouch:
            if var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                components.scheme = components.scheme == "https" ? "\(scheme)s" : scheme
                specificURL = components.url
            }
        case .brave, .firefox, .firefoxFocus:
            if let escapedUrl = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) {
                specificURL = URL(string: "\(scheme)://open-url?url=\(escapedUrl)")
            }
        case .duckDuckGo:
            if var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                components.scheme = scheme
                specificURL = components.url
            }
        case .safari, .mammoth:
            break
        }

        return specificURL ?? url
    }
}
