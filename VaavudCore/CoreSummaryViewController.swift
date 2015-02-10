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

class CoreSummaryViewController: UIViewController, MKMapViewDelegate, UIAlertViewDelegate {
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
    
    // <--- To be removed when storyboard is localized
    
    @IBOutlet weak var averageHeadingLabel: UILabel!
    @IBOutlet weak var maxHeadingLabel: UILabel!
    @IBOutlet weak var pressureHeadingLabel: UILabel!
    @IBOutlet weak var temperatureHeadingLabel: UILabel!
    @IBOutlet weak var windchillHeadingLabel: UILabel!
    @IBOutlet weak var gustinessHeadingLabel: UILabel!
    
    @IBOutlet weak var northLabel: UIButton!
    @IBOutlet weak var southLabel: UIButton!
    @IBOutlet weak var eastLabel: UIButton!
    @IBOutlet weak var westLabel: UIButton!
    
    // To be removed when storyboard is localized --->

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
        setupLocalUI()
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
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: 38, height: 38))
                label.backgroundColor = UIColor.clearColor()
                label.font = UIFont(name: "HelveticaNeue", size: 12)
                label.textColor = UIColor.whiteColor()
                label.textAlignment = .Center
                label.tag = 42
            
                annotationView.addSubview(label)
                annotationView.frame = label.frame
            
                if session.windDirection != nil {
                    annotationView.image = UIImage(named: UnitUtil.mapImageNameForDirection(session.windDirection))
                }
                else {
                    annotationView.image = UIImage(named:"mapmarker_no_direction.png")
                }
            }
            
            updateMapAnnotationLabel(annotationView)
            
            return annotationView
        }
        
        return nil
    }
    
    private func updateMapAnnotationLabel(annotationView: MKAnnotationView) {
        if let label = annotationView.viewWithTag(42) as? UILabel {
            label.text = formatter.localizedWindspeed(session.windSpeedAvg?.floatValue, digits: 2)
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
        if let time = formatter.localizedTime(session.startTime) {
            dateLabel.text = time.uppercaseString
        }
        
        if view.bounds.width > 375 {
            averageLabel.font = averageLabel.font.fontWithSize(85)
            maximumLabel.font = maximumLabel.font.fontWithSize(60)
        }
        else if view.bounds.width > 320 {
            averageLabel.font = averageLabel.font.fontWithSize(72)
            maximumLabel.font = maximumLabel.font.fontWithSize(50)
        }
        
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

    private func setupLocalUI() {
        northLabel.setTitle(formatter.localizedNorth, forState: .Normal)
        southLabel.setTitle(formatter.localizedSouth, forState: .Normal)
        eastLabel.setTitle(formatter.localizedEast, forState: .Normal)
        westLabel.setTitle(formatter.localizedWest, forState: .Normal)

        upsellLabel.text = NSLocalizedString("SUMMARY_UPSELL", comment: "")
        
        pressureHeadingLabel.text = NSLocalizedString("SUMMARY_PRESSURE", comment: "").uppercaseString
        temperatureHeadingLabel.text = NSLocalizedString("SUMMARY_TEMPERATURE", comment: "").uppercaseString
        windchillHeadingLabel.text = NSLocalizedString("SUMMARY_WIND_CHILL", comment: "").uppercaseString
        gustinessHeadingLabel.text = NSLocalizedString("SUMMARY_GUSTINESS", comment: "").uppercaseString

        maxHeadingLabel.text = NSLocalizedString("HEADING_MAX", comment: "").uppercaseString
        averageHeadingLabel.text = NSLocalizedString("HEADING_AVERAGE", comment: "").uppercaseString
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
        println("tapped compass")
        if isShowingDirection {
            println("showing compass")
            if !hasActualDirection {
                showAndHideSleipnir()
            }
            else if hasSomeDirection != nil {
                tappedWindDirection(sender)
            }
        }
        else {
            println("not showing compass")
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
        let title = NSLocalizedString("SUMMARY_MEASURE_WINDDIRECTION", comment: "")
        let message = NSLocalizedString("SUMMARY_WITH_SLEIPNIR_WINDDIRECTION", comment: "")
        let cancel = NSLocalizedString("BUTTON_CANCEL", comment: "")
        let other = NSLocalizedString("INTRO_UPGRADE_CTA_BUY", comment: "")
        showAlert(title, message: message, cancel: cancel, other: other)
    }
    
    func showAlert(title: String, message: String, cancel: String, other: String) {
        if objc_getClass("UIAlertController") == nil {
            let alert = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancel, otherButtonTitles: other)
            alert.tag = 1
            alert.show()
        }
        else {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: cancel, style: .Cancel, handler: { (action) -> Void in }))
            alert.addAction(UIAlertAction(title: other, style: .Default, handler: { (action) -> Void in VaavudInteractions.openBuySleipnir() }))
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == 1 {
            if buttonIndex == 1 {
                VaavudInteractions.openBuySleipnir()
            }
        }
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
            updateWindDirection(rotation)
        }
    }
    
    @IBAction func tappedPressure(sender: AnyObject) {
        if hasPressure {
            animator.removeAllBehaviors()
            snap(pressureItem, to: CGFloat(arc4random() % 100))
            
            formatter.pressureUnit = formatter.pressureUnit.next
            updatePressure(session)
        }
    }

    @IBAction func tappedTemperature(sender: AnyObject) {
        if hasTemperature {
            animator.removeAllBehaviors()
            snap(windchillItem, to: CGFloat(arc4random() % 100))
            snap(temperatureItem, to: CGFloat(arc4random() % 100))
            
            formatter.temperatureUnit = formatter.temperatureUnit.next
            updateTemperature(session)
        }
    }
    
    @IBAction func tappedWindchill(sender: AnyObject) {
        if hasWindChill {
            animator.removeAllBehaviors()
            snap(windchillItem, to: CGFloat(arc4random() % 100))
            snap(temperatureItem, to: CGFloat(arc4random() % 100))

            formatter.temperatureUnit = formatter.temperatureUnit.next
            updateTemperature(session)
        }
    }
    
    @IBAction func tappedWindSpeed(sender: AnyObject) {
        if hasWindSpeed {
            formatter.windSpeedUnit = formatter.windSpeedUnit.next
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
