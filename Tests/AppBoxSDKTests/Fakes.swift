//
//  Fakes.swift
//  AppBoxSDKTests
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Foundation
@testable import AppBoxSDK

/// Serves canned responses and records what was asked for, so no test touches the network.
actor FakeTransport: HTTPTransport {
    struct Reply {
        var data: Data
        var statusCode: Int
        var finalURL: URL?

        static func json(_ string: String, statusCode: Int = 200) -> Reply {
            Reply(data: Data(string.utf8), statusCode: statusCode)
        }

        static func redirect(to url: String) -> Reply {
            Reply(data: Data(), statusCode: 200, finalURL: URL(string: url))
        }
    }

    /// The last reply repeats, so a check that runs more than once stays deterministic.
    private var replies: [Reply]
    private var failure: Error?
    private(set) var requestedURLs: [URL] = []

    init(replies: [Reply] = [], failure: Error? = nil) {
        self.replies = replies
        self.failure = failure
    }

    func get(_ url: URL) async throws -> (data: Data, statusCode: Int, finalURL: URL?) {
        requestedURLs.append(url)
        if let failure { throw failure }
        guard !replies.isEmpty else {
            return (Data(), 200, url)
        }
        let reply = replies.count > 1 ? replies.removeFirst() : replies[0]
        return (reply.data, reply.statusCode, reply.finalURL ?? url)
    }

    func requested() -> [String] {
        requestedURLs.map(\.absoluteString)
    }
}

@MainActor
final class FakeStore: UpdateStoring {
    var skippedBuild: SkippedBuild?
    var lastCheckDate: Date?
    var sharePaths: [String: String] = [:]
    private(set) var cacheWrites = 0

    func cachedSharePath(forLink link: String) -> String? {
        sharePaths[link]
    }

    func cacheSharePath(_ sharePath: String, forLink link: String) {
        sharePaths[link] = sharePath
        cacheWrites += 1
    }
}

@MainActor
final class FakePresenter: UpdatePresenting {
    private(set) var presented: [(update: AppBoxUpdate, style: AppBoxAlertStyle)] = []
    private var handler: ((AppBoxAlertAction) -> Void)?

    var isPresenting = false

    func present(_ update: AppBoxUpdate, style: AppBoxAlertStyle, handler: @escaping (AppBoxAlertAction) -> Void) {
        presented.append((update, style))
        self.handler = handler
        isPresenting = true
    }

    func dismiss() {
        isPresenting = false
    }

    /// Answers the alert the way a user would.
    func tap(_ action: AppBoxAlertAction) {
        dismiss()
        handler?(action)
    }
}

enum Fixture {
    /// An `appinfo.json` as AppBox 4 writes it.
    static func appInfoJSON(version: String = "1.3",
                            build: String = "7",
                            name: String = "AppBox Demo",
                            shortLink: String = "https://appbox.me/AbCdEf") -> String {
        """
        {
          "latestVersion": {
            "name": "\(name)",
            "version": "\(version)",
            "build": "\(build)",
            "identifier": "com.developerinsider.appbox-demo",
            "manifestLink": "https://www.dropbox.com/scl/fi/m1/manifest.plist?rlkey=k&dl=1",
            "timestamp": 1789000000,
            "ipaFileLink": "https://www.dropbox.com/scl/fi/i1/Demo.ipa?rlkey=k&dl=1",
            "minosversion": "15.0",
            "supporteddevice": "iPhone, iPad",
            "buildtype": "development",
            "ipafilesize": 12,
            "mobileprovision": {
              "createdate": 1788000000,
              "expirationdata": 1819000000,
              "teamid": "3PQ7E4L589",
              "teamname": "Developer Insider",
              "uuid": "1f8c4f6a-0000-0000-0000-000000000000",
              "devicesudid": ["0000111122....223333"]
            }
          },
          "versions": [],
          "uniqueLinkShared": "https://www.dropbox.com/scl/fi/a1/appinfo.json?rlkey=k&dl=0",
          "uniqueLinkShort": "\(shortLink)"
        }
        """
    }
}
