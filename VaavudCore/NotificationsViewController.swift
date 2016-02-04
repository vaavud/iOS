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




class NotificationsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
//    @IBOutlet weak var typeControl: UISegmentedControl!
//    @IBOutlet weak var windspeedLabel: UILabel!
//    @IBOutlet weak var windspeedSlider: UISlider!
    var locationManager = CLLocationManager()
    var currentNotifications : [String:MKPointAnnotation] = [:]
    var currentCircleNotifications : [String:MKCircle] = [:]

    
    private let firebase = Firebase(url: firebaseUrl)
    private var windspeed: Double = 15
    private var notificationType: NotificationType = .Measurements
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        
//        self.locationManager.delegate = self
//        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        //self.locationManager.distanceFilter = 10
//        self.locationManager.requestWhenInUseAuthorization()
//        self.locationManager.startUpdatingLocation()
//
        
        
        let ref = firebase.childByAppendingPath("subscription")
        
        ref.queryOrderedByChild("uid")
            .queryEqualToValue(firebase.authData.uid)
            .observeEventType(.ChildRemoved, withBlock: { snapshot in
                
                if let marker = self.currentNotifications[snapshot.key], area = self.currentCircleNotifications[snapshot.key]{
                    self.mapView.removeOverlay(area)
                    self.mapView.removeAnnotation(marker)
                    self.currentNotifications[snapshot.key] = nil
                    self.currentCircleNotifications[snapshot.key] = nil
                    
                    
                }
            })
        
        
        
        ref.queryOrderedByChild("uid")
            .queryEqualToValue(firebase.authData.uid)
            .observeEventType(.ChildChanged, withBlock: { snapshot in
                
                guard let location = snapshot.value["location"] as? [String:Double] else {
                    return
                }
                
                if let lat = location["lat"], lon = location["lon"], radius = snapshot.value["radius"] as? Float, directions = snapshot.value["directions"] as? [String:Bool]{
                    let latlon = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    
                    if let marker = self.currentNotifications[snapshot.key], area = self.currentCircleNotifications[snapshot.key] {
                        
                        marker.coordinate = latlon
                        marker.subtitle = "\(Array(directions.keys))"
                        
                        self.mapView.removeOverlay(area)
                        let circule = MKCircle(centerCoordinate: latlon, radius: CLLocationDistance(radius))
                        self.currentCircleNotifications[snapshot.key] = circule
                        self.mapView.addOverlay(circule)
                        
                    }
                }
            })
        
        
        ref.queryOrderedByChild("uid")
            .queryEqualToValue(firebase.authData.uid)
            .observeEventType(.ChildAdded, withBlock: { snapshot in
            
            guard let location = snapshot.value["location"] as? [String:Double] else {
                return
            }
            
            if let lat = location["lat"], lon = location["lon"], radius = snapshot.value["radius"] as? Float,  directions = snapshot.value["directions"] as? [String:Bool] {
                
                let latlon = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                
                
                let annotation = NotificationAnnotation()
                annotation.coordinate = latlon
                annotation.title = "Wind Direction(s)"
                annotation.subtitle = "\(Array(directions.keys))"
                annotation.sessionKey = snapshot.key
                
                let circule = MKCircle(centerCoordinate: latlon, radius: CLLocationDistance(radius))
                
                
                self.currentNotifications[snapshot.key] = annotation
                self.currentCircleNotifications[snapshot.key] = circule
                
                self.mapView.addOverlay(circule)
                self.mapView.addAnnotation(annotation)
            }
        })
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? NotificationAnnotation {
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myNotificationPin")
            
            pinAnnotationView.pinColor = .Red
            //pinAnnotationView.draggable = true
            pinAnnotationView.canShowCallout = true
            pinAnnotationView.animatesDrop = true
            
            let deleteButton = ButtonWithSessionKey(type: .Custom)
            
            deleteButton.sessionKey = annotation.sessionKey
            deleteButton.frame.size.width = 44
            deleteButton.frame.size.height = 44
            deleteButton.backgroundColor = UIColor.redColor()
            deleteButton.addTarget(self, action: "btnDelete:", forControlEvents: .TouchUpInside)
            deleteButton.setImage(UIImage(named: "trash"), forState: .Normal)
            
            pinAnnotationView.leftCalloutAccessoryView = deleteButton
            pinAnnotationView.leftCalloutAccessoryView?.sizeToFit()
            
            
            let forwardButton = ButtonWithSessionKey(type: .Custom)
            forwardButton.frame.size.width = 44
            forwardButton.frame.size.height = 44
            forwardButton.addTarget(self, action: "btnEdit:", forControlEvents: .TouchUpInside)
            forwardButton.setImage(UIImage(named: "arrow"), forState: .Normal)
            forwardButton.sessionKey = annotation.sessionKey
            
            pinAnnotationView.rightCalloutAccessoryView = forwardButton
            
            
            return pinAnnotationView
        }
        
        return nil
    }
    
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay);
        circleRenderer.strokeColor = .blueColor()
        circleRenderer.fillColor = UIColor(red: 0.0, green: 0.0, blue: 0.7, alpha: 0.5)
        circleRenderer.lineWidth = 1.0
        return circleRenderer
    }
    
    
    func btnEdit(sender:ButtonWithSessionKey) {
        
        if let notificationDetails = storyboard?.instantiateViewControllerWithIdentifier("NotificationDetailsViewController") as? NotificationDetailsViewController,
            navigationController = navigationController {
                
                notificationDetails.sessionKey = sender.sessionKey
                notificationDetails.isItEditing = true
                navigationController.pushViewController(notificationDetails, animated: true)
        }
    }
    
    
    
    @IBAction func newNotification() {
        
        if let notificationDetails = storyboard?.instantiateViewControllerWithIdentifier("NotificationDetailsViewController") as? NotificationDetailsViewController,
            navigationController = navigationController {
                navigationController.pushViewController(notificationDetails, animated: true)
        }
    }
    
    
    func btnDelete(sender:ButtonWithSessionKey){
        
        if let subscriptionKey = sender.sessionKey {
            firebase.childByAppendingPaths("subscription",subscriptionKey).removeValue()
            firebase.childByAppendingPaths("subscriptionGeo",subscriptionKey).removeValue()
        }
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUI()
    }
    
    @IBAction func windspeedChanged(sender: UISlider) {
        windspeed = Double(sender.value)*notificationsWindspeedCeiling
        updateUI()
    }
    
    func updateUI() {
//        windspeedLabel.text = VaavudFormatter.shared.formattedSpeed(windspeed)
//        windspeedSlider.value = Float(windspeed/notificationsWindspeedCeiling)
//        typeControl.selectedSegmentIndex = notificationType.rawValue
    }
    
    @IBAction func typeChanged(sender: UISegmentedControl) {
        notificationType = NotificationType(rawValue: sender.selectedSegmentIndex) ?? NotificationType.None
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        
        print("locations = \(locValue.latitude) \(locValue.longitude)")
    }
    
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("locations = \(error)")
    }
    
    
}

