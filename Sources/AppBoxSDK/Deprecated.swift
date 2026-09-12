//
//  Deprecated.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Foundation

extension AppBox {
    @available(*, deprecated, renamed: "shared")
    public static var Default: AppBox { shared }

    /// - Warning: app update keys only address Dropbox's legacy `/s/` share links. Pass the install link AppBox shows for the build instead.
    @available(*, deprecated, message: "Use start(link:configuration:) with the install link AppBox gave you for the build.")
    public static func start(key: String,
                             alertType: AppBoxAlertStyle = .skippable,
                             checkVersionOnly: Bool = true) {
        start(link: key,
              configuration: AppBoxConfiguration(alertStyle: alertType,
                                                 comparison: checkVersionOnly ? .version : .versionAndBuild))
    }

    @available(*, deprecated, renamed: "link")
    public var key: String? { link }

    @available(*, deprecated, message: "Read configuration.comparison instead.")
    public var checkVersionOnly: Bool { configuration.comparison == .version }

    @available(*, deprecated, message: "Read configuration.alertStyle instead.")
    public var alertType: AppBoxAlertStyle { configuration.alertStyle }
}
