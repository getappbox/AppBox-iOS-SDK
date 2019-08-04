//
//  AppBox.swift
//  AppBoxSDK
//
//  Created by Vineet Choudhary on 03/08/19.
//  Copyright © 2019 Developer Insdier. All rights reserved.
//

import Foundation

open class AppBox {
    public private(set) var installationURL: String!
    
    private init() {
        
    }
    
    init(installationURL url: String) {
        self.installationURL = url
    }
}
