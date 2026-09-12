//
//  UpdateAlertPresenter.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import UIKit

/// Shows the update alert. Replaceable so the SDK can be driven without UIKit in tests.
@MainActor
protocol UpdatePresenting: AnyObject {
    var isPresenting: Bool { get }
    func present(_ update: AppBoxUpdate, style: AppBoxAlertStyle, handler: @escaping (AppBoxAlertAction) -> Void)
    func dismiss()
}

/// Presents a `UIAlertController` in a window of its own, above whatever the app is showing.
@MainActor
final class UpdateAlertPresenter: UpdatePresenting {
    private var window: UIWindow?

    var isPresenting: Bool { window != nil }

    func present(_ update: AppBoxUpdate, style: AppBoxAlertStyle, handler: @escaping (AppBoxAlertAction) -> Void) {
        guard !isPresenting, let scene = Self.activeWindowScene() else { return }

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        self.window = window

        show(update, style: style, handler: handler)
    }

    /// A forced alert comes straight back, so the app stays gated until the user really updates.
    private func show(_ update: AppBoxUpdate, style: AppBoxAlertStyle, handler: @escaping (AppBoxAlertAction) -> Void) {
        let alert = UIAlertController(title: Strings.title,
                                      message: Strings.message(appName: update.name, version: update.displayVersion),
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: Strings.update, style: .default) { [weak self] _ in
            handler(.update)
            if style == .forced {
                self?.show(update, style: style, handler: handler)
            } else {
                self?.dismiss()
            }
        })

        if style == .optional || style == .skippable {
            alert.addAction(UIAlertAction(title: Strings.later, style: .default) { [weak self] _ in
                self?.dismiss()
                handler(.later)
            })
        }

        if style == .skippable {
            alert.addAction(UIAlertAction(title: Strings.skip, style: .destructive) { [weak self] _ in
                self?.dismiss()
                handler(.skip)
            })
        }

        window?.rootViewController?.present(alert, animated: true)
    }

    func dismiss() {
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
    }

    private static func activeWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive }
            ?? scenes.first { $0.activationState == .foregroundInactive }
            ?? scenes.first
    }

    /// English text doubles as the lookup key, so a host app can localise the alert by adding these keys to its own strings file.
    private enum Strings {
        static var title: String {
            NSLocalizedString("Update Available", comment: "Title of the AppBox update alert")
        }

        static var update: String {
            NSLocalizedString("Update", comment: "Button that opens the AppBox install page")
        }

        static var later: String {
            NSLocalizedString("Next Time", comment: "Button that dismisses the update alert")
        }

        static var skip: String {
            NSLocalizedString("Skip This Version", comment: "Button that stops the SDK offering this build")
        }

        static func message(appName: String, version: String) -> String {
            let format = NSLocalizedString("A new version of %@ is available. Please update to version %@ now.",
                                           comment: "Body of the AppBox update alert")
            let name = appName.isEmpty ? NSLocalizedString("this app", comment: "Stand-in when the build has no name") : appName
            return String(format: format, name, version)
        }
    }
}
