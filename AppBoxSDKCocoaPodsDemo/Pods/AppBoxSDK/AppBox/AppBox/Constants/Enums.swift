//
//  Enums.swift
//  AppBox
//
//  Created by Vineet Choudhary on 13/08/19.
//  Copyright © 2019 Developer Insdier. All rights reserved.
//

import Foundation

public enum AlertType {
    /// Forces the user to update your app (1 button alert).
    case force
    /// Presents the user with option to update app now or at next launch (2 button alert).
    case option
    /// Presents the user with option to update the app now, at next launch, or to skip this version all together (3 button alert).
    case skip
}

public enum AlertAction {
    /// The user clicked on the `Update` option, which took them to the app's App Store page.
    case appBox
    /// The user clicked on the `Next Time` option, which dismissed the alert.
    case nextTime
    /// The user clicked on the `Skip this version` option, which dismissed the alert.
    case skip
}

extension AlertAction: CustomStringConvertible {
    public var description: String {
        switch self {
        case .appBox:
            return "update"
        case .nextTime:
            return "update next time"
        case .skip:
            return "skip"
        }
    }
}
