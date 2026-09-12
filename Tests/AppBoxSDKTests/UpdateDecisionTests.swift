//
//  UpdateDecisionTests.swift
//  AppBoxSDKTests
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Testing
@testable import AppBoxSDK

struct UpdateDecisionTests {
    private let installed = InstalledBuild(name: "Demo", version: "1.2", build: "34")

    private func published(version: String, build: String) -> AppInfoVersion {
        AppInfoVersion(name: "Demo", version: version, build: build)
    }

    @Test func offersANewerVersion() {
        let decision = UpdateDecision.evaluate(published: published(version: "1.3", build: "1"),
                                               installed: installed, comparison: .version, skipped: nil)
        #expect(decision == .available)
    }

    @Test func staysQuietOnTheSameVersion() {
        let decision = UpdateDecision.evaluate(published: published(version: "1.2", build: "34"),
                                               installed: installed, comparison: .version, skipped: nil)
        #expect(decision == .upToDate)
    }

    @Test func staysQuietOnAnOlderVersion() {
        let decision = UpdateDecision.evaluate(published: published(version: "1.1", build: "99"),
                                               installed: installed, comparison: .version, skipped: nil)
        #expect(decision == .upToDate)
    }

    /// A rebuild of the same version is only an update when the build number counts.
    @Test func ignoresANewerBuildWhenOnlyTheVersionCounts() {
        let decision = UpdateDecision.evaluate(published: published(version: "1.2", build: "35"),
                                               installed: installed, comparison: .version, skipped: nil)
        #expect(decision == .upToDate)
    }

    @Test func offersANewerBuildOfTheSameVersion() {
        let decision = UpdateDecision.evaluate(published: published(version: "1.2", build: "35"),
                                               installed: installed, comparison: .versionAndBuild, skipped: nil)
        #expect(decision == .available)
    }

    @Test func ignoresAnOlderBuildOfTheSameVersion() {
        let decision = UpdateDecision.evaluate(published: published(version: "1.2", build: "33"),
                                               installed: installed, comparison: .versionAndBuild, skipped: nil)
        #expect(decision == .upToDate)
    }

    @Test func respectsASkippedBuild() {
        let decision = UpdateDecision.evaluate(published: published(version: "1.3", build: "1"),
                                               installed: installed, comparison: .version,
                                               skipped: SkippedBuild(version: "1.3", build: "1"))
        #expect(decision == .skippedByUser)
    }

    /// Skipping 1.3 (1) must not hide the 1.3 (2) that follows it.
    @Test func offersARebuildOfASkippedVersion() {
        let decision = UpdateDecision.evaluate(published: published(version: "1.3", build: "2"),
                                               installed: installed, comparison: .version,
                                               skipped: SkippedBuild(version: "1.3", build: "1"))
        #expect(decision == .available)
    }
}
