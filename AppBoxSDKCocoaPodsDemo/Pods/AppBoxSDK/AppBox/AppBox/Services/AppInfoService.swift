//
//  AppInfoService.swift
//  AppBox
//
//  Created by Vineet Choudhary on 04/08/19.
//  Copyright © 2019 Developer Insdier. All rights reserved.
//

import Foundation

struct AppInfoService {
    
    static func getAppInfo(with appInfoURL: String, completion: @escaping (AppInfo?) -> Void) {
        guard let requestURL = URL(string: appInfoURL) else {
            ABLog.error("Unable to build request URL object from \(String.init(appInfoURL))")
            return
        }
        
        
        let dataTask = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    ABLog.error("Error in requesting AppInfo.", error: error)
                    completion(nil)
                    return
                }
                
                guard let data = data else {
                    ABLog.error("AppInfo data not available")
                    completion(nil)
                    return
                }
                
                do {
                    let appInfo = try JSONDecoder().decode(AppInfo.self, from: data)
                    completion(appInfo)
                }
                catch {
                    ABLog.error("Unable to decode AppInfo", error: error)
                    completion(nil)
                }
            }
        })
        dataTask.resume()
    }
}
