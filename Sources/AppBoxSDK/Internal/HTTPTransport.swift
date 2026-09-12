//
//  HTTPTransport.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Foundation

/// The single network call the SDK makes, behind a protocol so tests never touch the network.
protocol HTTPTransport: Sendable {
    /// - Returns: the body, the status code, and the URL the request ended on after redirects.
    func get(_ url: URL) async throws -> (data: Data, statusCode: Int, finalURL: URL?)
}

struct URLSessionTransport: HTTPTransport {
    let session: URLSession

    init(session: URLSession = URLSessionTransport.makeSession()) {
        self.session = session
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 20
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }

    func get(_ url: URL) async throws -> (data: Data, statusCode: Int, finalURL: URL?) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            let http = response as? HTTPURLResponse
            return (data, http?.statusCode ?? 0, response.url)
        } catch {
            throw AppBoxError.requestFailed(error.localizedDescription)
        }
    }
}
