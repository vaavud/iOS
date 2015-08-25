//
//  VaavudSDK.swift
//  Pods
//
//  Created by Andreas Okholm on 24/06/15.
//
//

import Foundation

public class VaavudSDK: WindListener {
    var windController: WindController!
    
    var calibrationProgression: (Double -> Void)! // Will be removed by September 5th, guaranteed
    
    public var debugPlotFunc: ([[CGFloat]] -> Void)?
    
    public var session = VaavudSession()
    
    weak var delegate: Listener!
    
    public init(delegate: Listener) {
        self.delegate = delegate
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
   
    public func calibrationProgress(progress: Double) {
        calibrationProgression(progress)
    }
    
    public func newWindSpeed(event: Failable<WindSpeedEvent>) {
        delegate.newWindSpeed(event)

        if let event = event.value {
            session.addWindSpeed(event)
        }
    }
    
    public func newWindDirection(event: Failable<WindDirectionEvent>) {
        delegate.newWindDirection(event)

        if let event = event.value {
            session.addWindDirection(event)
        }
    }
    
    public func debugPlot(valuess: [[CGFloat]]) {
        if let debugPlot = debugPlotFunc {
            debugPlot(valuess)
        }
    }
}

public class VaavudSession {
    public let time = NSDate()
    public var meanSpeed: Double { return windSpeedSum/Double(windSpeeds.count) }
    
    public private(set) var meanDirection: Double = 0
    public private(set) var windSpeeds = [WindSpeedEvent]()
    public private(set) var windDirections = [WindDirectionEvent]()
    
    var windSpeedSum: Double = 0

    func addWindSpeed(event: WindSpeedEvent) {
        windSpeeds.append(event)
        windSpeedSum += event.speed
        // update frequency should be concidered! (sum should be speed*timeDelta)
    }
    
    func addWindDirection(event: WindDirectionEvent) {
        windDirections.append(event)
    }
    
    public func relativeTime(measurement: WindSpeedEvent) -> NSTimeInterval {
        return measurement.time.timeIntervalSinceDate(time)
    }
    
    func description(measurement: WindSpeedEvent) -> String {
        return "WindSpeedEvent (time rel:" + String(format: "% 5.2f", relativeTime(measurement)) + " speed:" + String(format: "% 5.2f", measurement.speed) + " UnixTime: \(measurement.time.timeIntervalSince1970))"
    }
}