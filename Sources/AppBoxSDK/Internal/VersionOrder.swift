//
//  VersionOrder.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Foundation

/// Component-wise comparison of dotted version strings, so `1.10` sorts above `1.9` and `1.0` equals `1.0.0`.
enum VersionOrder {
    static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = components(of: lhs)
        let right = components(of: rhs)

        for index in 0..<max(left.count, right.count) {
            let leftValue = index < left.count ? left[index] : 0
            let rightValue = index < right.count ? right[index] : 0
            if leftValue != rightValue {
                return leftValue < rightValue ? .orderedAscending : .orderedDescending
            }
        }
        return .orderedSame
    }

    static func isNewer(_ candidate: String, than installed: String) -> Bool {
        compare(candidate, installed) == .orderedDescending
    }

    /// Every run of digits in the string, in order — `"2.1.0-beta3"` reads as `[2, 1, 0, 3]`.
    private static func components(of version: String) -> [Int] {
        version.split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) ?? Int($0.prefix(18)) }
    }
}
