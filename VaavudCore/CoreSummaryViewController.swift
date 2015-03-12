//
//  CoreSummaryViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 22/01/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class CoreSummaryViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var averageLabel: UILabel!
    @IBOutlet private weak var maximumLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    
    @IBOutlet private weak var averageUnitLabel: UILabel!
    @IBOutlet private weak var maximumUnitLabel: UILabel!
    
    @IBOutlet private weak var sleipnirView: SleipnirView!
    @IBOutlet private weak var upsellLabel: UILabel!
    
    @IBOutlet private weak var directionView: ArrowView!
    @IBOutlet private weak var directionButton: UIButton!
    
    @IBOutlet private weak var pressureLabel: UILabel!
    @IBOutlet private weak var pressureUnitLabel: UILabel!
    
    @IBOutlet private weak var temperatureLabel: UILabel!
    @IBOutlet private weak var temperatureUnitLabel: UILabel!
    
    @IBOutlet private weak var windchillLabel: UILabel!
    @IBOutlet private weak var windchillUnitLabel: UILabel!
    
    @IBOutlet private weak var gustinessLabel: UILabel!
    @IBOutlet private weak var gustinessUnitLabel: UILabel!
    
    @IBOutlet private weak var mapView: MKMapView!
    var locationOnMap: CLLocationCoordinate2D!
    
    @IBOutlet private weak var pressureView: PressureView!
    private var pressureItem: DynamicReadingItem!
    @IBOutlet private weak var temperatureView: TemperatureView!
    private var temperatureItem: DynamicReadingItem!
    @IBOutlet private weak var windchillView: WindchillView!
    private var windchillItem: DynamicReadingItem!
    @IBOutlet private weak var gustinessView: GustinessView!
    private var gustinessItem: DynamicReadingItem!
    
    private var hasSomeDirection: Float? = nil
    private var hasActualDirection = false
    private var isShowingDirection = false
    private var hasWindSpeed = false
    private var hasTemperature = false
    private var hasPressure = false
    private var hasGustiness = false
    private var hasWindChill = false
    
    private var animator: UIDynamicAnimator!
    private var formatter = VaavudFormatter()
    var session: MeasurementSession!
    
    override func viewDidLoad() {
        hideVolumeHUD()
        
        if Property.isMixpanelEnabled() {
            Mixpanel.sharedInstance().track("Summary Screen")
        }
        
        animator = UIDynamicAnimator(referenceView: view)
        pressureItem = DynamicReadingItem(readingView: pressureView)
        temperatureItem = DynamicReadingItem(readingView: temperatureView)
        windchillItem = DynamicReadingItem(readingView: windchillView)
        gustinessItem = DynamicReadingItem(readingView: gustinessView)
        
        title = formatter.localizedTitleDate(session.startTime)?.uppercaseStringWithLocale(NSLocale.currentLocale())
        
        setupMapView()
        setupUI()
        updateUI()
        updateLocalUI()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "unitsChanged:", name: "UnitChange", object: nil)
    }

    func unitsChanged(note: NSNotification) {
        if note.object as? CoreSummaryViewController != self {
            updateUI()
            updateMapView(session)
        }
    }

    func postUnitChange() {
        NSNotificationCenter.defaultCenter().postNotificationName("UnitChange", object: self)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidDisappear(animated: Bool) {
        if Property.isMixpanelEnabled() {
            Mixpanel.sharedInstance().track("Summary Screen - Disappear")
        }
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if let annotation = annotation as? MeasurementAnnotation {
            let identifier = "MeasureAnnotationIdentifier"
            
            var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView.canShowCallout = false
                annotationView.opaque = false
                
                let imageView = UIImageView()
                imageView.tag = 101
                annotationView.addSubview(imageView)

                let label = UILabel(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
                label.backgroundColor = UIColor.clearColor()
                label.font = UIFont(name: "HelveticaNeue", size: 12)
                label.textColor = UIColor.whiteColor()
                label.textAlignment = .Center
                label.tag = 42
            
                annotationView.addSubview(label)
                annotationView.frame = label.frame
            
            }
            
            updateMapAnnotationLabel(annotationView)
            updateMapAnnotationImage(annotationView)

            return annotationView
        }
        
        return nil
    }
    
    private func updateMapAnnotationLabel(annotationView: MKAnnotationView) {
        if let label = annotationView.viewWithTag(42) as? UILabel {
            label.text = formatter.localizedWindspeed(session.windSpeedAvg?.floatValue, digits: 2)
        }
    }
    
    private func updateMapAnnotationImage(annotationView: MKAnnotationView) {
        if let imageView = annotationView.viewWithTag(101) as? UIImageView {
            if let direction = session.windDirection {
                imageView.image = UIImage(named:"MapMarkerDirection")
                imageView.sizeToFit()
                imageView.transform = UnitUtil.transformForDirection(direction)
            }
            else {
                imageView.image = UIImage(named:"MapMarker")
                imageView.sizeToFit()
                imageView.transform = CGAffineTransformIdentity
            }
        }
    }
    
    private func setupMapView() {
        if session.latitude == nil || session.longitude == nil {
            mapView.alpha = 0.5
            mapView.userInteractionEnabled = false
            return
        }
        
        locationOnMap = CLLocationCoordinate2D(latitude: session.latitude.doubleValue, longitude: session.longitude.doubleValue)
        mapView.setRegion(MKCoordinateRegionMakeWithDistance(locationOnMap, 500, 500), animated: false)
        mapView.addAnnotation(MeasurementAnnotation(location: locationOnMap, windDirection: session.windDirection))
    }
    
    private func updateMapView(ms: MeasurementSession) {
        if let annotation = mapView.annotations.first as? MeasurementAnnotation {
            updateMapAnnotationLabel(mapView.viewForAnnotation(annotation))
        }
    }
    
    private func setupUI() {
        if view.bounds.width > 375 {
            averageLabel.font = averageLabel.font.fontWithSize(85)
            maximumLabel.font = maximumLabel.font.fontWithSize(60)
        }
        else if view.bounds.width > 320 {
            averageLabel.font = averageLabel.font.fontWithSize(72)
            maximumLabel.font = maximumLabel.font.fontWithSize(50)
        }
    }
    
    private func updateUI() {
        setupGeoLocation(session)
        setupWindDirection(session)
        
        updateWindSpeeds(session)
        updatePressure(session)
        updateTemperature(session)
        updateGustiness(session)
    }
    
    private func setupGeoLocation(ms: MeasurementSession) {
        if (ms.latitude == nil || ms.longitude == nil) {
            locationLabel.alpha = 0.3
            locationLabel.text = NSLocalizedString("GEOLOCATION_UNKNOWN", comment: "")
        }
        else if let geoName = ms.geoLocationNameLocalized {
            locationLabel.alpha = 1
            locationLabel.text = geoName
        }
        else {
            locationLabel.alpha = 0.3
            locationLabel.text = NSLocalizedString("GEOLOCATION_LOADING", comment: "")
        }
    }

    private func updateLocalUI() {
        if let time = formatter.localizedTime(session.startTime) {
            dateLabel.text = time.uppercaseString
        }
    }
    
    private func showSleipnir() {
        sleipnirView.alpha = 1
        upsellLabel.alpha = 1
        directionView.alpha = 0
        directionButton.alpha = 0
    }
    
    private func showDirection() {
        sleipnirView.alpha = 0
        upsellLabel.alpha = 0
        directionView.alpha = 1
        directionButton.alpha = 1
    }
    
    @IBAction private func tappedCompass(sender: AnyObject) {
        if isShowingDirection {
            if !hasActualDirection {
                showAndHideSleipnir()
            }
            else if hasSomeDirection != nil {
                tappedWindDirection(sender)
            }
        }
        else {
            tappedSleipnir(sender)
        }
    }
    
    private func showAndHideSleipnir(delay: Double = 4) {
        isShowingDirection = false
        UIView.animateWithDuration(0.2)  { self.showSleipnir() }
        UIView.animateWithDuration(0.2, delay: 2, options: nil, animations: { self.showDirection() }, completion: { (Bool) -> Void in
            self.isShowingDirection = true
        })
    }
    
    @IBAction private func tappedSleipnir(sender: AnyObject) {
        VaavudInteractions().showLocalAlert("SUMMARY_MEASURE_WINDDIRECTION",
            messageKey: "SUMMARY_WITH_SLEIPNIR_WINDDIRECTION",
            otherKey: "INTRO_UPGRADE_CTA_BUY",
            action: { VaavudInteractions.openBuySleipnir("Summary") },
            on: self)
    }
    
//    @IBAction func tappedShare(sender: AnyObject) {
//        if let windSpeed = formatter.localizedWindspeed(session.windSpeedAvg?.floatValue) {
//            let textToShare = "I just measured " + windSpeed + " " + formatter.windSpeedUnit.localizedString
//            if let myWebsite = NSURL(string: "http://www.vaavud.com/") {
//                let objectsToShare = [textToShare, myWebsite]
//                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
//                activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
//                
//                self.presentViewController(activityVC, animated: true, completion: nil)
//            }
//        }
//    }
    
    @IBAction func tappedWindDirection(sender: AnyObject) {
        if let rotation = hasSomeDirection {
            formatter.directionUnit = formatter.directionUnit.next
            postUnitChange()
            updateWindDirection(rotation)
        }
    }
    
    @IBAction func tappedPressure(sender: AnyObject) {
        if hasPressure {
            animator.removeAllBehaviors()
            snap(pressureItem, to: CGFloat(arc4random() % 100))
            
            formatter.pressureUnit = formatter.pressureUnit.next
            postUnitChange()
            updatePressure(session)
        }
    }

    @IBAction func tappedTemperature(sender: AnyObject) {
        if hasTemperature {
            animator.removeAllBehaviors()
            snap(windchillItem, to: CGFloat(arc4random() % 100))
            snap(temperatureItem, to: CGFloat(arc4random() % 100))
            
            formatter.temperatureUnit = formatter.temperatureUnit.next
            postUnitChange()
            updateTemperature(session)
        }
    }
    
    @IBAction func tappedWindchill(sender: AnyObject) {
        if hasWindChill {
            animator.removeAllBehaviors()
            snap(windchillItem, to: CGFloat(arc4random() % 100))
            snap(temperatureItem, to: CGFloat(arc4random() % 100))

            formatter.temperatureUnit = formatter.temperatureUnit.next
            postUnitChange()
            updateTemperature(session)
        }
    }
    
    @IBAction func tappedWindSpeed(sender: AnyObject) {
        if hasWindSpeed {
            formatter.windSpeedUnit = formatter.windSpeedUnit.next
            postUnitChange()
            updateWindSpeeds(session)
            updateMapView(session)
        }
    }
    
    @IBAction func tappedGustiness(sender: AnyObject) {
        if hasGustiness {
            animator.removeAllBehaviors()
            gustinessItem.center = CGPoint()
            snap(gustinessItem, to: 1000)
        }
    }
    
    private func animateAll() {
        animator.removeAllBehaviors()
        gustinessItem.center = CGPoint()
        snap(pressureItem, to: CGFloat(arc4random() % 100))
        snap(temperatureItem, to: CGFloat(arc4random() % 100))
        snap(windchillItem, to: CGFloat(arc4random() % 100))
        snap(gustinessItem, to: 1000)
    }
    
    private func updateWindDirection(rotation: Float) {
        directionButton.setTitle(formatter.localizedDirection(rotation), forState: .Normal)
    }
    
    private func setupWindDirection(ms: MeasurementSession) {
        hasActualDirection = session.windDirection != nil

        hasSomeDirection = (session.windDirection ?? session.sourcedWindDirection)?.floatValue
        hasSomeDirection = session.windDirection?.floatValue // FIXME: Temporary, will remove when we start sourcing directions
        
        if let rotation = hasSomeDirection {
            switch UIDevice.currentDevice().systemVersion.compare("8.0.0", options: NSStringCompareOptions.NumericSearch) {
            case .OrderedSame, .OrderedDescending:
                let t = CGAffineTransformMakeRotation(π*CGFloat(1 + rotation/180))
                UIView.animateWithDuration(0.3, delay: 0.2, options: nil, animations: { self.directionView.transform = t }, completion: { (done) -> Void in
                    self.animateAll()
                })
            case .OrderedAscending:
                let tt = CATransform3DMakeRotation(π*CGFloat(1 + rotation/180), 0, 0, 1)
                
                let anim = CABasicAnimation(keyPath: "transform")
                anim.duration = 0.5
                anim.removedOnCompletion = false
                anim.fillMode = kCAFillModeForwards
                CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
                
                CATransaction.setCompletionBlock{ self.animateAll() }
                anim.fromValue = NSValue(CATransform3D:CATransform3DIdentity)
                anim.toValue = NSValue(CATransform3D:tt)
                directionView.layer.addAnimation(anim, forKey: "")
            }
            
            updateWindDirection(rotation)
            
            showDirection()
            isShowingDirection = true

            if !hasActualDirection {
                showAndHideSleipnir(delay: 5)
            }
        }
        else {
            showSleipnir()
            isShowingDirection = false
        }
    }
    
    private func updateWindSpeeds(ms: MeasurementSession) {
        hasWindSpeed = formatter.updateAverageWindspeedLabels(ms, valueLabel: averageLabel, unitLabel: averageUnitLabel)
        formatter.updateMaxWindspeedLabels(ms, valueLabel: maximumLabel, unitLabel: maximumUnitLabel)
    }

    private func updatePressure(ms: MeasurementSession) {
        hasPressure = formatter.updatePressureLabels(ms, valueLabel: pressureLabel, unitLabel: pressureUnitLabel)
    }
    
    private func updateTemperature(ms: MeasurementSession) {
        hasTemperature = formatter.updateTemperatureLabels(ms, valueLabel: temperatureLabel, unitLabel: temperatureUnitLabel)
        hasWindChill = formatter.updateWindchillLabels(ms, valueLabel: windchillLabel, unitLabel: windchillUnitLabel)
    }
    
    private func updateGustiness(ms: MeasurementSession) {
        hasGustiness = formatter.updateGustinessLabels(ms, valueLabel: gustinessLabel, unitLabel: gustinessUnitLabel)
    }
    
    private func snap(item: DynamicReadingItem, to x: CGFloat) {
        animator.addBehavior(UISnapBehavior(item: item, snapToPoint: CGPoint(x: x, y: 0)))
    }
}
