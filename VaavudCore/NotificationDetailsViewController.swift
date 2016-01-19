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
    var windMin: Double
    var location: [String: Double]
    var directions: [String: Bool]
    let lastFired = [".sv": "timestamp"]
    var subscriptionKey: String?
    
    
    var fireDict : FirebaseDictionary {
        return ["directions" : directions, "location" : location, "radius" : radius, "uid" : uid, "windMin" :windMin, "lastFired" : lastFired]
    }
}


class NotificationDetailsViewController: UIViewController,MKMapViewDelegate,UIGestureRecognizerDelegate {
    
    @IBOutlet weak var directionSelector: DirectionSelector!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var radiusSlider: UISlider!
    
    
    let firebase = Firebase(url: firebaseUrl)
    var currentRadius : Float = 500.0
    var sessionKey: String?
    var isItEditing = false
    var currentSubscription: Subscription?
    
    
    let annotation = MKPointAnnotation()
    var overlays =  MKCircle()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        longPressRecognizer.minimumPressDuration = 0.3
        longPressRecognizer.delaysTouchesBegan = true
        longPressRecognizer.delegate = self
        mapView.addGestureRecognizer(longPressRecognizer)
        mapView.delegate = self
        
        radiusSlider.enabled = false
        
        
        if let sessionKey = sessionKey {
            firebase.childByAppendingPaths("subscription",sessionKey).observeSingleEventOfType(.Value, withBlock: { snapshot in
                
                if let location = snapshot.value["location"] as? [String:Double] ,
                    radius = snapshot.value["radius"] as? Float,
                    directions = snapshot.value["directions"] as? [String:Bool],
                    windMean = snapshot.value["windMin"] as? Double {
                    
                    if let lat = location["lat"], lon = location["lon"] {
                        
                        
                        self.currentSubscription = Subscription(uid: self.firebase.authData.uid, radius: radius, windMin: windMean, location: location, directions: directions, subscriptionKey: snapshot.key)
                        
                        print(Array(directions.keys))
                        
                        let latlon = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        
                        self.radiusSlider.value = radius
                        self.radiusSlider.enabled = true
                        self.currentRadius = radius
                        
                        self.addNewMarker(latlon)
                        
                    }
                }
            })
        }

    }
    
    @IBAction func buttonSave(sender: UIBarButtonItem) {
        
        
        guard var subscription = currentSubscription else {
            return
        }
        
        print(subscription.fireDict)

        if let subscriptionKey = subscription.subscriptionKey {
            
            let ref = firebase.childByAppendingPaths("subscription",subscriptionKey)
            ref.setValue(subscription.fireDict)
        }
        else{
            
            subscription.directions = directionSelector.areas
            
            let ref = firebase.childByAppendingPath("subscription")
            let post = ref.childByAutoId()
            post.setValue(subscription.fireDict)
            let subscriptionKey = post.key
            
            
            let geoFireRef = firebase.childByAppendingPath("subscriptionGeo")
            let geoFire = GeoFire(firebaseRef: geoFireRef)
            geoFire.setLocation(CLLocation(latitude: annotation.coordinate.latitude , longitude: annotation.coordinate.longitude), forKey: subscriptionKey)
            
                    
            print(subscriptionKey)
            print(subscription.fireDict)
            
        }
        
        navigationController?.popToRootViewControllerAnimated(true)
        
    }
    
    @IBAction func sliderValueChanged(sender: UISlider) {
        guard var _ = currentSubscription else {
            return
        }
        
        mapView.removeOverlay(overlays)
        
        overlays = MKCircle(centerCoordinate: annotation.coordinate, radius: CLLocationDistance(sender.value))
        mapView.addOverlay(overlays)
        
        currentRadius = sender.value
        currentSubscription?.radius = sender.value
        
    }
    
    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        
        
        if gestureReconizer.state == .Began {
            
            radiusSlider.enabled = true
            
            let touchPoint = gestureReconizer.locationInView(mapView)
            let location = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            let latlon = ["lat":location.latitude,"lon":location.longitude]
            currentSubscription = Subscription(uid: firebase.authData.uid, radius: currentRadius, windMin: 1, location: latlon, directions: directionSelector.areas, subscriptionKey: nil)
            
            addNewMarker(location)
        }
    }
    
    
    func addNewMarker(location: CLLocationCoordinate2D){
        //let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = "someting"
        annotation.subtitle = "something elee"
        
        overlays = MKCircle(centerCoordinate: location, radius: CLLocationDistance(currentRadius))
        
        
        var region = MKCoordinateRegion()
        region.center = location
        region.span.latitudeDelta = 0.05
        region.span.longitudeDelta = 0.05
        region = mapView.regionThatFits(region)
        
        
        
        mapView.setRegion(region, animated: true)
        mapView.addOverlay(overlays)
        mapView.addAnnotation(annotation)

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
    
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        guard var _ = currentSubscription else {
            return
        }
        
        if (newState == .Starting){
            mapView.removeOverlay(overlays)
        }
        
        if (newState == .Ending){
            
            if let annotation = view.annotation {
                let latlon = ["lat": annotation.coordinate.latitude,"lon": annotation.coordinate.longitude]
                currentSubscription?.location = latlon
                
                overlays = MKCircle(centerCoordinate: annotation.coordinate, radius: CLLocationDistance(currentRadius))
                mapView.addOverlay(overlays)
            }
        }
    }
    
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay);
        circleRenderer.strokeColor = .blueColor()
        circleRenderer.fillColor = UIColor(red: 0.0, green: 0.0, blue: 0.7, alpha: 0.5)
        circleRenderer.lineWidth = 1.0
        return circleRenderer
    }
}

struct Directions: OptionSetType, CustomStringConvertible {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }
    init(angle: CGFloat) { self = Directions.number(Int(round(CGFloat(Directions.count)*angle/(2*CGFloat(π))))) }
    
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
    
    var angle: CGFloat { return CGFloat(index)*2*CGFloat(π)/CGFloat(Directions.count) }
    
    var index: Int { return Directions.ordered.indexOf(self)! }
    
    var name: String { return ["N", "NW", "W", "SW", "S", "SE", "E", "NE"][index] }
    
    var description: String { return name }
    
    var local: String { return NSLocalizedString("DIRECTION_" + name, comment: "") }
}

func sectorBezierPath(total: Int)(direction: Directions) -> UIBezierPath {
    let phi = 2*CGFloat(π)/CGFloat(total)
    let path = UIBezierPath()
    path.moveToPoint(CGPoint())
    path.addLineToPoint(CGPoint(r: 0.5, phi: -phi/2))
    path.addArcWithCenter(CGPoint(), radius: 0.5, startAngle: -phi/2, endAngle: phi/2, clockwise: true)
    path.closePath()
    
    path.applyTransform(Affine.rotation(-CGFloat(π)/2 - CGFloat(direction.index)*phi))
    path.applyTransform(Affine.translation(0.5, 0.5))
    return path
}

class DirectionSelector: UIControl {
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
        return Directions(angle: -CGFloat(π)/2 - (point - bounds.center).polar.phi)
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
        let font = UIFont(name: "Helvetica Neue", size: 12)!
        let attributes = [NSForegroundColorAttributeName : color, NSFontAttributeName : font]
        
        let size = direction.local.sizeWithAttributes(attributes)
        direction.local.drawAtPoint(bounds.center + CGPoint(r: 0.35*bounds.width, phi: -π/2 - direction.angle) - 0.5*size.point, withAttributes: attributes)
    }
}
