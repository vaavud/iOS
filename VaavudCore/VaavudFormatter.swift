//
//  VaavudFormatter.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 01/02/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import Foundation
import UIKit
import Firebase

let π = CGFloat(M_PI)

enum Interface {
    case IPhone4
    case IPhone5
    case IPhone6
    case IPhone6Plus
    case IPad
    case IPadLandscape
    
    init() {
        let h = UIScreen.mainScreen().bounds.height
        
        if h == 480 {
            self = .IPhone4
        }
        else if h == 568 {
            self = .IPhone5
        }
        else if h == 667 {
            self = .IPhone6
        }
        else if h == 736 {
            self = .IPhone6Plus
        }
        else if h == 1024 {
            self = .IPad
        }
        else {
            self = .IPadLandscape
        }
    }
    
    static func choose<T>(iPhone4: T, _ iPhone5: T, _ iPhone6: T, _ iPhone6Plus: T, _ iPad: T, _ iPadLandscape: T) -> T {
        switch Interface() {
        case .IPhone4: return iPhone4
        case .IPhone5: return iPhone5
        case .IPhone6: return iPhone6
        case .IPhone6Plus: return iPhone6Plus
        case .IPad: return iPad
        case .IPadLandscape: return iPadLandscape
        }
    }
    
    static func choose<T>(iPhone: T, _ iPad: T) -> T {
        switch Interface() {
        case .IPhone4, .IPhone5, .IPhone6, .IPhone6Plus: return iPhone
        case .IPad, .IPadLandscape: return iPad
        }
    }
}

protocol Unit: Equatable {
    init?(rawValue: String)
    var rawValue: String { get }
    static var allCases: [Self] { get }
    static var unitKey: String { get }
}

extension Unit {
    var localizedString: String { return NSLocalizedString(rawValue, comment: "") }
    var next: Self { return Self.allCases.after(self) }
    var index: Int { return Self.allCases.indexOf(self)! }
    init(index: Int) {
        self.init(rawValue: Self.allCases[index].rawValue)!
    }
}

protocol FloatUnit: Unit {
    func fromBase(_: Float) -> Float
    var decimals: Int { get }
}

extension FloatUnit {
    func fromBase(cgValue: CGFloat) -> CGFloat {
        return CGFloat(fromBase(Float(cgValue)))
    }
}

extension Array where Element: Equatable {
    func after(element: Element) -> Element {
        return self[(indexOf(element)! + 1) % count]
    }
}

//protocol LocalUnit: Unit {
//    var localKeys: [String] { get }
//}
//
//extension LocalUnit {
//    var localizedString: String { return NSLocalizedString(localKeys[rawValue], comment: "") }
//}

//enum TemperatureUnit: Int, FloatUnit {
//    case Celsius = 0
//    case Fahrenheit = 1
//    
//    var next: TemperatureUnit { return TemperatureUnit(rawValue: (rawValue + 1) % 2)! }
//    var decimals: Int { return 1 }
//    
//    func fromBase(kelvinValue: Float) -> Float { return kelvinValue*ratio + constant}
//    func fromBase(kelvinValue: CGFloat) -> CGFloat { return CGFloat(fromBase(Float(kelvinValue))) }
//    
//    var keys: [String] { return ["UNIT_CELSIUS", "UNIT_FAHRENHEIT"] }
//    
//    private var ratio: Float { return [1, 9/5][rawValue] }
//    
//    private var constant: Float { return [-273.15, -459.67][rawValue] }
//}

enum TemperatureUnit: String, FloatUnit {
    case Celsius = "celsius"
    case Fahrenheit = "fahrenheit"
    
    // MARK: Unit protocol
    static var unitKey: String { "temperatureUnit" }
    static var allCases: [TemperatureUnit] { return [.Celsius, .Fahrenheit] }

    // MARK: FloatUnit protocol
    var decimals: Int { return 1 }
    func fromBase(kelvinValue: Float) -> Float { return kelvinValue*ratio + constant}
    
    // MARK: Convenience
    private var ratio: Float { return [1, 9/5][index] }
    private var constant: Float { return [-273.15, -459.67][index] }
}

enum PressureUnit: String, FloatUnit {
    case Mbar = "mbar"
    case Atm = "atm"
    case MmHg = "mmhg"
    
    // MARK: Unit protocol
    static var unitKey: String { "pressureUnit" }
    static var allCases: [PressureUnit] { return [.Mbar, .Atm, .MmHg] }

    // MARK: FloatUnit protocol
    var decimals: Int { return [0, 3, 0][index] }
    func fromBase(mbarValue: Float) -> Float { return mbarValue*ratio }
    
    // MARK: Convenience
    private var ratio: Float { return [1, 0.000986923267, 0.75006375541921][index] }
}

enum DirectionUnit: String, Unit {
    case Cardinal = "cardinal"
    case Degrees = "degrees"
    
    // MARK: Unit protocol
    static var unitKey: String { "directionUnit" }
    static var allCases: [DirectionUnit] { return [.Cardinal, .Degrees] }

    // MARK: Static
    static func degreesToCardinal(degreesValue: Float) -> Int {
        return Int(round(16*degreesValue/360)) % 16
    }
}

enum SpeedUnit: String, FloatUnit {
    case Kmh = "kmh"
    case Ms = "ms"
    case Mph = "mph"
    case Knots = "knots"
    case Bft = "beaufort"
    
    // MARK: Unit protocol
    static var unitKey: String { "speedUnit" }
    static var allCases: [SpeedUnit] { return [.Kmh, .Ms, .Mph, .Knots, .Bft ] }
    
    // MARK: FloatUnit protocol
    var decimals: Int { return [1, 1, 1, 1, 0][index] }
    func fromBase(msValue: Float) -> Float {
        return self == .Bft ? SpeedUnit.msToBft(msValue) : msValue*ratio
    }
    
    // MARK: Convenience
    private var ratio: Float { return [3.6, 1, 3600/1609.344, 3600/1852.0, 0][index] }
    
    private static func msToBft(msValue: Float) -> Float {
        let bftLimits: [Float] = [0.3, 1.6, 3.5, 5.5, 8.0, 10.8, 13.9, 17.2, 20.8, 24.5, 28.5, 32.7]
        
        for (index, limit) in bftLimits.enumerate() {
            if msValue < limit {
                return Float(index)
            }
        }
        return 12
    }
}

class VaavudFormatter: NSObject {
    static let shared = VaavudFormatter()
//    var windSpeedUnit: SpeedUnit = .Knots { didSet { writeWindSpeedUnit() } }
//    var directionUnit: DirectionUnit = .Cardinal { didSet { writeDirectionUnit() } }
//    var pressureUnit: PressureUnit = .Mbar { didSet { writePressureUnit() } }
//    var temperatureUnit: TemperatureUnit = .Celsius { didSet { writeTemperatureUnit() } }
    
    private let dateFormatter = NSDateFormatter()
    private let shortDateFormat: String
    private let calendar = NSCalendar.currentCalendar()
    
//    private let firebase = Firebase(url: firebaseUrl)
//    private var handles = [UInt]()
    
    let missingValue = "-"
    
    //    let standardWindspeedUnits: [String : SpeedUnit] = ["US" : .Knots, "UM" : .Knots, "GB" : .Knots, "CA" : .Knots, "VG" : .Knots, "VI" : .Knots]
    
    private override init() {
        dateFormatter.locale = NSLocale.currentLocale()
        shortDateFormat = NSDateFormatter.dateFormatFromTemplate("MMMMd", options: 0, locale: dateFormatter.locale)!
        
        super.init()
        
//        let handle = firebase.childByAppendingPaths("user", firebase.authData.uid, "setting", "shared").observeEventType(.ChildChanged, withBlock: { snap in
//            guard let shared = snap.value as? [String : AnyObject] else {
//                return
//            }
//            
//            self.windSpeedUnit = (shared["windspeedUnit"] as? String).flatMap(SpeedUnit.init) ?? self.windSpeedUnit
//            self.directionUnit = (shared["directionUnit"] as? String).flatMap(DirectionUnit.init) ?? self.directionUnit
//            self.pressureUnit = (shared["pressureUnit"] as? String).flatMap(PressureUnit.init) ?? self.pressureUnit
//            self.temperatureUnit = (shared["temperatureUnit"] as? String).flatMap(TemperatureUnit.init) ?? self.temperatureUnit
//        })
//        
//        handles.append(handle)
        
//        readUnits()
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "unitsChanged:", name: KEY_UNIT_CHANGED, object: nil)
    }
    
    deinit {
//        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
//    func unitsChanged(note: NSNotification) {
//        if note.object as? VaavudFormatter != self {
//            readUnits()
//        }
//    }
    
    // MARK - Public
    
    func hourValue(date: NSDate) -> Int {
        return calendar.components(.Hour, fromDate: date).hour
    }
    
    func dayValue(date: NSDate) -> Int {
        return calendar.components(.Day, fromDate: date).day
    }
    
    func shortDate(date: NSDate) -> String {
        dateFormatter.dateFormat = shortDateFormat
        return dateFormatter.stringFromDate(date)
    }
    
    func localizedRelativeDate(date: NSDate) -> String {
        switch dayValue(date) - dayValue(NSDate()) {
        case -1: return NSLocalizedString("YESTERDAY", comment: "")
        case 0: return NSLocalizedString("TODAY", comment: "")
        case 1: return NSLocalizedString("TOMORROW", comment: "")
        default: return shortDate(date)
        }
    }
    
    func localizedTitleDate(date: NSDate) -> String {
        dateFormatter.dateFormat = "EEEE, MMM d"
        return dateFormatter.stringFromDate(date)
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
    
//    func localizedDirection(degrees: Float) -> String {
//        switch directionUnit {
//        case .Cardinal:
//            return VaavudFormatter.localizedCardinal(degrees)
//        case .Degrees:
//            return String(format: "%.0f°", degrees)
//        }
//    }
    
    func localizedDirection(degrees: Float, unit: DirectionUnit) -> String {
        switch unit {
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
    
    func updateAverageWindspeedLabels(windMean: Float, valueLabel: UILabel, unitLabel: UILabel) -> Bool {
        if let string = localizedWindspeed(windMean) {
            unitLabel.text = windSpeedUnit.localizedString
            valueLabel.text = string
            return true
        }
        
        return failure(valueLabel: valueLabel, unitLabel: unitLabel)
    }

    func updateMaxWindspeedLabels(sessionWindSpeed: Float, valueLabel: UILabel, unitLabel: UILabel) -> Bool {
        if let string = localizedWindspeed(sessionWindSpeed) {
            unitLabel.text = windSpeedUnit.localizedString
            valueLabel.text = string
            return true
        }
        
        return failure(valueLabel: valueLabel, unitLabel: unitLabel)
    }
    
    func formattedWindspeedWithUnit(msSpeed: Float) -> String? {
        return localizedDecimalString(msSpeed, decimals: 0) + " " + windSpeedUnit.localizedString
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

    func localizedTemperature(kelvinTemperature: Float?, digits: Int? = nil) -> String? {
        return localizedConvertedString(kelvinTemperature, unit: temperatureUnit, digits: digits)
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

//    private func localizedConvertedString(value: Float?, unit: FloatUnit, min: Float = 0, decimals: Int? = nil, digits: Int? = nil) -> String? {
//        if value == nil || value < min {
//            return nil
//        }
//        
//        return localizedDecimalString(unit.fromBase(value!), decimals: decimals ?? unit.decimals, digits: digits)
//    }
    
    private func localizedConvertedString<U: FloatUnit>(value: Float?, unit: U, min: Float = 0, decimals: Int? = nil, digits: Int? = nil) -> String? {
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
    
    private func failure(valueLabel  valueLabel: UILabel, unitLabel: UILabel) -> Bool {
        valueLabel.text = missingValue
        unitLabel.text = ""
        return false
    }
}

