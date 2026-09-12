//
//  AppBox.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import UIKit

/// Offers the newest build published by AppBox to whoever is running an older one.
///
/// Start it once, with the install link AppBox gave you for the build:
///
/// ```swift
/// AppBox.start(link: "https://appbox.me/AbCdEf")
/// ```
@MainActor
public final class AppBox {
    public static let shared = AppBox()

    /// The version of the SDK itself, matching the tag this package was resolved at.
    public static let sdkVersion = "4.0.0"

    /// The link the SDK is watching, once `start(link:configuration:)` has been called.
    public private(set) var link: String?

    /// The configuration in force.
    public private(set) var configuration = AppBoxConfiguration()

    /// The newest update found so far, whether or not the user acted on it.
    public private(set) var update: AppBoxUpdate?

    /// Called when a check finds a build newer than the one running.
    public var updateHandler: ((AppBoxUpdate) -> Void)?

    /// Called when the user answers the built-in alert.
    public var alertActionHandler: ((AppBoxAlertAction, AppBoxUpdate) -> Void)?

    private let installedBuild: () throws -> InstalledBuild
    private let transport: HTTPTransport
    private let store: UpdateStoring
    private let presenter: UpdatePresenting
    private var log = Log(isEnabled: AppBoxConfiguration.defaultLoggingEnabled)
    private var foregroundObserver: NSObjectProtocol?
    private var checkTask: Task<Void, Never>?

    init(installedBuild: @escaping () throws -> InstalledBuild = { try InstalledBuild(bundle: .main) },
         transport: HTTPTransport = URLSessionTransport(),
         store: UpdateStoring? = nil,
         presenter: UpdatePresenting? = nil) {
        self.installedBuild = installedBuild
        self.transport = transport
        self.store = store ?? UserDefaultsUpdateStore()
        self.presenter = presenter ?? UpdateAlertPresenter()
    }

    // MARK: - Starting

    /// Starts watching `link` for newer builds, and checks straight away.
    ///
    /// - Parameters:
    ///   - link: the install link AppBox produced — the `appbox.me` short link, the `web.getappbox.com` install page link, or the Dropbox share link of `appinfo.json`. A legacy app update key still works.
    ///   - configuration: alert style, comparison rules and everything else tunable.
    public static func start(link: String, configuration: AppBoxConfiguration = AppBoxConfiguration()) {
        shared.start(link: link, configuration: configuration)
    }

    /// Stops foreground checks and cancels any check in flight.
    public static func stop() {
        shared.stop()
    }

    /// Checks now, regardless of `minimumCheckInterval`, and returns the update without showing any UI.
    @discardableResult
    public static func checkForUpdate() async throws -> AppBoxUpdate? {
        try await shared.checkForUpdate()
    }

    /// Forgets the build the user chose to skip, so it is offered again.
    public static func resetSkippedBuild() {
        shared.store.skippedBuild = nil
    }

    public func start(link: String, configuration: AppBoxConfiguration = AppBoxConfiguration()) {
        configure(link: link, configuration: configuration)

        log.debug("AppBox SDK \(Self.sdkVersion) watching \(link)")

        if configuration.checksOnForeground {
            observeForeground()
        }
        check(force: true)
    }

    public func stop() {
        checkTask?.cancel()
        checkTask = nil
        if let foregroundObserver {
            NotificationCenter.default.removeObserver(foregroundObserver)
        }
        foregroundObserver = nil
        presenter.dismiss()
    }

    // MARK: - Checking

    /// Reads `appinfo.json` and returns the published build when it is newer than the installed one and not skipped.
    @discardableResult
    public func checkForUpdate() async throws -> AppBoxUpdate? {
        guard let link else { throw AppBoxError.notStarted }

        let installed = try installedBuild()
        let loader = AppInfoLoader(transport: transport, serviceBaseURL: configuration.serviceBaseURL, log: log)

        let sharePath: String
        if let cached = store.cachedSharePath(forLink: link) {
            sharePath = cached
        } else {
            sharePath = try await loader.sharePath(for: link)
            store.cacheSharePath(sharePath, forLink: link)
        }

        let appInfo = try await loader.load(sharePath: sharePath)
        store.lastCheckDate = Date()

        guard let published = appInfo.publishedBuild else { throw AppBoxError.noPublishedBuild }
        guard let installURL = InstallPageLink.url(for: appInfo) else { throw AppBoxError.noInstallLink }

        switch UpdateDecision.evaluate(published: published, installed: installed,
                                       comparison: configuration.comparison, skipped: store.skippedBuild) {
        case .upToDate:
            log.debug("\(installed.version) (\(installed.build)) is the latest build.")
            return nil
        case .skippedByUser:
            log.debug("\(published.version) (\(published.build)) was skipped by the user.")
            return nil
        case .available:
            let update = AppBoxUpdate(name: published.name.isEmpty ? installed.name : published.name,
                                      version: published.version,
                                      build: published.build,
                                      installURL: installURL,
                                      uploadDate: published.uploadDate,
                                      minimumOSVersion: published.minosversion,
                                      buildType: published.buildtype,
                                      fileSizeMB: published.ipafilesize)
            self.update = update
            log.info("\(update.displayVersion) is available.")
            return update
        }
    }

    /// Opens the install page for `update` so the user can install the build.
    public func openInstallPage(for update: AppBoxUpdate) {
        UIApplication.shared.open(update.installURL)
    }

    /// Sets the session up without checking.
    func configure(link: String, configuration: AppBoxConfiguration) {
        self.link = link
        self.configuration = configuration
        log = Log(isEnabled: configuration.isLoggingEnabled)
    }

    /// One check, with the alert shown when it finds something. Failures are logged, never thrown at the host app.
    func checkAndPresent() async {
        do {
            if let update = try await checkForUpdate() {
                present(update)
            }
        } catch is CancellationError {
            return
        } catch {
            log.error(error.localizedDescription)
        }
    }

    /// Awaits the check `start(link:configuration:)` kicked off.
    func pendingCheck() async {
        await checkTask?.value
    }

    private func check(force: Bool) {
        guard link != nil else { return }
        if !force, let last = store.lastCheckDate,
           Date().timeIntervalSince(last) < configuration.minimumCheckInterval {
            return
        }

        checkTask?.cancel()
        checkTask = Task { [weak self] in
            await self?.checkAndPresent()
        }
    }

    private func present(_ update: AppBoxUpdate) {
        updateHandler?(update)
        guard configuration.presentsAlert else { return }

        presenter.present(update, style: configuration.alertStyle) { [weak self] action in
            self?.handle(action, for: update)
        }
    }

    private func handle(_ action: AppBoxAlertAction, for update: AppBoxUpdate) {
        switch action {
        case .update:
            openInstallPage(for: update)
        case .later:
            break
        case .skip:
            store.skippedBuild = SkippedBuild(version: update.version, build: update.build)
        }
        log.debug("User chose \(action) for \(update.displayVersion).")
        alertActionHandler?(action, update)
    }

    private func observeForeground() {
        guard foregroundObserver == nil else { return }
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.check(force: false)
            }
        }
    }
}
