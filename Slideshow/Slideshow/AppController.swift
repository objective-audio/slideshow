//
//  AppController.swift
//  Slideshow
//
//  Created by Yuki Yasoshima on 2018/04/30.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation

class AppController {
    static let shared = AppController()
    
    let imageLibrary = ImageLibrary()
    
    private init() {
    }
    
    func setup() {
        self.imageLibrary.setup()
    }
}
