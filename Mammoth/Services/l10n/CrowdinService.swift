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
    
    static let germanLocales = ["de", "de-US", "de-AT", "de-BE", "de-CH", "de-DE", "de-LI", "de-LU"]
    static let spanishLocales = ["es", "es-AR", "es-BO", "es-CL", "es-CO", "es-CR", "es-DO", "es-EC", "es-SV", "es-SV", "es-GT", "es-HN", "es-MX", "es-NI", "es-PA", "es-PY", "es-PE", "es-PR", "es-ES", "es-UY", "es-VE"]
    static let italianLocales = ["it", "it_IT"]
    static let dutchLocales = ["nl", "nl-BE", "nl-NL",]
    
    
    public static func start() {
        let crowdinProviderConfig = CrowdinProviderConfig(hashString: ArkanaKeys.Global().crowdinDistributionString,
                                                          sourceLanguage: GlobalStruct.rootLocalization)
        
        let crowdinSDKConfig = CrowdinSDKConfig.config().with(crowdinProviderConfig: crowdinProviderConfig)
            .with(settingsEnabled: false)
        
        CrowdinSDK.startWithConfig(crowdinSDKConfig, completion: { })
    }
    
    public static func checkForSupportedLanguage() {
        // Fallback to root localization if current device language is not supported
        let supported = GlobalStruct.supportedLocalizations
        if let currentLanguage = self.getCurrentLocale() {
            if !supported.contains(currentLanguage) {
                CrowdinSDK.currentLocalization = GlobalStruct.rootLocalization
            } else {
                CrowdinSDK.currentLocalization = currentLanguage
            }
        } else {
            CrowdinSDK.currentLocalization = GlobalStruct.rootLocalization
        }
    }
    
    private static func getCurrentLocale() -> String? {
        return Locale.preferredLanguages[0]
    }
}
