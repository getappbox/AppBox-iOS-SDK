//
//  AppBox.swift
//  AppBox
//
//  Created by Vineet Choudhary on 03/08/19.
//  Copyright © 2019 Developer Insdier. All rights reserved.
//

import Foundation

open class AppBox {
    private var appInfoURL: String!
    
    private var appNewBuild: String?
    private var appUpdateURL: String?
    private var appNewVersion: String?
    private var appNewVersionWithBuild: String = ""
    private var updateAlertController: UpdateAlertController?
    private var updateCheckInProgress: Bool = false
    private var appInfo: AppInfo?
    
    public static let Default = AppBox()
    public private(set) var key: String!
    public private(set) var checkVersionOnly: Bool = true
    public private(set) var alertType: AlertType = .force
    
    private init() {
        
    }
    
    public class func start(key: String, alertType: AlertType = .skip, checkVersionOnly: Bool = true) {
        AppBox.Default.key = key
        AppBox.Default.alertType = alertType
        AppBox.Default.checkVersionOnly = checkVersionOnly
        AppBox.Default.addObservers()
        AppBox.Default.requestAppInfo()
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { (notification) in
            if let appInfo = self.appInfo {
                self.checkForUpdate(appInfo: appInfo)
            }
        }
    }
    
    func requestAppInfo() {
        if updateCheckInProgress {
            return
        }
        
        appInfoURL = String(format: Constants.URLs.AppInfoFormat, key)
        
        updateCheckInProgress = true
        AppInfoService.getAppInfo(with: appInfoURL) { (appInfo) in
            self.updateCheckInProgress = false
            self.appInfo = appInfo
            if let appInfo = appInfo {
                self.checkForUpdate(appInfo: appInfo)
            }
        }
    }
    
    func checkForUpdate(appInfo: AppInfo) {
        let update = self.getUpdateDetails(from: appInfo)
        if UserDefaults.skippedVersion == update.version && UserDefaults.skippedBuild == update.build {
            ABLog.debug(String(format: "User has chosen to skip version %@.", self.appNewVersionWithBuild))
            return
        }
        
        guard let appUpdateURL = URL(string: self.appUpdateURL ?? "") else {
            return
        }
        
        guard let appName = appInfo.latestVersion?.name else {
            return
        }
        
        if DataParser.isNewVersionAvailable(newVersion: update.version, newBuild: update.build) {
            ABLog.debug(String(format: "A new version of %@ is available.", self.appNewVersionWithBuild))
            self.updateAlertController = UpdateAlertController(appName: appName, newVersion: update.version, newBuild: update.build)
            self.updateAlertController?.present(type: self.alertType, completion: { (action) in
                ABLog.debug(String(format: "User has chosen to %@ version %@.", action.description, self.appNewVersionWithBuild))
                switch action {
                case .appBox:
                    UIApplication.shared.open(appUpdateURL, options: [:], completionHandler: nil)
                case .skip:
                    break
                default:
                    break
                }
            })
        } else {
            ABLog.debug("You're using the latest version.")
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
