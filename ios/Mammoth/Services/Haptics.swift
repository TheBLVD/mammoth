//
//  Haptics.swift
//  Mammoth
//
//  Created by Nathan Liu on 6/16/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

public func triggerHapticImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    if GlobalStruct.hapticsEnabled {
        let haptics = UIImpactFeedbackGenerator(style: style) //default to medium if arg not present
        haptics.impactOccurred()
    }
}

public func triggerHaptic2Impact() {
    if GlobalStruct.hapticsEnabled {
        let haptics = UIImpactFeedbackGenerator(style: .rigid)
        haptics.impactOccurred()
    }
}

public func triggerHaptic3Impact() {
    if GlobalStruct.hapticsEnabled {
        let haptics = UIImpactFeedbackGenerator(style: .light)
        haptics.impactOccurred()
    }
}

public func triggerKeyHapticImpact() {
    if GlobalStruct.hapticsEnabled {
        let haptics = UIImpactFeedbackGenerator(style: .rigid)
        haptics.impactOccurred()
    }
}

public func triggerHapticNotification(feedback: UINotificationFeedbackGenerator.FeedbackType = .success) {
    if GlobalStruct.hapticsEnabled {
        let haptics = UINotificationFeedbackGenerator()
        haptics.notificationOccurred(feedback) 
    }
}

public func triggerHaptic3Notification() {
    if GlobalStruct.hapticsEnabled {
        let haptics = UINotificationFeedbackGenerator()
        haptics.notificationOccurred(.success)
    }
}

public func triggerHapticSelectionChanged() {
    if GlobalStruct.hapticsEnabled {
        let haptics = UISelectionFeedbackGenerator()
        haptics.selectionChanged()
    }
}
