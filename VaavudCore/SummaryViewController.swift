//
//  SummaryViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 22/01/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Social
import Firebase
import Mixpanel

class SummaryViewController: UIViewController, MKMapViewDelegate {
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
    
    @IBOutlet weak var shareHolder: GradientView!
    @IBOutlet weak var shareHolderHeight: NSLayoutConstraint!
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var isHistorySummary = false
    
    private var logGroup: LogGroup!
    private var logHelper: LogHelper!
    
    private var hasSomeDirection: Float?
    private var hasActualDirection = false
    private var isShowingDirection = false
    private var hasWindSpeed = false
    private var hasTemperature = false
    private var hasPressure = false
    private var hasGustiness = false
    private var hasWindChill = false
    
    private var formatterHandle: String!
    
    private var animator: UIDynamicAnimator!
    var session: Session!
    
    // MARK: Lifetime methods
    
    override func viewDidLoad() {
        hideVolumeHUD()
        
        logGroup = isHistorySummary ? .Summary : .Result
        logHelper = LogHelper(logGroup)

//        if Property.isMixpanelEnabled() {
//            Mixpanel.sharedInstance().track("Summary Screen")
//        }

        animator = UIDynamicAnimator(referenceView: view)
        pressureItem = DynamicReadingItem(readingView: pressureView)
        temperatureItem = DynamicReadingItem(readingView: temperatureView)
        windchillItem = DynamicReadingItem(readingView: windchillView)
        gustinessItem = DynamicReadingItem(readingView: gustinessView)
        
        title = VaavudFormatter.shared.localizedTitleDate(session.timeStart).uppercaseStringWithLocale(NSLocale.currentLocale())
        
        formatterHandle = VaavudFormatter.shared.observeUnitChange { [unowned self] in self.unitsChanged() }
        
        setupMapView()
        setupUI()
        updateUI()
        updateLocalUI()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionUpdated:", name: KEY_SESSION_UPDATED, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !Property.getAsBoolean(KEY_SHARE_OVERLAY_SHOWN, defaultValue: false), let tbc = tabBarController {
            Property.setAsBoolean(true, forKey: KEY_SHARE_OVERLAY_SHOWN)
            let p = Interface.choose((0.915, 0.09), (0.915, 0.075), (0.925, 0.065), (0.925, 0.06), (0.957, 0.043), (0.97, 0.053))
            let pos = CGPoint(x: p.0, y: p.1)
            let text = NSLocalizedString("SUMMARY_SHARE_OVERLAY", comment: "")
            let icon = UIImage(named: "SummaryShareOverlay")
            tbc.view.addSubview(RadialOverlay(frame: tbc.view.bounds, position: pos, text: text, icon: icon, radius: 75))
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        shareHolder.hidden = isHistorySummary
        logHelper.began()
        
        if !isShowingDirection {
            logHelper.log("Showed-Sleipnir-CTA")
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        logHelper.ended()
    }
    
//    override func viewDidDisappear(animated: Bool) {
//        if Property.isMixpanelEnabled() {
//            Mixpanel.sharedInstance().track("Summary Screen - Disappear")
//        }
//    }

    deinit {
        VaavudFormatter.shared.stopObserving(formatterHandle)
    }
    
    // MARK: Setup methods
    
    private func setupMapView() {
        guard let location = session.location else {
            mapView.alpha = 0.5
            mapView.userInteractionEnabled = false
            return
        }
        
        locationOnMap = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lon)
        mapView.setRegion(MKCoordinateRegionMakeWithDistance(locationOnMap, 500, 500), animated: false)
        mapView.addAnnotation(MeasurementAnnotation(location: locationOnMap, windDirection: session.windDirection))
    }

    private func setupUI() {
        averageLabel.font = averageLabel.font.fontWithSize(Interface.choose(65, 70, 80, 100, 200, 200))
        maximumLabel.font = maximumLabel.font.fontWithSize(Interface.choose(40, 50, 60, 75, 150, 150))
    }
    
    private func setupGeoLocation() {
        if session.location == nil {
            locationLabel.alpha = 0.3
            locationLabel.text = NSLocalizedString("GEOLOCATION_UNKNOWN", comment: "")
        }
        else if let geoName = session.location?.name {
            locationLabel.alpha = 1
            locationLabel.text = geoName
        }
        else {
            locationLabel.alpha = 0.3
            locationLabel.text = NSLocalizedString("GEOLOCATION_LOADING", comment: "")
        }
    }

    // MARK: Update methods

    private func updateUI() {
        setupGeoLocation()
        setupWindDirection()
        
        updateWindSpeeds()
        updatePressure()
        updateTemperature()
        updateGustiness()
    }

    private func updateLocalUI() {
        if let time = VaavudFormatter.shared.localizedTime(session.timeStart) {
            dateLabel.text = time.uppercaseString
        }
    }
    
    private func updateMapView() {
        if let annotation = mapView.annotations.first as? MeasurementAnnotation, view = mapView.viewForAnnotation(annotation) {
            updateMapAnnotationLabel(view)
        }
    }

    // MARK: Event handling
    
    func sessionUpdated(note: NSNotification) {
        if let objectId = note.userInfo?["objectID"] as? NSManagedObjectID where objectId == session.key {
            updateUI()
        }
    }

    func unitsChanged() {
        updateUI()
        updateMapView()
    }
    
    // MARK: User actions
    
    @IBAction func tappedDone(sender: AnyObject) {
        dismissViewControllerAnimated(true) {
        }
    }
    
    @IBAction func tappedShare(sender: AnyObject) {
        logHelper.log("Tapped-Share")
        let group = logGroup
        
        let frame: CGRect
        let size: CGSize
        
        if isHistorySummary {
            frame = view.bounds.moveY(-topLayoutGuide.length)
            size = view.bounds.size.expandY(-topLayoutGuide.length)
        }
        else {
            frame = view.bounds
            size = view.bounds.size
            shareHolder.hidden = true
        }
        
        defer { self.shareHolder.hidden = self.isHistorySummary }
        
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        
        view.drawViewHierarchyInRect(frame, afterScreenUpdates: true)
        guard let snap = UIImagePNGRepresentation(UIGraphicsGetImageFromCurrentImageContext()) else { return }
        UIGraphicsEndImageContext()

        let windSpeed = VaavudFormatter.shared.localizedSpeed(session.windMean) // fixme: should it be optional?
//        guard let windSpeed = session.windMean.map(VaavudFormatter.shared.localizedSpeed) else {
//            return
//        }
        
        var text = NSLocalizedString("I just measured ", comment: "")
        text += windSpeed + " " + VaavudFormatter.shared.speedUnit.localizedString
        
        if let place = session.location?.name  {
            text += " " + NSLocalizedString("at", comment: "Location preposition") + " " + place
        }
        text += NSLocalizedString(" with my Vaavud windmeter! #VaavudWeather\n", comment: "")
        
        //            let website = NSURL(string: "http://www.vaavud.com/")!
        //            let activityVC = UIActivityViewController(activityItems: [snap, text, website], applicationActivities: nil)
        
        let activityVC = UIActivityViewController(activityItems: [snap, text], applicationActivities: nil)
        activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
        if let senderItem = sender as? UIBarButtonItem {
            activityVC.popoverPresentationController?.barButtonItem = senderItem
        }
        else if let senderButton = sender as? UIButton {
            activityVC.popoverPresentationController?.sourceView = senderButton
        }
        
        activityVC.completionWithItemsHandler = { (type, completed, returnedItems, error) in
            var properties: [String : AnyObject] = ["completed" : completed]
            
            if let type = type { properties["activity"] = type }
            if let error = error { properties["error"] = error }
            
            LogHelper.log(group, event: "Shared", properties: properties)
            if completed {
                LogHelper.increaseUserProperty("Share-Count")
            }
            
            if Property.isMixpanelEnabled() {
                Mixpanel.sharedInstance().track("User shared", properties: properties)
            }
        }
        presentViewController(activityVC, animated: true) {
            if Property.isMixpanelEnabled() {
                Mixpanel.sharedInstance().track("Showed share sheet")
            }
        }
    }
    
    func logUnitChange(unitType: String) {
        LogHelper.log(event: "Changed-Unit", properties: ["place" : "summary", "type" : unitType])
    }
    
    @IBAction func tappedWindDirection(sender: AnyObject) {
        if let rotation = hasSomeDirection {
            VaavudFormatter.shared.directionUnit = VaavudFormatter.shared.directionUnit.next
            updateWindDirection(rotation)
            logUnitChange("direction")
        }
    }
    
    @IBAction func tappedPressure(sender: AnyObject) {
        if hasPressure {
            animator.removeAllBehaviors()
            snap(pressureItem, to: CGFloat(arc4random() % 100))
            
            VaavudFormatter.shared.pressureUnit = VaavudFormatter.shared.pressureUnit.next
            updatePressure()
            logUnitChange("pressure")
        }
    }
    
    @IBAction func tappedTemperature(sender: AnyObject) {
        if hasTemperature {
            animator.removeAllBehaviors()
            snap(windchillItem, to: CGFloat(arc4random() % 100))
            snap(temperatureItem, to: CGFloat(arc4random() % 100))
            
            VaavudFormatter.shared.temperatureUnit = VaavudFormatter.shared.temperatureUnit.next
            updateTemperature()
            logUnitChange("temperature")
        }
    }
    
    @IBAction func tappedWindchill(sender: AnyObject) {
        if hasWindChill {
            animator.removeAllBehaviors()
            snap(windchillItem, to: CGFloat(arc4random() % 100))
            snap(temperatureItem, to: CGFloat(arc4random() % 100))
            
            VaavudFormatter.shared.temperatureUnit = VaavudFormatter.shared.temperatureUnit.next
            updateTemperature()
            logUnitChange("temperature")
        }
    }
    
    @IBAction func tappedWindSpeed(sender: AnyObject) {
        if hasWindSpeed {
            VaavudFormatter.shared.speedUnit = VaavudFormatter.shared.speedUnit.next
            updateWindSpeeds()
            updateMapView()
            logUnitChange("speed")
        }
    }
    
    @IBAction func tappedGustiness(sender: AnyObject) {
        if hasGustiness {
            animator.removeAllBehaviors()
            gustinessItem.center = CGPoint()
            snap(gustinessItem, to: 1000)
        }
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
        UIView.animateWithDuration(0.2, delay: 2, options: [], animations: { self.showDirection() }, completion: { (Bool) -> Void in
            self.isShowingDirection = true
        })
    }
    
    @IBAction private func tappedSleipnir(sender: AnyObject) {
        logHelper.log("Tapped-Sleipnir-CTA")

        let source = logGroup.rawValue
        VaavudInteractions().showLocalAlert("SUMMARY_MEASURE_WINDDIRECTION",
            messageKey: "SUMMARY_WITH_SLEIPNIR_WINDDIRECTION",
            cancelKey: "BUTTON_CANCEL",
            otherKey: "SUMMARY_READ_MORE",
            action: { VaavudInteractions.openBuySleipnir(source) },
            on: self)
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    private func updateWindDirection(rotation: Float) {
        directionButton.setTitle(VaavudFormatter.shared.localizedDirection(rotation), forState: .Normal)
    }
    
    private func setupWindDirection() {
        hasActualDirection = session.windDirection != nil
        hasSomeDirection = session.windDirection // FIXME: Temporary, will remove when we start sourcing directions
        
        if let rotation = hasSomeDirection {
            let t = CGAffineTransformMakeRotation(π*CGFloat(1 + rotation/180))
            UIView.animateWithDuration(0.3, delay: 0.2, options: [], animations: { self.directionView.transform = t }) { (done) -> Void in
                self.animateAll()
            }
            
            updateWindDirection(rotation)
            
            showDirection()
            isShowingDirection = true

            if !hasActualDirection {
                showAndHideSleipnir(5)
            }
        }
        else {
            showSleipnir()
            isShowingDirection = false
        }
    }
    
    private func localisedLabelTexts<U: Unit>(unit: U, value: Float?) -> (String?, String?) {
        guard let value = value else {
            return (nil, "-")
        }
        
        let text: String
        switch unit {
        case is SpeedUnit: text = VaavudFormatter.shared.localizedSpeed(value, digits: 1)
        case is DirectionUnit: text = VaavudFormatter.shared.localizedDirection(value)
        case is PressureUnit: text = VaavudFormatter.shared.localizedPressure(value)
        case is TemperatureUnit: text = VaavudFormatter.shared.localizedTemperature(value, digits: 1)
        default: fatalError("Unknown unit")
        }
        return (unit.localizedString, text)
    }
    
    private func updateWindSpeeds() {
//        hasWindSpeed = session.windMean != nil // fixme: check
        hasWindSpeed = true
        let unit = VaavudFormatter.shared.speedUnit
        (averageUnitLabel.text, averageLabel.text) = localisedLabelTexts(unit, value: session.windMean)
        (maximumUnitLabel.text, maximumLabel.text) = localisedLabelTexts(unit, value: session.windMax)
    }

    private func updatePressure() {
        let unit = VaavudFormatter.shared.pressureUnit
        let pressure = session.pressure ?? session.sourced?.pressure
        hasPressure = pressure != nil
        
        (pressureUnitLabel.text, pressureLabel.text) = localisedLabelTexts(unit, value: pressure)
    }
    
    private func updateTemperature() {
        let unit = VaavudFormatter.shared.temperatureUnit
        let temperature = session.temperature ?? session.sourced?.temperature
        hasTemperature = temperature != nil
        
        (temperatureUnitLabel.text, temperatureLabel.text) = localisedLabelTexts(unit, value: temperature)
        
        let chill = windchill(temperature, session.windMean)
        (windchillUnitLabel.text, windchillLabel.text) = localisedLabelTexts(unit, value: chill)
        
        hasWindChill = chill != nil
    }
    
    private func updateGustiness() {
        if let gustiness = session.turbulence {
            gustinessUnitLabel.text = "%"
            gustinessLabel.text = String(format: "%.0f", gustiness*100)
        }
        else {
            gustinessUnitLabel.text = nil
            gustinessLabel.text = "-"
        }
        
        hasGustiness = session.turbulence != nil
    }
    
    private func snap(item: DynamicReadingItem, to x: CGFloat) {
        animator.addBehavior(UISnapBehavior(item: item, snapToPoint: CGPoint(x: x, y: 0)))
    }
    
    // MARK: Map View Delegate
    
    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        activityIndicator.stopAnimating()
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? MeasurementAnnotation {
            let identifier = "MeasureAnnotationIdentifier"
            
            let annotationView: MKAnnotationView
            if let newAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) {
                annotationView = newAnnotationView
            }
            else {
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
    
    // MARK: Map convenience
    
    private func updateMapAnnotationLabel(annotationView: MKAnnotationView) {
        if let label = annotationView.viewWithTag(42) as? UILabel {
//            label.text = session.windMean.map { VaavudFormatter.shared.localizedSpeed($0, digits: 2) }
            label.text = VaavudFormatter.shared.localizedSpeed(session.windMean, digits: 2)
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
    
    // MARK: User interface convenience

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
    
    // MARK: Animation convenience
    
    private func animateAll() {
        print("Animate all")
        animator.removeAllBehaviors()
        gustinessItem.center = CGPoint()
        snap(pressureItem, to: CGFloat(arc4random() % 100))
        snap(temperatureItem, to: CGFloat(arc4random() % 100))
        snap(windchillItem, to: CGFloat(arc4random() % 100))
        snap(gustinessItem, to: 1000)
    }
}
