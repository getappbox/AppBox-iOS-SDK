//
//  AppBox.swift
//  AppBox
//
//  Created by Vineet Choudhary on 03/08/19.
//  Copyright © 2019 Developer Insdier. All rights reserved.
//

import Foundation

open class AppBox {
    var appInfoURL: String!
    
    var appNewBuild: String?
    var appUpdateURL: String?
    var appNewVersion: String?
    var appNewVersionWithBuild: String = ""
    
    public static let Default = AppBox()
    public private(set) var key: String!
    public private(set) var checkVersionOnly: Bool = true
    
    private init() {
        
    }
    
    public class func start(key: String, checkVersionOnly: Bool = true) {
        AppBox.Default.key = key
        AppBox.Default.checkVersionOnly = checkVersionOnly
        AppBox.Default.checkForUpdate()
    }
    
    func checkForUpdate() {
        appInfoURL = String(format: Constants.URLs.AppInfoFormat, key)
        
        AppInfoService.getAppInfo(with: appInfoURL) { (appInfo) in
            guard let appInfo = appInfo else {
                ABLog.error("AppInfo not available.")
                return
            }
            
            let update = self.getUpdateDetails(from: appInfo)
            guard let appUpdateURL = URL(string: self.appUpdateURL ?? "") else {
                return
            }
            
            if DataParser.isNewVersionAvailable(newVersion: update.version, newBuild: update.build) {
                ABLog.debug(String(format: "A new version of %@ is available.", self.appNewVersionWithBuild))
                DispatchQueue.main.async {
                    UIApplication.shared.open(appUpdateURL, options: [:], completionHandler: nil)
                }
            } else {
                ABLog.debug("You're using the latest version.")
            }
        }
    }
    
    func getUpdateDetails(from appInfo: AppInfo)-> (version: String, build: String) {
        guard let appUpdateURL = appInfo.uniqueLinkShort else {
            ABLog.error("Update link not available in AppInfo.")
            return ("", "")
        }
        self.appUpdateURL = appUpdateURL
        
        guard let newVersion = appInfo.latestVersion?.version else {
            ABLog.error("Version number not available in AppInfo.")
            return ("", "")
        }
        self.appNewVersion = newVersion
        self.appNewVersionWithBuild = newVersion
        
        guard let newBuild = appInfo.latestVersion?.build else {
            ABLog.error("Version number not available in AppInfo.")
            return (newVersion, "")
        }
        
        self.appNewBuild = newBuild
        self.appNewVersionWithBuild = String(format: "%@(%@)", newVersion, newBuild)
        return (newVersion, newBuild)
    }
    
    
}
