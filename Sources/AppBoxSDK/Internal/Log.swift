//
//  Log.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Foundation
import os

/// SDK logging through the unified logging system, under the `com.getappbox.sdk` subsystem.
struct Log: Sendable {
    private let logger = Logger(subsystem: "com.getappbox.sdk", category: "AppBox")
    private let isEnabled: Bool

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func debug(_ message: String) {
        guard isEnabled else { return }
        logger.debug("\(message, privacy: .public)")
    }

    func info(_ message: String) {
        guard isEnabled else { return }
        logger.info("\(message, privacy: .public)")
    }

    func error(_ message: String) {
        guard isEnabled else { return }
        logger.error("\(message, privacy: .public)")
    }
}
