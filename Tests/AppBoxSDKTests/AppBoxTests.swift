//
//  AppBoxTests.swift
//  AppBoxSDKTests
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Testing
import Foundation
@testable import AppBoxSDK

@MainActor
struct AppBoxTests {
    private let installed = InstalledBuild(name: "Demo", version: "1.2", build: "34")

    private func makeSUT(_ transport: FakeTransport,
                         configuration: AppBoxConfiguration = AppBoxConfiguration(isLoggingEnabled: false),
                         link: String = "https://www.dropbox.com/scl/fi/a1/appinfo.json?rlkey=k")
    -> (sut: AppBox, store: FakeStore, presenter: FakePresenter) {
        let store = FakeStore()
        let presenter = FakePresenter()
        let sut = AppBox(installedBuild: { self.installed }, transport: transport, store: store, presenter: presenter)
        sut.configure(link: link, configuration: configuration)
        return (sut, store, presenter)
    }

    // MARK: - Finding an update

    @Test func findsANewerPublishedBuild() async throws {
        let transport = FakeTransport(replies: [.json(Fixture.appInfoJSON(version: "1.3", build: "7"))])
        let (sut, _, _) = makeSUT(transport)

        let update = try #require(await sut.checkForUpdate())
        #expect(update.version == "1.3")
        #expect(update.build == "7")
        #expect(update.displayVersion == "1.3 (7)")
        #expect(update.installURL.absoluteString == "https://appbox.me/AbCdEf")
        #expect(update.minimumOSVersion == "15.0")
        #expect(update.buildType == "development")
    }

    @Test func findsNothingWhenTheInstalledBuildIsCurrent() async throws {
        let transport = FakeTransport(replies: [.json(Fixture.appInfoJSON(version: "1.2", build: "34"))])
        let (sut, _, _) = makeSUT(transport)

        #expect(try await sut.checkForUpdate() == nil)
    }

    @Test func refusesToCheckBeforeItIsStarted() async throws {
        let sut = AppBox(installedBuild: { self.installed }, transport: FakeTransport(),
                         store: FakeStore(), presenter: FakePresenter())
        await #expect(throws: AppBoxError.notStarted) {
            try await sut.checkForUpdate()
        }
    }

    @Test func reportsAnAppInfoWithNoPublishedBuild() async throws {
        let transport = FakeTransport(replies: [.json("{}")])
        let (sut, _, _) = makeSUT(transport)

        await #expect(throws: AppBoxError.noPublishedBuild) {
            try await sut.checkForUpdate()
        }
    }

    @Test func reportsAnAppInfoWithNoInstallLink() async throws {
        let transport = FakeTransport(replies: [.json(#"{"latestVersion":{"version":"9.0"}}"#)])
        let (sut, _, _) = makeSUT(transport)

        await #expect(throws: AppBoxError.noInstallLink) {
            try await sut.checkForUpdate()
        }
    }

    // MARK: - Presenting

    @Test func showsTheAlertForAnAvailableUpdate() async {
        let transport = FakeTransport(replies: [.json(Fixture.appInfoJSON())])
        let (sut, _, presenter) = makeSUT(transport)

        await sut.checkAndPresent()

        #expect(presenter.presented.count == 1)
        #expect(presenter.presented.first?.style == .skippable)
        #expect(presenter.presented.first?.update.version == "1.3")
    }

    @Test func showsNoAlertWhenThereIsNothingToOffer() async {
        let transport = FakeTransport(replies: [.json(Fixture.appInfoJSON(version: "1.0", build: "1"))])
        let (sut, _, presenter) = makeSUT(transport)

        await sut.checkAndPresent()

        #expect(presenter.presented.isEmpty)
    }

    @Test func leavesTheAlertToTheHostAppWhenAsked() async {
        let transport = FakeTransport(replies: [.json(Fixture.appInfoJSON())])
        let (sut, _, presenter) = makeSUT(transport, configuration: AppBoxConfiguration(presentsAlert: false,
                                                                                       isLoggingEnabled: false))
        var handled: AppBoxUpdate?
        sut.updateHandler = { handled = $0 }

        await sut.checkAndPresent()

        #expect(presenter.presented.isEmpty)
        #expect(handled?.version == "1.3")
    }

    @Test func swallowsAFailedCheck() async {
        let transport = FakeTransport(failure: AppBoxError.requestFailed("offline"))
        let (sut, _, presenter) = makeSUT(transport)

        await sut.checkAndPresent()

        #expect(presenter.presented.isEmpty)
        #expect(sut.update == nil)
    }

    // MARK: - Answering the alert

    @Test func remembersASkippedBuildAndDoesNotOfferItAgain() async {
        let transport = FakeTransport(replies: [.json(Fixture.appInfoJSON(version: "1.3", build: "7"))])
        let (sut, store, presenter) = makeSUT(transport)

        await sut.checkAndPresent()
        presenter.tap(.skip)

        #expect(store.skippedBuild == SkippedBuild(version: "1.3", build: "7"))

        await sut.checkAndPresent()
        #expect(presenter.presented.count == 1)
    }

    @Test func offersTheBuildAgainAfterNextTime() async {
        let transport = FakeTransport(replies: [.json(Fixture.appInfoJSON())])
        let (sut, store, presenter) = makeSUT(transport)

        await sut.checkAndPresent()
        presenter.tap(.later)
        #expect(store.skippedBuild == nil)

        await sut.checkAndPresent()
        #expect(presenter.presented.count == 2)
    }

    @Test func reportsTheChosenActionToTheHostApp() async {
        let transport = FakeTransport(replies: [.json(Fixture.appInfoJSON())])
        let (sut, _, presenter) = makeSUT(transport)
        var actions: [AppBoxAlertAction] = []
        sut.alertActionHandler = { action, _ in actions.append(action) }

        await sut.checkAndPresent()
        presenter.tap(.skip)

        #expect(actions == [.skip])
    }

    @Test func forgetsASkippedBuildOnRequest() async {
        let transport = FakeTransport(replies: [.json(Fixture.appInfoJSON())])
        let (sut, store, presenter) = makeSUT(transport)
        store.skippedBuild = SkippedBuild(version: "1.3", build: "7")

        await sut.checkAndPresent()
        #expect(presenter.presented.isEmpty)

        store.skippedBuild = nil
        await sut.checkAndPresent()
        #expect(presenter.presented.count == 1)
    }

    // MARK: - Share path caching

    @Test func resolvesAShortLinkOnceAndRemembersIt() async {
        let transport = FakeTransport(replies: [
            .redirect(to: "https://web.getappbox.com/?url=%2Fscl%2Ffi%2Fa1%2Fappinfo.json%3Frlkey%3Dk"),
            .json(Fixture.appInfoJSON())
        ])
        let (sut, store, _) = makeSUT(transport, link: "https://appbox.me/AbCdEf")

        await sut.checkAndPresent()
        #expect(store.cachedSharePath(forLink: "https://appbox.me/AbCdEf") == "/scl/fi/a1/appinfo.json?rlkey=k")
        #expect(store.cacheWrites == 1)

        await sut.checkAndPresent()
        #expect(store.cacheWrites == 1)
    }

    // MARK: - Starting

    @Test func checksAsSoonAsItStarts() async {
        let transport = FakeTransport(replies: [.json(Fixture.appInfoJSON())])
        let store = FakeStore()
        let presenter = FakePresenter()
        let sut = AppBox(installedBuild: { self.installed }, transport: transport, store: store, presenter: presenter)

        sut.start(link: "https://www.dropbox.com/scl/fi/a1/appinfo.json?rlkey=k",
                  configuration: AppBoxConfiguration(checksOnForeground: false, isLoggingEnabled: false))
        await sut.pendingCheck()

        #expect(presenter.presented.count == 1)
        #expect(sut.link == "https://www.dropbox.com/scl/fi/a1/appinfo.json?rlkey=k")
        #expect(store.lastCheckDate != nil)
        sut.stop()
    }
}

@MainActor
struct AppBoxMetadataTests {

    /// Support asks which SDK a build shipped with, so the version has to be readable at runtime.
    @Test func exposesItsOwnVersion() {
        #expect(AppBox.sdkVersion == "4.0.0")
    }
}
