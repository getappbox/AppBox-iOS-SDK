//
//  AppInfoLoader.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Foundation

/// Reads `appinfo.json` for a link, following the link first when it is a short link.
struct AppInfoLoader: Sendable {
    let transport: HTTPTransport
    let serviceBaseURL: URL?
    let log: Log

    init(transport: HTTPTransport, serviceBaseURL: URL?, log: Log) {
        self.transport = transport
        self.serviceBaseURL = serviceBaseURL
        self.log = log
    }

    /// The Dropbox share path for `link`, following a short link once when the path is not already in it.
    func sharePath(for link: String) async throws -> String {
        if let path = AppBoxLink.sharePath(from: link) {
            return path
        }
        guard AppBoxLink.isResolvable(link), let url = URL(string: link) else {
            throw AppBoxError.invalidLink(link)
        }

        log.debug("Following \(url.absoluteString) to find appinfo.json.")
        let response = try await transport.get(url)
        guard let finalURL = response.finalURL,
              let path = AppBoxLink.sharePath(from: finalURL.absoluteString) else {
            throw AppBoxError.invalidLink(link)
        }
        return path
    }

    func load(sharePath: String) async throws -> AppInfo {
        guard let url = AppBoxLink.requestURL(sharePath: sharePath, serviceBaseURL: serviceBaseURL) else {
            throw AppBoxError.invalidLink(sharePath)
        }

        let fileName = AppBoxLink.fileName(ofSharePath: sharePath)
        if fileName != AppBoxLink.appInfoFileName {
            log.error("The link points at '\(fileName)', not \(AppBoxLink.appInfoFileName) — check you copied the install link and not the IPA or manifest link.")
        }

        log.debug("Reading \(url.absoluteString)")
        let response = try await transport.get(url)
        guard (200..<300).contains(response.statusCode) else {
            throw AppBoxError.unexpectedStatus(response.statusCode)
        }

        do {
            return try JSONDecoder().decode(AppInfo.self, from: response.data)
        } catch {
            throw AppBoxError.invalidResponse(error.localizedDescription)
        }
    }
}
