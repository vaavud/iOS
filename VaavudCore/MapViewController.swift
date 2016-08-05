//
//  MapViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 11/12/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import Foundation
import Firebase



class NewMeasurementAnnotation: NSObject, MKAnnotation {
    
    var location: CLLocationCoordinate2D
    let speed: Double
    let direction: Double?
    
    init(location: CLLocationCoordinate2D,speed: Double, direction: Double?) {
        self.speed = speed
        self.direction = direction
        self.location = location
    }
    
    var coordinate: CLLocationCoordinate2D {
        return location
    }
    
    var title: String? {
        return "12"
    }
}


class MeasurementAnnotationView: MKAnnotationView {
    
    let label = UILabel(frame: CGRectMake(0,0,48,48))
    let imageView = UIImageView()
    
    func finish() {
        self.addSubview(imageView)
        self.addSubview(label)
        self.frame = label.frame
    }
}


class NewMapViewController: UIViewController, MKMapViewDelegate {
    private let logHelper = LogHelper.init(groupName: "Map", counters: ["scrolled", "tapped-marker"])
    
    private var lastMeasurementsRead = NSDate.distantPast()
    private var hoursAgo = 24
    
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var hoursButton: UIButton!
    @IBOutlet private weak var unitButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    
    var measurementCalloutView: MeasurementCalloutView?
    
    
    
    // MARK: Lifetime

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
                // fixme: units
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        mapView.delegate = self
//        mapView.mapType = .Hybrid
//        
//        if (isDanish()) {
//            addLongPress()
//        }
//
//        setupFirebase()
    }
    
    deinit {
    }
    
    // MARK: Setup Firebase
    
    func setupFirebase() {
        let firebaseSession = Firebase(url: firebaseUrl)
        
        firebaseSession
            .childByAppendingPath("session")
            .queryOrderedByChild("timeStart")
            .queryStartingAtValue(NSDate(timeIntervalSinceNow: -24*60*60).ms)
            .observeEventType(.ChildAdded, withBlock: { snapshot in
                
                
                guard let _ = snapshot.value["timeEnd"] as? Double, location = snapshot.value["location"] as? [String: AnyObject], speed = snapshot.value["windMean"] as? Double  else{
                    return
                }
                
                if let lat = location["lat"] as? Double, lon = location["lon"] as? Double {
                    
                    let location = CLLocationCoordinate2D (
                        latitude: lat,
                        longitude: lon
                    )
                    
                    let direction = snapshot.value["windDirection"] as? Double
                    
                    let annotation = NewMeasurementAnnotation(location: location,speed: speed, direction: direction)
                    
//                    annotation.coordinate
//                    annotation.coordinate = location
//                    annotation.title = "Title"
//                    annotation.subtitle = "Sub Title"
                    
                    self.mapView.addAnnotation(annotation)
                    
                    
                    if let t = snapshot.value["timeStart"] as? Int {
                        print("Snapshot \( NSDate(ms: t))")
                    }
                }
            })
    }
    
    // MARK: Overrides
    
    // MARK: Map View Delegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        else if annotation is ForecastAnnotation {
            
        }
        else if let annotation = annotation as? NewMeasurementAnnotation {
            
            let identifier = "MeasureAnnotationIdentifier"
            
            guard let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MeasurementAnnotationView else {
                let annotationView = MeasurementAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView.opaque = false
                annotationView.canShowCallout = false
                
                annotationView.label.backgroundColor = .clearColor()
                annotationView.label.font = .systemFontOfSize(12)
                annotationView.label.textColor = .whiteColor()
                annotationView.label.textAlignment = .Center
                
                fillMarker(annotationView, speed: annotation.speed,direction: annotation.direction)
               
                return annotationView
            }
            
            dequeuedView.annotation = annotation
            fillMarker(dequeuedView, speed: annotation.speed,direction: annotation.direction)
            
            return dequeuedView
            
        }
        return nil
    }
    
    
    func fillMarker(marker: MeasurementAnnotationView, speed: Double, direction: Double?){
        
        if direction != nil{
            marker.imageView.image = UIImage(named: "MapMarkerDirection")
            marker.imageView.transform = CGAffineTransformIdentity
        }
        else {
            marker.imageView.image = UIImage(named: "MapMarker")
            marker.imageView.transform = CGAffineTransformIdentity
        }
        
        marker.imageView.sizeToFit()
        marker.label.text = "12"
        marker.finish()
    }
    
    
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        if let annotation = view.annotation as? MeasurementAnnotation {
            let height : CGFloat = 300.0
            
            let containerView = UIView(frame: CGRectMake(0, 0, 280, height))
            measurementCalloutView = MeasurementCalloutView(frame: CGRectMake(0, 0, 280, height))
            //measurementCalloutView!.mapViewController = self
            //measurementCalloutView.placeholderImage = self.placeholderImage;
            //measurementCalloutView.windSpeedUnit = self.windSpeedUnit;
            //measurementCalloutView.directionUnit = self.directionUnit;
            //measurementCalloutView.nearbyAnnotations = nearbyAnnotations;
            //measurementCalloutView!.measurementAnnotation = view.annotation
            containerView.addSubview(measurementCalloutView!)
            
            
//            mapView.calloutView.contentView = containerView;
//            self.mapView.calloutView.backgroundView = [CustomSMCalloutDrawnBackgroundView view];
//            [self.mapView.calloutView presentCalloutFromRect:view.bounds
//                        inView:view
//                        constrainedToView:mapView
//                        permittedArrowDirections:SMCalloutArrowDirectionDown
//                        animated:!self.isSelectingFromTableView];
            
        
        }
        
        
//        if ([view.annotation isKindOfClass:[MeasurementAnnotation class]]) {
//            NSArray *nearbyAnnotations;
//            
//            //NSLog(@"zoomLevel=%f", [self.mapView getZoomLevel]);
//            
//            if ([self.mapView getZoomLevel] <= 2) {
//                nearbyAnnotations = [NSArray array];
//            }
//            else {
//                nearbyAnnotations = [self findNearbyAnnotations:view.annotation];
//            }
//            
//            float height = 300.0;
//            if (nearbyAnnotations.count == 0) {
//                height = 112.0;
//            }
//            else if (nearbyAnnotations.count < 4) {
//                height -= (28.0 /* extra half cell to show you can scroll */ + (3 - nearbyAnnotations.count) * (ROW_HEIGHT));
//            }
//            
//            //NSLog(@"desired height=%f", height);
//            
//            UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, height)];
//            
//            NSArray* topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"MeasurementCalloutView" owner:self options:nil];
//            self.measurementCalloutView = (MeasurementCalloutView*) [topLevelObjects objectAtIndex:0];
//            self.measurementCalloutView.frame = CGRectMake(0, 0, 280, height);
//            self.measurementCalloutView.mapViewController = self;
//            self.measurementCalloutView.placeholderImage = self.placeholderImage;
//            self.measurementCalloutView.windSpeedUnit = self.windSpeedUnit;
//            self.measurementCalloutView.directionUnit = self.directionUnit;
//            self.measurementCalloutView.nearbyAnnotations = nearbyAnnotations;
//            self.measurementCalloutView.measurementAnnotation = view.annotation;
//            [containerView addSubview:self.measurementCalloutView];
//            
//            self.mapView.calloutView.contentView = containerView;
//            self.mapView.calloutView.backgroundView = [CustomSMCalloutDrawnBackgroundView view];
//            
//            [self.mapView.calloutView presentCalloutFromRect:view.bounds
//            inView:view
//            constrainedToView:mapView
//            permittedArrowDirections:SMCalloutArrowDirectionDown
//            animated:!self.isSelectingFromTableView];
//            
//        }
        
    }
    
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("selected 2")
    }

    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        logHelper.increase("scrolled")
    }
    
    // MARK: User Actions

    @IBAction func tappedUnit(sender: UIButton) {

    }
    
    @IBAction func tappedHours(sender: UIButton) {
        
    }
    
    // MARK: Updates

    func unitChanged() {
        refreshUnitButton()
        refreshAnnotations()
    }
    
    func refreshUnitButton() {
    }
    
    func refreshAnnotations() {
        
    }
    
    func refreshHours() {
        hoursButton.titleLabel?.text = "24"
    }
    
    // MARK: Convenience
    
    func addLongPress() {
//        mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: Selector("longPressed:")))
        logHelper.log("Can-Add-Forecast-Pin")
        LogHelper.increaseUserProperty("Use-Forecast-Count")
    }
    
    func isDanish() -> Bool {
        return NSLocale.preferredLanguages().first?.hasPrefix("da") ?? false
    }
    
}