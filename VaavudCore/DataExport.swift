//
//  DataExport.swift
//  Vaavud
//
//  Created by Andreas Okholm on 06/04/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class DataExport: NSObject, DBRestClientDelegate {
    
    struct ActiveWrappers {
        static var wrappers = NSMutableSet()
    }
    
    var restClient = DBRestClient(session: DataExport.dropboxSession())
    
    override init() {
        super.init()
        restClient.delegate = self
        DataExport.ActiveWrappers.wrappers.addObject(self)
    }
    
    class func dropboxSession() -> DBSession {
        if DBSession.sharedSession() == nil {
            DBSession.setSharedSession(DBSession(appKey: "zszsy52n0svxcv7", appSecret: "t39k1uzaxs7a0zj", root: kDBRootAppFolder))
        }
        return DBSession.sharedSession()
    }
    
    class func exportMeasurementSession(session: MeasurementSession) {
        
        if let sessionLocation:NSURL = DataExport.saveMeasurementSessionToLocalDisk(session) {
            var dataExport = DataExport()
            var uploadFolder = DataExport.uploadFolder(session.startTime, timezone: NSTimeZone(forSecondsFromGMT: session.timezoneOffset.integerValue))
            var destinationFilename = DataExport.uploadFileName(session.startTime, timezone: NSTimeZone(forSecondsFromGMT: session.timezoneOffset.integerValue), ending: " summary.csv")
            dataExport.restClient.uploadFile(destinationFilename, toPath:uploadFolder, withParentRev:nil, fromPath:sessionLocation.path)
        }
        
    }
    
    class func saveMeasurementSessionToLocalDisk(session: MeasurementSession) -> NSURL? {
        
        var headerRow = [String]()
        var dataRow = [String]()
        
        let notAvailable = "-"
        
        headerRow.append("startTime")
        dataRow.append(formatedDate(session.startTime, timezone: NSTimeZone(forSecondsFromGMT: session.timezoneOffset.integerValue)))
        
        headerRow.append("endTime")
        dataRow.append(formatedDate(session.endTime, timezone: NSTimeZone(forSecondsFromGMT: session.timezoneOffset.integerValue)))
    
        headerRow.append("latitude")
        dataRow.append(session.latitude != nil ? session.latitude.description : notAvailable)
        
        headerRow.append("longitude")
        dataRow.append(session.longitude != nil ? session.longitude.description : notAvailable)
        
        headerRow.append("geoLocationName")
        dataRow.append(session.geoLocationNameLocalized ?? notAvailable)
        
        headerRow.append("windSpeedAvg")
        dataRow.append(session.windSpeedAvg != nil ? session.windSpeedAvg.description : notAvailable)
        
        headerRow.append("windSpeedMax")
        dataRow.append(session.windSpeedMax != nil ? session.windSpeedMax.description : notAvailable)
        
        headerRow.append("windDirection")
        dataRow.append(session.windDirection != nil ? session.windDirection.description : notAvailable)
        
        headerRow.append("gustiness")
        dataRow.append(session.gustiness != nil ? session.gustiness.description : notAvailable)
        
        headerRow.append("humidity")
        dataRow.append(session.humidity != nil ? session.humidity.description : notAvailable)
        
        headerRow.append("pressure")
        dataRow.append(session.pressure != nil ? session.pressure.description : notAvailable)
        
        headerRow.append("temperature")
        dataRow.append(session.temperature != nil ? session.temperature.description : notAvailable)
        
        headerRow.append("windMeter")
        if (session.windMeter == 1) {
            dataRow.append("Mjolnir")
        }
        else if (session.windMeter == 2) {
            dataRow.append("Sleipnir")
        }
        else {
            dataRow.append(notAvailable)
        }
        
        headerRow.append("startTimeUnix")
        dataRow.append(session.startTime.timeIntervalSince1970.description)
        
        headerRow.append("endTimeUnix")
        dataRow.append(session.endTime.timeIntervalSince1970.description)
        
        var csv = ",".join(headerRow)
        csv += "\n"
        csv += ",".join(dataRow)
        
        if let baseUrl:NSURL = baseDocumentURL() {
            var fileURL = baseUrl.URLByAppendingPathComponent("summary.csv")
            let sucess = csv.writeToURL(fileURL, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
            if (sucess) {
                println("sucess writing file summary")
                return fileURL
            }
            else {
                println("not so sucessfull writing summary file")
            }
        }
        else {
            println("Could not get base directory")
        }
        
        return nil
    }
    
    class func baseDocumentURL() -> NSURL? {
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls.first as? NSURL
    }
    
    class func uploadFolder(date: NSDate, timezone: NSTimeZone) -> String {
        var formatter = NSDateFormatter();
        formatter.dateFormat = "'/'yyyy'-'MM'-'dd"
        formatter.timeZone = timezone;
        return formatter.stringFromDate(date);
    }
    
    class func uploadFileName(date: NSDate, timezone: NSTimeZone, ending:String) -> String {
        var formatter = NSDateFormatter();
        formatter.dateFormat = "yyyy'-'MM'-'dd' 'HH'-'mm'-'ss"
        formatter.timeZone = timezone;
        return formatter.stringFromDate(date).stringByAppendingString(ending);
    }
    
    class func formatedDate(date: NSDate, timezone: NSTimeZone) -> String {
        var formatter = NSDateFormatter();
        formatter.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss' 'Z"
        formatter.timeZone = timezone;
        return formatter.stringFromDate(date);
    }
    
    
    func restClient(client: DBRestClient!, uploadedFile destPath: String!, from srcPath: String!, metadata: DBMetadata!) {
        println("File uploaded successfully to path: %@", metadata.path)
        DataExport.ActiveWrappers.wrappers.removeObject(self)
    }
    
    
    func restClient(client: DBRestClient!, uploadFileFailedWithError error: NSError!) {
        println("File upload failed with error: %@", error)
        DataExport.ActiveWrappers.wrappers.removeObject(self)
    }
    
    
}
