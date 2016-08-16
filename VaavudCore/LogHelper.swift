//
//  LogHelper.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 23/11/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import Foundation
import Amplitude_iOS

class LogHelper: NSObject {
    private var dict: [String : AnyObject]
    private let counters: [String]
    private let group: LogGroup
    private var beganDate = NSDate()
    private var used = 0
    
    init(_ group: LogGroup, dict: [String : AnyObject] = [:], counters: String...) {
        self.group = group
        self.dict = dict
        self.counters = counters
        super.init()
        resetCounters()
    }
    
    init(groupName: String, counters: [String]) {
        self.group = LogGroup(rawValue: groupName) ?? .Free
        self.dict = [:]
        self.counters = counters
        super.init()
        resetCounters()
    }
    
    func addProperty(key: String, value: AnyObject) {
        dict[key] = value
    }
    
    func log(event: String, properties: [String : AnyObject] = [:]) {
        LogHelper.log(group, event: event, properties: properties)
    }
    
    func increase(counter: String? = nil) {
        if let counter = counter {
            if let oldValue = dict[counter] as? Int {
                dict[counter] = oldValue + 1
            }
            else {
                fatalError("LogHelper: Counter doesn't exist'")
            }
        }
        
        used += 1
    }
    
    func began(properties: [String : AnyObject] = [:]) {
        beganDate = NSDate()
        resetCounters()
        
        for (key, value) in properties {
            dict[key] = value
        }
        
        LogHelper.log(group, event: "Began", properties: properties)
    }
    
    func ended(properties: [String : AnyObject] = [:]) {
        for (key, value) in properties {
            dict[key] = value
        }
        
        dict["duration"] = NSDate().timeIntervalSinceDate(beganDate)

        if counters.count > 0 || used > 0 {
            dict["used"] = used
        }
        
        LogHelper.log(group, event: "Ended", properties: dict)
        resetCounters()
    }
    
    private func resetCounters() {
        for key in counters {
            dict[key] = 0
        }
    }
    
    private func sumCounters() -> Int {
        return counters.reduce(0) { sum, key in sum + (self.dict[key]! as! Int) }
    }
    
    class func logWithGroupName(groupName: String, event: String, properties: [String : AnyObject] = [:]) {
        log(LogGroup(rawValue: groupName) ?? .Free, event: event, properties: properties)
    }

    class func log(group: LogGroup = .Free, event: String, properties: [String : AnyObject] = [:]) {
        Amplitude.instance().logEvent(group.rawValue + "::" + event, withEventProperties: properties)
//        print("AMP:\(group.rawValue)::\(event) - \(properties)")
    }
    
    class func setUserProperty(key: String, value: NSObject) {
        Amplitude.instance().identify(AMPIdentify().set(key, value: value))
//        print("AMP:\(key) - \(value)")
    }
    
    class func increaseUserProperty(key: String) {
        Amplitude.instance().identify(AMPIdentify().add(key, value: 1))
//        print("AMP:increase \(key)")
    }
}

enum LogGroup: String {
    case Free
    case Activities
    case Map
    case Forecast
    case History
    case Summary
    case Measure
    case Result
    case Settings
    case Notifications
    case NotificationDetails = "Notification-Details"
    case URLScheme = "URL-Scheme"
    case Login
    case App
}
