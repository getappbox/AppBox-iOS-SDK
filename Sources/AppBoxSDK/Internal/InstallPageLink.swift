//
//  InstallPageLink.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Foundation

/// The page a user opens to install a published build.
enum InstallPageLink {
    static let defaultBase = "https://web.getappbox.com"

    /// `uniqueLinkShort` when AppBox wrote one, else the install page built from the `appinfo.json` share link.
    static func url(for appInfo: AppInfo) -> URL? {
        if let short = appInfo.uniqueLinkShort, let url = URL(string: short) {
            return url
        }
        guard let shared = appInfo.uniqueLinkShared, let url = URL(string: shared) else { return nil }
        return make(fromDropboxShareURL: url) ?? url
    }

    /// Mirrors how AppBox itself builds the install link, so an `appinfo.json` written before short links still resolves.
    static func make(fromDropboxShareURL shareURL: URL, base: String = defaultBase) -> URL? {
        let absolute = shareURL.absoluteString
        guard let range = absolute.range(of: "dropbox.com") else { return nil }
        let sharePath = escapedForQueryValue(String(absolute[range.upperBound...]))
        return URL(string: "\(base)?url=\(sharePath)")
    }

    private static func escapedForQueryValue(_ value: String) -> String {
        value.replacingOccurrences(of: "%", with: "%25")
            .replacingOccurrences(of: "&", with: "%26")
            .replacingOccurrences(of: "#", with: "%23")
    }
}
