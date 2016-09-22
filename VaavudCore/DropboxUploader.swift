//
//  DataExport.swift
//  Vaavud
//
//  Created by Andreas Okholm on 06/04/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import VaavudSDK

func formattedDate(date: NSDate, timezone: NSTimeZone) -> String {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss' 'Z"
    formatter.timeZone = timezone
    return formatter.stringFromDate(date)
}

class DropboxUploader: NSObject, DBRestClientDelegate {
    static let shared = DropboxUploader()
    
    private let restClient = DBRestClient(session: DBSession.sharedSession())
    private let formatter = NSDateFormatter()
    
    private override init() {
        super.init()
        formatter.timeZone = NSTimeZone.localTimeZone()
        restClient.delegate = self
    }
    
    // MARK - Public
    
    func uploadToDropbox(session: VaavudSession, aggregate: Session) {
        let dbFolder = uploadFolder(aggregate.timeStart)
        
        func uploadFile(string: String, suffix: String) {
            if let path = save(string)?.path {
                let name = uploadFileName(aggregate.timeStart, ending: suffix)
                restClient.uploadFile(name, toPath: dbFolder, withParentRev: nil, fromPath: path)
            }
        }
        
        uploadFile(aggregate.csv(), suffix: " session.csv")
        uploadFile(session.csv(), suffix: " points.csv")
    }

    // MARK - Drobbox Rest Client
    
    func restClient(client: DBRestClient!, uploadedFile destPath: String!, from srcPath: String!, metadata: DBMetadata!) {
        
        do {
            try NSFileManager.defaultManager().removeItemAtPath(srcPath)
            print("File uploaded and deleted successfully to path: \(metadata.path)")
        }
        catch {
            print("File uploaded successfully, but not deleted to path: \(metadata.path), error: \( error)")
        }
    }

    func restClient(client: DBRestClient!, uploadFileFailedWithError error: NSError!) {
        print("File uploaded and deleted successfully to path: \(error)")
    }
    
    // MARK - Private

    private func uploadFolder(date: NSDate) -> String {
        formatter.dateFormat = "'/'yyyy'-'MM'-'dd"
        return formatter.stringFromDate(date)
    }
    
    private func uploadFileName(date: NSDate, ending: String) -> String {
        formatter.dateFormat = "yyyy'-'MM'-'dd' 'HH'-'mm'-'ss"
        return formatter.stringFromDate(date) + ending
    }
    
    private func save(string: String) -> NSURL? {
        let fileURL = NSURL.fileURLWithPath(NSTemporaryDirectory(), isDirectory: true)
            .URLByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString)
        
        do {
            try string.writeToURL(fileURL!, atomically: true, encoding: NSUTF8StringEncoding)

            return fileURL
        }
        catch {
            return nil
        }
    }
}

extension VaavudSession {
    func csv() -> String {
        guard let startTime = windSpeeds.first?.time else { return "No data" }
        
        let header = ["time (s)", "windspeed (m/s)", "time (s)", "winddirection (deg), time (s)", "lat", "lon", "time (s)", "speed", "course"].joinWithSeparator(",")

        var rows = [[Double?]]()

        for i in 0..<max(windSpeeds.count, windDirections.count, locations.count, velocities.count) {
            let w: [Double?] = windSpeeds.count > i ? [windSpeeds[i].time.timeIntervalSinceDate(startTime), windSpeeds[i].speed] : [nil, nil]
            let d: [Double?] = windDirections.count > i ? [windDirections[i].time.timeIntervalSinceDate(startTime), windDirections[i].direction] : [nil, nil]
            let l: [Double?] = locations.count > i ? [locations[i].time.timeIntervalSinceDate(startTime), locations[i].lat, locations[i].lon] : [nil, nil, nil]
            let v: [Double?] = velocities.count > i ? [velocities[i].time.timeIntervalSinceDate(startTime), velocities[i].speed, velocities[i].course] : [nil, nil, nil]
            rows.append(w + d + l + v)
        }
        
        return header + "\n" + rows.map({ $0.map({ $0.map(String.init) ?? "" }).joinWithSeparator(",") }).joinWithSeparator("\n")
    }
}

extension Session {
    func csv() -> String {
        var headerRow = [String]()
        var dataRow = [String]()
        
        let notAvailable = "-"
        let timeZone = NSTimeZone.localTimeZone()
        
        func addDate(headerCell: String, _ data: NSDate) {
            headerRow.append(headerCell)
            dataRow.append(formattedDate(data, timezone: timeZone))
        }
        
        func addObject(headerCell: String, _ data: AnyObject?) {
            headerRow.append(headerCell)
            dataRow.append(data?.description ?? notAvailable)
        }
        
        addDate("startTime", timeStart)
        addDate("endTime", timeEnd!)
        
        addObject("latitude", location?.lat)
        addObject("longitude", location?.lon)
        
        addObject("GeoLocationName", location?.name)
        
        addObject("windspeed Avg", windMean)
        addObject("windspeed Max", windMax)
        
        addObject("wind direction", windDirection)
        addObject("turbulence intensity", turbulence)
        
        addObject("pressure", pressure)
        
        addObject("Sourced: humidity", sourced?.humidity)
        addObject("Sourced: pressure", sourced?.pressure)
        addObject("Sourced: temperature", sourced?.temperature)
        addObject("Sourced: windDirection", sourced?.windDirection)
        addObject("Sourced: windspeed Avg", sourced?.windMean)
        
        addObject("wind meter", windMeter.rawValue)
        
        addObject("startTime Unix", timeStart.timeIntervalSince1970)
        addObject("endTime Unix", timeEnd!.timeIntervalSince1970)
        
        return headerRow.joinWithSeparator(",") + "\n" + dataRow.joinWithSeparator(",")
    }
}


