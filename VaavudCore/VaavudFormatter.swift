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

protocol FloatUnit {
    func fromBase(Float) -> Float
    var decimals: Int { get }
}

enum TemperatureUnit: Int, FloatUnit {
    case Celsius = 0
    case Fahrenheit = 1
    
    var localizedString: String { return NSLocalizedString(key, comment: "") }
    var next: TemperatureUnit { return TemperatureUnit(rawValue: (rawValue + 1) % 2)! }
    var decimals: Int { return 1 }
    func fromBase(kelvinValue: Float) -> Float { return kelvinValue*ratio + constant}
    
    private var key: String { return ["UNIT_CELCIUS", "UNIT_FAHRENHEIT"][rawValue] }
    
    private var ratio: Float { return [1, 9/5][rawValue] }
    
    private var constant: Float { return [-273.15, -459.67][rawValue] }
}

enum PressureUnit: Int, FloatUnit {
    case Mbar = 0
    case Atm = 1
    case MmHg = 2
    
    var localizedString: String { return NSLocalizedString(key, comment: "") }
    var next: PressureUnit { return PressureUnit(rawValue: (rawValue + 1) % 3)! }
    var decimals: Int { return [0, 3, 2][rawValue] }
    func fromBase(mbarValue: Float) -> Float { return mbarValue*ratio }
    
    private var ratio: Float { return [1, 1/101325, 1/133.322387415][rawValue] }
    
    private var key: String { return ["UNIT_MBAR", "UNIT_ATM", "UNIT_MMHG"][rawValue] }
}

enum DirectionUnit: Int {
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

class VaavudFormatter {
    var windSpeedUnit: SpeedUnit = .Knots { didSet { writeWindSpeedUnit() } }
    var directionUnit: DirectionUnit = .Cardinal { didSet { writeDirectionUnit() } }
    var pressureUnit: PressureUnit = .Mbar { didSet { writePressureUnit() } }
    var temperatureUnit: TemperatureUnit = .Celsius { didSet { writeTemperatureUnit() } }
    
    let dateFormatter = NSDateFormatter()
    
    //    let standardWindspeedUnits: [String : SpeedUnit] = ["US" : .Knots, "UM" : .Knots, "GB" : .Knots, "CA" : .Knots, "VG" : .Knots, "VI" : .Knots]
    
    init() {
        dateFormatter.locale = NSLocale.currentLocale()
        readUnits()
    }
    
    // MARK - Public
    
    var missingValue = "-"
    
    func localizedTitleDate(date: NSDate?) -> String? {
        if let date = date {
            dateFormatter.dateFormat = "EEEE, MMM dd"
            return dateFormatter.stringFromDate(date).uppercaseString
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

    func localizedWindspeed(msSpeed: Float?) -> String? {
        readUnits()
        return localizedConvertedString(msSpeed, unit: windSpeedUnit)
    }
    
    var localizedNorth: String { return NSLocalizedString(directionKey(0), comment: "") }
    var localizedEast: String { return NSLocalizedString(directionKey(4), comment: "") }
    var localizedSouth: String { return NSLocalizedString(directionKey(8), comment: "") }
    var localizedWest: String { return NSLocalizedString(directionKey(12), comment: "") }
    
    func localizedDirection(degrees: Float) -> String {
        readUnits()
        
        switch directionUnit {
        case .Cardinal:
            let cardinalDirection = DirectionUnit.degreesToCardinal(degrees)
            return NSLocalizedString(directionKey(cardinalDirection), comment: "")
        case .Degrees:
            return NSString(format: "%.0f°", degrees)
        }
    }
    
    func localizedPressure(mbarPressure: Float?) -> String? {
        readUnits()
        return localizedConvertedString(mbarPressure, unit: pressureUnit)
    }
    
    func localizedTemperature(kelvinTemperature: Float?) -> String? {
        readUnits()
        return localizedConvertedString(kelvinTemperature, unit: temperatureUnit)
    }
    
    func localizedWindchill(kelvinTemperature: Float?) -> String? {
        readUnits()
        return localizedConvertedString(kelvinTemperature, unit: temperatureUnit, decimals: 0)
    }

    func formattedGustiness(gustiness: Float?) -> String? {
        if gustiness == nil || gustiness < 0.1 {
            return nil
        }
        return NSString(format: "%.0f", 100*gustiness!)
    }
    
    // MARK - Private
    
    // Units
    
    private func readUnits() {
        if let storedWindspeedInt = Property.getAsInteger("windSpeedUnit")?.integerValue {
            windSpeedUnit = SpeedUnit(rawValue:storedWindspeedInt)!
        }
        
        if let storedDirectionInt = Property.getAsInteger("directionUnit")?.integerValue {
            directionUnit = DirectionUnit(rawValue:storedDirectionInt)!
        }
        
        if let storedPressureInt = Property.getAsInteger("pressureUnit")?.integerValue {
            pressureUnit = PressureUnit(rawValue:storedPressureInt)!
        }
        
        if let storedTemperatureInt = Property.getAsInteger("temperatureUnit")?.integerValue {
            temperatureUnit = TemperatureUnit(rawValue:storedTemperatureInt)!
        }
    }
    
    func writeWindSpeedUnit() { Property.setAsInteger(windSpeedUnit.rawValue, forKey: "windSpeedUnit") }
    func writeDirectionUnit() { Property.setAsInteger(directionUnit.rawValue, forKey: "directionUnit") }
    func writePressureUnit() { Property.setAsInteger(pressureUnit.rawValue, forKey: "pressureUnit") }
    func writeTemperatureUnit() { Property.setAsInteger(temperatureUnit.rawValue, forKey: "temperatureUnit") }

    // Direction
    
    private func directionKey(cardinal: Int) -> String {
        return "DIRECTION_" + directionNames[cardinal]
    }
    
    private var directionNames: [String] { return ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"] }
    
    // Convenience
    
    private func decimalString(value: Float?, decimals: Int = 0, min: Float = 0.1) -> String? {
        if value == nil || value < min {
            return nil
        }
        
        return localizedDecimalString(value!, decimals: decimals)
    }

    private func localizedConvertedString(value: Float?, unit: FloatUnit, min: Float = 0.1, decimals: Int? = nil) -> String? {
        if value == nil || value < min {
            return nil
        }
        
        return localizedDecimalString(unit.fromBase(value!), decimals: decimals ?? unit.decimals)
    }
    
    private func localizedDecimalString(value: Float, decimals: Int) -> String {
        let formatString = NSString(format: "%%.%df", decimals)
        return NSString(format: formatString, locale: NSLocale.currentLocale(), value)
    }
}

