//
//  UserDefaultExtension.swift
//  AppBox
//
//  Created by Vineet Choudhary on 13/08/19.
//  Copyright © 2019 Developer Insdier. All rights reserved.
//

import Foundation

extension UserDefaults {
    private enum AppBoxKeys: String {
        case VersionCheckDate
        case SkippedVersion
        case SkippedBuild
    }
    
    static var skippedVersion: String? {
        get {
            return standard.string(forKey: AppBoxKeys.SkippedVersion.rawValue)
        } set {
            standard.set(newValue, forKey: AppBoxKeys.SkippedVersion.rawValue)
            standard.synchronize()
        }
    }
    
    static var skippedBuild: String? {
        get {
            return standard.string(forKey: AppBoxKeys.SkippedBuild.rawValue)
        } set {
            standard.set(newValue, forKey: AppBoxKeys.SkippedBuild.rawValue)
            standard.synchronize()
        }
    }
    
    static var alertPresentationDate: Date? {
        get {
            return standard.object(forKey: AppBoxKeys.VersionCheckDate.rawValue) as? Date
        } set {
            standard.set(newValue, forKey: AppBoxKeys.VersionCheckDate.rawValue)
            standard.synchronize()
        }
    }
}
