//
//  MapMeasurementViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 19/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class MapMeasurementViewController: UIViewController, VaavudElectronicWindDelegate, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var speedLabel: UILabel!

    private var displayLink: CADisplayLink!
    private var latestHeading: CGFloat = 0
    private var latestWindDirection: CGFloat = 0
    private var latestSpeed: CGFloat = 0

    let sdk = VEVaavudElectronicSDK.sharedVaavudElectronic()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideVolumeHUD()

        displayLink = CADisplayLink(target: self, selector: Selector("tick:"))
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        
        sdk.addListener(self)
        sdk.start()
        
//        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "changeOffset:"))
        
        mapView.delegate = self
        
        LocationManager.sharedInstance().start()
        let latestLocation = LocationManager.sharedInstance().latestLocation
        
        println(latestLocation.latitude)
        
        if LocationManager.isCoordinateValid(latestLocation) {
            let region = MKCoordinateRegionMakeWithDistance(latestLocation, 200000, 200000)
            mapView.setRegion(region, animated: true)
        }
    }
 
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    deinit {
        sdk.stop()
        displayLink.invalidate()
    }
    
    @IBOutlet weak var label: UILabel!
    
    func changeOffset(sender: UIPanGestureRecognizer) {
        let y = sender.locationInView(view).y
        let x = view.bounds.midX - sender.locationInView(view).x
        let dx = sender.translationInView(view).x/3
        let dy = sender.translationInView(view).y/2
        
        if y < 20 {
//            weight = max(0.01, weight + sender.translationInView(view).x/1000)
//            label.text = NSString(format: "%.2f", weight) as String
        }
        else if y < 120 {
            newHeading(latestHeading - dx)
            label.text = NSString(format: "%.0f", latestHeading) as String
        }
        else {
            newWindDirection(latestWindDirection + dx)
            newSpeed(max(0, latestSpeed - dy/10))
            label.text = NSString(format: "%.0f", latestWindDirection) as String
        }
        
        sender.setTranslation(CGPoint(), inView: view)
    }
    
    func tick(link: CADisplayLink) {
//        ruler.compassDirection = weight*latestHeading + (1 - weight)*ruler.compassDirection
//        ruler.windDirection = weight*latestWindDirection + (1 - weight)*ruler.windDirection
//        ruler.tick()
//        
//        graph.reading = weight*latestSpeed + (1 - weight)*graph.reading
//        gauge.complete += CGFloat(link.duration)/interval
    }

    // MARK: SDK Callbacks
    func newWindDirection(windDirection: NSNumber!) {
        latestWindDirection += distanceOnCircle(from: latestWindDirection, to: CGFloat(windDirection.floatValue))
    }
    
    func newSpeed(speed: NSNumber!) {
        speedLabel.text = NSString(format: "%.1f", speed.floatValue) as String
        latestSpeed = CGFloat(speed.floatValue)
    }
    
    func newHeading(heading: NSNumber!) {
        latestHeading += distanceOnCircle(from: latestHeading, to: CGFloat(heading.floatValue))
    }

}