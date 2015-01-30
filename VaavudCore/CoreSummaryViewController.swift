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
    
    @IBOutlet weak var directionLabel: UIButton!
    
    @IBOutlet weak var pressureLabel: NSLayoutConstraint!
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
    
    var session: MeasurementSession?
    
//    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
//        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
//        println("nib")
//        setup()
//    }
//
//    required init(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        println("coder")
//        setup()
//    }
    
    override func viewDidLoad() {
        animator = UIDynamicAnimator(referenceView: view)
        pressureItem = DynamicReadingItem(readingView: pressureView)
        temperatureItem = DynamicReadingItem(readingView: temperatureView)
        windchillItem = DynamicReadingItem(readingView: windchillView)
        gustinessItem = DynamicReadingItem(readingView: gustinessView)
        
        setupMapView()
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

class DynamicReadingItem: NSObject, UIDynamicItem {
    let readingView: ReadingView
    var bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
    var center: CGPoint = CGPoint() { didSet { readingView.reading = center.x/100 } }
    var transform = CGAffineTransformIdentity
    
    init(readingView: ReadingView) {
        self.readingView = readingView
        super.init()
    }
}

class ReadingView: UIView {
    @IBInspectable var reading: CGFloat = 0.0 { didSet { setNeedsDisplay() } }
}

@IBDesignable class TemperatureView: ReadingView {
    override func drawRect(rect: CGRect) {
        VaavudStyle.drawVaavudTemperature(height: bounds.height, reading: reading)
    }
}

@IBDesignable class PressureView: ReadingView {
    override func drawRect(rect: CGRect) {
        VaavudStyle.drawVaavudPressure(height: bounds.height, reading: reading)
    }
}

@IBDesignable class WindchillView: ReadingView {
    override func drawRect(rect: CGRect) {
        VaavudStyle.drawVaavudWindchill(height: bounds.height, reading: reading)
    }
}

@IBDesignable class GustinessView: ReadingView {
    override func drawRect(rect: CGRect) {
        VaavudStyle.drawVaavudGustiness(height: bounds.height, reading: reading)
    }
}

class DynamicOffsetItem: NSObject, UIDynamicItem {
    let offsetView: OffsetView
    var bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
    var center: CGPoint = CGPoint() { didSet { offsetView.offsetX = center.x/100; offsetView.offsetY = center.y/100; } }
    var transform = CGAffineTransformIdentity
    
    init(offsetView: OffsetView) {
        self.offsetView = offsetView
        super.init()
    }
}

@IBDesignable class ArrowView: UIView {
    @IBInspectable var strokeWidth: CGFloat = 3.0 { didSet { setNeedsDisplay() } }
    @IBInspectable var strokeColor: UIColor = UIColor.blackColor() { didSet { setNeedsDisplay() } }
    
    override func drawRect(rect: CGRect) {
        let rect = CGRect(x: 0, y: 0, width: bounds.height, height: bounds.height)
        VaavudStyle.drawCompassArrow(frame: rect, strokeColor: strokeColor, strokeWidth: strokeWidth)
    }
}

class OffsetView: UIView {
    @IBInspectable var offsetX: CGFloat = 0.0 { didSet { setNeedsDisplay() } }
    @IBInspectable var offsetY: CGFloat = 0.0 { didSet { setNeedsDisplay() } }
}
