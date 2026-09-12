//
//  AppBoxLink.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Foundation

/// Turns whatever the developer pasted into the Dropbox share path of an `appinfo.json`, and that path into a request URL.
enum AppBoxLink {
    static let appInfoFileName = "appinfo.json"

    /// The share path (`/scl/fi/…/appinfo.json?rlkey=…`) carried by `input`, or `nil` when the link has to be followed first.
    ///
    /// Understands the AppBox install page link, a Dropbox share link, an already proxied install-service link, and a legacy app update key.
    static func sharePath(from input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let key = legacyUpdateKey(in: trimmed) {
            return validated("/s/\(key)/\(appInfoFileName)")
        }

        guard let components = URLComponents(string: trimmed), let host = components.host?.lowercased() else {
            return nil
        }

        if let embedded = embeddedSharePath(in: trimmed, host: host) {
            return validated(embedded)
        }

        if host == "dropbox.com" || host.hasSuffix(".dropbox.com") {
            return validated(pathWithQuery(components))
        }

        if components.path.hasPrefix("/appinfo/") {
            var proxied = components
            proxied.path = String(components.path.dropFirst("/appinfo".count))
            return validated(pathWithQuery(proxied))
        }

        return nil
    }

    /// Whether `input` is an http(s) link the SDK has to follow (a short link) before it can find a share path.
    static func isResolvable(_ input: String) -> Bool {
        guard let components = URLComponents(string: input.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = components.scheme?.lowercased() else {
            return false
        }
        return (scheme == "https" || scheme == "http") && components.host != nil
    }

    /// The URL to GET the `appinfo.json` at `sharePath` from.
    ///
    /// - Parameter serviceBaseURL: the AppBox install service to proxy through, or `nil` to read the share link straight from Dropbox.
    static func requestURL(sharePath: String, serviceBaseURL: URL?) -> URL? {
        let (path, query) = split(sharePath)
        let base = serviceBaseURL.map { $0.absoluteString.trimmingTrailingSlash + "/appinfo" } ?? "https://www.dropbox.com"
        return URL(string: base + path + "?" + downloadQuery(from: query))
    }

    /// The last path component of a share path, so a wrong link (a manifest or IPA share link) can be reported.
    static func fileName(ofSharePath sharePath: String) -> String {
        split(sharePath).path.components(separatedBy: "/").last ?? ""
    }

    private static func legacyUpdateKey(in input: String) -> String? {
        guard !input.contains("/"), !input.contains(":"), !input.contains(".") else { return nil }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard input.unicodeScalars.allSatisfy(allowed.contains) else { return nil }
        return input
    }

    /// The `url` value of an AppBox install page link, decoded as many times as it was escaped.
    private static func embeddedSharePath(in input: String, host: String) -> String? {
        guard host.hasSuffix("getappbox.com"), let marker = input.range(of: "url=") else { return nil }
        let raw = String(input[marker.upperBound...])
        guard !raw.isEmpty else { return nil }
        return fullyDecoded(raw)
    }

    /// `InstallLink` in AppBox escapes `%`, `&` and `#` by hand, and a browser can escape the whole value again on top of that.
    private static func fullyDecoded(_ value: String) -> String {
        var current = value
        for _ in 0..<3 {
            guard knownEscapes.contains(where: { current.range(of: $0, options: .caseInsensitive) != nil }),
                  let decoded = current.removingPercentEncoding, decoded != current else { break }
            current = decoded
        }
        return current
    }

    /// Only escapes AppBox or a browser can have introduced are undone, so a `%` that is really part of the path survives.
    private static let knownEscapes = ["%2F", "%3F", "%3D", "%26", "%25", "%23"]

    private static func pathWithQuery(_ components: URLComponents) -> String {
        guard let query = components.percentEncodedQuery, !query.isEmpty else { return components.path }
        return "\(components.path)?\(query)"
    }

    private static func split(_ sharePath: String) -> (path: String, query: String?) {
        guard let separator = sharePath.firstIndex(of: "?") else { return (sharePath, nil) }
        let query = String(sharePath[sharePath.index(after: separator)...])
        return (String(sharePath[..<separator]), query.isEmpty ? nil : query)
    }

    /// The share link's own query with tracking parameters dropped and `dl=1` forced, so Dropbox serves the file rather than its preview page.
    private static func downloadQuery(from query: String?) -> String {
        var parts = (query ?? "").split(separator: "&").map(String.init).filter { pair in
            let name = String(pair.split(separator: "=", maxSplits: 1).first ?? "")
            return !name.isEmpty && name != "dl" && !ignoredQueryNames.contains(name)
        }
        parts.append("dl=1")
        return parts.joined(separator: "&")
    }

    /// Tracking parameters the short link adds, which Dropbox rejects the link for.
    private static let ignoredQueryNames: Set<String> = ["$web_only", "_branch_match_id", "_branch_referrer"]

    /// Mirrors the install service's own check, so a bad link fails on device instead of as an HTTP 400.
    private static func validated(_ sharePath: String) -> String? {
        guard sharePath.count <= 1024 else { return nil }
        guard sharePath.hasPrefix("/s/") || sharePath.hasPrefix("/scl/") else { return nil }
        guard !split(sharePath).path.components(separatedBy: "/").contains("..") else { return nil }
        return sharePath
    }
}

private extension String {
    var trimmingTrailingSlash: String {
        hasSuffix("/") ? String(dropLast()) : self
    }
}
