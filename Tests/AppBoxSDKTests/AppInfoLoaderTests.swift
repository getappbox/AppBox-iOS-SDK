//
//  AppInfoLoaderTests.swift
//  AppBoxSDKTests
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Testing
import Foundation
@testable import AppBoxSDK

struct AppInfoLoaderTests {

    private func loader(_ transport: FakeTransport, serviceBaseURL: URL? = AppBoxConfiguration.defaultServiceBaseURL) -> AppInfoLoader {
        AppInfoLoader(transport: transport, serviceBaseURL: serviceBaseURL, log: Log(isEnabled: false))
    }

    @Test func readsAppInfoThroughTheInstallService() async throws {
        let transport = FakeTransport(replies: [.json(Fixture.appInfoJSON())])
        let appInfo = try await loader(transport).load(sharePath: "/scl/fi/a1/appinfo.json?rlkey=k")

        #expect(appInfo.publishedBuild?.version == "1.3")
        #expect(await transport.requested() == ["https://install.getappbox.com/appinfo/scl/fi/a1/appinfo.json?rlkey=k&dl=1"])
    }

    @Test func readsAppInfoStraightFromDropbox() async throws {
        let transport = FakeTransport(replies: [.json(Fixture.appInfoJSON())])
        _ = try await loader(transport, serviceBaseURL: nil).load(sharePath: "/scl/fi/a1/appinfo.json?rlkey=k")

        #expect(await transport.requested() == ["https://www.dropbox.com/scl/fi/a1/appinfo.json?rlkey=k&dl=1"])
    }

    @Test func reportsANonSuccessStatus() async throws {
        let transport = FakeTransport(replies: [.json("", statusCode: 404)])
        await #expect(throws: AppBoxError.unexpectedStatus(404)) {
            try await loader(transport).load(sharePath: "/s/a1/appinfo.json")
        }
    }

    /// Dropbox answers a banned or deleted link with an HTML notice page.
    @Test func reportsABodyThatIsNotAppInfo() async throws {
        let transport = FakeTransport(replies: [.json("<html><title>Invalid link</title></html>")])
        await #expect(throws: AppBoxError.self) {
            try await loader(transport).load(sharePath: "/s/a1/appinfo.json")
        }
    }

    @Test func reportsATransportFailure() async throws {
        let transport = FakeTransport(failure: AppBoxError.requestFailed("offline"))
        await #expect(throws: AppBoxError.requestFailed("offline")) {
            try await loader(transport).load(sharePath: "/s/a1/appinfo.json")
        }
    }

    // MARK: - Share path resolution

    @Test func readsTheSharePathWithoutAnyRequest() async throws {
        let transport = FakeTransport()
        let path = try await loader(transport).sharePath(for: "https://www.dropbox.com/scl/fi/a1/appinfo.json?rlkey=k")

        #expect(path == "/scl/fi/a1/appinfo.json?rlkey=k")
        #expect(await transport.requested().isEmpty)
    }

    /// A short link is followed once, and the install page it lands on carries the share path.
    @Test func followsAShortLinkToFindTheSharePath() async throws {
        let transport = FakeTransport(replies: [
            .redirect(to: "https://web.getappbox.com/?url=%2Fscl%2Ffi%2Fa1%2Fappinfo.json%3Frlkey%3Dk")
        ])
        let path = try await loader(transport).sharePath(for: "https://appbox.me/AbCdEf")

        #expect(path == "/scl/fi/a1/appinfo.json?rlkey=k")
        #expect(await transport.requested() == ["https://appbox.me/AbCdEf"])
    }

    @Test func reportsAShortLinkThatLeadsNowhereUseful() async throws {
        let transport = FakeTransport(replies: [.redirect(to: "https://getappbox.com/download")])
        await #expect(throws: AppBoxError.invalidLink("https://appbox.me/AbCdEf")) {
            try await loader(transport).sharePath(for: "https://appbox.me/AbCdEf")
        }
    }

    @Test func reportsSomethingThatIsNotALinkAtAll() async throws {
        let transport = FakeTransport()
        await #expect(throws: AppBoxError.invalidLink("not a link")) {
            try await loader(transport).sharePath(for: "not a link")
        }
    }
}
