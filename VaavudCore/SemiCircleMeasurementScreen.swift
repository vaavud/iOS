//
//  SemiCircleMeasurementScreen.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 12/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class CircularMeasurementViewController : UIViewController, VaavudElectronicWindDelegate {
    @IBOutlet weak var ruler: CircularRuler!
    @IBOutlet weak var speedLabel: UILabel!
    
    private var displayLink: CADisplayLink!
    private var latestHeading: CGFloat = 0
    private var latestWindDirection: CGFloat = 0
    private var latestSpeed: CGFloat = 0
    
    @IBOutlet weak var debugLabel: UILabel!
    
    func updateDebugLabel() {
        debugLabel.text = NSString(format: "Heading: %.1f\nLocal: %.1f", latestHeading, latestWindDirection - latestHeading) as String
    }
    
    var interval: CGFloat = 30
    
    var weight: CGFloat = 0.1
    
    let sdk = VEVaavudElectronicSDK.sharedVaavudElectronic()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayLink = CADisplayLink(target: self, selector: Selector("tick:"))
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        
//        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "changeOffset:"))
        
        sdk.addListener(self)
        sdk.start()
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.rawValue)
    }
    
    deinit {
        sdk.stop()
        displayLink.invalidate()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func tick(link: CADisplayLink) {
        ruler.compassDirection = weight*latestHeading + (1 - weight)*ruler.compassDirection
        ruler.windDirection = weight*latestWindDirection + (1 - weight)*ruler.windDirection
        ruler.windSpeed = weight*latestSpeed + (1 - weight)*ruler.windSpeed
        //
        //        gauge.complete += CGFloat(link.duration)/interval
    }
    
    // MARK: SDK Callbacks
    func newWindDirection(windDirection: NSNumber!) {
        latestWindDirection += distanceOnCircle(from: latestWindDirection, to: CGFloat(windDirection.floatValue))
        
        updateDebugLabel()
    }
    
    func newSpeed(speed: NSNumber!) {
        speedLabel.text = NSString(format: "%.1f", speed.floatValue) as String
        latestSpeed = CGFloat(speed.floatValue)
    }
    
    func newHeading(heading: NSNumber!) {
        if !lockNorth {
            latestHeading += distanceOnCircle(from: latestHeading, to: CGFloat(heading.floatValue))
        }
        
        updateDebugLabel()
    }
    
    @IBOutlet weak var label: UILabel!
    
    var lockNorth = false
    
    @IBAction func lockNorthChanged(sender: UISwitch) {
        lockNorth = sender.on
        
        if lockNorth {
            latestHeading = 0
        }
    }
    
    func changeOffset(sender: UIPanGestureRecognizer) {
        let y = sender.locationInView(view).y
        let x = view.bounds.midX - sender.locationInView(view).x
        let dx = sender.translationInView(view).x/3
        let dy = sender.translationInView(view).y/2
        
        if y < 20 {
            weight = max(0.01, weight + sender.translationInView(view).x/1000)
            label.text = NSString(format: "%.2f", weight) as String
        }
        else if y < 120 {
            newHeading(latestHeading - dx)
            label.text = NSString(format: "%.0f", latestHeading) as String
        }
        else {
            newWindDirection(latestWindDirection + dx)
            label.text = NSString(format: "%.0f", latestWindDirection) as String
            newSpeed(max(0, latestSpeed - dy/10))
        }
        
        sender.setTranslation(CGPoint(), inView: view)
    }
    
    @IBAction func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

class CircularRuler : UIView {
    var compassDirection: CGFloat = 0 { didSet { setNeedsDisplay() } }
    var windDirection: CGFloat = 0 { didSet { setNeedsDisplay() } }
    var windSpeed: CGFloat = 0 { didSet { setNeedsDisplay() } }

    private let tickLength: CGFloat = 20
    private let tickWidth: CGFloat = 2
    private var visibleMarkers = 150
    
    private let cardinalDirections = 16
    
    private var font = UIFont(name: "BebasNeueRegular", size: 20)!
    private var markers = [Polar]()
    
//    required init(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//    }
    
    override func drawRect(rect: CGRect) {
        let cardinalAngle = 360/CGFloat(cardinalDirections)
        
//        let fromCardinal = Int(ceil((compassDirection - 180)/cardinalAngle))
//        let toCardinal = Int(floor((compassDirection + 180)/cardinalAngle))

        let fromCardinal = 0
        let toCardinal = cardinalDirections - 1

        let path = UIBezierPath()
        
        let innerRadius: CGFloat = 70
        let origin = bounds.center
        
        for cardinal in fromCardinal...toCardinal {
            if cardinal % 2 != 0 {
                continue
            }
            
            let phi = (CGFloat(cardinal)*cardinalAngle - compassDirection - 90).radians
            
//            path.moveToPoint(origin + CGPoint(r: innerRadius, phi: phi))
//            path.addLineToPoint(origin + CGPoint(r: innerRadius + tickLength, phi: phi))
            
            let direction = mod(cardinal, cardinalDirections)
            let text = VaavudFormatter.localizedCardinal(direction)
            let p = origin + CGPoint(r: innerRadius + 2*tickLength, phi: phi)

            let blackColor = direction % 4 == 0 ? UIColor.blackColor() : UIColor.lightGrayColor()
            let color = direction == 0 ? UIColor.redColor() : blackColor
            
            drawLabel(text, at: p, color: color)
        }
        
//        UIColor.darkGrayColor().setStroke()
//        path.lineWidth = tickWidth
//        path.stroke()
        
        let contextRef = UIGraphicsGetCurrentContext()
        CGContextSetRGBFillColor(contextRef, 0, 0, 0, 1);
        let rect = CGRect(center: origin, size: CGSize(width: 2, height: 2))
        CGContextFillEllipseInRect(contextRef, rect)

        newMarker(Polar(r: windSpeed, phi: windDirection.radians))
        drawMarkers(markers, rotation: compassDirection.radians)
    }
    
    func newMarker(polar: Polar) {
        markers.append(polar)
        if markers.count > visibleMarkers {
            markers.removeAtIndex(0)
        }
    }
    
    func drawMarkers(ms: [Polar], rotation: CGFloat) {
        let radius: CGFloat = 3
        let origin = CGPoint(x: bounds.midX, y: bounds.midY)
        let offset = CGPoint(x: -radius, y: -radius)
        let size = CGSize(width: 2*radius, height: 2*radius)
        
        let contextRef = UIGraphicsGetCurrentContext()
        
        for (i, m) in enumerate(ms) {
            let age = 1 - CGFloat(i)/CGFloat(visibleMarkers)
            let gray = 0.5 + 0.5*age
            CGContextSetRGBFillColor(contextRef, gray, gray, gray, 1);

            let corner = origin + CGPoint(r: 10*m.r, phi: m.phi - rotation - π/2) + offset
            let rect = CGRect(origin: corner, size: size)
            CGContextFillEllipseInRect(contextRef, CGRect(origin: corner, size: size))
        }
        
        if let m = ms.last {
            CGContextSetRGBFillColor(contextRef, 1, 0, 0, 1);
        
            let corner = origin + CGPoint(r: 10*m.r, phi: m.phi - rotation - π/2) + offset
            let rect = CGRect(origin: corner, size: size)
            CGContextFillEllipseInRect(contextRef, CGRect(origin: corner, size: size))
        }
    }
    
    func drawLabel(string: String, at p: CGPoint, color: UIColor) {
        let text: NSString = string
        
        let attributes = [NSForegroundColorAttributeName : color, NSFontAttributeName : font]
        
        let size = text.sizeWithAttributes(attributes)
        let origin = CGPoint(x: p.x - size.width/2, y: p.y - size.height/2)
        
        text.drawInRect(CGRect(origin: origin, size: size), withAttributes: attributes)
    }
}

class TimeGauge2 : UIView {
    var complete: CGFloat = 0.0 { didSet { setNeedsDisplay() } }
    var backColor = UIColor(red: CGFloat(228)/255, green: CGFloat(231)/255, blue: CGFloat(232)/255, alpha: 1)
    var completeColor = UIColor.vaavudBlueColor()
    
    private var border: CGFloat = 14
    private var width: CGFloat = 15
    
    override func drawRect(rect: CGRect) {
        let outline = CGRectInset(bounds, border + width/2, border + width/2)
        let mid = CGPoint(x: outline.midX, y: outline.midY)
        
        backColor.setStroke()
        let backPath = UIBezierPath(ovalInRect: outline)
        backPath.lineWidth = width
        backPath.stroke()
        
        completeColor.setStroke()
        let completePath = UIBezierPath(arcCenter: mid, radius: outline.width/2, startAngle: -π/2, endAngle: 2*π*complete - π/2, clockwise: true)
        completePath.lineWidth = width
        completePath.lineCapStyle = kCGLineCapRound
        completePath.stroke()
    }
}

