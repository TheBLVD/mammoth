//
//  Notifications.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 5/17/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public struct Notifications {
    /// Fetches a user's notifications.
    ///
    /// - Parameter range: The bounds used when requesting data from Mastodon.
    /// - Returns: Request for `[Notification]`.
    public static func all(range: RequestRange = .default, typesToExclude: [NotificationType] = []) -> Request<[Notificationt]> {
        let parameters = range.parameters(limit: between(1, and: 15, default: 30)) ?? []
        let otherParameter = typesToExclude.map(toArrayOfParameters(withName: "exclude_types"))
        
        let otherParameter2 = ["admin.sign_up", "admin.report"].map(toArrayOfParameters(withName: "exclude_types"))
        
        let method = HTTPMethod.get(.parameters(parameters + otherParameter + otherParameter2))

        return Request<[Notificationt]>(path: "/api/v1/notifications", method: method)
    }

    /// Gets a single notification.
    ///
    /// - Parameter id: The notification id.
    /// - Returns: Request for `Notification`.
    public static func notification(id: String) -> Request<Notificationt> {
        return Request<Notificationt>(path: "/api/v1/notifications/\(id)")
    }

    /// Deletes all notifications for the authenticated user.
    ///
    /// - Returns: Request for `Empty`.
    public static func dismissAll() -> Request<Empty> {
        return Request<Empty>(path: "/api/v1/notifications/clear", method: .post(.empty))
    }

    /// Deletes a single notification for the authenticated user.
    ///
    /// - Parameter id: The notification id.
    /// - Returns: Request for `Empty`.
    public static func dismiss(id: String) -> Request<Empty> {
        let parameter = [Parameter(name: "id", value: String(id))]
        let method = HTTPMethod.post(.parameters(parameter))

        return Request<Empty>(path: "/api/v1/notifications/dismiss", method: method)
    }
}
