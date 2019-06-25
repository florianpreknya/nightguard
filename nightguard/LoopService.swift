//
//  LoopService.swift
//  nightguard
//
//  Created by Florian Preknya on 6/18/19.
//  Copyright © 2019 private. All rights reserved.
//

import Foundation
import UIKit
import WatchKit

/// A high level service that provides Loop related data (Loop state, prediction values, basals, bolus suggestions, etc.). The service self-manages itself, refreshing its data regularily through Nightscout "device status" API, sending notifications to its clients when its data has changed.
class LoopService {
 
    static let singleton = LoopService()
    
    // is the Loop service enabled?
    var enabled: Bool {
        get {
            return UserDefaultsRepository.loopIntegration.value
        }
        
        set(value) {
            UserDefaultsRepository.loopIntegration.value = value
            serviceStateChanged()
        }
    }
    
    #if os(watchOS)
    // public setter, should be set by WKExtension (there are no notifications on WK for this!)
    var isAppActive: Bool = false {
        didSet {
            appStateChanged()
        }
    }
    #else
    // internally managed app state for iOS
    private(set) var isAppActive: Bool {
        get {
            return UIApplication.shared.applicationState == .active
        }
        set {
            appStateChanged()
        }
    }
    #endif
    
    // most recent received loop data
    private(set) var loopData: LoopData? {
        didSet {
            NotificationCenter.default.post(name: .LoopDataChanged, object: self)
        }
    }
    
    // References to registered notification center observers
    private var notificationObservers: [Any] = []
    
    // loop API query timer
    private var queryTimer: Timer?
    
    // loop API query task
    private var queryTask: URLSessionTask?
    
    private init() {
        
        #if os(iOS)
        let notificationCenter = NotificationCenter.default
        notificationObservers = [
            notificationCenter.addObserver(forName: .UIApplicationDidEnterBackground, object: UIApplication.shared, queue: .main) { [weak self] _ in
                self?.isAppActive = false
            },
            notificationCenter.addObserver(forName: .UIApplicationDidBecomeActive, object: UIApplication.shared, queue: .main) { [weak self] _ in
                self?.isAppActive = true
            }
        ]
        #endif
        
        if enabled {
            serviceStateChanged()
        }
    }
    
    deinit {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // trigger a refresh of the loop data
    func refresh() {
        queryLoopData(force: true)
    }
    
    private func serviceStateChanged() {

        if enabled {
            startQueryTimer()
            queryLoopData()
        } else {
            stopQueryTimer()
        }
    }
    
    private func appStateChanged() {
        
        if isAppActive {
            startQueryTimer()
            queryLoopData()
        } else {
            stopQueryTimer()
        }
    }
    
    private func startQueryTimer() {
        stopQueryTimer()
        
        queryTimer = Timer.schedule(repeatInterval: 30) { [weak self] _ in
            self?.queryLoopData()
        }
    }
    
    private func stopQueryTimer() {
        queryTimer?.invalidate()
        queryTimer = nil
    }
    
    private func queryLoopData(force: Bool = false) {
        
        guard force || (self.loopData?.shouldRefresh ?? true) else {
            return
        }
        
        // cancel the current query (if any)
        self.queryTask?.cancel()
        
        // start a new one
        self.queryTask = NightscoutService.singleton.readLoopData { [weak self] (result: NightscoutRequestResult<LoopData?>) -> Void in
            
            if case .data(let loopData) = result {
                if loopData?.id != self?.loopData?.id {
                    
                    // update ONLY if fresh loop data arrived
                    self?.loopData = loopData
                }
            }
        }
    }
}

extension Notification.Name {
    static let LoopDataChanged = Notification.Name(rawValue:  "com.nightguard.notification.LoopDataChanged")
}
