//
//  SKMesurement.swift
//  SKPhotoBrowser
//
//  Created by 鈴木 啓司 on 2016/08/09.
//  Copyright © 2016年 suzuki_keishi. All rights reserved.
//

import Foundation
import UIKit

struct SKMesurement {
    static let isPhone: Bool = UIDevice.current.userInterfaceIdiom == .phone
    static let isPad: Bool = UIDevice.current.userInterfaceIdiom == .pad
    static var statusBarH: CGFloat {
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        return window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    }
    static var screenHeight: CGFloat {
        return UIApplication.shared.preferredApplicationWindow?.rootViewController?.view.bounds.height ?? UIScreen.main.bounds.height
    }
    static var screenWidth: CGFloat {
        return UIApplication.shared.preferredApplicationWindow?.rootViewController?.view.bounds.width ?? UIScreen.main.bounds.width
    }
    static var screenScale: CGFloat {
        return UIScreen.main.scale
    }
    static var screenRatio: CGFloat {
        return screenWidth / screenHeight
    }
    static var isPhoneX: Bool {
        let iPhoneXHeights: [CGFloat] = [2436, 2688, 1792]
        if isPhone, iPhoneXHeights.contains(UIScreen.main.nativeBounds.height) {
           return true
        }
        return false
    }
}
