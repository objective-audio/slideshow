//
//  ImagePageController.swift
//  Slideshow
//
//  Created by Yuki Yasoshima on 2018/04/30.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation
import Photos

class ImagePageController {
    enum Event {
        case launched
        case showManyImages
        case showSingleImage
        case showEmpty
        case showAlert
        case moveToNextImage
    }
    
    var assets: [PHAsset] {
        if let library = self.imageLibrary {
            return library.assets
        } else {
            return []
        }
    }
    
    var eventHandler: ((Event, ImagePageController) -> Void)?
    
    fileprivate var isAppeared = false
    
    private weak var imageLibrary: ImageLibrary?
    private let flow =  ImagePageControllerFlow()
    private var loadedObserver: NSObjectProtocol?
    private var failedObserver: NSObjectProtocol?
    private var timer: Timer?
    
    init(imageLibrary: ImageLibrary) {
        self.imageLibrary = imageLibrary
    }
    
    deinit {
        self.timer?.invalidate()
    }
    
    func setup(object: ImagePageViewController) {
        self.loadedObserver =
            NotificationCenter.default.addObserver(forName: .imageLibraryLoaded,
                                                   object: self.imageLibrary,
                                                   queue: OperationQueue.main)
            { [weak self] notification in self?.flow.graph.run((.loadSucceeded, self!)) }
        
        self.failedObserver =
            NotificationCenter.default.addObserver(forName: .imageLibraryFailed,
                                                   object: self.imageLibrary,
                                                   queue: OperationQueue.main)
            { [weak self] notification in self?.flow.graph.run((.loadFailed, self!)) }
        
        self.flow.graph.run((.setup, self))
    }
    
    func appeared(object: ImagePageViewController) {
        self.isAppeared = true
        
        self.flow.graph.run((.appeared, self))
    }
    
    func nextIndex(from idx: Int) -> Int {
        if idx < self.assets.count - 1 {
            return idx + 1
        } else {
            return 0
        }
    }
    
    func prevIndex(from idx: Int) -> Int {
        if idx > 0 {
            return idx - 1
        } else {
            return self.assets.count - 1
        }
    }
}

// MARK: - Functions For Flow

extension ImagePageController {
    func send(event: Event) {
        if let handler = self.eventHandler {
            handler(event, self)
        }
    }
    
    func beginTimer() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] timer in
            self?.flow.graph.run((.next, self!))
        }
    }
}

// MARK: - Flow

class ImagePageControllerFlow {
    enum State : EnumEnumerable {
        case begin
        case checkEnter
        case check
        case loading
        case loadedEnter
        case manyImagesLoadedEnter
        case manyImagesLoaded
        case singleImageLoadedEnter
        case singleImageLoaded
        case emptyEnter
        case empty
        case failedEnter
        case failedWaiting
        case failed
    }
    
    enum EventName {
        case setup
        case loadSucceeded
        case loadFailed
        case appeared
        case next
    }
    
    typealias Event = (name: EventName, object: ImagePageController)
    
    let graph: FlowGraph<State, Event>
    
    init() {
        let builder = FlowGraphBuilder<State, Event>()
        
        builder.add(state: .begin) { event in
            switch event.name {
            case .setup:
                return .run(.checkEnter, event)
            default:
                return .stay
            }
        }
        
        builder.add(state: .checkEnter) { event in
            event.object.send(event: .launched)
            
            return .run(.check, event)
        }
        
        builder.add(state: .check) { event in
            switch AppController.shared.imageLibrary.state {
            case .loading:
                return .wait(.loading)
            case .loaded:
                return .run(.loadedEnter, event)
            case .failed:
                return .run(.failedEnter, event)
            }
        }
        
        builder.add(state: .loading) { event in
            switch event.name {
            case .loadSucceeded:
                return .run(.loadedEnter, event)
            case .loadFailed:
                return .run(.failedEnter, event)
            default:
                return .stay
            }
        }
        
        builder.add(state: .loadedEnter) { event in
            if event.object.assets.count > 1 {
                return .run(.manyImagesLoadedEnter, event)
            } else if event.object.assets.count == 1 {
                return .run(.singleImageLoadedEnter, event)
            } else {
                return .run(.emptyEnter, event)
            }
        }
        
        builder.add(state: .manyImagesLoadedEnter) { event in
            event.object.send(event: .showManyImages)
            event.object.beginTimer()
            
            return .wait(.manyImagesLoaded)
        }
        
        builder.add(state: .manyImagesLoaded) { event in
            switch event.name {
            case .next:
                event.object.send(event: .moveToNextImage)
            default:
                break
            }
            return .stay
        }
        
        builder.add(state: .singleImageLoadedEnter) { event in
            event.object.send(event: .showSingleImage)
            
            return .wait(.singleImageLoaded)
        }
        
        builder.add(state: .singleImageLoaded) { _ in .stay }
        
        builder.add(state: .emptyEnter) { event in
            event.object.send(event: .showEmpty)
            
            return .wait(.empty)
        }
        
        builder.add(state: .empty) { _ in .stay }
        
        builder.add(state: .failedEnter) { event in
            if event.object.isAppeared {
                event.object.send(event: .showAlert)
                
                return .wait(.failed)
            } else {
                return .wait(.failedWaiting)
            }
        }
        
        builder.add(state: .failedWaiting) { event in
            switch event.name {
            case .appeared:
                event.object.send(event: .showAlert)
            default:
                break
            }
            return .wait(.failed)
        }
        
        builder.add(state: .failed) { _ in .stay }
        
        for state in State.cases {
            if !builder.contains(state: state) {
                fatalError()
            }
        }
        
        self.graph = builder.build(initial: .begin)
    }
}
