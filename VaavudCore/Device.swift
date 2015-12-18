//
//  Device.swift
//  Vaavud
//
//  Created by Diego R on 11/20/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import Firebase

struct DeviceSettings: Firebaseable {
    
    let mapHour: Int
    let hasAskedForLocationAccess: Bool
    let hasApprovedLocationAccess: Bool
    let usesSleipnir: Bool
    let sleipnirClipSideScreen: Bool
    let isDropboxLinked: Bool
    let timeUnlimited: Int
    let defaultMeasurementScreen: String
    let defaultFlatVariant: Int
    
    
    init(mapHour: Int, hasAskedForLocationAccess: Bool, hasApprovedLocationAccess: Bool, usesSleipnir: Bool, sleipnirClipSideScreen: Bool, isDropboxLinked: Bool, timeUnlimited: Int, defaultMeasurementScreen: String, defaultFlatVariant: Int){
        self.mapHour = mapHour
        self.hasAskedForLocationAccess = hasAskedForLocationAccess
        self.hasApprovedLocationAccess = hasApprovedLocationAccess
        self.usesSleipnir = usesSleipnir
        self.sleipnirClipSideScreen = sleipnirClipSideScreen
        self.isDropboxLinked = isDropboxLinked
        self.timeUnlimited = timeUnlimited
        self.defaultMeasurementScreen = defaultMeasurementScreen
        self.defaultFlatVariant = defaultFlatVariant
    }
    
    
    init?(dict: FirebaseDictionary) {
        
        self.mapHour = dict["mapHour"] as? Int ?? 3
        self.hasAskedForLocationAccess = dict["hasAskedForLocationAccess"] as? Bool ?? false
        self.hasApprovedLocationAccess = dict["hasApprovedLocationAccess"] as? Bool ?? false
        self.usesSleipnir = dict["usesSleipnir"] as? Bool ?? false
        self.sleipnirClipSideScreen = dict["sleipnirClipSideScreen"] as? Bool ?? false
        self.isDropboxLinked = dict["isDropboxLinked"] as? Bool ?? false
        self.timeUnlimited = dict["timeUnlimited"] as? Int ?? 3
        self.defaultMeasurementScreen = dict["defaultMeasurementScreen"] as? String ?? "TODO"
        self.defaultFlatVariant = dict["defaultFlatVariant"] as? Int ?? 3
        
    }
    
    var fireDict: FirebaseDictionary {
        let dic = FirebaseDictionary()
        return dic
    }
}

struct UserSettings {
    
    let windSpeedUnit: WindSpeedUnit
    let windDirectionUnit: String
    let temperatireUnit: String
    let pressureUnit: String
    let mapForecastHours: String
    
    init?(data: FirebaseDictionary) {
        fatalError()
//        self.windSpeedUnit = WindSpeedUnit(key: data["windSpeedUnit"] as? String)
//        
//        
//        data["windSpeedUnit"] as? String ?? "TODO"
//        self.windDirectionUnit = data["windDirectionUnit"] as? String ?? "TODO"
//        self.temperatireUnit = data["temperatireUnit"] as? String ?? "TODO"
//        self.pressureUnit = data["pressureUnit"] as? String ?? "TODO"
//        self.mapForecastHours = data["mapForecastHours"] as? String ?? "TODO"
    }
    
}

struct InstructionsShown {
    
    let mapGuideMarkerShown: Bool
    let mapGuideTimeIntervalShown: Bool
    let mapGuideZoomShown: Bool
    let mapGuideMeasurePopupShown: Bool
    let mapGuideMeasurePopupShownToday: Bool
    let mapGuideForecastShown: Bool
    let forecastOverlayShown: Bool
    
    init(snapshot: FDataSnapshot) {
        mapGuideMarkerShown = snapshot.value["mapGuideMarkerShown"] as? Bool ?? false
        mapGuideTimeIntervalShown = snapshot.value["mapGuideTimeIntervalShown"] as? Bool ?? false
        mapGuideZoomShown = snapshot.value["mapGuideZoomShown"] as? Bool ?? false
        mapGuideMeasurePopupShown = snapshot.value["mapGuideMeasurePopupShown"] as? Bool ?? false
        mapGuideMeasurePopupShownToday = snapshot.value["mapGuideMeasurePopupShownToday"] as? Bool ?? false
        mapGuideForecastShown = snapshot.value["mapGuideForecastShown"] as? Bool ?? false
        forecastOverlayShown = snapshot.value["forecastOverlayShown"] as? Bool ?? false
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
