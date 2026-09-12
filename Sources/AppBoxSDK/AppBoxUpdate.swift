//
//  AppBoxUpdate.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Foundation

/// A build AppBox has published that is newer than the one running.
public struct AppBoxUpdate: Sendable, Equatable {
    /// App name as recorded in the uploaded build.
    public let name: String

    /// `CFBundleShortVersionString` of the published build.
    public let version: String

    /// `CFBundleVersion` of the published build.
    public let build: String

    /// The page to open to install the build.
    public let installURL: URL

    /// When the build was uploaded.
    public let uploadDate: Date?

    /// Minimum iOS version the build supports.
    public let minimumOSVersion: String?

    /// `development`, `ad-hoc` or `enterprise`, when AppBox recorded it.
    public let buildType: String?

    /// IPA size in megabytes, when AppBox recorded it.
    public let fileSizeMB: Int?

    /// `1.2 (34)`, or just the version when the build number is unknown.
    public var displayVersion: String {
        build.isEmpty ? version : "\(version) (\(build))"
    }

    public init(name: String, version: String, build: String, installURL: URL,
                uploadDate: Date? = nil, minimumOSVersion: String? = nil,
                buildType: String? = nil, fileSizeMB: Int? = nil) {
        self.name = name
        self.version = version
        self.build = build
        self.installURL = installURL
        self.uploadDate = uploadDate
        self.minimumOSVersion = minimumOSVersion
        self.buildType = buildType
        self.fileSizeMB = fileSizeMB
    }
}
