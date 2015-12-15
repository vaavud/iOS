//
//  MapViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 11/12/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import Foundation
import Firebase


class NewMapViewController: UIViewController, MKMapViewDelegate {
    private let logHelper = LogHelper.init(groupName: "Map", counters: ["scrolled", "tapped-marker"])
    
    private var lastMeasurementsRead = NSDate.distantPast()
    private var hoursAgo = 24
    
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var hoursButton: UIButton!
    @IBOutlet private weak var unitButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Lifetime

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "unitChanged", name: KEY_UNIT_CHANGED, object: nil)
        
        if (isDanish()) {
            addLongPress()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFirebase()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    // MARK: Setup Firebase
    
    func setupFirebase() {
        let firebaseSession = Firebase(url: "https://vaavud-core-demo.firebaseio.com/")
        
        let time = NSDate(timeIntervalSinceNow: -24*60*60).timeIntervalSince1970*1000
        
        firebaseSession
            .childByAppendingPath("session")
            .queryOrderedByChild("timeStart")
            .queryStartingAtValue(time)
            .observeEventType(.ChildAdded, withBlock: { snapshot in
                
                if let t = snapshot.value["timeStart"] as? Double {
                    print("Snapshot \( NSDate(timeIntervalSince1970: t/1000))")
                }
            })
    }
    
    // MARK: Overrides
    
    // MARK: Map View Delegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        else if let annotation = annotation as? ForecastAnnotation {
            
        }
        
        return nil
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    }

    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        logHelper.increase("scrolled")
    }
    
    // MARK: User Actions

    @IBAction private func dd() {
        
    }
    
    // MARK: Updates

    func unitChanged() {
        refreshUnitButton()
        refreshAnnotations()
    }
    
    func refreshUnitButton() {
        unitButton.titleLabel?.text = VaavudFormatter.shared.windSpeedUnit.localizedString
    }
    
    func refreshAnnotations() {
        
    }
    
    func refreshHours() {
        hoursButton.titleLabel?.text = "24"
    }
    
    // MARK: Convenience
    
    func addLongPress() {
        mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "longPressed:"))
        logHelper.log("Can-Add-Forecast-Pin")
        LogHelper.increaseUserProperty("Use-Forecast-Count")
    }
    
    func isDanish() -> Bool {
        return NSLocale.preferredLanguages().first?.hasPrefix("da") ?? false
    }
    
}