//
//  NotificationDetailsViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 05/10/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import Firebase

struct Subscription {

    let uid: String
    var radius: Float
    var windMin: Float
    let name: String
    var location: [String: Double]
    var directions: [String: Bool]
    let lastFired = [".sv": "timestamp"]
    var subscriptionKey: String?
    
    
    init(uid: String, name: String, radius: Float, windMin: Float, location: [String: Double], directions: [String: Bool]){
        self.uid = uid
        self.name = name
        self.radius = radius
        self.windMin = windMin
        self.location = location
        self.directions = directions 
    }
    
    init?(dict: FirebaseDictionary){
        
        
        guard let uid = dict["uid"] as? String, name = dict["name"] as? String, radius =  dict["radius"] as? Float, windMin =  dict["windMin"] as? Float, location =  dict["location"] as? [String: Double], directions =  dict["directions"] as? [String: Bool]  else {
            return nil
        }
        
        self.name = name
        self.location = location
        self.directions = directions
        self.uid = uid
        self.radius = radius
        self.windMin = windMin
        
    }
    
    var fireDict : FirebaseDictionary {
        return ["directions" : directions, "name": name, "location" : location, "radius" : radius, "uid" : uid, "windMin" :windMin, "lastFired" : lastFired]
    }
}


class WhatsNewViewController: UIViewController{
    
    @IBAction func didcontinueTouch(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}



class NotificationPopOver: UIViewController, UIPopoverPresentationControllerDelegate{
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "popoverSegue" {
            let popoverViewController = segue.destinationViewController
            popoverViewController.modalPresentationStyle = .Popover
            popoverViewController.popoverPresentationController!.delegate = self
        }
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }

}


class NotificationDetailsViewController: UIViewController,MKMapViewDelegate,UIGestureRecognizerDelegate, UITextFieldDelegate,UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var txtSubscriptionName: UITextField!
    
    private let firebase = Firebase(url: firebaseUrl)
    private var longPressRecognizer: UILongPressGestureRecognizer!
    private var annotation: MKPointAnnotation?
    private let geocoder = CLGeocoder()
    var subscriptionKey: String?
    var coordinate: CLLocationCoordinate2D?
    var locationName: String?
    @IBOutlet weak var nameLocationView: UIView!
    private let logHelper = LogHelper(.NotificationDetails)
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "popoverSegue" {
            let popoverViewController = segue.destinationViewController
            popoverViewController.modalPresentationStyle = .Popover
            popoverViewController.popoverPresentationController!.delegate = self
        }
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    deinit{
        print("NotificationDetails Deleted")
    }
    
    func presentHelpPopup(){
        let storyboard : UIStoryboard = UIStoryboard(
            name: "MainStoryboard",
            bundle: nil)
        if let menuViewController = storyboard.instantiateViewControllerWithIdentifier("NotificationPopOver") as? NotificationPopOver{
            menuViewController.modalPresentationStyle = .Popover
            menuViewController.preferredContentSize = CGSizeMake(250, 54)
            
            
            let popoverMenuViewController = menuViewController.popoverPresentationController
            popoverMenuViewController?.permittedArrowDirections = .Any
            popoverMenuViewController?.delegate = self
            popoverMenuViewController?.sourceView = nameLocationView
            popoverMenuViewController?.sourceRect = CGRect(
                x: 0,
                y: 0,
                width: 250,
                height: 54)
            presentViewController(
                menuViewController,
                animated: true,
                completion: nil)
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == txtSubscriptionName {
            guard !txtSubscriptionName.text!.isEmpty else {
                return false
            }
            
            nextDetails()
            
            return true
        }
        
        return true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logHelper.began()
        logHelper.log("map")
        
        if let _ = subscriptionKey, latlon = coordinate, locationName = locationName {
        
            addNewMarker(latlon)
            mapView.selectAnnotation(mapView.annotations[0], animated: true)
            txtSubscriptionName.text = locationName
            
            nameLocationView.hidden = false
        }
        else{
            NSDate().ms
            longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(NotificationDetailsViewController.handleLongPress(_:)))
            longPressRecognizer.minimumPressDuration = 0.3
            longPressRecognizer.delaysTouchesBegan = true
            longPressRecognizer.delegate = self
            mapView.addGestureRecognizer(longPressRecognizer)
        }
        
        
        let preferences = NSUserDefaults.standardUserDefaults()
        let firstTime = preferences.objectForKey("NotificationFirstTimeMap") is Bool
        
        if (!firstTime) {
            
            
            let p = Interface.choose((0.5, 0.2), (0.5, 0.2), (0.5, 0.2), (0.5, 0.2), (0.857, 0.443), (0.87, 0.453))
            let pos = CGPoint(x: p.0, y: p.1)
            let text = NSLocalizedString("PRESSLONG", comment: "")
            let icon = UIImage(named: "map_placeholder")
            tabBarController?.view.addSubview(RadialOverlay(frame: self.view.bounds, position: pos, text: text, icon: icon, radius: 0))
            
            preferences.setValue(true, forKey: "NotificationFirstTimeMap")
            preferences.synchronize()
        }
    }
    
    func requestGeocode(location: CLLocationCoordinate2D, callback: String? -> ()) {
        geocoder.reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude)) { placemarks, error in
            dispatch_async(dispatch_get_main_queue()) {
                guard let first = placemarks?.first else {
                    callback("My new Area")
                    return
                }
                callback(first.thoroughfare ?? first.locality ?? first.country ?? "My new Area")
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        logHelper.ended()
    }
    
    @IBAction func nextDetails() {
        
        if txtSubscriptionName.text!.isEmpty {
            txtSubscriptionName.becomeFirstResponder()
            return
        }
        
        view.endEditing(true)
        
        
        if let subscriptionKey = subscriptionKey {
            print(subscriptionKey)
            firebase.childByAppendingPaths("subscription",subscriptionKey,"name").setValue(txtSubscriptionName.text!)
            firebase.childByAppendingPaths("subscription",subscriptionKey,"location").setValue(["lat": annotation!.coordinate.latitude, "lon":annotation!.coordinate.longitude])
        }
        
        
        
        if let annotation = annotation {
            
            if let notificationSettings = storyboard?.instantiateViewControllerWithIdentifier("notificationSettingsViewController") as? NotificationSettingsViewController, nc = navigationController {
                
                notificationSettings.txtLocation = txtSubscriptionName.text
                notificationSettings.coordinate = annotation.coordinate
                notificationSettings.subscriptionKey = subscriptionKey
                
                nc.pushViewController(notificationSettings, animated: true)
            }
        }
    }
    
    
    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        
        
        if gestureReconizer.state == .Began {
            
            let touchPoint = gestureReconizer.locationInView(mapView)
            let location = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            addNewMarker(location)
            mapView.removeGestureRecognizer(longPressRecognizer)
            mapView.selectAnnotation(mapView.annotations[0], animated: true)
            
            
            requestGeocode(location) {
                self.txtSubscriptionName.text = $0
                self.presentHelpPopup()
            }
            
            nameLocationView.hidden = false
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == .Ending {
            if let annotation = view.annotation{
                requestGeocode(annotation.coordinate) {
                    self.txtSubscriptionName.text = $0
                    self.view.endEditing(true)
                }
            }
        }
    }
    
    
    func addNewMarker(location: CLLocationCoordinate2D){
        annotation = MKPointAnnotation()
        annotation!.coordinate = location
        annotation!.title = NSLocalizedString("HOLDDRAG", comment: "")
        annotation!.subtitle = NSLocalizedString("HOLDDRAGDESCRIPT", comment: "")
        
        
        
        var region = MKCoordinateRegion()
        region.center = location
        region.span.latitudeDelta = 0.05
        region.span.longitudeDelta = 0.05
        region = mapView.regionThatFits(region)
        
        mapView.setRegion(region, animated: true)
        mapView.addAnnotation(annotation!)
    }
    
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKPointAnnotation {
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myNotificationPin")
            
            pinAnnotationView.draggable = true
            pinAnnotationView.canShowCallout = true
            pinAnnotationView.animatesDrop = true
            
        
            
            return pinAnnotationView
        }
        
        return nil
    }
}

struct Directions: OptionSetType, CustomStringConvertible {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }
    init(angle: CGFloat) { self = Directions.number(Int(round(CGFloat(Directions.count)*angle/(2*π)))) }
    
    static let None = Directions(rawValue: 0)
    static let N = Directions(rawValue: 1)
    static let NW = Directions(rawValue: 2)
    static let W = Directions(rawValue: 4)
    static let SW = Directions(rawValue: 8)
    static let S = Directions(rawValue: 16)
    static let SE = Directions(rawValue: 32)
    static let E = Directions(rawValue: 64)
    static let NE = Directions(rawValue: 128)
    
    static let ordered: [Directions] = [.N, .NW, .W, .SW, .S, .SE, .E, .NE]
    static let count = Directions.ordered.count
    static func number(i: Int) -> Directions { return ordered[mod(i, 8)] }
    
    var angle: CGFloat { return CGFloat(index)*2*π/CGFloat(Directions.count) }
    
    var index: Int { return Directions.ordered.indexOf(self)! }
    
    var name: String { return ["N", "NW", "W", "SW", "S", "SE", "E", "NE"][index] }
    
    var description: String { return name }
    
    var local: String { return NSLocalizedString("DIRECTION_" + name, comment: "") }
}

func sectorBezierPath(total: Int) (direction: Directions) -> UIBezierPath {
    let phi = 2*π/CGFloat(total)
    let path = UIBezierPath()
    path.moveToPoint(CGPoint())
    path.addLineToPoint(CGPoint(r: 0.5, phi: -phi/2))
    path.addArcWithCenter(CGPoint(), radius: 0.5, startAngle: -phi/2, endAngle: phi/2, clockwise: true)
    path.closePath()
    
    path.applyTransform(Affine.rotation(-π/2 - CGFloat(direction.index)*phi))
    path.applyTransform(Affine.translation(0.5, 0.5))
    return path
}


@IBDesignable class DirectionSelector: UIControl {
    
    @IBInspectable var fontSize: CGFloat = 15
    
    
    enum State {
        case Adding, Removing, Default
    }
    
    let lineWidth: CGFloat = 1
    
    var selection: Directions = []
    let paths = Directions.ordered.map(sectorBezierPath(Directions.count))
    var laidOut = false
    var touchState = State.Default
    var areas : [String:Bool] = [:]
    
    override func layoutSubviews() {
        if laidOut { return }

        let scaling = Affine.scaling(frame.width - lineWidth, frame.height - lineWidth)
        let translation = Affine.translation(lineWidth/2, lineWidth/2)
        for path in paths {
            path.lineWidth = lineWidth
            path.applyTransform(scaling)
            path.applyTransform(translation)
        }
        
        laidOut = true
    }
    
    func updateSelection(direction: Directions) {
        
        if touchState == .Adding {
            selection.insert(direction)
            areas[direction.description] = true
        }
        else {
            selection.remove(direction)
            areas[direction.description] = nil
        }
        
        setNeedsDisplay()
    }
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        if let current = direction(at: touch.locationInView(self)) {
            touchState = selection.contains(current) ? .Removing : .Adding
            updateSelection(current)

            return true
        }
        
        return false
    }
    
    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        if let current = direction(at: touch.locationInView(self)) {
            updateSelection(current)
        }
        
        return true
    }
    
    override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        touchState = .Default
    }
    
    func direction(at point: CGPoint) -> Directions? {
        if (point - bounds.center).polar.r > bounds.width/2 {
            return nil
        }
        return Directions(angle: -π/2 - (point - bounds.center).polar.phi)
    }
    
    override func drawRect(rect: CGRect) {
        for (i, direction) in Directions.ordered.enumerate() {
            UIColor.vaavudBlueColor().setStroke()
            UIColor.vaavudBlueColor().setFill()

            paths[i].stroke()
            
            let selected = selection.contains(direction)
            if selected {
                paths[i].fill()
            }

            drawlabel(direction, selected: selected)
        }
    }
    
    func drawlabel(direction: Directions, selected: Bool) {
        let color = selected ? UIColor.whiteColor() : UIColor.vaavudBlueColor()
        let font = UIFont(name: "Helvetica Neue", size: fontSize)!
        let attributes = [NSForegroundColorAttributeName : color, NSFontAttributeName : font]
        
        let size = direction.local.sizeWithAttributes(attributes)
        direction.local.drawAtPoint(bounds.center + CGPoint(r: 0.35*bounds.width, phi: -π/2 - direction.angle) - 0.5*size.point, withAttributes: attributes)
    }
}
