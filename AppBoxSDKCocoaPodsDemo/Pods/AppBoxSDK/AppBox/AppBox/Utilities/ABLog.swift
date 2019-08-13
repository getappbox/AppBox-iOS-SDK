//
//  ABLog.swift
//  AppBox
//
//  Created by Vineet Choudhary on 04/08/19.
//  Copyright © 2019 Developer Insdier. All rights reserved.
//

import Foundation

struct ABLog {
    static func error(_ msg: String, error: Error? = nil) {
        log(String.init(format: "🔥 - %@ %@", msg, error?.localizedDescription ?? ""))
    }
    
    static func info(_ msg: String) {
        log(String.init(format: "🚀 - %@", msg))
    }
    
    static func debug(_ msg: String) {
        log(String.init(format: "👀 - %@", msg))
    }
    
    static func log(_ msg: String) {
        #if DEBUG
        print(String.init(format: "AppBoxSDK %@", msg))
        #endif
    }
}
