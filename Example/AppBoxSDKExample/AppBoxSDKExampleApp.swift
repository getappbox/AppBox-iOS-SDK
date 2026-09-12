//
//  AppBoxSDKExampleApp.swift
//  AppBoxSDKExample
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import AppBoxSDK
import SwiftUI

@main
struct AppBoxSDKExampleApp: App {
    init() {
        guard ExampleConfiguration.isConfigured else { return }

        AppBox.start(
			link: ExampleConfiguration.installLink,
			configuration: AppBoxConfiguration(
				alertStyle: .skippable,
				comparison: .versionAndBuild))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
