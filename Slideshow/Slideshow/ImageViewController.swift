//
//  ImageViewController.swift
//  Slideshow
//
//  Created by Yuki Yasoshima on 2018/04/30.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import UIKit
import Photos

class ImageViewController: UIViewController {
    var index: Int = 0
    weak var controller: ImagePageController?
    
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadImage()
    }
    
    func loadImage() {
        guard let asset = self.controller?.assets[self.index] else {
            return
        }
        
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                                              contentMode: .default,
                                              options: nil)
        { [weak self] (image, info) in self?.imageView.image = image }
    }
}
