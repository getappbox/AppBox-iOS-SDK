//
//  DataParser.swift
//  AppBox
//
//  Created by Vineet Choudhary on 04/08/19.
//  Copyright © 2019 Developer Insdier. All rights reserved.
//

import Foundation

struct DataParser {
    
    static func isNewVersionAvailable(newVersion: String, newBuild: String) -> Bool {
        guard let infoPlist = Bundle.main.infoDictionary else {
            ABLog.error("InfoPlist not found in main Bundle.")
            return false
        }
        
        guard let installedVersion = infoPlist[Constants.Bundle.Version] as? String else {
            ABLog.error("Version number not available in InfoPlist.")
            return false
        }
        
        
        if (AppBox.Default.checkVersionOnly) {
            //Check version only
            return (installedVersion.compare(newVersion, options: .numeric) == .orderedAscending)
        }
        
        guard let installedBuildNumber = infoPlist[Constants.Bundle.BuildNumber] as? String else {
            ABLog.error("Build number not available in InfoPlist.")
            return false
        }
        
        //Check Version and Build Number 
        return (installedVersion.compare(newVersion, options: .numeric) == .orderedAscending) ||
            (installedVersion.compare(newVersion, options: .numeric) == .orderedSame &&
            installedBuildNumber.compare(newBuild, options: .numeric) == .orderedAscending)
    }
}
