//
//  CoreSummaryViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 22/01/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import Foundation
import UIKit

class CoreSummaryViewController: UIViewController {
    var animator: UIDynamicAnimator!
    
    @IBOutlet weak var pressureView: PressureView!
    var pressureItem: DynamicReadingItem!
    @IBOutlet weak var temperatureView: TemperatureView!
    var temperatureItem: DynamicReadingItem!
    @IBOutlet weak var windchillView: WindchillView!
    var windchillItem: DynamicReadingItem!
    @IBOutlet weak var gustinessView: GustinessView!
    var gustinessItem: DynamicReadingItem!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        println("nib")
        setup()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        println("coder")
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
    }
    
    @IBAction func tapped(sender: AnyObject) {
        animator.removeAllBehaviors()
        snap(pressureItem, to: CGFloat(arc4random() % 100))
        snap(temperatureItem, to: CGFloat(arc4random() % 100))
        snap(windchillItem, to: CGFloat(arc4random() % 100))
        snap(gustinessItem, to: CGFloat(arc4random() % 100))
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
