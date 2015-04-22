//
//  DataExport.swift
//  Vaavud
//
//  Created by Andreas Okholm on 06/04/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class DropboxUploader: NSObject, DBRestClientDelegate {
    let restClient = DBRestClient(session: DBSession.sharedSession())
    let formatter = NSDateFormatter()
    
    let i = 0
    
    init(delegate: DBRestClientDelegate) {
        super.init()
        restClient.delegate = delegate
    }
    
    func uploadFolder(date: NSDate, timezone: NSTimeZone) -> String {
        formatter.dateFormat = "'/'yyyy'-'MM'-'dd"
        formatter.timeZone = timezone
        return formatter.stringFromDate(date)
    }
    
    func uploadFileName(date: NSDate, timezone: NSTimeZone, ending:String) -> String {
        formatter.dateFormat = "yyyy'-'MM'-'dd' 'HH'-'mm'-'ss"
        formatter.timeZone = timezone
        return formatter.stringFromDate(date) + ending
    }
    
    func uploadToDropbox(session: MeasurementSession) {
        let timeZone = NSTimeZone(forSecondsFromGMT: session.timezoneOffset.integerValue)
        let dbFolder = uploadFolder(session.startTime, timezone:timeZone )
        
        func uploadFile(string:String, fileNameEnding:String) {
            if let fileLocation = save(string) {
                let dbFilename = uploadFileName(session.startTime, timezone: timeZone, ending:fileNameEnding)
                restClient.uploadFile(dbFilename, toPath:dbFolder, withParentRev:nil, fromPath:fileLocation.path)
            }
        }
        
        uploadFile(session.asCSV(), " session.csv")
        uploadFile(session.pointsAsCSV(), " points.csv")
    }
    
    func save(string:String) -> NSURL? {
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask) as! [NSURL]
        
        if let baseUrl = urls.first {
            var fileURL = baseUrl.URLByAppendingPathComponent(NSUUID().UUIDString)
            let success = string.writeToURL(fileURL, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
            if (success) {
                println("sucess writing file %@", fileURL.path)
                return fileURL
            }
            else {
                println("not so sucessfull writing file %@", fileURL.path)
            }
        }
        println("Could not get base directory")
        return nil
    }
}


extension MeasurementSession {
    func asCSV() -> String {
        var headerRow = [String]()
        var dataRow = [String]()
        
        let notAvailable = "-"
        let timeZone = NSTimeZone(forSecondsFromGMT: timezoneOffset.integerValue)
        
        func addDate(headerCell: String, data: NSDate) {
            headerRow.append(headerCell)
            dataRow.append(formattedDate(data, timeZone))
        }
        
        func addObject(headerCell: String, data: NSObject?) {
            headerRow.append(headerCell)
            dataRow.append(data != nil ? data!.description : notAvailable)
        }
        
        addDate("startTime", startTime)
        addDate("endTime", endTime)
        addObject("latitude", latitude)
        addObject("longitude", longitude)
        addObject("GeoLocationName", geoLocationNameLocalized)
        addObject("windspeed Avg", windSpeedAvg)
        addObject("windspeed Max", windSpeedMax)
        addObject("wind direction", windDirection)
        addObject("turbulence intensity", gustiness)
        addObject("humidity", humidity)
        addObject("pressure", pressure)
        addObject("temperature", temperature)
        var windmeterString:String;
        if windMeter == 1 {
            windmeterString = "Mjolnir"
        }
        else if windMeter == 2 {
            windmeterString = "Sleipnir"
        }
        else {
            windmeterString = notAvailable
        }
        addObject("wind meter", windmeterString)
        addObject("startTime Unix", startTime.timeIntervalSince1970)
        addObject("endTime Unix", endTime.timeIntervalSince1970)
        
        var csv = ",".join(headerRow)
        csv += "\n"
        csv += ",".join(dataRow)
        
        return csv
    }
    
    func pointsAsCSV() -> String {
        
        var headerRow = [String]()
        var dataRow = [String]()
        
        let notAvailable = "-"
        
        headerRow.append("time (s)")
        headerRow.append("windspeed (m/s)")
        headerRow.append("winddirection (deg)")
        var csv = ",".join(headerRow)
        csv += "\n"
        
        
        points.enumerateObjectsUsingBlock { (elem, idx, stop) -> Void in
            if let point = elem as? MeasurementPoint {
                csv += point.time.timeIntervalSinceDate(self.startTime).description
                csv += ","
                csv += point.windSpeed != nil ? point.windSpeed.description : notAvailable
                csv += ","
                csv += point.windDirection != nil ? point.windDirection.description : notAvailable
                csv += "\n"
            }
        }
        return csv
    }
}

func formattedDate(date: NSDate, timezone: NSTimeZone) -> String {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss' 'Z"
    formatter.timeZone = timezone
    return formatter.stringFromDate(date)
}