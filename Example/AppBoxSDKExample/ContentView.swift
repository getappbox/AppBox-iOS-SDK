//
//  ContentView.swift
//  AppBoxSDKExample
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import AppBoxSDK
import SwiftUI

struct ContentView: View {
    @State private var status: Status = .idle

    var body: some View {
        NavigationView {
            List {
                Section("This build") {
                    Row("Version", Bundle.main.shortVersion)
                    Row("Build", Bundle.main.buildNumber)
                }

                Section("AppBox") {
                    if ExampleConfiguration.isConfigured {
                        Row("Watching", ExampleConfiguration.installLink)
                    } else {
                        Text("Set an install link in ExampleConfiguration.swift to start checking for updates.")
                            .foregroundColor(.secondary)
                    }

                    Button("Check for update now", action: check)
                        .disabled(!ExampleConfiguration.isConfigured || status == .checking)
                }

                Section("Result") {
                    statusView
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("AppBox SDK")
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder private var statusView: some View {
        switch status {
        case .idle:
            Text("Not checked yet.").foregroundColor(.secondary)
        case .checking:
            HStack(spacing: 8) {
                ProgressView()
                Text("Checking…")
            }
        case .upToDate:
            Label("You are on the latest build.", systemImage: "checkmark.circle")
        case .available(let update):
            VStack(alignment: .leading, spacing: 8) {
                Label("\(update.displayVersion) is available", systemImage: "arrow.down.circle")
                if let buildType = update.buildType {
                    Row("Build type", buildType)
                }
                if let size = update.fileSizeMB {
                    Row("Size", "\(size) MB")
                }
                Link("Install it", destination: update.installURL)
            }
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundColor(.red)
        }
    }

    private func check() {
        status = .checking
        Task {
            do {
                if let update = try await AppBox.checkForUpdate() {
                    status = .available(update)
                } else {
                    status = .upToDate
                }
            } catch {
                status = .failed(error.localizedDescription)
            }
        }
    }

    private enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case available(AppBoxUpdate)
        case failed(String)
    }
}

private struct Row: View {
    let title: String
    let value: String

    init(_ title: String, _ value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
            Spacer(minLength: 16)
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .truncationMode(.middle)
        }
    }
}

private extension Bundle {
    var shortVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}
