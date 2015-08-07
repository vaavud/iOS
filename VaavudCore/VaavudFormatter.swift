//
//  VaavudFormatter.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 01/02/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import Foundation
import UIKit

let π = CGFloat(M_PI)

protocol FloatUnit: Unit {
    func fromBase(Float) -> Float
    func fromBase(CGFloat) -> CGFloat
    var decimals: Int { get }
}

protocol Unit {
    var rawValue: Int { get }
}

enum TemperatureUnit: Int, FloatUnit {
    case Celsius = 0
    case Fahrenheit = 1
    
    var localizedString: String { return NSLocalizedString(key, comment: "") }
    var next: TemperatureUnit { return TemperatureUnit(rawValue: (rawValue + 1) % 2)! }
    var decimals: Int { return 1 }
    func fromBase(kelvinValue: Float) -> Float { return kelvinValue*ratio + constant}
    func fromBase(kelvinValue: CGFloat) -> CGFloat { return CGFloat(fromBase(Float(kelvinValue))) }
    
    private var key: String { return ["UNIT_CELSIUS", "UNIT_FAHRENHEIT"][rawValue] }
    
    private var ratio: Float { return [1, 9/5][rawValue] }
    
    private var constant: Float { return [-273.15, -459.67][rawValue] }
}

enum PressureUnit: Int, FloatUnit {
    case Mbar = 0
    case Atm = 1
    case MmHg = 2
    
    var localizedString: String { return NSLocalizedString(key, comment: "") }
    var next: PressureUnit { return PressureUnit(rawValue: (rawValue + 1) % 3)! }
    var decimals: Int { return [0, 3, 0][rawValue] }
    func fromBase(mbarValue: Float) -> Float { return mbarValue*ratio }
    func fromBase(mbarValue: CGFloat) -> CGFloat { return CGFloat(fromBase(Float(mbarValue))) }
    
    private var ratio: Float { return [1, 0.000986923267, 0.75006375541921][rawValue] }
    
    private var key: String { return ["UNIT_MBAR", "UNIT_ATM", "UNIT_MMHG"][rawValue] }
}

enum DirectionUnit: Int, Unit {
    case Cardinal = 0
    case Degrees = 1
    
    var localizedString: String { return NSLocalizedString(key, comment: "") }
    var next: DirectionUnit { return DirectionUnit(rawValue: (rawValue + 1) % 2)! }
    
    static func degreesToCardinal(degreesValue: Float) -> Int {
        return Int(round(16*degreesValue/360)) % 16
    }
    
    private var key: String { return ["DIRECTION_CARDINAL", "DIRECTION_DEGREES"][rawValue] }
    
}

enum SpeedUnit: Int, FloatUnit {
    case Kmh = 0
    case Ms = 1
    case Mph = 2
    case Knots = 3
    case Bft = 4
    
    var localizedString: String { return NSLocalizedString(key, comment: "") }
    var next: SpeedUnit { return SpeedUnit(rawValue: (rawValue + 1) % 5)! }
    var decimals: Int { return [1, 1, 1, 1, 0][rawValue] }
    func fromBase(msValue: Float) -> Float {
        if self == .Bft {
            return SpeedUnit.msToBft(msValue)
        }
        else {
            return msValue*ratio
        }
    }
    func fromBase(msValue: CGFloat) -> CGFloat { return CGFloat(fromBase(Float(msValue))) }
    
    private var key: String { return ["UNIT_KMH", "UNIT_MS", "UNIT_MPH", "UNIT_KN", "UNIT_BFT"][rawValue] }
    private var ratio: Float { return [3.6, 1, 3600/1609.344, 3600/1852.0, 0][rawValue] }
    
    private static func msToBft(msValue: Float) -> Float {
        let bftLimits: [Float] = [0.3, 1.6, 3.5, 5.5, 8.0, 10.8, 13.9, 17.2, 20.8, 24.5, 28.5, 32.7]
        
        for (index, limit) in enumerate(bftLimits) {
            if msValue < limit {
                return Float(index)
            }
        }
        return 12
    }
}

class VaavudFormatter: NSObject {
    var windSpeedUnit: SpeedUnit = .Knots { didSet { writeWindSpeedUnit() } }
    var directionUnit: DirectionUnit = .Cardinal { didSet { writeDirectionUnit() } }
    var pressureUnit: PressureUnit = .Mbar { didSet { writePressureUnit() } }
    var temperatureUnit: TemperatureUnit = .Celsius { didSet { writeTemperatureUnit() } }
    
    let dateFormatter = NSDateFormatter()
    
    //    let standardWindspeedUnits: [String : SpeedUnit] = ["US" : .Knots, "UM" : .Knots, "GB" : .Knots, "CA" : .Knots, "VG" : .Knots, "VI" : .Knots]
    
    override init() {
        dateFormatter.locale = NSLocale.currentLocale()
        super.init()
        
        println("I am a formatter: \(self)") // tabort

        readUnits()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "unitsChanged:", name: KEY_UNIT_CHANGED, object: nil)
    }
    
    deinit {
        println(" >>> I was a formatter: \(self)") // tabort

        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func unitsChanged(note: NSNotification) {
        if note.object as? VaavudFormatter != self {
            println("Units changed: \(note.object) me: \(self)") // tabort
            readUnits()
        }
        else {
            println("Units changed (here): \(self)")
        }
    }

    // MARK - Public
    
    var missingValue = "-"
    
    func localizedTitleDate(date: NSDate?) -> String? {
        if let date = date {
            dateFormatter.dateFormat = "EEEE, MMM d"
            return dateFormatter.stringFromDate(date)
        }
        return nil
    }
    
    func localizedTime(date: NSDate?) -> String? {
        if let date = date {
            dateFormatter.timeStyle = .ShortStyle
            dateFormatter.dateStyle = .NoStyle
            return dateFormatter.stringFromDate(date)
        }
        return nil
    }
    
    // Direction
    
    static var localizedNorth: String { return NSLocalizedString(directionKey(0), comment: "") }
    static var localizedEast: String { return NSLocalizedString(directionKey(4), comment: "") }
    static var localizedSouth: String { return NSLocalizedString(directionKey(8), comment: "") }
    static var localizedWest: String { return NSLocalizedString(directionKey(12), comment: "") }
    
    func localizedDirection(degrees: Float) -> String {
        switch directionUnit {
        case .Cardinal:
            return VaavudFormatter.localizedCardinal(degrees)
        case .Degrees:
            return String(format: "%.0f°", degrees)
        }
    }
    
    static func localizedCardinal(degrees: Float) -> String {
        let cardinalDirection = DirectionUnit.degreesToCardinal(degrees)
        return NSLocalizedString(directionKey(cardinalDirection), comment: "")
    }
    
    static func localizedCardinalFromDirection(direction: Int) -> String {
        return NSLocalizedString(directionKey(direction), comment: "")
    }
    
    // Speed
    
    func updateAverageWindspeedLabels(session: MeasurementSession, valueLabel: UILabel, unitLabel: UILabel) -> Bool {
        if let string = localizedWindspeed(session.windSpeedAvg?.floatValue) {
            unitLabel.text = windSpeedUnit.localizedString
            valueLabel.text = string
            return true
        }
        
        return failure(valueLabel: valueLabel, unitLabel: unitLabel)
    }

    func updateMaxWindspeedLabels(session: MeasurementSession, valueLabel: UILabel, unitLabel: UILabel) -> Bool {
        if let string = localizedWindspeed(session.windSpeedMax?.floatValue) {
            unitLabel.text = windSpeedUnit.localizedString
            valueLabel.text = string
            return true
        }
        
        return failure(valueLabel: valueLabel, unitLabel: unitLabel)
    }

    func localizedWindspeed(msSpeed: Float?, digits: Int? = nil) -> String? {
        return localizedConvertedString(msSpeed, unit: windSpeedUnit, digits: digits)
    }
    
    // Pressure
    
    func updatePressureLabels(session: MeasurementSession, valueLabel: UILabel, unitLabel: UILabel) -> Bool {
        let value = session.pressure?.floatValue ?? session.sourcedPressureGroundLevel?.floatValue
        
        if let string = localizedPressure(value) {
            unitLabel.text = pressureUnit.localizedString
            valueLabel.text = string
            return true
        }
        
        return failure(valueLabel: valueLabel, unitLabel: unitLabel)
    }

    func localizedPressure(mbarPressure: Float?) -> String? {
        return localizedConvertedString(mbarPressure, unit: pressureUnit)
    }
    
    // Temperature
    
    func updateTemperatureLabels(session: MeasurementSession, valueLabel: UILabel, unitLabel: UILabel) -> Bool {
        let value = session.temperature?.floatValue ?? session.sourcedTemperature?.floatValue
        
        if let string = localizedTemperature(value) {
            unitLabel.text = temperatureUnit.localizedString
            valueLabel.text = string
            return true
        }
        
        return failure(valueLabel: valueLabel, unitLabel: unitLabel)
    }

    func localizedTemperature(kelvinTemperature: Float?) -> String? {
        return localizedConvertedString(kelvinTemperature, unit: temperatureUnit)
    }
    
    // Windchill

    func updateWindchillLabels(session: MeasurementSession, valueLabel: UILabel, unitLabel: UILabel) -> Bool {
        let value = session.windChill?.floatValue
        
        if let string = localizedWindchill(value) {
            unitLabel.text = temperatureUnit.localizedString
            valueLabel.text = string
            return true
        }
        
        return failure(valueLabel: valueLabel, unitLabel: unitLabel)
    }

    func localizedWindchill(kelvinTemperature: Float?) -> String? {
        return localizedConvertedString(kelvinTemperature, unit: temperatureUnit, decimals: 0)
    }

    // Gustiness
    
    func updateGustinessLabels(session: MeasurementSession, valueLabel: UILabel, unitLabel: UILabel) -> Bool {
        let value = session.gustiness?.floatValue
        
        if let string = formattedGustiness(value) {
            unitLabel.text = "%"
            valueLabel.text = string
            return true
        }
        
        return failure(valueLabel: valueLabel, unitLabel: unitLabel)
    }
    
    func formattedGustiness(gustiness: Float?) -> String? {
        if let gustiness = gustiness where gustiness > 0.001 {
            return String(format: "%.0f", 100*gustiness)
        }
        
        return nil
    }
    
    // Units
    
    func readUnits() {
        println("================ Read Units (\(self))")

        if let storedWindspeedInt = Property.getAsInteger(KEY_WIND_SPEED_UNIT)?.integerValue {
            windSpeedUnit = SpeedUnit(rawValue:storedWindspeedInt)!
        }
        
        if let storedDirectionInt = Property.getAsInteger(KEY_DIRECTION_UNIT)?.integerValue {
            directionUnit = DirectionUnit(rawValue:storedDirectionInt)!
        }
        
        if let storedPressureInt = Property.getAsInteger(KEY_PRESSURE_UNIT)?.integerValue {
            pressureUnit = PressureUnit(rawValue:storedPressureInt)!
        }
        
        if let storedTemperatureInt = Property.getAsInteger(KEY_TEMPERATURE_UNIT)?.integerValue {
            temperatureUnit = TemperatureUnit(rawValue:storedTemperatureInt)!
        }
    }
    
    // MARK - Private
    
    private func writeWindSpeedUnit() { writeIfChanged(windSpeedUnit, key: KEY_WIND_SPEED_UNIT) }
    private func writeDirectionUnit() { writeIfChanged(directionUnit, key: KEY_DIRECTION_UNIT) }
    private func writePressureUnit() { writeIfChanged(pressureUnit, key: KEY_PRESSURE_UNIT) }
    private func writeTemperatureUnit() { writeIfChanged(temperatureUnit, key: KEY_TEMPERATURE_UNIT) }

    private func writeIfChanged(unit: Unit, key: String) {
        if unit.rawValue != Property.getAsInteger(key) {
            println("postUnitChange: \(self)")
            Property.setAsInteger(unit.rawValue, forKey: key)
            NSNotificationCenter.defaultCenter().postNotificationName(KEY_UNIT_CHANGED, object: self)
        }
    }
    
    // Direction
    
    private static func directionKey(cardinal: Int) -> String {
        let n = mod(cardinal, directionNames.count - 1)
        return "DIRECTION_" + directionNames[n]
    }
    
    private static var directionNames: [String] { return ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"] }
    
    // Convenience
    
    private func decimalString(value: Float?, decimals: Int = 0, min: Float = 0.1) -> String? {
        if value == nil || value < min {
            return nil
        }
        
        return localizedDecimalString(value!, decimals: decimals)
    }

    private func localizedConvertedString(value: Float?, unit: FloatUnit, min: Float = 0.0, decimals: Int? = nil, digits: Int? = nil) -> String? {
        if value == nil || value < min {
            return nil
        }
        
        return localizedDecimalString(unit.fromBase(value!), decimals: decimals ?? unit.decimals, digits: digits)
    }
    
    private func localizedDecimalString(value: Float, decimals: Int, digits: Int? = nil) -> String {
        var actualDecimals = decimals
        if value > 0, let digits = digits {
            let digitsBeforePoint = max(Int(floor(log10(value)) + 1), 1)
            actualDecimals = min(max(digits - digitsBeforePoint, 0), decimals)
        }
        
        let formatString = String(format: "%%.%df", actualDecimals)
        return String(format: formatString, locale: NSLocale.currentLocale(), value)
    }
    
    private func failure(# valueLabel: UILabel, unitLabel: UILabel) -> Bool {
        valueLabel.text = missingValue
        unitLabel.text = ""
        return false
    }
}

