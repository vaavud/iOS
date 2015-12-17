//
//  Device.swift
//  Vaavud
//
//  Created by Diego R on 11/20/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import Firebase

struct DeviceSettings {
    
    let mapHours: [Int]
    let hasAskedForLocationAccess: Bool
    let hasApprovedLocationAccess: Bool
    let usesSleipnir: Bool
    let sleipnirClipSideScreen: Bool
    let isDropboxLinked: Bool
    let timeUnlimited: Int
    let defaultMeasurementScreen: String
    let defaultFlatVariant: Int
    let key: String
    
    
    
}



struct UserSettings {
    
    let key: String
    let windSpeedUnit: String
    let windDirectionUnit: String
    let temperatireUnit: String
    let pressureUnit: String
    let mapForecastHours: String
    
    
    
}

struct InstructionsShown {
    
    let key: String
    let mapGuideMarkerShown: Bool
    let mapGuideTimeIntervalShown: Bool
    let mapGuideZoomShown: Bool
    let mapGuideMeasurePopupShown: Bool
    let mapGuideMeasurePopupShownToday: Bool
    let mapGuideForecastShown: Bool
    let forecastOverlayShown: Bool
    
    init(snapshot: FDataSnapshot) {
        key = snapshot.key
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
        dict["key"] = key
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
