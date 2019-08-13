//
//  UpdateAlertController.swift
//  AppBox
//
//  Created by Vineet Choudhary on 13/08/19.
//  Copyright © 2019 Developer Insdier. All rights reserved.
//

import Foundation

public class UpdateAlertController {
    typealias CompletionHandler = (AlertAction) -> Void
    
    private let window = UpdateWindow.Default
    private let appName: String!
    private let newVersion: String!
    private let newBuild: String!
    private let alertController: UIAlertController!
    private var alertType: AlertType = .force
    
    init(appName name: String, newVersion version: String, newBuild build: String) {
        newVersion = version
        newBuild = build
        appName = name
        
        let alertTitle = "Update Available"
        let version = String(format: "%@(%@)", newVersion, newBuild)
        var alertMessage = "A new version of %@ is available. Please update to version %@ now."
        alertMessage = String(format: alertMessage, appName, version)
        
        alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
    }
    
    func present(type: AlertType = .force, completion handler: @escaping CompletionHandler) {
        alertType = type
        UserDefaults.alertPresentationDate = Date()
        
        switch type {
        case .force:
            alertController?.addAction(updateAlertAction(completion: handler))
        case .option:
            alertController?.addAction(updateAlertAction(completion: handler))
            alertController?.addAction(nextTimeAlertAction(completion: handler))
        case .skip:
            alertController?.addAction(updateAlertAction(completion: handler))
            alertController?.addAction(nextTimeAlertAction(completion: handler))
            alertController?.addAction(skipAlertAction(newVersion: newVersion, newBuild: newBuild, completion: handler))
        }
        
        show()
    }
    
    private func updateAlertAction(completion handler: CompletionHandler?) -> UIAlertAction {
        let updateButtonTitle = "Update"
        
        let action = UIAlertAction(title: updateButtonTitle, style: .default) { [weak self] _ in
            if (self?.alertType != .force) {
                self?.hide()
            }
            handler?(.appBox)
            return
        }
        
        return action
    }
    
    
    private func nextTimeAlertAction(completion handler: CompletionHandler?) -> UIAlertAction {
        let nextTimeButtonTitle = "Next time"
        
        let action = UIAlertAction(title: nextTimeButtonTitle, style: .default) { [weak self] _ in
            handler?(.nextTime)
            self?.hide()
            return
        }
        
        return action
    }
    
    private func skipAlertAction(newVersion: String, newBuild: String, completion handler: CompletionHandler?) -> UIAlertAction {
        let skipButtonTitle = "Skip this version"
        
        let action = UIAlertAction(title: skipButtonTitle, style: .default) { [weak self] _ in
            UserDefaults.skippedVersion = newVersion
            UserDefaults.skippedBuild = newBuild
            handler?(.skip)
            self?.hide()
            return
        }
        
        return action
    }
    
    private func show() {
        window.windowLevel = UIWindow.Level.alert + 1
        window.makeKeyAndVisible()
        if window.rootViewController?.presentedViewController == nil {
            window.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func hide() {
        window.isHidden = true
    }
}

