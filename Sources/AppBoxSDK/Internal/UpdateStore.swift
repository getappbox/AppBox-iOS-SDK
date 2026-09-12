//
//  UpdateStore.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Foundation

/// What the SDK remembers between launches.
@MainActor
protocol UpdateStoring: AnyObject {
    var skippedBuild: SkippedBuild? { get set }
    var lastCheckDate: Date? { get set }
    func cachedSharePath(forLink link: String) -> String?
    func cacheSharePath(_ sharePath: String, forLink link: String)
}

/// `UserDefaults` backed store. Keys are namespaced so they cannot collide with the host app's.
@MainActor
final class UserDefaultsUpdateStore: UpdateStoring {
    private enum Key {
        static let skippedVersion = "com.getappbox.sdk.skippedVersion"
        static let skippedBuild = "com.getappbox.sdk.skippedBuild"
        static let lastCheckDate = "com.getappbox.sdk.lastCheckDate"
        static let sharePaths = "com.getappbox.sdk.sharePaths"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var skippedBuild: SkippedBuild? {
        get {
            guard let version = defaults.string(forKey: Key.skippedVersion) else { return nil }
            return SkippedBuild(version: version, build: defaults.string(forKey: Key.skippedBuild) ?? "")
        }
        set {
            defaults.set(newValue?.version, forKey: Key.skippedVersion)
            defaults.set(newValue?.build, forKey: Key.skippedBuild)
        }
    }

    var lastCheckDate: Date? {
        get { defaults.object(forKey: Key.lastCheckDate) as? Date }
        set { defaults.set(newValue, forKey: Key.lastCheckDate) }
    }

    /// A short link costs a redirect to resolve, so the share path it led to is remembered.
    func cachedSharePath(forLink link: String) -> String? {
        (defaults.dictionary(forKey: Key.sharePaths) as? [String: String])?[link]
    }

    func cacheSharePath(_ sharePath: String, forLink link: String) {
        var paths = (defaults.dictionary(forKey: Key.sharePaths) as? [String: String]) ?? [:]
        paths[link] = sharePath
        defaults.set(paths, forKey: Key.sharePaths)
    }
}
