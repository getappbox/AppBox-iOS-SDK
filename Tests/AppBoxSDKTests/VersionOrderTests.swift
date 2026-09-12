//
//  VersionOrderTests.swift
//  AppBoxSDKTests
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Testing
@testable import AppBoxSDK

struct VersionOrderTests {

    @Test(arguments: [
        ("1.1", "1.0"),
        ("1.10", "1.9"),
        ("2.0", "1.99"),
        ("1.0.1", "1.0"),
        ("10", "9"),
        ("1.2.3", "1.2.2")
    ])
    func recognisesANewerVersion(_ pair: (String, String)) {
        #expect(VersionOrder.isNewer(pair.0, than: pair.1))
        #expect(VersionOrder.isNewer(pair.1, than: pair.0) == false)
    }

    @Test(arguments: [
        ("1.0", "1.0.0"),
        ("1.0.0", "1.0"),
        ("1", "1.0.0"),
        ("2.1", "2.1")
    ])
    func treatsMissingComponentsAsZero(_ pair: (String, String)) {
        #expect(VersionOrder.compare(pair.0, pair.1) == .orderedSame)
    }

    /// Build numbers are compared with the same rules, and are often not dotted at all.
    @Test func comparesPlainBuildNumbers() {
        #expect(VersionOrder.isNewer("124", than: "123"))
        #expect(VersionOrder.isNewer("99", than: "100") == false)
    }

    @Test func ignoresNonNumericSuffixes() {
        #expect(VersionOrder.compare("2.1.0-beta", "2.1.0") == .orderedSame)
        #expect(VersionOrder.isNewer("2.1.1-beta", than: "2.1.0"))
    }

    @Test func treatsAnEmptyVersionAsZero() {
        #expect(VersionOrder.isNewer("0.1", than: ""))
        #expect(VersionOrder.compare("", "") == .orderedSame)
    }
}
