//
//  FlatMeasurementController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 14/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class FlatMeasurementViewController : UIViewController, VaavudElectronicWindDelegate {
    @IBOutlet weak var ruler: FlatRuler!
    @IBOutlet weak var gauge: FlatTimeGauge!
    @IBOutlet weak var graph: FlatGraph!
    
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
        latestWindDirection += distanceOnCircle(from: latestWindDirection, to: CGFloat(windDirection.floatValue))
    }
    
    func newSpeed(speed: NSNumber!) {
        speedLabel.text = NSString(format: "%.1f", speed.floatValue) as String
        latestSpeed = CGFloat(speed.floatValue)
    }
    
    func newHeading(heading: NSNumber!) {
        latestHeading += distanceOnCircle(from: latestHeading, to: CGFloat(heading.floatValue))
    }
    
    @IBOutlet weak var label: UILabel!
    
    func changeOffset(sender: UIPanGestureRecognizer) {
        let y = sender.locationInView(view).y
        let x = view.bounds.midX - sender.locationInView(view).x
        let dx = sender.translationInView(view).x/3
        
        if y < 120 {
            newHeading(latestHeading - dx)
            label.text = NSString(format: "%.0f", latestHeading) as String
        }
        else if y < 240 {
            newWindDirection(latestWindDirection + dx)
            label.text = NSString(format: "%.0f", latestWindDirection) as String
        }
        else {
            newSpeed(max(0, y - 260)/10)
            weight = max(0.01, weight + sender.translationInView(view).x/1000)
            label.text = NSString(format: "%.2f", weight) as String
        }
        
        sender.setTranslation(CGPoint(), inView: view)
    }
    
    @IBAction func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

class FlatRuler : UIView {
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
        let padding = 20
        
        let cardinalAngle = 360/CGFloat(cardinalDirections)
        
        //        let fromCardinal = Int(ceil((compassDirection - 180)/cardinalAngle))
        //        let toCardinal = Int(floor((compassDirection + 180)/cardinalAngle))
        
        let fromCardinal = 0
        let toCardinal = cardinalDirections - 1
        
        let path = UIBezierPath()
        
        let innerRadius: CGFloat = 100
        let origin = CGPoint(x: bounds.midX, y: bounds.midY)
        
        for cardinal in fromCardinal...toCardinal {
            let phi = (CGFloat(cardinal)*cardinalAngle - compassDirection - 90).radians
            
            path.moveToPoint(origin + CGPoint(r: innerRadius, phi: phi))
            path.addLineToPoint(origin + CGPoint(r: innerRadius + tickLength, phi: phi))
            
            let direction = mod(cardinal, cardinalDirections)
            let text = VaavudFormatter.localizedCardinal(direction)
            let p = origin + CGPoint(r: innerRadius + 2*tickLength, phi: phi)
            drawLabel(text, at: p, black: direction % 4 == 0)
        }
        
        UIColor.darkGrayColor().setStroke()
        path.lineWidth = tickWidth
        path.stroke()
        
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
            
            let corner = origin + CGPoint(r: 10*m.r, phi: m.phi - rotation) + offset
            let rect = CGRect(origin: corner, size: size)
            CGContextFillEllipseInRect(contextRef, CGRect(origin: corner, size: size))
        }
        
        if let m = ms.last {
            CGContextSetRGBFillColor(contextRef, 1, 0, 0, 1);
            
            let corner = origin + CGPoint(r: 10*m.r, phi: m.phi - rotation) + offset
            let rect = CGRect(origin: corner, size: size)
            CGContextFillEllipseInRect(contextRef, CGRect(origin: corner, size: size))
        }
    }
    
    func drawLabel(string: String, at p: CGPoint, black: Bool = false) {
        let text: NSString = string
        
        let fieldColor = black ? UIColor.blackColor() : UIColor.darkGrayColor()
        let attributes = [NSForegroundColorAttributeName : fieldColor, NSFontAttributeName : font]
        
        let size = text.sizeWithAttributes(attributes)
        let origin = CGPoint(x: p.x - size.width/2, y: p.y - size.height/2)
        
        text.drawInRect(CGRect(origin: origin, size: size), withAttributes: attributes)
    }
}

class FlatTimeGauge : UIView {
    var complete: CGFloat = 0.0 { didSet { setNeedsDisplay() } }
    var completeColor = UIColor.vaavudBlueColor()
    
    private var border: CGFloat = 14
    private var width: CGFloat = 15
    
    override func drawRect(rect: CGRect) {
        let outline = CGRectInset(bounds, border + width/2, border + width/2)
        let mid = CGPoint(x: outline.midX, y: outline.midY)
                
        completeColor.setStroke()
        let completePath = UIBezierPath(arcCenter: mid, radius: outline.width/2, startAngle: -π/2, endAngle: 2*π*complete - π/2, clockwise: true)
        completePath.lineWidth = width
        completePath.lineCapStyle = kCGLineCapRound
        completePath.stroke()
    }
}

class FlatGraph : UIView {
    var lowY: CGFloat = 0
    var highY: CGFloat = 40
    var n = 100
    
    var readings = [CGFloat()]
    var reading: CGFloat = 0 { didSet { addReading(reading) } }
    
    let graphColor = UIColor.vaavudGreyColor()
    let shape = CAShapeLayer()
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        shape.strokeColor = nil
        shape.fillColor = graphColor.CGColor
        shape.lineJoin = kCALineJoinRound
        
        layer.addSublayer(shape)
    }
    
    func addReading(value: CGFloat) {
        readings.append(value)
        
        func yValue(reading: CGFloat) -> CGFloat {
            return bounds.height*(highY - reading)/(highY - lowY)
        }
        
        func xValue(i: Int) -> CGFloat {
            return bounds.width*CGFloat(i + n - readings.count)/CGFloat(n - 1)
        }
        
        let path = UIBezierPath()
        
        let iEnd = readings.count
        let iStart = max(iEnd - n, 0)
        
        path.moveToPoint(CGPoint(x: 0, y: yValue(readings[iStart])))
        
        for i in (iStart + 1)..<iEnd {
            path.addLineToPoint(CGPoint(x: xValue(i), y: yValue(readings[i])))
        }
        
        path.addLineToPoint(CGPoint(x: bounds.maxX, y: bounds.maxY))
        path.addLineToPoint(CGPoint(x: bounds.minX, y: bounds.maxY))
        path.closePath()
        
        shape.path = path.CGPath
    }
    
    override func layoutSubviews() {
        shape.frame = bounds
    }
}

