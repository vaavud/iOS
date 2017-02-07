//
//  notificationSettingsViewController.swift
//  Vaavud
//
//  Created by Diego Galindo on 2/8/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import UIKit
import Firebase
import GeoFire

class NotificationSettingsViewController: UIViewController {

    var coordinate: CLLocationCoordinate2D?
    var txtLocation: String?
    var overlays: MKCircle!
    let firebase = FIRDatabase.database().reference()
    var subscriptionKey: String?
    
    @IBOutlet weak var lblSpeed: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var lblRadius: UILabel!
    @IBOutlet weak var direcitonSelector: DirectionSelector!
    @IBOutlet weak var lblLocation: UILabel!
    
    
    @IBOutlet weak var speedSlider: UISlider!
    @IBOutlet weak var radiusSlider: UISlider!
    var currentRadius: Float = 500.0
    private let logHelper = LogHelper(.NotificationDetails)
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        logHelper.ended()
        logHelper.log("settings")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logHelper.began()
        
        
        guard let latlon = coordinate else {
            fatalError()
        }
        
        lblLocation.text = txtLocation
        
        if let subscriptionKey = subscriptionKey {
            
            firebase.child("subscription").child(subscriptionKey).observeSingleEventOfType(.Value, withBlock: {data in
                
                guard let data = data.value else {
                    fatalError("Wrong information firebase")
                }
                
                guard let directions = data.value["directions"] as? [String:Bool], radius = data.value["radius"] as? Float, name = data.value["name"] as? String, windMin = data.value["windMin"] as? Float else {
                    fatalError("Wrong information firebase")
                }
                
                self.lblLocation.text = name
                self.txtLocation = name
                self.radiusSlider.value = radius
                self.speedSlider.value = windMin
                self.currentRadius = radius
                
                self.lblRadius.text = "\(Int(radius)) m"
                self.lblSpeed.text = "\(Int(windMin)) m/s"
                
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
                
                self.direcitonSelector.areas = directions
                self.direcitonSelector.selection = actualDirections
                self.direcitonSelector.setNeedsDisplay()
                
                
                self.overlays = MKCircle(centerCoordinate: latlon, radius: CLLocationDistance(radius))
                self.mapView.addOverlay(self.overlays)

            })
        }
        else {
            overlays = MKCircle(centerCoordinate: latlon, radius: CLLocationDistance(currentRadius))
            mapView.addOverlay(overlays)
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = latlon
        
        mapView.addAnnotation(annotation)
        
        let mapCamera = MKMapCamera(lookingAtCenterCoordinate: latlon, fromEyeCoordinate: latlon, eyeAltitude: 5000)
        mapView.setCamera(mapCamera, animated: true)
    }
    
    
    @IBAction func didChangeRadius(sender: UISlider) {
        if let coordinate = coordinate {
            mapView.removeOverlay(overlays)
            
            self.lblRadius.text = "\(Int(sender.value)) m"
            
            overlays = MKCircle(centerCoordinate: coordinate, radius: CLLocationDistance(sender.value))
            mapView.addOverlay(overlays)
            logHelper.increase()
        }
    }
    
    @IBAction func didChangeSpeed(sender: UISlider) {
        let plus = Int(sender.value) == 15 ? "+" : ""

        lblSpeed.text = "\(Int(sender.value))\(plus) m/s"
        logHelper.increase()
    }
    
    
    @IBAction func saveNewSubscription(sender: UIBarButtonItem) {
        guard let coor = coordinate else {
            fatalError("No location")
        }
        
        if let key = self.subscriptionKey {
            let data: [String:AnyObject] = ["radius": radiusSlider.value, "windMin": speedSlider.value, "directions": direcitonSelector.areas]
            firebase.child("subscription").child(key).updateChildValues(data)
        }
        else{
            
            let latlon = ["lat": coor.latitude, "lon": coor.longitude]
            
            let uid = FIRAuth.auth()?.currentUser?.uid
            
            
            let subscription = Subscription(uid: uid!, name: txtLocation!, radius: radiusSlider.value, windMin: speedSlider.value, location: latlon, directions: direcitonSelector.areas)
            
            let ref = firebase.child("subscription")
            let post = ref.childByAutoId()
            post.setValue(subscription.fireDict)
//            let subscriptionKey = post.key
            
            
//            let geoFireRef = firebase.childByAppendingPath("subscriptionGeo")
//            let geoFire = GeoFire(firebaseRef: geoFireRef)
//            geoFire.setLocation(CLLocation(latitude: coor.latitude , longitude: coor.longitude), forKey: subscriptionKey)
            logHelper.log("newNotification")
            
        }
        
        
        let preferences = NSUserDefaults.standardUserDefaults()
        if !preferences.boolForKey("FirstNotification") {
            preferences.setBool(true, forKey: "FirstNotification")
            preferences.setBool(true, forKey: "showFirstNotification")
            preferences.synchronize()
        }
        
        navigationController?.popToRootViewControllerAnimated(true)
    }

    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay);
        circleRenderer.strokeColor = .whiteColor()
        circleRenderer.fillColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        circleRenderer.lineWidth = 1.0
        return circleRenderer
    }
    
}
