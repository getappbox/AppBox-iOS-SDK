//
//  ExampleConfiguration.swift
//  AppBoxSDKExample
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Foundation

/// Where this sample gets the link it watches.
///
/// Upload a build with `fastlane appbox_demo`, then paste the link the lane prints below — or pass it in without
/// editing code by setting `APPBOX_INSTALL_LINK` in the scheme's environment variables.
enum ExampleConfiguration {
    static let installLink = ProcessInfo.processInfo.environment["APPBOX_INSTALL_LINK"] ?? fallbackInstallLink

    /// Replace this with the install link AppBox gave you: the `appbox.me` short link, the `web.getappbox.com`
    /// install page link, or the Dropbox share link of the build's `appinfo.json`.
    private static let fallbackInstallLink = "https://appbox.me/2zyazagj"

    static var isConfigured: Bool {
        !installLink.isEmpty
    }
}
