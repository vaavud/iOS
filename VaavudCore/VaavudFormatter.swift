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

enum TemperatureUnit: String, FloatUnit {
    case Celsius = "celsius"
    case Fahrenheit = "fahrenheit"
    
    // MARK: Unit protocol
    static var unitKey: String { return "temperatureUnit" }
    static var allCases: [TemperatureUnit] { return [.Celsius, .Fahrenheit] }

    // MARK: FloatUnit protocol
    var decimals: Int { return 1 }
    func fromBase(kelvinValue: Float) -> Float { return kelvinValue*ratio + constant }
    
    // MARK: Convenience
    private var ratio: Float { return [1, 9/5][index] }
    private var constant: Float { return [-273.15, -459.67][index] }
}

enum PressureUnit: String, FloatUnit {
    case Mbar = "mbar"
    case Atm = "atm"
    case MmHg = "mmhg"
    
    // MARK: Unit protocol
    static var unitKey: String { return "pressureUnit" }
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
    static var unitKey: String { return "directionUnit" }
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
    static var unitKey: String { return "speedUnit" }
    static var allCases: [SpeedUnit] { return [.Kmh, .Ms, .Mph, .Knots, .Bft] }
    
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

typealias Callback = () -> ()

class VaavudFormatter: NSObject {
    static let shared = VaavudFormatter()
    
    private var _speedUnit: SpeedUnit = .Knots
    private var _directionUnit: DirectionUnit = .Cardinal
    private var _pressureUnit: PressureUnit = .Mbar
    private var _temperatureUnit: TemperatureUnit = .Celsius

    var speedUnit: SpeedUnit { set { writeUnit(newValue, old: speedUnit) } get { return _speedUnit } }
    var directionUnit: DirectionUnit { set { writeUnit(newValue, old: directionUnit) } get { return _directionUnit } }
    var pressureUnit: PressureUnit { set { writeUnit(newValue, old: pressureUnit) } get { return _pressureUnit } }
    var temperatureUnit: TemperatureUnit { set { writeUnit(newValue, old: temperatureUnit) } get { return _temperatureUnit } }
    
    private var callbacks = [String : Callback]()
    
    private let dateFormatter = NSDateFormatter()
    private let shortDateFormat: String
    private let calendar = NSCalendar.currentCalendar()
    
    private let firebase = Firebase(url: firebaseUrl)
    private var handle: UInt!
    
    //    let standardWindspeedUnits: [String : SpeedUnit] = ["US" : .Knots, "UM" : .Knots, "GB" : .Knots, "CA" : .Knots, "VG" : .Knots, "VI" : .Knots]
    
    private override init() {
        dateFormatter.locale = NSLocale.currentLocale()
        shortDateFormat = NSDateFormatter.dateFormatFromTemplate("MMMMd", options: 0, locale: dateFormatter.locale)!
        
        super.init()
        
        handle = firebase
            .childByAppendingPaths("user", firebase.authData.uid, "setting", "shared")
            .observeEventType(.ChildChanged, withBlock: parseSnapshot(updateUnits))
    }
    
    private func updateUnits(dict: [String : AnyObject]) {
        if let key = dict[SpeedUnit.unitKey] as? String, unit = SpeedUnit(rawValue: key) {
            _speedUnit = unit
        }
        
        if let key = dict[DirectionUnit.unitKey] as? String, unit = DirectionUnit(rawValue: key) {
            _directionUnit = unit
        }
        
        if let key = dict[PressureUnit.unitKey] as? String, unit = PressureUnit(rawValue: key) {
            _pressureUnit = unit
        }
        
        if let key = dict[TemperatureUnit.unitKey] as? String, unit = TemperatureUnit(rawValue: key) {
            _temperatureUnit = unit
        }
        
        print("Formatter updateUnits units \(dict)")
        
        for callback in callbacks.values { callback() }
    }
    
    deinit {
        firebase.removeObserverWithHandle(handle)
    }
    
    // MARK - Public
    
    func observeUnitChange(callback: Callback) -> String {
        let uid = NSUUID().UUIDString
        callbacks[uid] = callback
        return uid
    }
    
    func stopObserving(uid: String) -> Bool {
        return callbacks.removeValueForKey(uid) != nil
    }

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
    
    // Formatted

    func formattedSpeed(msSpeed: Float, decimals: Int = 0) -> String {
        return localizedDecimalString(msSpeed, decimals: decimals) + " " + speedUnit.localizedString
    }
    
    func formattedGustiness(gustiness: Float?) -> String? {
        if let gustiness = gustiness where gustiness > 0.001 {
            return String(format: "%.0f", 100*gustiness)
        }
        
        return nil
    }

    // Direction
    
//    static var localizedNorth: String { return NSLocalizedString(directionKey(0), comment: "") }
//    static var localizedEast: String { return NSLocalizedString(directionKey(4), comment: "") }
//    static var localizedSouth: String { return NSLocalizedString(directionKey(8), comment: "") }
//    static var localizedWest: String { return NSLocalizedString(directionKey(12), comment: "") }
    
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
    
//    static func localizedCardinalFromDirection(direction: Int) -> String {
//        return NSLocalizedString(directionKey(direction), comment: "")
//    }
    
    func localizedSpeed(msSpeed: Float) -> String {
        return localizedConvertedString(msSpeed, unit: speedUnit, digits: nil)
    }
    
    func localizedSpeed(msSpeed: Float, digits: Int) -> String {
        return localizedConvertedString(msSpeed, unit: speedUnit, digits: digits)
    }
    
    func localizedPressure(mbarPressure: Float) -> String {
        return localizedConvertedString(mbarPressure, unit: pressureUnit)
    }
    
    func localizedTemperature(kelvin: Float, digits: Int? = nil) -> String {
        return localizedConvertedString(kelvin, unit: temperatureUnit, digits: digits)
    }
    
    func localizedWindchill(kelvin: Float) -> String {
        return localizedConvertedString(kelvin, unit: temperatureUnit, decimals: 0)
    }
    
    // Gustiness
    
//    func updateGustinessLabels(session: MeasurementSession, valueLabel: UILabel, unitLabel: UILabel) -> Bool {
//        let value = session.gustiness?.floatValue
//        
//        if let string = formattedGustiness(value) {
//            unitLabel.text = "%"
//            valueLabel.text = string
//            return true
//        }
//        
//        return failure(valueLabel: valueLabel, unitLabel: unitLabel)
//    }
    
    func writeUnit<U: Unit>(unit: U, old: U) {
        print("Write unit \(U.unitKey): \(unit.rawValue)")
        guard unit != old else { return }
        firebase.childByAppendingPaths("user", firebase.authData.uid, "setting", "shared", U.unitKey).setValue(unit.rawValue)
    }
    
    // Direction
    
    private static func directionKey(cardinal: Int) -> String {
        let n = mod(cardinal, directionNames.count - 1)
        return "DIRECTION_" + directionNames[n]
    }
    
    private static var directionNames: [String] { return ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"] }
    
    // Convenience
    
//    private func decimalString(value: Float?, decimals: Int = 0, min: Float = 0.1) -> String? {
//        if value == nil || value < min {
//            return nil
//        }
//        
//        return localizedDecimalString(value!, decimals: decimals)
//    }

//    private func localizedConvertedString(value: Float?, unit: FloatUnit, min: Float = 0, decimals: Int? = nil, digits: Int? = nil) -> String? {
//        if value == nil || value < min {
//            return nil
//        }
//        
//        return localizedDecimalString(unit.fromBase(value!), decimals: decimals ?? unit.decimals, digits: digits)
//    }
    
    func localizedConvertedString<U: FloatUnit>(value: Float, unit: U, decimals: Int? = nil, digits: Int? = nil) -> String {
        return localizedDecimalString(unit.fromBase(value), decimals: decimals ?? unit.decimals, digits: digits)
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
}

