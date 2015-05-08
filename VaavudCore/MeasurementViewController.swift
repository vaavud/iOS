//
//  MeasurementViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 04/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class Ruler : UIView {
    var compassDirection: CGFloat = 0 { didSet { setNeedsDisplay() } }
    var windDirection: CGFloat = 0 { didSet { setNeedsDisplay() } }
    var pointsPerTick: CGFloat = 15
    
    private let shortTickLength: CGFloat = 18
    private let longTickLength: CGFloat = 36
    
    private let longTickPeriod = 10

    private let cardinalPeriod = 45
    private let cardinalMajorPeriod = 90

    private let tickWidth: CGFloat = 1

    override func drawRect(rect: CGRect) {
        let padding: CGFloat = 30
        let halfWidth = bounds.width/2 + padding

        let fromTick = Int(ceil(compassDirection - halfWidth/pointsPerTick))
        let toTick = Int(floor(compassDirection + halfWidth/pointsPerTick))
        
        let path = UIBezierPath()
        
        for halfTick in 2*fromTick...2*toTick {
            let tick = (halfTick/2 % 360 + 360) % 360
            let x = pointsPerTick*(CGFloat(halfTick)/2 - compassDirection) + halfWidth - padding

            let isTick = halfTick % 2 == 0
            let isLongTick = halfTick % longTickPeriod == 0
            let isMajorCardinal = halfTick % cardinalMajorPeriod == 0
            
            let y = isLongTick ? longTickLength : shortTickLength
            
            if isTick {
                path.moveToPoint(CGPoint(x: x, y: 0))
                path.addLineToPoint(CGPoint(x: x, y: y))
            }
            
            let p = CGPoint(x: x, y: y + 10)
            if halfTick % cardinalPeriod == 0 {
                drawLabel(VaavudFormatter.localizedCardinal(Float(tick)), at: p, red: tick == 0, small: !isMajorCardinal)
            }
            else if isLongTick {
                drawLabel(NSString(format: "%d°", tick) as String, at: p, isDegree: true)
            }
        }
        
        UIColor.vaavudDarkGreyColor().setStroke()
        path.lineWidth = tickWidth
        path.stroke()
        
        drawNeedle(pointsPerTick*(windDirection - compassDirection) + halfWidth - padding)
    }
    
    func drawNeedle(var x: CGFloat) {
        let base: CGFloat = 20
        let height: CGFloat = 35
        
        let outside = x - base/2 < 0 || x + base/2 > bounds.width
        
        if outside {
            x = min(max(x, base/2), bounds.width - base/2)
        }
        
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: x, y: height))
        path.addLineToPoint(CGPoint(x: x - base/2, y: 0))
        path.addLineToPoint(CGPoint(x: x + base/2, y: 0))
        path.closePath()
        
        if outside {
            UIColor.vaavudRedColor().setStroke()
            path.lineWidth = 2
            path.stroke()
        }
        else {
            UIColor.vaavudRedColor().setFill()
            path.fill()
        }
    }
    
    func drawLabel(string: String, at p: CGPoint, isDegree: Bool = false, red: Bool = false, small: Bool = false) {
        let s: NSString = string
        let alignmentString = isDegree ? s.substringWithRange(NSRange(location: 0, length: s.length - 1)) : s
        
        let fieldColor = red ? UIColor.vaavudRedColor() : UIColor.darkGrayColor()
        
        let fieldFont = UIFont(name: "BebasNeueRegular", size: small ? 20 : 33)!
        let attributes = [NSForegroundColorAttributeName : fieldColor, NSFontAttributeName : fieldFont]
        let offset = alignmentString.sizeWithAttributes(attributes).width/2
        let size = s.sizeWithAttributes(attributes)
        let origin = CGPoint(x: p.x - offset, y: p.y)

        s.drawInRect(CGRect(origin: origin, size: size), withAttributes: attributes)
    }
}

class Graph : UIView {
    var lowY: CGFloat = 0
    var highY: CGFloat = 50
    var n = 100

    var readings = [CGFloat()]
    var reading: CGFloat = 0 { didSet { addReading(reading) } }
    
    let lineWidth: CGFloat = 5
    let lineColor = UIColor.vaavudBlueColor()
    let upperColor = UIColor(red: CGFloat(153)/255, green: CGFloat(217)/255, blue: CGFloat(243)/255, alpha: 1)
    let lowerColor = UIColor(red: CGFloat(242)/255, green: CGFloat(250)/255, blue: CGFloat(253)/255, alpha: 1)
    
    func addReading(value: CGFloat) {
        readings.append(value)
        setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        func yValue(reading: CGFloat) -> CGFloat {
            return bounds.height*(highY - reading)/(highY - lowY) - lineWidth/2
        }
        
        func xValue(i: Int) -> CGFloat {
            return bounds.width*CGFloat(i + n - readings.count)/CGFloat(n - 1)
        }
        
        lineColor.setStroke()
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        
        let iEnd = readings.count
        let iStart = max(iEnd - n, 0)

        path.moveToPoint(CGPoint(x: 0, y: yValue(readings[iStart])))
        
        for i in (iStart + 1)..<iEnd {
            path.addLineToPoint(CGPoint(x: xValue(i), y: yValue(readings[i])))
        }
        path.stroke()
        
//        let clippingPath = path.copy() as! UIBezierPath
//        clippingPath.addLineToPoint(CGPoint(x: bounds.maxX, y: bounds.maxY))
//        clippingPath.addLineToPoint(CGPoint(x: bounds.minX, y: bounds.maxY))
//        clippingPath.closePath()
//        clippingPath.addClip()
//        
//        let context = UIGraphicsGetCurrentContext()
//        let colors = [lowerColor.CGColor, upperColor.CGColor]
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let colorLocations: [CGFloat] = [0, 1]
//        let gradient = CGGradientCreateWithColors(colorSpace, colors, colorLocations)
//        let startPoint = CGPoint(x:0, y:bounds.height)
//        let endPoint = CGPoint()
//        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0)
    }
}

class TimeGauge : UIView {
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

class MeasurementViewController : UIViewController, VaavudElectronicWindDelegate {
    @IBOutlet weak var ruler: Ruler!
    @IBOutlet weak var gauge: TimeGauge!
    @IBOutlet weak var graph: Graph!
    
    @IBOutlet weak var speedLabel: UILabel!
    
    private var displayLink: CADisplayLink!
    private var latestHeading: CGFloat = 0
    private var latestWindDirection: CGFloat = 0
    private var latestSpeed: CGFloat = 0
    
    var interval: CGFloat = 30
    
    var weight: CGFloat = 0.1
    
    let sdk = VEVaavudElectronicSDK.sharedVaavudElectronic()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayLink = CADisplayLink(target: self, selector: Selector("tick:"))
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)

        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "changeOffset:"))

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
        graph.reading = weight*latestSpeed + (1 - weight)*graph.reading
        
        gauge.complete += CGFloat(link.duration)/interval
    }
    
    func slowTick() {
        
    }
    
    // MARK: SDK Callbacks
    func newWindDirection(windDirection: NSNumber!) {
        latestWindDirection = closestOnCircle(CGFloat(windDirection.floatValue), to:latestWindDirection)
    }
    
    func newSpeed(speed: NSNumber!) {
        speedLabel.text = NSString(format: "%.1f", speed.floatValue) as String
        latestSpeed = CGFloat(speed.floatValue)
    }
    
    func newHeading(heading: NSNumber!) {
        latestHeading = closestOnCircle(CGFloat(heading.floatValue), to:latestHeading)
    }
    
    @IBOutlet weak var label: UILabel!
    
    func changeOffset(sender: UIPanGestureRecognizer) {
        let y = sender.locationInView(view).y
        let x = view.bounds.midX - sender.locationInView(view).x
        
        if y < 100 {
            newHeading(x)
            label.text = NSString(format: "%.0f", x) as String
        }
        else if y < 200 {
            newWindDirection(-x)
            label.text = NSString(format: "%.0f", -x) as String
        }
        else {
            newSpeed(max(0, y - 250)/10)
            weight = max(0.01, weight + sender.translationInView(view).x/1000)
            label.text = NSString(format: "%.2f", weight) as String
        }
        
        sender.setTranslation(CGPoint(), inView: view)
    }
    
    @IBAction func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

func closestOnCircle(var value: CGFloat, to previous: CGFloat) -> CGFloat {
    while value - previous < -180 {
        value += 360
    }
    while value - previous > 180 {
        value -= 360
    }
    
    return value
}


