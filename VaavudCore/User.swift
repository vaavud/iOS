//
//  Device.swift
//  Vaavud
//
//  Created by Diego R on 11/20/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import VaavudSDK

typealias FirebaseDictionary = [String:AnyObject]

struct Device {
    let appVersion: String
    let appBuild: String
    let model: String
    let vendor: String
    let osVersion: String
    let uid: String
    let created: NSDate? = nil
    
//    init?(dict: FirebaseDictionary) {
//        guard let appVersion = dict["appVersion"] as? String,
//            model = dict["model"] as? String,
//            vendor = dict["vendor"] as? String,
//            osVersion = dict["osVersion"] as? String,
//            uid = dict["uid"] as? String
//            else {
//                return nil
//        }
//        
//        self.appVersion = appVersion
//        self.model = model
//        self.vendor = vendor
//        self.osVersion = osVersion
//        self.uid = uid
//    }
    
    var fireDict : FirebaseDictionary {
        return ["appVersion" : appVersion, "model" : model, /* "appBuild" : appBuild,*/ "vendor" : vendor, "osVersion" : osVersion, "uid" : uid, "created" : created ?? [".sv": "timestamp"]]
    }
}

struct DeviceSettings: Firebaseable {
    var mapHour: Int
    var hasAskedForLocationAccess: Bool
    var hasApprovedLocationAccess: Bool
    var usesSleipnir: Bool
    var sleipnirClipSideScreen: Bool
    var isDropboxLinked: Bool
    var measuringTime: Int
    var defaultMeasurementScreen: String
    
    init(mapHour: Int, hasAskedForLocationAccess: Bool, hasApprovedLocationAccess: Bool, usesSleipnir: Bool, sleipnirClipSideScreen: Bool, isDropboxLinked: Bool, measuringTime: Int, defaultMeasurementScreen: String) {
        self.mapHour = mapHour
        self.hasAskedForLocationAccess = hasAskedForLocationAccess
        self.hasApprovedLocationAccess = hasApprovedLocationAccess
        self.usesSleipnir = usesSleipnir
        self.sleipnirClipSideScreen = sleipnirClipSideScreen
        self.isDropboxLinked = isDropboxLinked
        self.measuringTime = measuringTime
        self.defaultMeasurementScreen = defaultMeasurementScreen
    }
    
    init?(dict: FirebaseDictionary) {
        self.mapHour = dict["mapHour"] as! Int
        self.hasAskedForLocationAccess = dict["hasAskedForLocationAccess"] as! Bool
        self.hasApprovedLocationAccess = dict["hasApprovedLocationAccess"] as! Bool
        self.usesSleipnir = dict["usesSleipnir"] as! Bool
        self.sleipnirClipSideScreen = dict["sleipnirClipSideScreen"] as! Bool
        self.isDropboxLinked = dict["isDropboxLinked"] as! Bool
        self.measuringTime = dict["measuringTime"] as! Int
        self.defaultMeasurementScreen = dict["defaultMeasurementScreen"] as! String
    }
    
    var fireDict: FirebaseDictionary {
        var dict = FirebaseDictionary()
        dict["mapHour"] = mapHour
        dict["hasAskedForLocationAccess"] = hasAskedForLocationAccess
        dict["hasApprovedLocationAccess"] = hasApprovedLocationAccess
        dict["usesSleipnir"] = usesSleipnir
        dict["sleipnirClipSideScreen"] = sleipnirClipSideScreen
        dict["isDropboxLinked"] = isDropboxLinked
        dict["measuringTime"] = measuringTime
        dict["defaultMeasurementScreen"] = defaultMeasurementScreen
        
        return dict
    }
}

struct User {
    let firstName: String
    let lastName: String
    let country: String
    let language: String
    let email: String
    let created: NSDate? = nil
    var settingIos: UserSettingsIos
    var settingShared: UserSettingsShared
    
    init(firstName: String, lastName: String, country: String, language: String, email: String, settingIos: UserSettingsIos = UserSettingsIos(), settingShared: UserSettingsShared = UserSettingsShared()) {
        self.firstName = firstName
        self.lastName = lastName
        self.country = country
        self.language = language
        self.email = email
        self.settingIos = settingIos
        self.settingShared = settingShared
    }
    
//    init?(dict: FirebaseDictionary) {
//        guard let firstName = dict["firstName"] as? String,
//            lastName = dict["lastName"] as? String,
//            country = dict["country"] as? String,
//            language = dict["language"] as? String,
//            email = dict["email"] as? String,
//            created = dict["created"] as? Double
//            else {
//                return nil
//        }
//        
//        self.firstName = firstName
//        self.lastName = lastName
//        self.country = country
//        self.language = language
//        self.email = email
//        self.created = created
//        
//        self.activity = dict["activity"] as? String
//    }
    
    var fireDict: FirebaseDictionary {
        let setting = ["ios" : settingIos.fireDict, "shared" : settingShared.fireDict]
        
        let dict: FirebaseDictionary = ["firstName" : firstName, "lastName" : lastName, "country" : country, "language" : language, "email" : email, "created" : created ?? [".sv": "timestamp"], "setting" : setting]
        
        return dict
    }
}

struct UserSettingsIos: Firebaseable {
    var mapGuideMarkerShown = false
    var mapGuideTimeIntervalShown = false
    var mapGuideZoomShown = false
    var mapGuideMeasurePopupShown = false
    var mapGuideMeasurePopupShownToday = false
    var mapGuideForecastShown = false
    var forecastOverlayShown = false
    var summaryShareOverlayShown = false
    
    init() {}
    
    init?(dict: FirebaseDictionary) {
        mapGuideMarkerShown = dict["mapGuideMarkerShown"] as? Bool ?? mapGuideMarkerShown
        mapGuideTimeIntervalShown = dict["mapGuideTimeIntervalShown"] as? Bool ?? mapGuideTimeIntervalShown
        mapGuideZoomShown = dict["mapGuideZoomShown"] as? Bool ?? mapGuideZoomShown
        mapGuideMeasurePopupShown = dict["mapGuideMeasurePopupShown"] as? Bool ?? mapGuideMeasurePopupShown
        mapGuideMeasurePopupShownToday = dict["mapGuideMeasurePopupShownToday"] as? Bool ?? mapGuideMeasurePopupShownToday
        mapGuideForecastShown = dict["mapGuideForecastShown"] as? Bool ?? mapGuideForecastShown
        forecastOverlayShown = dict["forecastOverlayShown"] as? Bool ?? forecastOverlayShown
        summaryShareOverlayShown = dict["summaryShareOverlayShown"] as? Bool ?? summaryShareOverlayShown
    }
    
    var fireDict: FirebaseDictionary {
        var dict = FirebaseDictionary()
        dict["mapGuideMarkerShown"] = mapGuideMarkerShown
        dict["mapGuideTimeIntervalShown"] = mapGuideTimeIntervalShown
        dict["mapGuideZoomShown"] = mapGuideZoomShown
        dict["mapGuideMeasurePopupShown"] = mapGuideMeasurePopupShown
        dict["mapGuideMeasurePopupShownToday"] = mapGuideMeasurePopupShownToday
        dict["mapGuideForecastShown"] = mapGuideForecastShown
        dict["forecastOverlayShown"] = forecastOverlayShown
        dict["summaryShareOverlayShown"] = summaryShareOverlayShown
        
        return dict
    }
}

struct UserSettingsShared: Firebaseable {
    var windSpeedUnit: SpeedUnit = .Ms
    var windDirectionUnit: DirectionUnit = .Cardinal
    var temperatureUnit: TemperatureUnit = .Celsius
    var pressureUnit: PressureUnit = .Mbar
    var mapForecastHours: Int = 2

    init() {}

    init(windSpeedUnit: SpeedUnit, windDirectionUnit: DirectionUnit, temperatureUnit: TemperatureUnit, pressureUnit: PressureUnit, mapForecastHours: Int) {
        self.windSpeedUnit = windSpeedUnit
        self.windDirectionUnit = windDirectionUnit
        self.temperatureUnit = temperatureUnit
        self.pressureUnit = pressureUnit
        self.mapForecastHours = mapForecastHours
    }

    init?(dict: FirebaseDictionary) {
        windSpeedUnit = SpeedUnit(rawValue: dict["windSpeedUnit"] as! String)!
        windDirectionUnit = DirectionUnit(rawValue: dict["windDirectionUnit"] as! String)!
        temperatureUnit = TemperatureUnit(rawValue: dict["temperatureUnit"] as! String)!
        pressureUnit = PressureUnit(rawValue: dict["pressureUnit"] as! String)!
        mapForecastHours = dict["mapForecastHours"] as? Int ?? mapForecastHours
    }

    var fireDict: FirebaseDictionary {
        var dict = FirebaseDictionary()
        dict["windSpeedUnit"] = windSpeedUnit.rawValue
        dict["windDirectionUnit"] = windDirectionUnit.rawValue
        dict["temperatureUnit"] = temperatureUnit.rawValue
        dict["pressureUnit"] = pressureUnit.rawValue
//        dict["mapForecastHours"] = mapForecastHours
        return dict
    }
}

