//
//  LoopData.swift
//  nightguard
//
//  Created by Florian Preknya on 6/18/19.
//  Copyright © 2019 private. All rights reserved.
//

import Foundation

/// A loop entry provided by the Loop app
struct LoopEntry: Codable {
    
    // loop entry id
    var id: String
    
    // loop entry timestamp
    var timestamp: Date
    
    // predicted values for the next 3 hours
    var predictedValues: [Float]?
    
    // the start time for predicted values
    var predictedValuesStartTime: Date?

    // the recommended bolus (insulin units)
    var recommendedBolus: Float?
    
    // recommended basal rate
    var recommendedBasalRate: Float?
    
    // the enacted basal data
    struct EnactedBasal: Codable {
    
        // enacted basal rate
        var rate: Float
        
        // enacted basal timestamp
        var timestamp: Date
        
        // enacted basal duration (in minutes)
        var duration: TimeInterval
        
        init?(from dictionary: [String: AnyObject]) {
            
            guard let duration = dictionary["duration"] as? NSNumber else { return nil}
            self.duration = duration.doubleValue
            
            guard let rate = dictionary["rate"] as? NSNumber else { return nil }
            self.rate = rate.floatValue
                
            guard let formattedTimestamp = dictionary["timestamp"] as? String, let timestamp = DateFormatter.date(fromISO8601String: formattedTimestamp) else { return nil }
            self.timestamp = timestamp
        }
    }
    var enactedBasal: EnactedBasal?
    
    // loop IOB
    var iob: Float = 0.0
    
    // loop COB
    var cob: Float = 0.0
    
    // error message (if any)
    var failureReason: String?

    // initialize LoopData from nightscout API dictionary
    init?(from dictionary: [String: AnyObject]) {
        
        guard let id = dictionary["_id"] as? String else { return nil}
        self.id = id
        
        guard let loopDictionary = dictionary["loop"] as? [String: AnyObject] else { return nil }
        
        guard let formattedTimestamp = loopDictionary["timestamp"] as? String, let timestamp = DateFormatter.date(fromISO8601String: formattedTimestamp) else { return nil }
        self.timestamp = timestamp
        
        self.failureReason = loopDictionary["failureReason"] as? String
        
        if let enactedDictionary = loopDictionary["enacted"] as? [String: AnyObject] {
            enactedBasal = EnactedBasal(from: enactedDictionary)
        }
        
        if let recommendedTempBasal = loopDictionary["recommendedTempBasal"] as? [String: AnyObject]  {
            self.recommendedBasalRate = (recommendedTempBasal["rate"] as? NSNumber)?.floatValue
        }
        
        self.recommendedBolus = (loopDictionary["recommendedBolus"] as? NSNumber)?.floatValue
        
        if let predicted = loopDictionary["predicted"] as? [String: AnyObject] {
            guard let predictedValues = predicted["values"] as? [NSNumber] else { return nil }
            self.predictedValues = predictedValues.map { $0.floatValue }
            
            guard let formattedPredictedValuesStartTime = predicted["startDate"] as? String, let predictedValuesStartTime = DateFormatter.date(fromISO8601String: formattedPredictedValuesStartTime) else { return nil}
            self.predictedValuesStartTime = predictedValuesStartTime
        }
        
        if let iobDictionary = loopDictionary["iob"] as? [String: AnyObject], let iob = iobDictionary["iob"] as? NSNumber {
            self.iob = iob.floatValue
        }
        
        if let cobDictionary = loopDictionary["cob"] as? [String: AnyObject], let cob = cobDictionary["cob"] as? NSNumber {
            self.cob = cob.floatValue
        }
    }
}

/// A collection of Loop entries
struct LoopData: Codable {
    
    let entries: [LoopEntry]
    
    // loop data timestamp
    var id: String {
        return entries.first!.id
    }
    
    // loop data timestamp
    var timestamp: Date {
        return entries.first!.timestamp
    }
    
    // is the Loop closed or not
    //var isClosed: Bool
    
    // predicted values for the next 3 hours
    var predictedValues: [Float]? {
        return entries.first(where: { $0.predictedValues != nil })?.predictedValues
    }
    
    // the start time for predicted values
    var predictedValuesStartTime: Date? {
        return entries.first(where: { $0.predictedValuesStartTime != nil })?.predictedValuesStartTime
    }
    
    // the recommended bolus (insulin units)
    var recommendedBolus: Float? {
        return entries.first!.recommendedBolus
    }
    
    // recommended basal rate
    var recommendedBasalRate: Float? {
        return entries.first!.recommendedBasalRate
    }
    
    // enacted basal rate
    var enactedBasalRate: Float? {
        
        let entry = entries.first { entry in
            guard let enactedBasal = entry.enactedBasal else {
                return false
            }
            
            // basal is enacted if its timestamp + duration pasts current time
            return enactedBasal.timestamp.addingTimeInterval(enactedBasal.duration * 60) > Date()
        }
        
        return entry?.enactedBasal?.rate
    }

    // loop IOB
    var iob: Float {
        return entries.first!.iob
    }

    // loop COB
    var cob: Float {
        return entries.first!.cob
    }
    
    // error message (if any)
    var failureReason: String? {
        return entries.first!.failureReason
    }
    
    // initialize LoopData from nightscout API response (JSON)
    init?(from data: Data) {
        
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers), let jsonArray = jsonObject as? [AnyObject]  else { return nil }
        
        var entries: [LoopEntry] = []
        for json in jsonArray {
            guard let jsonObject = json as? [String: AnyObject], jsonObject["loop"] != nil else { continue }
            if let loopEntry = LoopEntry(from: jsonObject) {
                entries.append(loopEntry)
            }
        }
        
        guard !entries.isEmpty else { return nil }
        self.entries = entries
    }
}

enum LoopState {
    case fresh
    case aging
    case stale
    case unknown
}

extension LoopData {
    
    var minutesAgo: Int {
        let thirtySeconds: TimeInterval = 30.0  // add thirty seconds for sync with Nightscout
        return Int((Date().timeIntervalSince(timestamp) + thirtySeconds) / 60)
    }
    
    // Is the loop data expired (stale data)? Should be refrehed?
    var shouldRefresh: Bool {
        return minutesAgo >= 5
    }
    
    // state, expressed as how old the loop data are
    var state: LoopState {
        switch minutesAgo {
        case 0...5: return .fresh
        case 6...15: return .aging
        case 16...12*60: return .stale
        default: return .unknown
        }
    }
    
    var predictedReadings: [BloodSugar]? {
        
        guard let referenceStartTime = self.predictedValuesStartTime else {
            return nil
        }
        
        guard let predictedValues = self.predictedValues else {
            return nil
        }
        
        return (0..<predictedValues.count).map { index in
            return BloodSugar(value: predictedValues[index], timestamp: referenceStartTime.addingTimeInterval(TimeInterval(index * 60 * 5)).timeIntervalSince1970 * 1000)
        }
    }
}
