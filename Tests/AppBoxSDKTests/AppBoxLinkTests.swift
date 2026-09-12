//
//  AppBoxLinkTests.swift
//  AppBoxSDKTests
//
//  Created by Vineet Choudhary on 08/09/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

import Testing
import Foundation
@testable import AppBoxSDK

struct AppBoxLinkTests {

    // MARK: - Share path

    @Test func readsSharePathFromDropboxShareLink() {
        let path = AppBoxLink.sharePath(from: "https://www.dropbox.com/scl/fi/abc123/appinfo.json?rlkey=xyz&st=tok&dl=0")
        #expect(path == "/scl/fi/abc123/appinfo.json?rlkey=xyz&st=tok&dl=0")
    }

    @Test func readsSharePathFromLegacyDropboxShareLink() {
        let path = AppBoxLink.sharePath(from: "https://www.dropbox.com/s/oge15hcy8nhw9q3/appinfo.json")
        #expect(path == "/s/oge15hcy8nhw9q3/appinfo.json")
    }

    @Test func readsSharePathFromInstallPageLink() {
        let path = AppBoxLink.sharePath(from: "https://web.getappbox.com?url=/scl/fi/abc123/appinfo.json?rlkey=xyz")
        #expect(path == "/scl/fi/abc123/appinfo.json?rlkey=xyz")
    }

    /// AppBox escapes `&` as `%26` when it builds the install link, so a multi-parameter share link survives the round trip.
    @Test func readsSharePathFromInstallPageLinkWithEscapedAmpersand() {
        let path = AppBoxLink.sharePath(from: "https://web.getappbox.com?url=/scl/fi/abc/appinfo.json?rlkey=xyz%26st=tok")
        #expect(path == "/scl/fi/abc/appinfo.json?rlkey=xyz&st=tok")
    }

    /// A browser escapes the whole `url` value again on top of AppBox's own escaping.
    @Test func readsSharePathFromFullyEscapedInstallPageLink() {
        let link = "https://web.getappbox.com/?url=%2Fscl%2Ffi%2Fabc%2Fappinfo.json%3Frlkey%3Dxyz%2526st%3Dtok"
        #expect(AppBoxLink.sharePath(from: link) == "/scl/fi/abc/appinfo.json?rlkey=xyz&st=tok")
    }

    @Test func readsSharePathFromAlreadyProxiedLink() {
        let path = AppBoxLink.sharePath(from: "https://install.getappbox.com/appinfo/scl/fi/abc/appinfo.json?rlkey=xyz")
        #expect(path == "/scl/fi/abc/appinfo.json?rlkey=xyz")
    }

    @Test func readsSharePathFromLegacyUpdateKey() {
        #expect(AppBoxLink.sharePath(from: "oge15hcy8nhw9q3") == "/s/oge15hcy8nhw9q3/appinfo.json")
    }

    @Test func trimsSurroundingWhitespace() {
        #expect(AppBoxLink.sharePath(from: "  oge15hcy8nhw9q3\n") == "/s/oge15hcy8nhw9q3/appinfo.json")
    }

    @Test(arguments: [
        "",
        "https://example.com/scl/fi/abc/appinfo.json",
        "https://www.dropbox.com/home/appinfo.json",
        "https://www.dropbox.com/scl/fi/../../etc/passwd"
    ])
    func rejectsLinksItCannotUse(_ link: String) {
        #expect(AppBoxLink.sharePath(from: link) == nil)
    }

    /// A short link carries no share path, so the SDK has to follow it.
    @Test func shortLinkHasNoSharePathButIsResolvable() {
        #expect(AppBoxLink.sharePath(from: "https://appbox.me/AbCdEf") == nil)
        #expect(AppBoxLink.isResolvable("https://appbox.me/AbCdEf"))
    }

    @Test func plainKeyIsNotResolvableAsAURL() {
        #expect(AppBoxLink.isResolvable("oge15hcy8nhw9q3") == false)
    }

    // MARK: - Request URL

    @Test func buildsRequestURLThroughTheInstallService() {
        let url = AppBoxLink.requestURL(sharePath: "/scl/fi/abc/appinfo.json?rlkey=xyz&st=tok",
                                        serviceBaseURL: AppBoxConfiguration.defaultServiceBaseURL)
        #expect(url?.absoluteString == "https://install.getappbox.com/appinfo/scl/fi/abc/appinfo.json?rlkey=xyz&st=tok&dl=1")
    }

    @Test func buildsRequestURLStraightFromDropbox() {
        let url = AppBoxLink.requestURL(sharePath: "/scl/fi/abc/appinfo.json?rlkey=xyz", serviceBaseURL: nil)
        #expect(url?.absoluteString == "https://www.dropbox.com/scl/fi/abc/appinfo.json?rlkey=xyz&dl=1")
    }

    /// Dropbox serves its preview page for `dl=0`, so whatever the link said, the request asks for the file.
    @Test func forcesDownloadQueryParameter() {
        let url = AppBoxLink.requestURL(sharePath: "/s/abc/appinfo.json?dl=0", serviceBaseURL: nil)
        #expect(url?.absoluteString == "https://www.dropbox.com/s/abc/appinfo.json?dl=1")
    }

    @Test func addsDownloadQueryParameterWhenTheLinkHasNoQuery() {
        let url = AppBoxLink.requestURL(sharePath: "/s/abc/appinfo.json", serviceBaseURL: nil)
        #expect(url?.absoluteString == "https://www.dropbox.com/s/abc/appinfo.json?dl=1")
    }

    /// The short link adds tracking parameters that Dropbox rejects the request for.
    @Test func dropsShortLinkTrackingParameters() {
        let url = AppBoxLink.requestURL(sharePath: "/s/abc/appinfo.json?rlkey=k&_branch_match_id=670527565819258213&$web_only=true",
                                        serviceBaseURL: nil)
        #expect(url?.absoluteString == "https://www.dropbox.com/s/abc/appinfo.json?rlkey=k&dl=1")
    }

    @Test func honoursASelfHostedInstallService() {
        let url = AppBoxLink.requestURL(sharePath: "/s/abc/appinfo.json",
                                        serviceBaseURL: URL(string: "https://install.example.com/")!)
        #expect(url?.absoluteString == "https://install.example.com/appinfo/s/abc/appinfo.json?dl=1")
    }

    @Test func readsTheFileNameOfASharePath() {
        #expect(AppBoxLink.fileName(ofSharePath: "/scl/fi/abc/appinfo.json?rlkey=x") == "appinfo.json")
        #expect(AppBoxLink.fileName(ofSharePath: "/scl/fi/abc/manifest.plist") == "manifest.plist")
    }
}
