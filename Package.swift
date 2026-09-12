// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AppBoxSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "AppBoxSDK", targets: ["AppBoxSDK"])
    ],
    targets: [
        .target(name: "AppBoxSDK"),
        .testTarget(name: "AppBoxSDKTests", dependencies: ["AppBoxSDK"])
    ],
    swiftLanguageModes: [.v6]
)
