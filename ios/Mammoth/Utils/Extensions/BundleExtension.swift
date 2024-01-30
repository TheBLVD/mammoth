//
//  BundleExtension.swift
//  Mammoth
//
//  Created by Jesse Tomchak on 4/14/23.
//  Allowing for quick access to regularly used Bundle plist info

import Foundation
extension Bundle {

    public var appBuild: String          { getInfo("CFBundleVersion") }
    public var appVersion: String    { getInfo("CFBundleShortVersionString") }
    
    public var deviceType:  String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier;
    }
    
    public var systemVersion: String {
        let iOSProcessInfo = ProcessInfo.processInfo.operatingSystemVersion
        let iOSVersion = String(iOSProcessInfo.majorVersion) + "." + String(iOSProcessInfo.minorVersion) + "." + String(iOSProcessInfo.patchVersion)
        return iOSVersion;
    }
    
    
    fileprivate func getInfo(_ str: String) -> String { Bundle.main.infoDictionary?[str] as? String ?? "⚠️" }
}
