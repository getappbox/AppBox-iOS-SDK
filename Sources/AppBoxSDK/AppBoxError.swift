//
//  AppBoxError.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Foundation

/// Everything that can go wrong while checking for an update.
public enum AppBoxError: Error, Sendable, Equatable {
    /// `AppBox.start(link:)` has not been called yet.
    case notStarted
    /// The link could not be read as an AppBox install link, a Dropbox `appinfo.json` share link, or a legacy app update key.
    case invalidLink(String)
    /// The request failed before a response arrived.
    case requestFailed(String)
    /// The service answered with a status other than 2xx.
    case unexpectedStatus(Int)
    /// The response body was not the `appinfo.json` the SDK expected.
    case invalidResponse(String)
    /// `appinfo.json` carried no `latestVersion` entry.
    case noPublishedBuild
    /// `appinfo.json` carried no install link to open.
    case noInstallLink
    /// The host app's `Info.plist` has no `CFBundleShortVersionString`.
    case missingBundleVersion
}

extension AppBoxError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notStarted:
            return "AppBox has not been started. Call AppBox.start(link:) first."
        case .invalidLink(let link):
            return "'\(link)' is not an AppBox install link, a Dropbox appinfo.json share link, or an app update key."
        case .requestFailed(let reason):
            return "Could not reach the AppBox install service: \(reason)"
        case .unexpectedStatus(let code):
            return "The AppBox install service answered with HTTP \(code)."
        case .invalidResponse(let reason):
            return "Could not read appinfo.json: \(reason)"
        case .noPublishedBuild:
            return "appinfo.json has no published build yet."
        case .noInstallLink:
            return "appinfo.json has no install link."
        case .missingBundleVersion:
            return "The app's Info.plist has no CFBundleShortVersionString."
        }
    }
}
