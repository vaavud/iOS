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
    let altitude: Double?
    
    init(lat: Double, lon: Double, name: String?, altitude: Double?) {
        self.lat = lat
        self.lon = lon
        self.name = name
        self.altitude = altitude
    }
    
    init?(dict: [String : AnyObject]) {
        guard let lat = dict["lat"] as? Double, lon = dict["lon"] as? Double else {
            return nil
        }
        
        self.lat = lat
        self.lon = lon
        self.name = dict["name"] as? String
        self.altitude = dict["altitude"] as? Double
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

struct Sourced: Firebaseable {
    let humidity: Double?
    let icon: WeatherState?
    let pressure: Double?
    let temperature: Double?
    let windDirection: Double?
    let windMean: Double?
    
    init?(dict: [String : AnyObject]) {
        humidity = dict["humidity"] as? Double
        icon = (dict["icon"] as? String).flatMap { WeatherState(rawValue: $0) }
        pressure = dict["pressure"] as? Double
        temperature = dict["temperature"] as? Double
        windDirection = dict["windDirection"] as? Double
        windMean = dict["windMean"] as? Double
    }
    
    var fireDict: FirebaseDictionary {
        var dict = FirebaseDictionary()
        dict["humidity"] = humidity
        dict["icon"] = icon?.rawValue
        dict["pressure"] = pressure
        dict["temperature"] = temperature
        dict["windDirection"] = windDirection
        dict["windMean"] = windMean

        return dict
    }
}

struct Session {
    let key: String

    let uid: String
    let deviceKey: String
    let timeStart: NSDate

    var windMax: Double = 0
    var windMean: Double = 0

    let windMeter: WindMeterModel

    var timeEnd: NSDate?
    var windDirection: Double?
    var pressure: Double?
    var temperature: Double?
    var turbulence: Double?
    var sourced: Sourced?
    var location: Location?
    
    init(snapshot: FDataSnapshot) {
        key = snapshot.key
        
        uid = snapshot.value["uid"] as! String
        deviceKey = snapshot.value["deviceKey"] as! String
        timeStart = NSDate(ms: snapshot.value["timeStart"] as! NSNumber)
        
        windMeter = WindMeterModel(rawValue: snapshot.value["windMeter"] as! String)!

        windMax = snapshot.value["windMax"] as? Double ?? 0
        windMean = snapshot.value["windMean"] as? Double ?? 0
        
        timeEnd = (snapshot.value["timeEnd"] as? NSNumber).map(NSDate.init)
        
        windDirection = snapshot.value["windDirection"] as? Double
        pressure = snapshot.value["pressure"] as? Double
        temperature = snapshot.value["temperature"] as? Double
        turbulence = snapshot.value["turbulence"] as? Double
        
        sourced = (snapshot.value["sourced"] as? FirebaseDictionary).flatMap(Sourced.init)
        location = (snapshot.value["location"] as? FirebaseDictionary).flatMap(Location.init)
    }
    
    init(uid: String, key: String, deviceId: String, timeStart: NSDate, windMeter: WindMeterModel) {
        self.uid = uid
        self.key = key
        self.deviceKey = deviceId
        self.timeStart = timeStart
        self.windMeter = windMeter
    }
    
    var fireDict: FirebaseDictionary {
        var dict = FirebaseDictionary()
        dict["uid"] = uid
        dict["deviceKey"] = deviceKey
        dict["timeStart"] = timeStart.ms
        dict["timeEnd"] = timeEnd?.ms
        dict["windMax"] = windMax
        dict["windDirection"] = windDirection
        dict["windMean"] = windMean
        dict["pressure"] = pressure
        dict["temperature"] = temperature
        dict["windMeter"] = windMeter.rawValue
        dict["sourced"] = sourced?.fireDict
        dict["location"] = location?.fireDict
        dict["turbulence"] = turbulence
        
        return dict
    }
}

class HistoryViewController: UITableViewController, HistoryDelegate {
    private var controller: HistoryController!
    private let spinner = MjolnirSpinner(frame: CGRectMake(0, 0, 100, 100))
    private var formatterHandle: String!
    let emptyHistoryArrow = EmptyHistoryArrow()
    lazy var emptyView : UIView = {UIView(frame: self.view.bounds)}()
    lazy var emptyLabelView = UIView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        controller = HistoryController(delegate: self)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.alpha = 0.4
        spinner.center = tableView.bounds.moveY(-64).center
        tableView.addSubview(spinner)
        spinner.show()
        
        let width = CGRectGetWidth(view.bounds);
        let height = CGRectGetHeight(view.bounds);
        let startY = 0.35*height;
        
        
        emptyHistoryArrow.frame = CGRectMake(0, startY, width, height - 120 - startY)
        emptyLabelView.center = CGPointMake(width/2, startY - 40);
        

        emptyHistoryArrow.forceSetup()
        
        let upper = UILabel()
        upper.font = UIFont(name: "Helvetica", size: 20)
        upper.textColor = .vaavudColor()
        upper.text = NSLocalizedString("HISTORY_NO_MEASUREMENTS", comment: "")
        upper.sizeToFit()
        
        let lower = UILabel()
        lower.font = UIFont(name: "Helvetica", size: 15)
        lower.textColor = .vaavudColor()
        lower.text =  NSLocalizedString("HISTORY_GO_TO_MEASURE", comment: "")
        lower.sizeToFit()
        
        //emptyLabelView.frame = CGRectMake(0, 0, max(CGRectGetWidth(upper.bounds), CGRectGetWidth(lower.bounds)), 60)
        upper.center = CGPointMake(CGRectGetMidX(emptyLabelView.bounds), 10);
        lower.center = CGPointMake(CGRectGetMidX(emptyLabelView.bounds), 45);
        
        
        emptyLabelView.addSubview(upper)
        emptyLabelView.addSubview(lower)
        
        view.addSubview(emptyView)
        emptyView.addSubview(emptyLabelView)
        emptyView.addSubview(emptyHistoryArrow)
        emptyView.alpha = 0
        
        
        formatterHandle = VaavudFormatter.shared.observeUnitChange { [unowned self] in self.refreshUnits() }
        refreshUnits()
    }
    
    deinit {
        VaavudFormatter.shared.stopObserving(formatterHandle)
        print("history destroy")
    }
    
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//    }
    
    func refreshUnits() {
        print("TVC refreshUnits")
        tableView.reloadData()
    }
    
    // MARK: Table View Controller
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        //print(controller.sessionss.count)
        return controller.sessionss.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print(controller.sessionss[section].count)
        return controller.sessionss[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("HistoryCell", forIndexPath: indexPath) as? HistoryCell else {
            fatalError("Unknown cell identifier")
        }
        
        let session = controller.sessionss[indexPath.section][indexPath.row]
        cell.time.text = VaavudFormatter.shared.localizedTime(session.timeStart)
        
        if let windDirection = session.windDirection {
            cell.directionUnit.hidden = false
            cell.directionArrow.hidden = false
            cell.directionUnit.text = VaavudFormatter.shared.localizedDirection(windDirection)
            cell.directionArrow.transform = CGAffineTransformMakeRotation(CGFloat(windDirection).radians)
        }
        else{
            cell.directionUnit.hidden = true
            cell.directionArrow.hidden = true
        }
        
        cell.speedUnit.text = VaavudFormatter.shared.speedUnit.localizedString
        cell.speed.text = VaavudFormatter.shared.localizedSpeed(session.windMean)
        
        if let loc = session.location, name = loc.name {
            cell.location.text = name
        }
        else {
            cell.location.text = "Unknown" // Need to localize, should alredy exist
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let deletedSession = controller.sessionss[indexPath.section][indexPath.row]
        
            controller.removeItem(deletedSession, section: indexPath.section, row: indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerCell = tableView.dequeueReusableCellWithIdentifier("HistoryHeaderCell") as? HistoryHeaderCell else {
            fatalError("Unknown header")
        }
        
        headerCell.titleLabel.text = controller.sessionDates[section]
        
        return headerCell.contentView
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let selectedSession = controller.sessionss[indexPath.section][indexPath.row]
        
        if let summary = storyboard?.instantiateViewControllerWithIdentifier("SummaryViewController") as? SummaryViewController,
            navigationController = navigationController {
                summary.session = selectedSession
                summary.isHistorySummary = true
                
                navigationController.pushViewController(summary, animated: true)
        }
        
        //NSUserDefaults.standardUserDefaults().removeObjectForKey("deviceId")
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait, .PortraitUpsideDown]
    }
    
    // MARK: History Delegate
    
    func fetchedMeasurements() {
        dispatch_async(dispatch_get_main_queue()) {
            self.spinner.hide()
            self.emptyView.alpha = 0
            self.tableView.reloadData()
        }
    }
    
    func gotMeasurements() {
        spinner.hide()
        emptyView.alpha = 0
    }
    
    func noMeasurements() {
        emptyView.alpha = 1
        spinner.hide()
        emptyHistoryArrow.animate()
    }
}
