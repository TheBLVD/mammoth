//
//  CrowdinService.swift
//  Mammoth
//
//  Created by Benoit Nolens on 08/03/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import Foundation
import CrowdinSDK
import ArkanaKeys

struct l10n {

    public static func start() {
        let crowdinProviderConfig = CrowdinProviderConfig(hashString: ArkanaKeys.Global().crowdinDistributionString,
                                                          sourceLanguage: GlobalStruct.rootLocalization)
        
        let crowdinSDKConfig = CrowdinSDKConfig.config().with(crowdinProviderConfig: crowdinProviderConfig)
            .with(settingsEnabled: false)
        
        CrowdinSDK.startWithConfig(crowdinSDKConfig, completion: { })
    }
    
    public static func isCurrentLanguageSupported() -> Bool {
        let supported = GlobalStruct.supportedLocalizations
        if let currentLocale = self.getCurrentLocale() {
            if !supported.contains(currentLocale) {
                if let range = currentLocale.range(of: "-") {
                    let languageCode = String(currentLocale[currentLocale.startIndex..<range.lowerBound])
                    if supported.contains(languageCode) {
                        return true
                    }
                }
                
                return false
                
            } else {
                return true
            }
        }
        
        return false
    }
    
    public static func checkForSupportedLanguage() {
        // Fallback to root localization if current device language is not supported
        let supported = GlobalStruct.supportedLocalizations
        if let currentLocale = self.getCurrentLocale() {
            if !supported.contains(currentLocale) {
                if let range = currentLocale.range(of: "-") {
                    let languageCode = String(currentLocale[currentLocale.startIndex..<range.lowerBound])
                    if supported.contains(languageCode) {
                        CrowdinSDK.currentLocalization = languageCode
                        return
                    }
                }
                
                CrowdinSDK.currentLocalization = GlobalStruct.rootLocalization
                
            } else {
                CrowdinSDK.currentLocalization = currentLocale
                return
            }
        }
        
        CrowdinSDK.currentLocalization = GlobalStruct.rootLocalization
    }
    
    public static func getCurrentLocale() -> String? {
        return Locale.preferredLanguages[0]
    }
}
