//
//  UpdateWindow.swift
//  AppBox
//
//  Created by Vineet Choudhary on 13/08/19.
//  Copyright © 2019 Developer Insdier. All rights reserved.
//

import Foundation

class UpdateWindow: UIWindow {
    public static let Default = UpdateWindow()
    
    private init() {
        super.init(frame: UIScreen.main.bounds)
        rootViewController = UIViewController()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
