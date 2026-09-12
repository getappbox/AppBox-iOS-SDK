//
//  InstalledBuild.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Foundation

/// The version, build and name of the app that is running.
struct InstalledBuild: Equatable, Sendable {
    let name: String
    let version: String
    let build: String

    init(name: String, version: String, build: String) {
        self.name = name
        self.version = version
        self.build = build
    }

    init(bundle: Bundle) throws {
        let info = bundle.infoDictionary ?? [:]
        guard let version = info["CFBundleShortVersionString"] as? String, !version.isEmpty else {
            throw AppBoxError.missingBundleVersion
        }
        self.version = version
        build = info["CFBundleVersion"] as? String ?? ""
        name = (info["CFBundleDisplayName"] as? String) ?? (info["CFBundleName"] as? String) ?? ""
    }
}
