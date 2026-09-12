//
//  AppInfoTests.swift
//  AppBoxSDKTests
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Testing
import Foundation
@testable import AppBoxSDK

struct AppInfoTests {

    @Test func decodesAnAppBoxFourFile() throws {
        let appInfo = try JSONDecoder().decode(AppInfo.self, from: Data(Fixture.appInfoJSON().utf8))
        let published = try #require(appInfo.publishedBuild)

        #expect(published.name == "AppBox Demo")
        #expect(published.version == "1.3")
        #expect(published.build == "7")
        #expect(published.minosversion == "15.0")
        #expect(published.buildtype == "development")
        #expect(published.ipafilesize == 12)
        #expect(published.uploadDate == Date(timeIntervalSince1970: 1789000000))
        #expect(appInfo.uniqueLinkShort == "https://appbox.me/AbCdEf")
        #expect(published.mobileprovision?.teamid == "3PQ7E4L589")
    }

    /// AppBox 3 era and hand-edited files miss fields the current writer always emits.
    @Test func decodesASparseFile() throws {
        let json = """
        { "latestVersion": { "version": "2.0" } }
        """
        let appInfo = try JSONDecoder().decode(AppInfo.self, from: Data(json.utf8))
        let published = try #require(appInfo.publishedBuild)

        #expect(published.version == "2.0")
        #expect(published.build.isEmpty)
        #expect(published.name.isEmpty)
        #expect(appInfo.versions.isEmpty)
        #expect(published.uploadDate == nil)
    }

    /// With previous versions kept, the newest entry stands in when `latestVersion` is missing.
    @Test func fallsBackToTheNewestHistoryEntry() throws {
        let json = """
        { "versions": [ { "version": "1.0", "build": "1" }, { "version": "1.1", "build": "2" } ] }
        """
        let appInfo = try JSONDecoder().decode(AppInfo.self, from: Data(json.utf8))
        #expect(appInfo.publishedBuild?.version == "1.1")
    }

    @Test func decodesAnEmptyObject() throws {
        let appInfo = try JSONDecoder().decode(AppInfo.self, from: Data("{}".utf8))
        #expect(appInfo.publishedBuild == nil)
    }
}

struct InstallPageLinkTests {

    @Test func prefersTheShortLink() {
        let appInfo = AppInfo(uniqueLinkShared: "https://www.dropbox.com/scl/fi/a1/appinfo.json?rlkey=k",
                              uniqueLinkShort: "https://appbox.me/AbCdEf")
        #expect(InstallPageLink.url(for: appInfo)?.absoluteString == "https://appbox.me/AbCdEf")
    }

    /// Files written before short links existed only carry the Dropbox share URL.
    @Test func buildsTheInstallPageFromTheShareLink() {
        let appInfo = AppInfo(uniqueLinkShared: "https://www.dropbox.com/scl/fi/a1/appinfo.json?rlkey=k")
        #expect(InstallPageLink.url(for: appInfo)?.absoluteString
                == "https://web.getappbox.com?url=/scl/fi/a1/appinfo.json?rlkey=k")
    }

    @Test func escapesTheShareLinkTheWayAppBoxDoes() {
        let url = URL(string: "https://www.dropbox.com/scl/fi/a1/appinfo.json?rlkey=k&st=t")!
        #expect(InstallPageLink.make(fromDropboxShareURL: url)?.absoluteString
                == "https://web.getappbox.com?url=/scl/fi/a1/appinfo.json?rlkey=k%26st=t")
    }

    @Test func hasNoLinkWhenTheFileCarriesNeither() {
        #expect(InstallPageLink.url(for: AppInfo()) == nil)
    }

    /// The install page round trips: what AppBox writes is what the SDK can read back.
    @Test func roundTripsThroughTheLinkParser() {
        let share = URL(string: "https://www.dropbox.com/scl/fi/a1/appinfo.json?rlkey=k&st=t")!
        let install = InstallPageLink.make(fromDropboxShareURL: share)!
        #expect(AppBoxLink.sharePath(from: install.absoluteString) == "/scl/fi/a1/appinfo.json?rlkey=k&st=t")
    }
}
