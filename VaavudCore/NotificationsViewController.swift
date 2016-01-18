//
//  NotificationsViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 05/10/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import Firebase

let notificationsWindspeedCeiling: Float = 30

enum NotificationType: Int {
    case None = 0
    case Measurements = 1
    case Both = 2
}

class NotificationsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var typeControl: UISegmentedControl!
    @IBOutlet weak var windspeedLabel: UILabel!
    @IBOutlet weak var windspeedSlider: UISlider!
    var locationManager = CLLocationManager()

    
    private let firebase = Firebase(url: firebaseUrl)
    private var windspeed: Float = 15
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
//        
        let ref = firebase.childByAppendingPath("subscription")
        ref.queryOrderedByChild("uid").queryEqualToValue(firebase.authData.uid).observeEventType(.ChildAdded, withBlock: { snapshot in
            
            guard let location = snapshot.value["location"] as? [String:Double] else {
                return
            }
            
            if let lat = location["lat"], lon = location["lon"] {
                
                let latlon = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let radius = snapshot.value["radius"] as! Float
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = latlon
                annotation.title = "Wind Directions"
                annotation.subtitle = "N, E, W, NE, NW"
                
                
                let circule = MKCircle(centerCoordinate: latlon, radius: CLLocationDistance(radius))
                
                self.mapView.addOverlay(circule)
                self.mapView.addAnnotation(annotation)
            }
        })

        
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKPointAnnotation {
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myNotificationPin")
            
            pinAnnotationView.pinColor = .Red
            //pinAnnotationView.draggable = true
            pinAnnotationView.canShowCallout = true
            pinAnnotationView.animatesDrop = true
            
            let deleteButton = UIButton(type: .Custom)
            
            deleteButton.frame.size.width = 44
            deleteButton.frame.size.height = 44
            deleteButton.backgroundColor = UIColor.redColor()
            deleteButton.addTarget(self, action: "buttonAction:", forControlEvents: .TouchUpInside)
            deleteButton.setImage(UIImage(named: "trash"), forState: .Normal)
            
            pinAnnotationView.leftCalloutAccessoryView = deleteButton
            pinAnnotationView.leftCalloutAccessoryView?.sizeToFit()
            
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
    
    
    func buttonAction(sender:UIButton){
        print("Button tapped")
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUI()
    }
    
    @IBAction func windspeedChanged(sender: UISlider) {
        windspeed = sender.value*notificationsWindspeedCeiling
        updateUI()
    }
    
    func updateUI() {
        windspeedLabel.text = VaavudFormatter.shared.formattedSpeed(windspeed)
        windspeedSlider.value = windspeed/notificationsWindspeedCeiling
        typeControl.selectedSegmentIndex = notificationType.rawValue
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

