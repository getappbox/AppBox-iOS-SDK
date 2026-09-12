//
//  UpdateDecision.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Foundation

/// One published build the user has chosen not to be offered again.
struct SkippedBuild: Equatable, Sendable {
    let version: String
    let build: String
}

/// Whether a published build should be offered to the user.
enum UpdateDecision: Equatable, Sendable {
    case upToDate
    case skippedByUser
    case available

    static func evaluate(published: AppInfoVersion,
                         installed: InstalledBuild,
                         comparison: AppBoxVersionComparison,
                         skipped: SkippedBuild?) -> UpdateDecision {
        guard isNewer(published: published, than: installed, comparison: comparison) else {
            return .upToDate
        }
        if let skipped, skipped.version == published.version, skipped.build == published.build {
            return .skippedByUser
        }
        return .available
    }

    private static func isNewer(published: AppInfoVersion,
                                than installed: InstalledBuild,
                                comparison: AppBoxVersionComparison) -> Bool {
        switch VersionOrder.compare(published.version, installed.version) {
        case .orderedDescending:
            return true
        case .orderedAscending:
            return false
        case .orderedSame:
            guard comparison == .versionAndBuild else { return false }
            return VersionOrder.isNewer(published.build, than: installed.build)
        }
    }
}
