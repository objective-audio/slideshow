//
//  ImageLibrary.swift
//  Slideshow
//
//  Created by Yuki Yasoshima on 2018/04/30.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation
import Photos

extension Notification.Name {
    static let imageLibraryLoaded = Notification.Name("ImageLibraryLoaded")
    static let imageLibraryFailed = Notification.Name("ImageLibraryFailed")
}

class ImageLibrary {
    enum State {
        case loading
        case loaded
        case failed
    }
    
    var state: State {
        switch self.flow.state {
        case .loadedEnter, .loaded:
            return .loaded
        case .failedEnter, .failed:
            return .failed
        default:
            return .loading
        }
    }
    
    private(set) var assets: [PHAsset] = []
    
    private let flow = ImageLibraryFlow()
    
    func setup() {
        self.flow.graph.run((.load, self))
    }
    
    fileprivate func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            self?.flow.graph.run((.status(status), self!))
        }
    }
    
    fileprivate func loadAssets() {
        self.assets = []
        
        let assets: PHFetchResult = PHAsset.fetchAssets(with: .image, options: nil)
        assets.enumerateObjects({ [weak self] (asset, index, stop) -> Void in
            self?.assets.append(asset)
        })
    }
    
    fileprivate func postLoadedNotify() {
        NotificationCenter.default.post(name: .imageLibraryLoaded, object: self)
    }
    
    fileprivate func postFailedNotify() {
        NotificationCenter.default.post(name: .imageLibraryFailed, object: self)
    }
}

fileprivate class ImageLibraryFlow {
    enum State: EnumEnumerable {
        case begin
        case check
        case requestingEnter
        case requesting
        case loading
        case loadedEnter
        case loaded
        case failedEnter
        case failed
    }
    
    enum EventName {
        case load
        case status(PHAuthorizationStatus)
        case success
        case fail
    }
    
    typealias Event = (name: EventName, object: ImageLibrary)
    
    let graph: FlowGraph<State, Event>
    var state: State { return self.graph.state }
    
    init() {
        let builder = FlowGraphBuilder<State, Event>()
        
        builder.add(state: .begin) { event in
            switch event.name {
            case .load:
                return .run(.check, event)
            default:
                return .stay
            }
        }
        
        builder.add(state: .check) { event in
            switch PHPhotoLibrary.authorizationStatus() {
            case .authorized:
                return .run(.loading, event)
            case .notDetermined:
                return .run(.requestingEnter, event)
            case .denied:
                return .run(.failedEnter, event)
            case .restricted:
                return .run(.failedEnter, event)
            }
        }
        
        builder.add(state: .requestingEnter) { event in
            event.object.requestAuthorization()
            
            return .wait(.requesting)
        }
        
        builder.add(state: .requesting) { event in
            switch PHPhotoLibrary.authorizationStatus() {
            case .authorized:
                return .run(.loading, event)
            case .notDetermined:
                fatalError()
            case .denied:
                return .run(.failedEnter, event)
            case .restricted:
                return .run(.failedEnter, event)
            }
        }
        
        builder.add(state: .loading) { event in
            event.object.loadAssets()
            
            return .run(.loadedEnter, event)
        }
        
        builder.add(state: .loadedEnter) { event in
            event.object.postLoadedNotify()
            
            return .wait(.loaded)
        }
        
        builder.add(state: .failedEnter) { event in
            event.object.postFailedNotify()
            
            return .wait(.failed)
        }
        
        builder.add(state: .loaded) { event in
            return .stay
        }
        
        builder.add(state: .failed) { event in
            return .stay
        }
        
        for state in State.cases {
            if !builder.contains(state: state) {
                fatalError()
            }
        }
        
        self.graph = builder.build(initial: .begin)
    }
}
