//
//  AppDelegate.swift
//  Slideshow
//
//  Created by Yuki Yasoshima on 2018/04/30.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        AppController.shared.setup()
        
        return true
    }
}

