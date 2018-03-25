//
//  BackgroundRefreshLogger.swift
//  nightguard WatchKit Extension
//
//  Created by Florian Preknya on 3/16/18.
//  Copyright © 2018 private. All rights reserved.
//

import Foundation

// A debugging tool that keeps info about the nightscout data updates obtained through background tasks (URL sessions) or updates received from the phone app (that also relies on background fetch for refreshing its data).
class BackgroundRefreshLogger {
    
    static var logs: [String] = []
    static var receivedData: [String] = []
    
    // keep some background refrehs related stats data...
    static var backgroundRefreshes: Int = 0
    static var backgroundURLSessions: Int = 0
    static var backgroundURLSessionUpdatesWithNewData: Int = 0
    static var backgroundURLSessionUpdatesWithSameData: Int = 0
    static var backgroundURLSessionUpdatesWithOldData: Int = 0
    static var phoneUpdates: Int = 0
    static var phoneUpdatesWithNewData: Int = 0
    static var phoneUpdatesWithSameData: Int = 0
    static var phoneUpdatesWithOldData: Int = 0
    
    static var backgroundRefreshesPerHour: Double {
        guard let logStartTime = BackgroundRefreshLogger.logStartTime else {
            return 0
        }
        
        let minutes: Double = Date().timeIntervalSince(logStartTime) / 60
        let refreshesPerMinute = Double(backgroundRefreshes) / minutes
        return refreshesPerMinute * 60
    }
    
    static var formattedBackgroundRefreshesPerHour: String {
        return String(format: "%.2f", backgroundRefreshesPerHour)
    }
    
    static var backgroundRefreshesStartingURLSessions: Double {
        return backgroundRefreshes != 0 ? Double(backgroundURLSessions) / Double(backgroundRefreshes) : 0
    }
    
    static var formattedBackgroundRefreshesStartingURLSessions: String {
        return "\(Int(backgroundRefreshesStartingURLSessions * 100))%"
    }
    
    private static var logStartTime: Date?
    private static var appStartTime: Date?
    private static let showLogs = BackgroundRefreshSettings.showBackgroundTasksLogs
    
    static func info(_ text: String) {
        resetStatsDataIfNeeded()
        
        let logEntry = formattedTime(Date()) + " " + text
        NSLog(logEntry)
        
        if showLogs {
            logs.append(logEntry)
        }
    }
    
    
    static func nightscoutDataReceived(_ nightscoutData: NightscoutData, updateResult: ExtensionDelegate.UpdateResult, updateSource: ExtensionDelegate.UpdateSource) {
        
        var updateSourceString = ""
        switch updateSource {
        case .phoneApp :
            updateSourceString = "📱"
        default:
            updateSourceString = "⌚"
        }
        
        var updateResultString = ""
        switch updateResult {
        case .updated:
            updateResultString = "NEW"
        case .updateDataAlreadyExists:
            updateResultString = "EXISTING"
        case .updateDataIsOld:
            updateResultString = "OLD"
        }
        
        let nightscoutDataTime = Date(timeIntervalSince1970: nightscoutData.time.doubleValue / 1000)
        let nightscoutDataTimeString = formattedTime(nightscoutDataTime, showSeconds: false)
        
        let logEntry = formattedTime(Date()) + " " + updateSourceString + updateResultString + " (\(nightscoutData.sgv)@\(nightscoutDataTimeString))"
        NSLog(logEntry)
        
        if showLogs {
            receivedData.append(logEntry)
        }
        
    }
    
    private static func resetStatsDataIfNeeded() {
        
        let now = Date()
        
        guard let appStartTime = BackgroundRefreshLogger.appStartTime, let logStartTime = BackgroundRefreshLogger.logStartTime else {
            BackgroundRefreshLogger.appStartTime = now
            BackgroundRefreshLogger.logStartTime = now
            info("App started!")
            return
        }
        
        let unitFlags:Set<Calendar.Component> = [.day]
        let nowDateComponents = Calendar.current.dateComponents(unitFlags, from: logStartTime)
        let logStartDateComponents = Calendar.current.dateComponents(unitFlags, from: now)

        // keep log data only for one day (from 00:00 until 23:59)
        if logStartDateComponents.day != nowDateComponents.day {
            
            BackgroundRefreshLogger.logStartTime = now
            
            // reset log data
            logs.removeAll()
            info("Reseting logs (new day), but continuing stats from app start (\(formattedTime(appStartTime)))")
            receivedData.removeAll()
            
//            backgroundRefreshes = 0
//            backgroundURLSessions = 0
//            backgroundURLSessionUpdatesWithNewData = 0
//            backgroundURLSessionUpdatesWithSameData = 0
//            backgroundURLSessionUpdatesWithOldData = 0
//            phoneUpdates = 0
//            phoneUpdatesWithNewData = 0
//            phoneUpdatesWithSameData = 0
//            phoneUpdatesWithOldData = 0
        }
    }
    
    private static func formattedTime(_ time: Date, showSeconds: Bool = true) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = showSeconds ? "HH:mm:ss" : "HH:mm"
        return timeFormatter.string(from: Date())
    }
}
