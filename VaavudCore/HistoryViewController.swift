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
    
    
    init(dict: FirebaseDictionary, key: String){
        self.key = key
        
        uid = dict["uid"] as! String
        deviceKey = dict["deviceKey"] as! String
        timeStart = NSDate(ms: dict["timeStart"] as! NSNumber)
        
        windMeter = WindMeterModel(rawValue: dict["windMeter"] as! String)!
        
        windMax = dict["windMax"] as? Double ?? 0
        windMean = dict["windMean"] as? Double ?? 0
        
        timeEnd = (dict["timeEnd"] as? NSNumber).map(NSDate.init)
        
        windDirection = dict["windDirection"] as? Double
        pressure = dict["pressure"] as? Double
        temperature = dict["temperature"] as? Double
        turbulence = dict["turbulence"] as? Double
        
        sourced = (dict["sourced"] as? FirebaseDictionary).flatMap(Sourced.init)
        location = (dict["location"] as? FirebaseDictionary).flatMap(Location.init)
    }
    
    init(snapshot: FIRDataSnapshot) {
        key = snapshot.key
        
        guard let snapshot = snapshot.value else{
            fatalError("Bad Json History")
        }
        
        uid = snapshot["uid"] as! String
        deviceKey = snapshot["deviceKey"] as! String
        timeStart = NSDate(ms: snapshot["timeStart"] as! NSNumber)
        
        windMeter = WindMeterModel(rawValue: snapshot["windMeter"] as! String)!

        windMax = snapshot["windMax"] as? Double ?? 0
        windMean = snapshot["windMean"] as? Double ?? 0
        
        timeEnd = (snapshot["timeEnd"] as? NSNumber).map(NSDate.init)
        
        windDirection = snapshot["windDirection"] as? Double
        pressure = snapshot["pressure"] as? Double
        temperature = snapshot["temperature"] as? Double
        turbulence = snapshot["turbulence"] as? Double
        
        sourced = (snapshot["sourced"] as? FirebaseDictionary).flatMap(Sourced.init)
        location = (snapshot["location"] as? FirebaseDictionary).flatMap(Location.init)
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
        if AuthorizationController.shared.isAuth{
            controller = HistoryController(delegate: self)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if AuthorizationController.shared.isAuth {
            
            navigationController?.navigationBar.hidden = false

            
            spinner.alpha = 0.4
            spinner.center = tableView.bounds.moveY(-64).center
            tableView.addSubview(spinner)
            spinner.show()
            
            
            
            formatterHandle = VaavudFormatter.shared.observeUnitChange { [weak self] in self?.refreshUnits() }
            refreshUnits()

        
        }
        else {
            
            navigationController?.navigationBar.hidden = true

            let callback = { () in
                gotoLoginFrom(self.tabBarController!, inside: self.view.window!.rootViewController!)

            }
            
            let myCustomView = LoginWallView.fromNib("LoginWall")
            myCustomView.isMap = false
            myCustomView.callback = callback
            
            let rec = CGRect(x: 0, y: -21, width: UIScreen.mainScreen().bounds.width, height: UIScreen.mainScreen().bounds.height)
            
            myCustomView.frame = rec
            myCustomView.setUp()
            
            view.addSubview(myCustomView)

        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    private func addEmpyView() {
    
    let width = CGRectGetWidth(view.bounds);
    let height = CGRectGetHeight(view.bounds);
    let startY = (0.35*height)
    
    emptyHistoryArrow.frame = CGRectMake(0, startY + 20, width, height - 150 - startY)
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
    lower.text =  NSLocalizedString("", comment: "")
    lower.sizeToFit()
    
    //emptyLabelView.frame = CGRectMake(0, 0, max(CGRectGetWidth(upper.bounds), CGRectGetWidth(lower.bounds)), 60)
    upper.center = CGPointMake(CGRectGetMidX(emptyLabelView.bounds), 10)
    lower.center = CGPointMake(CGRectGetMidX(emptyLabelView.bounds), 45)
    
    emptyLabelView.addSubview(upper)
    emptyLabelView.addSubview(lower)
    
    view.addSubview(emptyView)
    emptyView.addSubview(emptyLabelView)
    emptyView.addSubview(emptyHistoryArrow)
    emptyView.alpha = 0
    
    }
    
    
    deinit {
        guard AuthorizationController.shared.isAuth else {
            return
        }
        VaavudFormatter.shared.stopObserving(formatterHandle)
    }
    
    func refreshUnits() {
        tableView.reloadData()
    }
    
    // MARK: Table View Controller
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return AuthorizationController.shared.isAuth ? controller.sessionss.count : 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AuthorizationController.shared.isAuth ? controller.sessionss[section].count : 0
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
            cell.location.text = NSLocalizedString("GEOLOCATION_UNKNOWN", comment: "")
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let deletedSession = controller.sessionss[indexPath.section][indexPath.row]
        
            controller.removeItem(deletedSession, section: indexPath.section, row: indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            
            if controller.sessionss[indexPath.section].isEmpty {
                controller.removeSection(indexPath.section)
                tableView.deleteSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Middle)
            }
            
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
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait, .PortraitUpsideDown]
    }
    
    // MARK: History Delegate
    
    func fetchedMeasurements() {
        self.spinner.hide()
        self.emptyView.alpha = 0
        self.tableView.reloadData()
    }
    
    func gotMeasurements() {
        spinner.hide()
        emptyView.alpha = 0
    }
    
    func noMeasurements() {
        addEmpyView()
        emptyView.alpha = 1
        spinner.hide()
        emptyHistoryArrow.animate()
    }
}
