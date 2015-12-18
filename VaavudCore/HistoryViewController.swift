//
//  HistoryViewController.swift
//  Vaavud
//
//  Created by Diego R on 12/3/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import Firebase
import VaavudSDK

// Reflection with computed properties
// Parse NSDate to Double using timeIntervalSince1970
// use optionals for things that are not known in the beginnning
// the parser should not set properties where the value is nil ( dict["windMean"] = windMean )
// NSDataFormatter : use VaavudFormatter

struct Location: Firebaseable {
    let lat: Double
    let lon: Double
    var name: String?
    let altitude: Float?
    
    init?(dict: [String : AnyObject]) {
        guard let lat = dict["lat"] as? Double,
            lon = dict["lon"] as? Double
            else {
                return nil
        }
        
        self.lat = lat
        self.lon = lon
        self.name = dict["name"] as? String
        self.altitude = dict["altitude"] as? Float
    }
    
    var fireDict: FirebaseDictionary {
        var dict = FirebaseDictionary()
        
        dict["altitude"] = altitude
        dict["lat"] = lat
        dict["lon"] = lon
        dict["name"] = name
        
        return dict
    }
}

struct Sourced {
    let humidity: Float
    let icon: String
    let pressure: Float
    let temperature: Float
    let windDirection: Float
    let windMean: Float
    
    init(forecastDict: [String : AnyObject]) {
        fatalError()
    }
    
    init?(dict: [String : AnyObject]) {
        guard let humidity = dict["humidity"] as? Float,
            icon = dict["icon"] as? String,
            pressure = dict["pressure"] as? Float,
            temperature = dict["temperature"] as? Float,
            windDirection = dict["windBearing"] as? Float,
            windSpeed = dict["windSpeed"] as? Float
            else {
                return nil
        }
        
        self.humidity = humidity
        self.icon = icon
        self.pressure = pressure
        self.temperature = temperature
        self.windDirection = windDirection
        self.windMean = windSpeed
    }
    
    var fireDict: FirebaseDictionary {
        return ["humidity": humidity, "icon": icon, "pressure": pressure, "temperature": temperature, "windDirection": windDirection, "windMean": windMean]
    }
}

struct Session {
    let deviceKey: String
    let uid: String
    let timeStart: NSDate
    
    var key: String?
    var timeEnd: NSDate?
    var windDirection: Float?
    var windMax: Float?
    var windMean: Float?
    let windMeter: String
    var turbulence: Float?
    var sourced: Sourced?
    var location: Location?
    
    init(snapshot: FDataSnapshot) {
        key = snapshot.key
        uid = snapshot.value["uid"] as! String
        deviceKey = snapshot.value["deviceKey"] as! String
        timeStart = NSDate(ms: snapshot.value["timeStart"] as! NSNumber)

//        if let timeEnd = snapshot.value["timeEnd"] as? NSNumber {
//            self.timeEnd = NSDate(ms: timeEnd)
//        }
        
        timeEnd = (snapshot.value["timeEnd"] as? NSNumber).map(NSDate.init)

        // Should be equivalent to:
        //        if let timeEnd = snapshot.value["timeEnd"] as? NSNumber {
        //            self.timeEnd = NSDate(ms: timeEnd)
        //        }
        
        windDirection = snapshot.value["windDirection"] as? Float
        windMax = snapshot.value["windMax"] as? Float
        windMean = snapshot.value["windMean"] as? Float
        windMeter = snapshot.value["windMeter"] as! String
        turbulence = snapshot.value["turbulence"] as? Float

        sourced = (snapshot.value["sourced"] as? FirebaseDictionary).flatMap(Sourced.init)
        location = (snapshot.value["location"] as? FirebaseDictionary).flatMap(Location.init)

        // Should be equivalent to:
        //        if let sourced = snapshot.value["sourced"] as? FirebaseDictionary {
        //            self.sourced = Sourced(dict: sourced)
        //        }
        //
        //        if let location = snapshot.value["location"] as? FirebaseDictionary {
        //            self.location = Location(dict: location)
        //        }
    }
    
    init(uid: String, deviceId: String, timeStart: NSDate, windMeter: String) {
        self.uid = uid
        self.deviceKey = deviceId
        self.timeStart = timeStart
        self.windMeter = windMeter
    }
    
    func initDict() -> FirebaseDictionary { // Fixme: why is this necessary?
        var dict = FirebaseDictionary()
        dict["deviceKey"] = deviceKey
        dict["uid"] = uid
        dict["timeStart"] = timeStart.ms
        dict["windMeter"] = windMeter
        
        return dict
    }
    
    var fireDict: FirebaseDictionary {
        var dict = FirebaseDictionary()
        dict["uid"] = uid
        dict["deviceKey"] = deviceKey
        dict["timeStart"] = timeStart.ms
        dict["timeEnd"] = timeEnd
        dict["windMax"] = windMax
        dict["windDirection"] = windDirection
        dict["windMean"] = windMean
        dict["windMeter"] = windMeter
        dict["sourced"] = sourced?.fireDict
        dict["location"] = location?.fireDict
        dict["turbulence"] = turbulence
        
        return dict
    }
}

class HistoryViewController: UITableViewController, HistoryDelegate {
    var sessions = [[Session]]()
    var sessionDates = [String]()
    var controller: HistoryController!
    let spinner = MjolnirSpinner(frame: CGRectMake(100, 100, 100, 100))
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        controller = HistoryController(delegate: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        spinner.alpha = 0.4
        spinner.center = tableView.bounds.center
        tableView.addSubview(spinner)
        spinner.show()
    }
    
    func updateTable(sessions: [[Session]], sessionDates: [String]) {
        self.sessions = sessions
        self.sessionDates = sessionDates
        
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sessions.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCellWithIdentifier("HistoryCell", forIndexPath: indexPath) as? HistoryCell else {
            fatalError("Unknown cell")
        }
        
        cell.time.text = VaavudFormatter.shared.localizedTime(sessions[indexPath.section][indexPath.row].timeStart)
        
        if let windDirection = sessions[indexPath.section][indexPath.row].windDirection {
            cell.directionUnit.text = VaavudFormatter.shared.localizedDirection(windDirection)
            cell.directionArrow.transform = CGAffineTransformMakeRotation(CGFloat(windDirection) / 180 * CGFloat(π))
        }
        else{
            cell.directionUnit.hidden = true
            cell.directionArrow.hidden = true
        }
        
        cell.speedUnit.text = VaavudFormatter.shared.windSpeedUnit.localizedString
        cell.speed.text = VaavudFormatter.shared.localizedWindspeed(sessions[indexPath.section][indexPath.row].windMean)
        
        if let loc = sessions[indexPath.section][indexPath.row].location, name = loc.name {
            cell.location.text = name
        }
        else {
            cell.location.text = "Unknown" // Need to localize, should alredy exist
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let deletedSession = sessions[indexPath.section][indexPath.row]
            
            guard let sessionKey = deletedSession.key else {
                fatalError("No session key")
            }
            
            sessions[indexPath.section].removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            
            if let controller = controller {
                controller.removeItem(sessionKey, sessionDeleted: deletedSession, section: indexPath.section, row: indexPath.row)
                print(sessionKey)
            }
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerCell = tableView.dequeueReusableCellWithIdentifier("HistoryHeaderCell") as? HistoryHeaderCell else {
            fatalError("Unknown header")
        }
        
        headerCell.titleLabel.text = sessionDates[section]
        
        return headerCell.contentView
    }
    
    func hideSpinner() {
        spinner.hide()
        print("hide")
    }
    
    func noMeasurements() {
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let selectedSession = sessions[indexPath.section][indexPath.row]
        
        if let summary = self.storyboard?.instantiateViewControllerWithIdentifier("SummaryViewController") as? CoreSummaryViewController {
            summary.session = selectedSession
            summary.isHistorySummary = true
            
            navigationController?.pushViewController(summary, animated: true)
        }
        
        
        //NSUserDefaults.standardUserDefaults().removeObjectForKey("deviceId")
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25
    }
}
