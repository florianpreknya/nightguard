//
//  AppDelegate.swift
//  scoutwatch
//
//  Created by Dirk Hermanns on 20.11.15.
//  Copyright © 2015 private. All rights reserved.
//

import UIKit
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    // Delegate Requests from the Watch to the WatchMessageService
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = WatchMessageService.singleton
                session.activate()
            }
        }
    }
    
    @available(iOS 3.0, *)
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        UITabBar.appearance().tintColor = UIColor.white
        
        // This application should be called in background every 5 Minutes
        UIApplication.shared.setMinimumBackgroundFetchInterval(5 * 60)
        
        activateWatchConnectivity()
        initializeApplicationDefaults()
        initializeAlarmRule()
        return true

    }

    func activateWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
        }
    }
    
    func initializeAlarmRule() {
        let defaults = UserDefaults(suiteName: AppConstants.APP_GROUP_ID)
        
        AlarmRule.isEdgeDetectionAlarmEnabled = (defaults?.bool(forKey: "edgeDetectionAlarmEnabled"))!
        AlarmRule.numberOfConsecutiveValues = (defaults?.integer(forKey: "numberOfConsecutiveValues"))!
        AlarmRule.deltaAmount = (defaults?.float(forKey: "deltaAmount"))!
        
        AlarmRule.alertIfAboveValue = (defaults?.float(forKey: "alertIfAboveValue"))!
        AlarmRule.alertIfBelowValue = (defaults?.float(forKey: "alertIfBelowValue"))!
        
        AlarmRule.minutesWithoutValues = (defaults?.integer(forKey: "noDataAlarmAfterMinutes"))!
    }
    
    func initializeApplicationDefaults() {
        
        // Setting the defaults if the users starts the application for the first time
        let initialDefaults: NSDictionary =
            ["edgeDetectionAlarmEnabled": false,
             "numberOfConsecutiveValues": 3,
             "deltaAmount": 8,
             
             "alertIfAboveValue": 180,
             "alertIfBelowValue": 80,
             "maximumBloodGlucoseDisplayed": 350,
             
             "noDataAlarmAfterMinutes": 15
        ]
        UserDefaults.standard.register(defaults: initialDefaults as! [String : AnyObject])
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        // If there is already a snooze active => we don't have to fear that an alarm
        // would be played.
        if !AlarmRule.isSnoozed() {
            // snooze the alarm for 15 Seconds in order to retrieve new data
            // before playing alarm
            // Otherwise it could be the case that the app immediately plays
            // an alarm sound without giving the app the chance to reload
            // current data
            AlarmRule.snoozeSeconds(15)
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // just refresh the current nightscout data
        let _ = NightscoutCacheService.singleton.loadCurrentNightscoutData { _, error in
            if let _ = error {
                completionHandler(.failed)
            } else {
                completionHandler(.newData)
//                WatchService.singleton.updateWatchComplicationIfPossible()
            }
        }
        
        // This can be used to alarm even when the app is in the background
        // but this doesn't work very well - so removed it so far...
//            ServiceBoundary.singleton.readCurrentDataForPebbleWatch({(nightscoutData) -> Void in
//                
//                DataRepository.singleton.storeCurrentNightscoutData(nightscoutData)
//                if AlarmRule.isAlarmActivated(nightscoutData) {
//                    AlarmSound.play()
//                } else {
//                    AlarmSound.stop()
//                }
//                completionHandler (.NoData)
//            })
    }
}

