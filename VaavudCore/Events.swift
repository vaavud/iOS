//
//  Events.swift
//  Pods
//
//  Created by Gustaf Kugelberg on 20/08/15.
//
//

import Foundation

public class Box<T> {
    public let unbox: T
    
    init(_ value: T) {
        self.unbox = value
    }
}

public enum Failable<T> {
    case Value(Box<T>)
    case Error(ErrorEvent)
    
    init(_ value: T) {
        self = .Value(Box(value))
    }
    
    init(_ error: ErrorEvent) {
        self = .Error(error)
    }

    var value: T? {
        switch self {
        case let .Value(val): return val.unbox
        case .Error: return nil
        }
    }
}

protocol Event {
    var time: NSDate { get }
}

protocol Dictionarifiable {
    var dict: [String : AnyObject] { get }
}

public struct WindSpeedEvent: Event, Dictionarifiable {
    public let time: NSDate
    public let speed: Double
    
    var dict: [String : AnyObject] {
        return ["time" : time.timeIntervalSince1970, "speed" : speed]
    }
}

public struct WindDirectionEvent: Event, Dictionarifiable {
    public let time: NSDate
    public let direction: Double

    var dict: [String : AnyObject] {
        return ["time" : time.timeIntervalSince1970, "direction" : direction]
    }
}

public struct TemperatureEvent: Event, Dictionarifiable {
    public let time = NSDate()
    public let temperature: Double
    
    var dict: [String : AnyObject] {
        return ["time" : time.timeIntervalSince1970, "temperature" : temperature]
    }
}

public struct ErrorEvent: Event, Dictionarifiable {
    public let time = NSDate()
    public let technicalDescription: String
    public let userDescription: String
    
    init(_ technical: String, user: String) {
        self.technicalDescription = technical
        self.userDescription = user
    }
    
    init(_ error: String) {
        self.init(error, user: error)
    }

    var dict: [String : AnyObject] {
        return ["time" : time.timeIntervalSince1970, "technicalDescription" : technicalDescription, "userDescription" : userDescription]
    }
}

public protocol Listener: WindListener, TemperatureListener { }

public protocol WindListener: class {
    func newWindSpeed(Failable<WindSpeedEvent>)
    func newWindDirection(Failable<WindDirectionEvent>)

    func calibrationProgress(Double)
    func debugPlot([[CGFloat]])
}

public protocol TemperatureListener: class {
    func newTemperature(Failable<TemperatureEvent>)
}
