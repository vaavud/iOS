//
//  NotificationsViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 05/10/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import Firebase

let notificationsWindspeedCeiling: Double = 30

enum NotificationType: Int {
    case None = 0
    case Measurements = 1
    case Both = 2
}


class ButtonWithSessionKey: UIButton {
    var sessionKey: String?
}


class NotificationAnnotation: MKPointAnnotation {
    var sessionKey: String?
}


class NotificationViewCell : UITableViewCell {
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblRadius: UILabel!
    @IBOutlet weak var lblWind: UILabel!
    @IBOutlet weak var directionSelector: DirectionSelector!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    func setDirections(directions: [String:Bool]){

        var actualDirections: Directions = []
        
       for dir in Array(directions.keys) {
        
            var direction: Directions
            switch dir {
            case "N": direction = .N; break
            case "NW": direction = .NW; break
            case "W": direction = .W; break
            case "SW": direction = .SW; break
            case "S": direction = .S; break
            case "SE": direction = .SE; break
            case "E": direction = .E; break
            case "NE": direction = .NE; break
            default: fatalError("Unknown Direction")
        }
        
        actualDirections.insert(direction)
        }
        
        self.directionSelector.areas = directions
        self.directionSelector.selection = actualDirections
        self.directionSelector.setNeedsDisplay()
    }
}

class NotificationsViewController: UIViewController, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource,UIGestureRecognizerDelegate  {
    
    private var locations : [Subscription] = []
    private var subsKeys : [String] = []
    private var circule: MKCircle?
    
    private let annotation = NotificationAnnotation()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnNewSubscription: UIButton!
    private let logHelper = LogHelper(.Notifications)
    var firstNotificationView: UIView!
    private let firebase = Firebase(url: firebaseUrl)
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        logHelper.began()
        logHelper.log("notification")
        
        let preferences = NSUserDefaults.standardUserDefaults()
        let firstTime = preferences.boolForKey("showFirstNotification")
        if firstTime {
            
            let p = Interface.choose((0.865, 0.249), (0.865, 0.255), (0.905, 0.215), (0.905, 0.206), (0.857, 0.443), (0.87, 0.453))
            let pos = CGPoint(x: p.0, y: p.1)
            let text = NSLocalizedString("FIRSTNOTIFICATIONFINISHED", comment: "")
            firstNotificationView = RadialOverlay(frame: self.view.bounds, position: pos, text: text, icon: nil, radius: 0)
            
            let tap = UITapGestureRecognizer(target: self, action: Selector("handleFirstNotificationTapView"))
            tap.delegate = self
            firstNotificationView.addGestureRecognizer(tap)
            self.view.addSubview(firstNotificationView)
            
            preferences.setBool(false, forKey: "showFirstNotification")
            preferences.synchronize()

        }
    }
    
    
    func handleFirstNotificationTapView(){
        firstNotificationView.removeFromSuperview()
        AuthorizationController.shared.registerNotifications()
    }
    
    func showLastAnnotation(){
        if !self.locations.isEmpty {
        
            AuthorizationController.shared.registerNotifications()
            
            let preferences = NSUserDefaults.standardUserDefaults()
            preferences.setValue(true, forKey: "FirstNotification")
            preferences.synchronize()

            let firstSub = self.locations.first!
            
            if let lat = firstSub.location["lat"], lon = firstSub.location["lon"]  {
                
                let latlon = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                
                self.moveMarkerInMap(latlon, radius: firstSub.radius)
                self.mapView.addAnnotation(self.annotation)
            }
        }
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        logHelper.ended()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let ref = firebase.childByAppendingPath("subscription")
            .queryOrderedByChild("uid")
            .queryEqualToValue(firebase.authData.uid)
        
        
        ref.observeEventType(.ChildChanged, withBlock: { snapshot in
            
            guard let subsDict = snapshot.value as? FirebaseDictionary else {
                return
            }
            
            if let index = self.subsKeys.indexOf(snapshot.key), var model = Subscription(dict: subsDict){
                model.subscriptionKey = snapshot.key
                self.locations[index] = model
                self.tableView.reloadData()
            }
        })
        
        
        ref.observeEventType(.ChildAdded, withBlock: { snapshot in
            
                
            guard let _ = snapshot.value["location"] as? [String:Double], subsDict = snapshot.value as? FirebaseDictionary else {
                return
            }
                
                
            if var model = Subscription(dict: subsDict) {
                model.subscriptionKey = snapshot.key
                self.locations.insert(model, atIndex: 0)
                self.subsKeys.insert(snapshot.key, atIndex: 0)
            }
            
            self.tableView.reloadData()
        })
        
        
        ref.observeSingleEventOfType(.Value, withBlock: { [unowned self] snapshot in
            self.showLastAnnotation()
        })
        
        let preferences = NSUserDefaults.standardUserDefaults()
        let firstTime = preferences.boolForKey("NotificationFirstTimeTable")
        
        if (!firstTime) {
            
            
            let p = Interface.choose((0.865, 0.249), (0.865, 0.255), (0.905, 0.215), (0.905, 0.206), (0.857, 0.443), (0.87, 0.453))
            let pos = CGPoint(x: p.0, y: p.1)
            let text = NSLocalizedString("FIRSTNOTIFICATION", comment: "")
            //        let icon = UIImage(named: "map_placeholder")
            self.view.addSubview(RadialOverlay(frame: self.view.bounds, position: pos, text: text, icon: nil, radius: 55))
            
            preferences.setValue(true, forKey: "NotificationFirstTimeTable")
            preferences.synchronize()
        }
    }
    
    
    private func moveMarkerInMap(latlon: CLLocationCoordinate2D, radius: Float){
        annotation.coordinate = latlon
        
        let mapCamera = MKMapCamera(lookingAtCenterCoordinate: latlon, fromEyeCoordinate: latlon, eyeAltitude: 8000)
        mapView.setCamera(mapCamera, animated: true)
        
        
        if let circule = circule {
            self.mapView.removeOverlay(circule)
        }
        
        self.circule = MKCircle(centerCoordinate: latlon, radius: CLLocationDistance(radius))
        self.mapView.addOverlay(circule!)
        
    }
    
    
    @IBAction func didProSelect() {
        logHelper.log("Pro")
        logHelper.increase()
    }
    
    
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let  cell = tableView.dequeueReusableCellWithIdentifier("notificationCell") as? NotificationViewCell  else {
            fatalError("Unkonwn cell for notifications")
        }
        
        let sub = locations[indexPath.row]
        
        cell.lblTitle.text = sub.name
        cell.lblRadius.text = "\(NSLocalizedString("RADIUS", comment: "")): \(Int(sub.radius)) mts"
        
        let plus = Int(sub.windMin) == 15 ? "+" : ""
        cell.lblWind.text = "\(NSLocalizedString("WIND", comment: "")): \(Int(sub.windMin))\(plus) m/s"
        cell.setDirections(sub.directions)
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let sub = locations[indexPath.row]
        
        
        if let lat = sub.location["lat"], lon = sub.location["lon"] {
            let latlon = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            self.moveMarkerInMap(latlon, radius:  sub.radius)
            logHelper.increase()
        }
        
    }
    
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay);
        circleRenderer.strokeColor = .whiteColor()
        circleRenderer.fillColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        circleRenderer.lineWidth = 1.0
        return circleRenderer
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .Normal, title: "Delete") { action, index in
            self.deleteSession(self.locations[indexPath.row].subscriptionKey)
            self.locations.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        
        let edit = UITableViewRowAction(style: .Normal, title: NSLocalizedString("EDIT", comment: "")) { action, index in
            self.editSubscription(indexPath.row)
        }
        
        delete.backgroundColor = .redColor()
        edit.backgroundColor = .orangeColor()
        
        return [delete,edit]
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    
    @IBAction func newNotification() {
        if let notificationDetails = storyboard?.instantiateViewControllerWithIdentifier("NotificationDetailsViewController") as? NotificationDetailsViewController,
            navigationController = navigationController {
                logHelper.log("added")
                navigationController.pushViewController(notificationDetails, animated: true)
        }
    }
    
    
    func editSubscription(row: Int){
        
        if let notificationSettings = storyboard?.instantiateViewControllerWithIdentifier("NotificationDetailsViewController") as? NotificationDetailsViewController, nc = navigationController {
            
            let subscriptionKey = self.locations[row].subscriptionKey
            
            if let lat = locations[row].location["lat"], lon = locations[row].location["lon"] {
                let latlon = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                
                notificationSettings.subscriptionKey = subscriptionKey
                notificationSettings.coordinate = latlon
                notificationSettings.locationName = locations[row].name
                nc.pushViewController(notificationSettings, animated: true)
                logHelper.log("edited")
                logHelper.increase()
            }
            
            
        }
    }
    
    func deleteSession(subscriptionKey: String?){
        
        if let subscriptionKey = subscriptionKey {
            firebase.childByAppendingPaths("subscription",subscriptionKey).removeValue()
            firebase.childByAppendingPaths("subscriptionGeo",subscriptionKey).removeValue()
            logHelper.log("deleted")
            logHelper.increase()
        }
    }
}

