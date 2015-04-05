//
//  DataExport.swift
//  Vaavud
//
//  Created by Andreas Okholm on 06/04/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class DataExport: NSObject {
    class func exportMeasurementSession(session: MeasurementSession) {
        
    }
    
    class func saveMeasurementSessionToLocalDisk(session: MeasurementSession) {
        
        var headerRow = [String]()
        var dataRow = [String]()
        
        headerRow.append("startTime")
        dataRow.append(formatedDate(session.startTime, timezone: NSTimeZone(forSecondsFromGMT: session.timezoneOffset.integerValue)))
        
        headerRow.append("endTime")
        dataRow.append(formatedDate(session.endTime, timezone: NSTimeZone(forSecondsFromGMT: session.timezoneOffset.integerValue)))
    
        headerRow.append("latitude")
        dataRow.append(session.latitude.description)
        
        headerRow.append("longitude")
        dataRow.append(session.longitude.description)
        
        headerRow.append("geoLocationName")
        dataRow.append(session.geoLocationNameLocalized)
        
        headerRow.append("windSpeedAvg")
        dataRow.append(session.windSpeedAvg.description)
        
        headerRow.append("windSpeedMax")
        dataRow.append(session.windSpeedMax.description)
        
        headerRow.append("windDirection")
        dataRow.append(session.windDirection.description)
        
        headerRow.append("gustiness")
        dataRow.append(session.gustiness.description)
        
        headerRow.append("humidity")
        dataRow.append(session.humidity.description)
        
        headerRow.append("pressure")
        dataRow.append(session.pressure.description)
        
        headerRow.append("temperature")
        dataRow.append(session.temperature.description)
        
        headerRow.append("windMeter")
        if (session.windMeter == 1) {
            dataRow.append("Mjolnir")
        }
        else if (session.windMeter == 2) {
            dataRow.append("Sleipnir")
        }
        else {
            dataRow.append("N/A")
        }
        
        headerRow.append("startTimeUnix")
        dataRow.append(session.startTime.timeIntervalSince1970.description)
        
        headerRow.append("endTimeUnix")
        dataRow.append(session.endTime.timeIntervalSince1970.description)
        
        var csv = ",".join(headerRow)
        csv += "\n"
        csv += ",".join(dataRow)
        
        if let baseUrl:NSURL = baseDocumentURL() {
            let sucess = csv.writeToURL(baseUrl.URLByAppendingPathComponent("summary.csv"), atomically: false, encoding: NSUTF8StringEncoding, error: nil)
            if (sucess) {
                println("sucess writing file summary")
            }
            else {
                println("not so sucessfull writing summary file")
            }
            
        }
        else {
            println("Could not get base directory")
        }
    }
    
    class func formatedDate(date: NSDate, timezone: NSTimeZone) -> NSString {
        var formatter = NSDateFormatter();
        formatter.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss' 'Z"
        formatter.timeZone = timezone;
        return formatter.stringFromDate(date);
    }
    
    class func baseDocumentURL() -> NSURL? {
        
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        
        return urls.first as? NSURL
        
//        {
//        
//        } else {
//            println("Couldn't get documents directory!")
//        }
//            
//            
//            // This is where the database should be in the documents directory
//            let finalDatabaseURL = documentDirectory.URLByAppendingPathComponent("items.db")
//            
//            if finalDatabaseURL.checkResourceIsReachableAndReturnError(nil) {
//                // The file already exists, so just return the URL
//                return finalDatabaseURL
//            } else {
//                // Copy the initial file from the application bundle to the documents directory
//                if let bundleURL = NSBundle.mainBundle().URLForResource("items", withExtension: "db") {
//                    let success = fileManager.copyItemAtURL(bundleURL, toURL: finalDatabaseURL, error: nil)
//                    if success {
//                        return finalDatabaseURL
//                    } else {
//                        println("Couldn't copy file to final location!")
//                    }
//                } else {
//                    println("Couldn't find initial database in the bundle!")
//                }
//            }
//        
//        
//        return nil
    }
}
