//
//  VaavudSDK.swift
//  Pods
//
//  Created by Andreas Okholm on 24/06/15.
//
//

import Foundation

public class VaavudSDK: WindListener, TemperatureListener {
    var windController: WindController!
    
    var calibrationProgression: (Double -> Void)! // Will be removed by September 5th, guaranteed
    
    public var debugPlotFunc: ([[CGFloat]] -> Void)?
    
    public var session = VaavudSession()
    
    public var windSpeedCallback: (Failable<WindSpeedEvent> -> ())?
    public var windDirectionCallback: (Failable<WindDirectionEvent> -> ())?
    public var temperatureCallback: (Failable<TemperatureEvent> -> ())?
    
    func sleipnirAvailable() -> Bool {
        self.windController = WindController(delegate: self)

        if windController.start() == nil {
            return true
        }
        
        windController.stop()
        
        return false
    }
    
    func reset() {
        self.session = VaavudSession()
        self.windController = WindController(delegate: self)
    }
    
    public func start() -> ErrorEvent? {
        reset()
        return windController.start()
    }

    public func startCalibration(progression: Double -> Void) -> ErrorEvent? {
        self.calibrationProgression = progression
        reset()
        
        return windController.startCalibration()
    }
    
    public func stop() {
        windController.stop()
    }
    
    // Temperature listener
    
    func newTemperature(event: Failable<TemperatureEvent>) {
        temperatureCallback?(event)
    }
    
    // Wind listener
    
    func newWindSpeed(event: Failable<WindSpeedEvent>) {
        windSpeedCallback?(event)
        
        if let event = event.value {
            session.addWindSpeed(event)
        }
    }
    
    func newWindDirection(event: Failable<WindDirectionEvent>) {
        windDirectionCallback?(event)
        
        if let event = event.value {
            session.addWindDirection(event)
        }
    }
    
    func calibrationProgress(progress: Double) {
        calibrationProgression(progress)
    }
    
    func debugPlot(valuess: [[CGFloat]]) {
        if let debugPlot = debugPlotFunc {
            debugPlot(valuess)
        }
    }
}

public struct VaavudSession {
    public let time = NSDate()
    public var meanSpeed: Double { return windSpeedSum/Double(windSpeeds.count) }
    
    public private(set) var meanDirection: Double = 0
    public private(set) var windSpeeds = [WindSpeedEvent]()
    public private(set) var windDirections = [WindDirectionEvent]()
    
    private var windSpeedSum: Double = 0

    mutating func addWindSpeed(event: WindSpeedEvent) {
        windSpeeds.append(event)
        windSpeedSum += event.speed
        // update frequency should be concidered! (sum should be speed*timeDelta)
    }
    
    mutating func addWindDirection(event: WindDirectionEvent) {
        windDirections.append(event)
    }
    
    public func relativeTime(measurement: WindSpeedEvent) -> NSTimeInterval {
        return measurement.time.timeIntervalSinceDate(time)
    }
    
    func description(measurement: WindSpeedEvent) -> String {
        return "WindSpeedEvent (time rel:" + String(format: "% 5.2f", relativeTime(measurement)) + " speed:" + String(format: "% 5.2f", measurement.speed) + " UnixTime: \(measurement.time.timeIntervalSince1970))"
    }
}