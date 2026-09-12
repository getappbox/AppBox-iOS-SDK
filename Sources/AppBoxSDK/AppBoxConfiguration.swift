//
//  AppBoxConfiguration.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Foundation

/// Which alert buttons the user is offered when a newer build is available.
public enum AppBoxAlertStyle: Sendable, Equatable {
    /// One button: the user can only update.
    case forced
    /// Two buttons: update now, or next launch.
    case optional
    /// Three buttons: update now, next launch, or skip this build entirely.
    case skippable

    @available(*, deprecated, renamed: "forced")
    public static var force: Self { .forced }

    @available(*, deprecated, renamed: "optional")
    public static var option: Self { .optional }

    @available(*, deprecated, renamed: "skippable")
    public static var skip: Self { .skippable }
}

/// What the user chose on the update alert.
public enum AppBoxAlertAction: Sendable, Equatable {
    /// Update: the install page was opened.
    case update
    /// Next time: the alert was dismissed and will be shown again.
    case later
    /// Skip: this version and build will not be offered again.
    case skip

    @available(*, deprecated, renamed: "update")
    public static var appBox: Self { .update }

    @available(*, deprecated, renamed: "later")
    public static var nextTime: Self { .later }
}

/// How the installed build is compared against the one AppBox published.
public enum AppBoxVersionComparison: Sendable, Equatable {
    /// Only `CFBundleShortVersionString` is compared.
    case version
    /// `CFBundleShortVersionString` first, then `CFBundleVersion` when the versions match.
    case versionAndBuild
}

/// Everything tunable about an `AppBox.start(link:configuration:)` session.
public struct AppBoxConfiguration: Sendable, Equatable {
    /// Buttons offered on the update alert. Defaults to `.skippable`.
    public var alertStyle: AppBoxAlertStyle

    /// Whether the build number takes part in the comparison. Defaults to `.version`.
    public var comparison: AppBoxVersionComparison

    /// Re-check when the app returns to the foreground. Defaults to `true`.
    public var checksOnForeground: Bool

    /// Shortest gap between two automatic checks, in seconds. Defaults to 60.
    public var minimumCheckInterval: TimeInterval

    /// Present the built-in alert when an update is found. Set `false` to drive your own UI from `AppBox.updateHandler`.
    public var presentsAlert: Bool

    /// Base URL of the AppBox install service that proxies `appinfo.json`. Set to `nil` to read the share link straight from Dropbox, or to your own host when you self-host the AppBox install helper.
    public var serviceBaseURL: URL?

    /// Log SDK activity through `os.Logger`. Defaults to `true` in debug builds.
    public var isLoggingEnabled: Bool

    public static let defaultServiceBaseURL = URL(string: "https://install.getappbox.com")!

    public init(alertStyle: AppBoxAlertStyle = .skippable,
                comparison: AppBoxVersionComparison = .version,
                checksOnForeground: Bool = true,
                minimumCheckInterval: TimeInterval = 60,
                presentsAlert: Bool = true,
                serviceBaseURL: URL? = AppBoxConfiguration.defaultServiceBaseURL,
                isLoggingEnabled: Bool = AppBoxConfiguration.defaultLoggingEnabled) {
        self.alertStyle = alertStyle
        self.comparison = comparison
        self.checksOnForeground = checksOnForeground
        self.minimumCheckInterval = minimumCheckInterval
        self.presentsAlert = presentsAlert
        self.serviceBaseURL = serviceBaseURL
        self.isLoggingEnabled = isLoggingEnabled
    }

    /// `true` in debug builds, `false` otherwise.
    public static var defaultLoggingEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

@available(*, deprecated, renamed: "AppBoxAlertStyle")
public typealias AlertType = AppBoxAlertStyle

@available(*, deprecated, renamed: "AppBoxAlertAction")
public typealias AlertAction = AppBoxAlertAction
