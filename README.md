[![Sponsor on GitHub](https://img.shields.io/badge/Sponsor%20on%20GitHub-EA4AAA?style=for-the-badge&logo=github&logoColor=white)](https://github.com/sponsors/vineetchoudhary)
[![Buy me a coffee](https://img.shields.io/badge/Buy%20me%20a%20coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/vineetchoudhary)
[![Test status](https://img.shields.io/github/actions/workflow/status/getappbox/AppBox-iOS-SDK/test.yml?branch=master&style=for-the-badge&logo=githubactions&logoColor=white&label=tests)](https://github.com/getappbox/AppBox-iOS-SDK/actions/workflows/test.yml)
[![Swift Package Manager](https://img.shields.io/badge/SPM-supported-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org/package-manager/)
[![Platform](https://img.shields.io/badge/iOS-15%2B-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)

# AppBox SDK for iOS

Add the AppBox SDK to your development, ad-hoc or in-house (enterprise) iOS app and it tells whoever is running an old build that a newer one is ready — from the same [AppBox](https://getappbox.com) upload you already do.

## How it works

Every AppBox upload writes an `appinfo.json` next to the build and gives you one link to share. The SDK reads that same file, compares the published build against the one running, and offers the install page when there is something newer. No account, no extra service, no analytics.

## Requirements

- iOS 15.0 or later
- Xcode 16 or later (Swift 6 tools)
- [AppBox for Mac](https://getappbox.com/download) to publish the builds

## Install

The SDK ships as a Swift package. CocoaPods and Carthage are no longer supported — see [Migrating from 1.x](#migrating-from-1x).

### Xcode

**File ▸ Add Package Dependencies…**, enter `https://github.com/getappbox/AppBox-iOS-SDK.git`, and add **AppBoxSDK** to your app target.

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/getappbox/AppBox-iOS-SDK.git", from: "4.0.0")
],
targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "AppBoxSDK", package: "AppBox-iOS-SDK")
    ])
]
```

## Get the link to watch

Upload a build with AppBox and **keep the same link for all future builds** turned on — [Keep same link](https://docs.getappbox.com/Features/keepsamelink/) — so one link keeps pointing at your newest build. AppBox then gives you a short link like `https://appbox.me/AbCdEf`. That is the link the SDK watches.

Any of these work, so paste whichever you have:

| Link | Example |
|---|---|
| Short link | `https://appbox.me/AbCdEf` |
| Install page link | `https://web.getappbox.com?url=/scl/fi/…/appinfo.json?rlkey=…` |
| Dropbox share link of `appinfo.json` | `https://www.dropbox.com/scl/fi/…/appinfo.json?rlkey=…` |
| Legacy app update key | `oge15hcy8nhw9q3` |

> Without keep-same-link every upload gets its own link, so a build already on a device keeps watching the link it shipped with and never sees the next one.

## Start the SDK

```swift
import AppBoxSDK

@main
struct YourApp: App {
    init() {
        AppBox.start(link: "https://appbox.me/AbCdEf")
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

Or from a `UIApplicationDelegate`:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    AppBox.start(link: "https://appbox.me/AbCdEf")
    return true
}
```

That is the whole integration. The SDK checks at launch and again whenever the app returns to the foreground, and shows an alert when a newer build is published.

## Configuration

```swift
AppBox.start(
    link: "https://appbox.me/AbCdEf",
    configuration: AppBoxConfiguration(alertStyle: .optional, comparison: .versionAndBuild))
```

| Option | Default | What it does |
|---|---|---|
| `alertStyle` | `.skippable` | `.forced` offers only Update, `.optional` adds Next Time, `.skippable` adds Skip This Version. |
| `comparison` | `.version` | `.version` compares `CFBundleShortVersionString` only; `.versionAndBuild` also compares `CFBundleVersion`, so a rebuild of the same version counts. |
| `checksOnForeground` | `true` | Check again when the app comes back to the foreground. |
| `minimumCheckInterval` | `60` | Shortest gap, in seconds, between two automatic checks. |
| `presentsAlert` | `true` | Set `false` to show your own UI from `updateHandler`. |
| `serviceBaseURL` | `install.getappbox.com` | The AppBox install service that serves `appinfo.json`. Set `nil` to read the share link straight from Dropbox, or point it at your own [install-helper](https://github.com/getappbox/install-helper). |
| `isLoggingEnabled` | `true` in debug | Logs to the unified logging system under the `com.getappbox.sdk` subsystem. |

Version and build numbers are compared component by component, so `1.10` is newer than `1.9`, and `1.0` and `1.0.0` are the same build.

## Your own UI

Turn the built-in alert off and handle the update yourself:

```swift
AppBox.start(link: link, configuration: AppBoxConfiguration(presentsAlert: false))

AppBox.shared.updateHandler = { update in
    print("\(update.name) \(update.displayVersion) is available")
    AppBox.shared.openInstallPage(for: update)
}
```

Or check on demand — this never shows UI and returns `nil` when there is nothing newer:

```swift
if let update = try await AppBox.checkForUpdate() {
    // update.version, update.build, update.installURL, update.uploadDate,
    // update.buildType, update.fileSizeMB, update.minimumOSVersion
}
```

To watch what the user chose:

```swift
AppBox.shared.alertActionHandler = { action, update in
    // .update, .later or .skip
}
```

`AppBox.resetSkippedBuild()` forgets a skipped build so it is offered again, `AppBox.stop()` ends foreground checking, and `AppBox.sdkVersion` reports which SDK a build shipped with.

## Example app

[`Example/`](Example) is a small SwiftUI app with the SDK linked through SPM, plus two ways to publish it — [`Example/Scripts/upload.sh`](Example/Scripts/upload.sh), which drives `appboxcli` directly, and fastlane lanes using the [AppBox fastlane plugin](https://github.com/getappbox/fastlane-plugin-appbox). Either one gives you the whole build ▸ upload ▸ auto-update loop in one project. See [`Example/README.md`](Example/README.md).

## Migrating from 1.x

1.x shipped as a CocoaPods pod and a Carthage framework. Both are gone; the SDK is a Swift package. Remove `pod 'AppBoxSDK'` or the `getappbox/AppBox-iOS-SDK` Cartfile entry and add the package instead.

`AppBox.start(key:)` addressed Dropbox's legacy `/s/<key>/` share links, which new uploads no longer use, and it made you dig the key out of a URL by hand. Pass the link AppBox gives you instead:

```swift
// 1.x
AppBox.start(key: "oge15hcy8nhw9q3", alertType: .skip, checkVersionOnly: true)

// 4.x
AppBox.start(
    link: "https://appbox.me/AbCdEf",
    configuration: AppBoxConfiguration(alertStyle: .skippable, comparison: .version)
)
```

The old symbols still compile, with deprecation warnings pointing at the replacements:

| 1.x | 4.x |
|---|---|
| `AppBox.start(key:alertType:checkVersionOnly:)` | `AppBox.start(link:configuration:)` |
| `AppBox.Default` | `AppBox.shared` |
| `AlertType` / `.force` `.option` `.skip` | `AppBoxAlertStyle` / `.forced` `.optional` `.skippable` |
| `AlertAction` / `.appBox` `.nextTime` | `AppBoxAlertAction` / `.update` `.later` |
| `checkVersionOnly: Bool` | `comparison: .version` / `.versionAndBuild` |

The minimum deployment target moves from iOS 10 to iOS 15.

## Troubleshooting

**Nothing happens.** Turn logging on (it is on by default in debug builds) and watch the console, or filter Console.app by the `com.getappbox.sdk` subsystem. Every skipped check says why.

**"is not an AppBox install link".** The link isn't one of the four forms in the table above. Check you copied the install link and not the IPA or manifest link — the SDK needs the one that ends in `appinfo.json`.

**The alert never comes back after a new upload.** The upload has to reuse the same link. Upload with keep-same-link on, or with the fastlane plugin's `keep_same_link: true`.

**A build was skipped by mistake.** `AppBox.resetSkippedBuild()`, or reinstall.

## Contributions ❤️

Any contribution is more than welcome, through pull requests and [issues](https://github.com/getappbox/AppBox-iOS-SDK/issues) on [GitHub](https://github.com/getappbox/AppBox-iOS-SDK/).

## Bugs 💔

Please post bugs to the [issue tracker](https://github.com/getappbox/AppBox-iOS-SDK/issues), including a description of what is not working.

## Support

If the AppBox SDK has been useful to you, consider supporting its continued development.

<a href="https://github.com/sponsors/vineetchoudhary">
  <img src="https://img.shields.io/badge/Sponsor%20on%20GitHub-EA4AAA?style=for-the-badge&logo=github&logoColor=white" alt="Sponsor on GitHub" height="50">
</a>
&nbsp;
<a href="https://buymeacoffee.com/vineetchoudhary">
  <img src="https://img.shields.io/badge/Buy%20me%20a%20coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me a Coffee" height="50">
</a>

Thank you for supporting open source! 🙏

## License

MIT — see [LICENSE](LICENSE).
