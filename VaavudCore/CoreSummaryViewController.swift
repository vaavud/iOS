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
    var animator: UIDynamicAnimator!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var averageLabel: UILabel!
    @IBOutlet weak var maximumLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var averageUnitLabel: UILabel!
    @IBOutlet weak var maximumUnitLabel: UILabel!
    
    @IBOutlet weak var directionView: ArrowView!
    @IBOutlet weak var directionButton: UIButton!
    
    @IBOutlet weak var pressureLabel: UILabel!
    @IBOutlet weak var pressureUnitLabel: UILabel!
    
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var temperatureUnitLabel: UILabel!
    
    @IBOutlet weak var windchillLabel: UILabel!
    @IBOutlet weak var windchillUnitLabel: UILabel!
    
    @IBOutlet weak var gustinessLabel: UILabel!
    @IBOutlet weak var gustinessUnitLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var pressureView: PressureView!
    var pressureItem: DynamicReadingItem!
    @IBOutlet weak var temperatureView: TemperatureView!
    var temperatureItem: DynamicReadingItem!
    @IBOutlet weak var windchillView: WindchillView!
    var windchillItem: DynamicReadingItem!
    @IBOutlet weak var gustinessView: GustinessView!
    var gustinessItem: DynamicReadingItem!
    
    let formatter = VaavudFormatter()
    var session: MeasurementSession?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
    }
    
    override func viewDidLoad() {
        animator = UIDynamicAnimator(referenceView: view)
        pressureItem = DynamicReadingItem(readingView: pressureView)
        temperatureItem = DynamicReadingItem(readingView: temperatureView)
        windchillItem = DynamicReadingItem(readingView: windchillView)
        gustinessItem = DynamicReadingItem(readingView: gustinessView)
        
        setupMapView()
        setupUI()
    }
    
    func setupMapView() {
        if let session = session {
            if session.latitude == nil || session.longitude == nil {
                return
            }
            
            let coord = CLLocationCoordinate2D(latitude: session.latitude.doubleValue, longitude: session.longitude.doubleValue)
            mapView.setRegion(MKCoordinateRegionMakeWithDistance(coord, 500, 500), animated: false)
        }
    }
    
    func setupUI() {
        if let session = session {
            if let date = formatter.localizedTitleDate(session.startTime) {
                dateLabel.text = date.uppercaseString
            }
            
            locationLabel.text = session.geoLocationNameLocalized
            
            if let rotation = session.windDirection?.floatValue {
                directionView.transform = CGAffineTransformMakeRotation(π*CGFloat(1 + rotation/180))
            }
            
            updateWindSpeeds(session)
            updateWindDirection(session)
            updatePressure(session)
            updateTemperature(session)
            updateGustiness(session)
        }
    }
    
    @IBAction func tappedWindDirection(sender: UIButton) {
        formatter.directionUnit = formatter.directionUnit.next
        updateWindDirection(session!)
    }
    
    @IBAction func tappedPressure(sender: AnyObject) {
        animator.removeAllBehaviors()
        snap(pressureItem, to: CGFloat(arc4random() % 100))

        formatter.pressureUnit = formatter.pressureUnit.next
        updatePressure(session!)
    }
    
    @IBAction func tappedTemperature(sender: AnyObject) {
        animator.removeAllBehaviors()
        snap(temperatureItem, to: CGFloat(arc4random() % 100))
        snap(windchillItem, to: CGFloat(arc4random() % 100))

        formatter.temperatureUnit = formatter.temperatureUnit.next
        updateTemperature(session!)
    }
    
    @IBAction func tappedWindSpeed(sender: AnyObject) {
        formatter.windSpeedUnit = formatter.windSpeedUnit.next
        updateWindSpeeds(session!)
    }
    
    @IBAction func tappedGustiness(sender: AnyObject) {
        formatter.windSpeedUnit = formatter.windSpeedUnit.next
        updateWindSpeeds(session!)

        animator.removeAllBehaviors()
        gustinessItem.center = CGPoint()
        
        snap(gustinessItem, to: 1000)
    }
    
    func updateWindSpeeds(ms: MeasurementSession) {
        averageUnitLabel.text = formatter.windSpeedUnit.localizedString
        averageLabel.text = formatter.localizedWindspeed(ms.windSpeedAvg?.floatValue)

        maximumUnitLabel.text = formatter.windSpeedUnit.localizedString
        maximumLabel.text = formatter.localizedWindspeed(ms.windSpeedMax?.floatValue)
    }
    
    func updateWindDirection(ms: MeasurementSession) {
        if let direction = formatter.localizedDirection(ms.windDirection?.floatValue ?? ms.sourcedWindDirection?.floatValue) {
            directionButton.setTitle(direction, forState: .Normal)
        }
    }

    func updatePressure(ms: MeasurementSession) {
        pressureUnitLabel.text = formatter.pressureUnit.localizedString

        if let pressure = formatter.localizedPressure(ms.pressure?.floatValue ?? ms.sourcedPressureGroundLevel?.floatValue) {
            pressureLabel.text = pressure
        }
    }
    
    func updateTemperature(ms: MeasurementSession) {
        temperatureUnitLabel.text = formatter.temperatureUnit.localizedString
        windchillUnitLabel.text = formatter.temperatureUnit.localizedString
        
        if let temperature = formatter.localizedTemperature(ms.temperature?.floatValue ?? ms.sourcedTemperature?.floatValue) {
            temperatureLabel.text = temperature
        }
        if let windChill = formatter.localizedWindchill(ms.windChill?.floatValue) {
            windchillLabel.text = windChill
        }
    }
    
    func updateGustiness(ms: MeasurementSession) {
        if let gustiness = formatter.formattedGustiness(ms.gustiness?.floatValue) {
            gustinessLabel.text = gustiness
        }
    }
    
    @IBAction func tapped(sender: AnyObject) {
        animator.removeAllBehaviors()
        gustinessItem.center = CGPoint()
        
        snap(pressureItem, to: CGFloat(arc4random() % 100))
        snap(temperatureItem, to: CGFloat(arc4random() % 100))
        snap(windchillItem, to: CGFloat(arc4random() % 100))
        snap(gustinessItem, to: 1000)
    }
    
    func snap(item: DynamicReadingItem, to x: CGFloat) {
        animator.addBehavior(UISnapBehavior(item: item, snapToPoint: CGPoint(x: x, y: 0)))
    }
}
