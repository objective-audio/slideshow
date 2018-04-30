//
//  ImagePageViewController.swift
//  Slideshow
//
//  Created by Yuki Yasoshima on 2018/04/30.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import UIKit
import Photos

class ImagePageViewController: UIPageViewController {
    let controller = ImagePageController(imageLibrary: AppController.shared.imageLibrary)
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.controller.eventHandler = { [weak self] (event, controller) in
            guard let sself = self else { return }
            
            switch event {
            case .launched:
                sself.showLaunching()
            case .showManyImages:
                sself.showManyImages()
            case .showSingleImage:
                sself.showSingleImage()
            case .showEmpty:
                sself.showEmpty()
            case .showAlert:
                sself.showAlert()
            case .moveToNextImage:
                sself.moveToNextImage()
            }
        }
        
        self.controller.setup(object: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.controller.appeared(object: self)
    }
}

// MARK: - Event Functions

extension ImagePageViewController {
    private func showManyImages() {
        self.dataSource = self
        
        let imageViewController = self.createImageViewController(index: 0)
        self.setViewControllers([imageViewController], direction: .forward, animated: true, completion: nil)
    }
    
    private func showSingleImage() {
        self.dataSource = nil
        
        let imageViewController = self.createImageViewController(index: 0)
        self.setViewControllers([imageViewController], direction: .forward, animated: true, completion: nil)
    }
    
    private func showEmpty() {
        self.dataSource = nil
        self.setViewControllers([self.createEmptyViewController()], direction: .forward, animated: true, completion: nil)
    }
    
    private func showLaunching() {
        self.dataSource = nil
        self.setViewControllers([self.createLaunchingViewController()], direction: .forward, animated: true, completion: nil)
    }
    
    private func showAlert() {
        let alert = UIAlertController(title: "アクセス不可", message: "画像ライブラリへのアクセスが許可されていません", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func moveToNextImage() {
        guard let next = self.createNextImageViewController() else {
            return
        }
        
        self.setViewControllers([next], direction: .forward, animated: true, completion: nil)
    }
}

// MARK: - ViewController Creating Functions

extension ImagePageViewController {
    private func createLaunchingViewController() -> UIViewController {
        return UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()!
    }
    
    private func createEmptyViewController() -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Empty")
    }
    
    private func createImageViewController(index: Int) -> ImageViewController {
        guard let imageViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Image") as? ImageViewController else {
            fatalError()
        }
        
        imageViewController.index = index
        imageViewController.controller = self.controller
        
        return imageViewController
    }
    
    private func createNextImageViewController() -> ImageViewController? {
        guard let imageViewController = self.currentImageViewController() else {
            return nil
        }
        
        return self.createImageViewController(index: self.controller.nextIndex(from: imageViewController.index))
    }
    
    private func createPrevImageViewController() -> ImageViewController? {
        guard let imageViewController = self.currentImageViewController() else {
            return nil
        }
        
        return self.createImageViewController(index: self.controller.prevIndex(from: imageViewController.index))
    }
    
    private func currentImageViewController() -> ImageViewController? {
        guard self.controller.assets.count > 0 else {
            return nil
        }
        
        guard let imageViewController = self.viewControllers?.first as? ImageViewController else {
            return nil
        }
        
        return imageViewController
    }
}

// MARK: - UIPageViewControllerDataSource

extension ImagePageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard self.controller.assets.count > 1 else {
            return nil
        }
        
        return self.createPrevImageViewController()
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard self.controller.assets.count > 1 else {
            return nil
        }
        
        return self.createNextImageViewController()
    }
}
