//
//  ActivityCardModel.swift
//  Mammoth
//
//  Created by Benoit Nolens on 01/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class ActivityCardModel {
    let id: String  // Local ID (might not be unique across instances)
    let uniqueId: String // Unique ID across instances
    var cursorId: String // ID used for pagination
    let type: NotificationType
    let notification: Notificationt
    var postCard: PostCardModel?
    let user: UserCardModel
    var createdAt: Date
    var time: String
    
    var cellHeight: CGFloat?
    
    // Debug properties
    var batchId: String?
    var batchItemIndex: Int?
    
    init(notification: Notificationt, batchId: String? = nil, batchItemIndex: Int? = nil) {
        self.id = notification.id
        self.uniqueId = notification.id
        self.cursorId = self.id
        self.type = notification.type
        self.notification = notification
        self.createdAt = notification.createdAt.toDate()
        self.time = Self.formattedTime(notification: notification, formatter: GlobalStruct.dateFormatter)
        
        if let status = notification.status {
            self.postCard = PostCardModel(status: status)
        } else {
            self.postCard = nil
        }
        
        self.user = UserCardModel(account: notification.account)
        
        self.batchId = batchId
        self.batchItemIndex = batchItemIndex
    }
}

extension ActivityCardModel {
    static func formattedTime(notification: Notificationt, formatter: DateFormatter) -> String {
        let createdAt = notification.createdAt
        var timeStr = formatter.date(from: createdAt)?.toStringWithRelativeTime() ?? ""

        if GlobalStruct.timeStampStyle == 1 {
            let createdAt = notification.createdAt
           timeStr = formatter.date(from: createdAt)?.toString(dateStyle: .short, timeStyle: .short) ?? ""
        } else if GlobalStruct.timeStampStyle == 2 {
           timeStr = ""
        }

        return timeStr
    }
}

extension ActivityCardModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueId)
    }
}

extension ActivityCardModel: Equatable {
    static func == (lhs: ActivityCardModel, rhs: ActivityCardModel) -> Bool {
        return lhs.uniqueId == rhs.uniqueId && lhs.postCard == rhs.postCard
    }
}
