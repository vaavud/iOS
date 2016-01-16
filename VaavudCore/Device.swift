//
//  Device.swift
//  Vaavud
//
//  Created by Diego R on 11/20/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import Firebase
import VaavudSDK

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

//struct UserSettings: Firebaseable {
//    var windSpeedUnit: String
//    var windDirectionUnit: String
//    var temperatireUnit: String
//    var pressureUnit: String
//    var mapForecastHours: Int
//    
//    init(windSpeedUnit: String, windDirectionUnit: String, temperatireUnit: String, pressureUnit: String, mapForecastHours: Int) {
//        self.windSpeedUnit = windSpeedUnit
//        self.windDirectionUnit = windDirectionUnit
//        self.temperatireUnit = temperatireUnit
//        self.pressureUnit = pressureUnit
//        self.mapForecastHours = mapForecastHours
//    }
//    
//    init?(dict: FirebaseDictionary) {
//        //self.windSpeedUnit = WindSpeedUnit(key: data["windSpeedUnit"] as? String)
//        self.windSpeedUnit =  dict["windSpeedUnit"] as? String ?? "TODO"
//        self.windDirectionUnit = dict["windDirectionUnit"] as? String ?? "TODO"
//        self.temperatireUnit = dict["temperatireUnit"] as? String ?? "TODO"
//        self.pressureUnit = dict["pressureUnit"] as? String ?? "TODO"
//        self.mapForecastHours = dict["mapForecastHours"] as? Int ?? 0
//    }
//    
//    var fireDict: FirebaseDictionary {
//        var dict = FirebaseDictionary()
//        dict["windSpeedUnit"] = windSpeedUnit
//        dict["windDirectionUnit"] = windDirectionUnit
//        dict["temperatireUnit"] = temperatireUnit
//        dict["pressureUnit"] = pressureUnit
//        dict["mapForecastHours"] = mapForecastHours
//        return dict
//    }
//}

struct InstructionsShown: Firebaseable {
    var mapGuideMarkerShown = false
    var mapGuideTimeIntervalShown = false
    var mapGuideZoomShown = false
    var mapGuideMeasurePopupShown = false
    var mapGuideMeasurePopupShownToday = false
    var mapGuideForecastShown = false
    var forecastOverlayShown = false
    
    init() {}
    
    init?(dict: FirebaseDictionary) {
        mapGuideMarkerShown = dict["mapGuideMarkerShown"] as? Bool ?? mapGuideMarkerShown
        mapGuideTimeIntervalShown = dict["mapGuideTimeIntervalShown"] as? Bool ?? mapGuideTimeIntervalShown
        mapGuideZoomShown = dict["mapGuideZoomShown"] as? Bool ?? mapGuideZoomShown
        mapGuideMeasurePopupShown = dict["mapGuideMeasurePopupShown"] as? Bool ?? mapGuideMeasurePopupShown
        mapGuideMeasurePopupShownToday = dict["mapGuideMeasurePopupShownToday"] as? Bool ?? mapGuideMeasurePopupShownToday
        mapGuideForecastShown = dict["mapGuideForecastShown"] as? Bool ?? mapGuideForecastShown
        forecastOverlayShown = dict["forecastOverlayShown"] as? Bool ?? forecastOverlayShown
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
        
        return dict
    }
}
