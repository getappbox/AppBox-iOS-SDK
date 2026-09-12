//
//  AppInfo.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Foundation

/// The `appinfo.json` AppBox writes next to an uploaded build.
struct AppInfo: Decodable, Equatable, Sendable {
    var latestVersion: AppInfoVersion?
    var versions: [AppInfoVersion]
    /// Dropbox share URL of this very `appinfo.json`.
    var uniqueLinkShared: String?
    /// Short install link for the latest build.
    var uniqueLinkShort: String?

    init(latestVersion: AppInfoVersion? = nil, versions: [AppInfoVersion] = [],
         uniqueLinkShared: String? = nil, uniqueLinkShort: String? = nil) {
        self.latestVersion = latestVersion
        self.versions = versions
        self.uniqueLinkShared = uniqueLinkShared
        self.uniqueLinkShort = uniqueLinkShort
    }

    enum CodingKeys: String, CodingKey {
        case latestVersion, versions, uniqueLinkShared, uniqueLinkShort
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latestVersion = try container.decodeIfPresent(AppInfoVersion.self, forKey: .latestVersion)
        versions = try container.decodeIfPresent([AppInfoVersion].self, forKey: .versions) ?? []
        uniqueLinkShared = try container.decodeIfPresent(String.self, forKey: .uniqueLinkShared)
        uniqueLinkShort = try container.decodeIfPresent(String.self, forKey: .uniqueLinkShort)
    }

    /// `latestVersion` when present, else the newest entry in the history.
    var publishedBuild: AppInfoVersion? {
        latestVersion ?? versions.last
    }
}

/// One uploaded build inside `appinfo.json`.
struct AppInfoVersion: Decodable, Equatable, Sendable {
    var name: String
    var version: String
    var build: String
    var identifier: String
    var manifestLink: String
    var timestamp: Double?
    var ipaFileLink: String?
    var minosversion: String?
    var supporteddevice: String?
    var buildtype: String?
    var ipafilesize: Int?
    var mobileprovision: AppInfoProvisioning?

    init(name: String = "", version: String = "", build: String = "", identifier: String = "",
         manifestLink: String = "", timestamp: Double? = nil, ipaFileLink: String? = nil,
         minosversion: String? = nil, supporteddevice: String? = nil, buildtype: String? = nil,
         ipafilesize: Int? = nil, mobileprovision: AppInfoProvisioning? = nil) {
        self.name = name
        self.version = version
        self.build = build
        self.identifier = identifier
        self.manifestLink = manifestLink
        self.timestamp = timestamp
        self.ipaFileLink = ipaFileLink
        self.minosversion = minosversion
        self.supporteddevice = supporteddevice
        self.buildtype = buildtype
        self.ipafilesize = ipafilesize
        self.mobileprovision = mobileprovision
    }

    enum CodingKeys: String, CodingKey {
        case name, version, build, identifier, manifestLink, timestamp, ipaFileLink
        case minosversion, supporteddevice, buildtype, ipafilesize, mobileprovision
    }

    /// Tolerant decoding: hand-edited and AppBox 3 era files miss fields the current writer always emits.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        version = try container.decodeIfPresent(String.self, forKey: .version) ?? ""
        build = try container.decodeIfPresent(String.self, forKey: .build) ?? ""
        identifier = try container.decodeIfPresent(String.self, forKey: .identifier) ?? ""
        manifestLink = try container.decodeIfPresent(String.self, forKey: .manifestLink) ?? ""
        timestamp = try container.decodeIfPresent(Double.self, forKey: .timestamp)
        ipaFileLink = try container.decodeIfPresent(String.self, forKey: .ipaFileLink)
        minosversion = try container.decodeIfPresent(String.self, forKey: .minosversion)
        supporteddevice = try container.decodeIfPresent(String.self, forKey: .supporteddevice)
        buildtype = try container.decodeIfPresent(String.self, forKey: .buildtype)
        ipafilesize = try container.decodeIfPresent(Int.self, forKey: .ipafilesize)
        mobileprovision = try container.decodeIfPresent(AppInfoProvisioning.self, forKey: .mobileprovision)
    }

    var uploadDate: Date? {
        timestamp.map(Date.init(timeIntervalSince1970:))
    }
}

/// The provisioning profile summary AppBox records when "more build details" is on.
struct AppInfoProvisioning: Decodable, Equatable, Sendable {
    var createdate: Double?
    var expirationdata: Double?
    var teamid: String?
    var teamname: String?
    var uuid: String?
    var devicesudid: [String]?
}
