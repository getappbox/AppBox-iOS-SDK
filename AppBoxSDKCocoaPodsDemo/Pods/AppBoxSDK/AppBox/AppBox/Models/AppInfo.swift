//
//  AppInfo.swift
//  AppBox
//
//  Created by Vineet Choudhary on 03/08/19.
//  Copyright © 2019 Developer Insdier. All rights reserved.
//

import Foundation

// MARK: - Welcome
struct AppInfo: Decodable {
    let uniqueLinkShared: String?
    let latestVersion: Version?
    let versions: [Version]?
    let uniqueLinkShort: String?
}

// MARK: - Version
struct Version: Decodable {
    let build, buildtype: String?
    let manifestLink: String?
    let supporteddevice, minosversion: String?
    let ipafilesize: Int?
    let mobileprovision: Mobileprovision?
    let identifier, version: String?
    let timestamp: Double?
    let name: String?
}

// MARK: - Mobileprovision
struct Mobileprovision: Decodable {
    let devicesudid: [String]?
    let uuid, teamname: String?
    let expirationdata, createdate: Int?
    let teamid: String?
}

