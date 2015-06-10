//
//  SemiCircleMeasurementScreen.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 12/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class RoundMeasurementViewController : UIViewController {
    @IBOutlet weak var ruler: RoundRuler!
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
    }
    
    // MARK: SDK Callbacks
    func newWindDirection(windDirection: Float) {
        latestWindDirection += distanceOnCircle(from: latestWindDirection, to: CGFloat(windDirection))
    }
    
    func newSpeed(speed: NSNumber!) {
        speedLabel.text = String(format: "%.1f", speed.floatValue)
        latestSpeed = CGFloat(speed.floatValue)
    }
    
    func newHeading(heading: NSNumber!) {
        if !lockNorth {
            latestHeading += distanceOnCircle(from: latestHeading, to: CGFloat(heading.floatValue))
        }
    }
    
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
        }
        else if y < 120 {
            newHeading(latestHeading - dx)
        }
        else {
            newWindDirection(latestWindDirection + dx)
            newSpeed(max(0, latestSpeed - dy/10))
        }
        
        sender.setTranslation(CGPoint(), inView: view)
    }
}

class RoundRuler : UIView {
    var compassDirection: CGFloat = 0 { didSet { setNeedsDisplay() } }
    var windDirection: CGFloat = 0 { didSet { setNeedsDisplay() } }
    var windSpeed: CGFloat = 0 { didSet { setNeedsDisplay() } }

    var scaling: CGFloat = 1 { didSet { setNeedsDisplay() } }
    
    private var visibleMarkers = 150
    
    private let cardinalDirections = 16
    
    private var font = UIFont(name: "Roboto", size: 20)!
    private var smallFont = UIFont(name: "Roboto", size: 12)!
    
    private var markers = [Polar]()
    
//    required init(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//    }
    
    override func drawRect(rect: CGRect) {
        drawCircles(bounds, scaling: scaling)
        
        let cardinalAngle = 360/CGFloat(cardinalDirections)
        
        let toCardinal = cardinalDirections - 1

        let path = UIBezierPath()
        let innerRadius = bounds.width/2 - 20
        let origin = bounds.center
        
        for cardinal in 0...toCardinal {
            if cardinal % 2 != 0 {
                continue
            }
            
            let phi = (CGFloat(cardinal)*cardinalAngle - compassDirection - 90).radians
            
            let direction = mod(cardinal, cardinalDirections)
            let text = VaavudFormatter.localizedCardinal(direction)
            let p = origin + CGPoint(r: innerRadius, phi: phi)

            let blackColor = direction % 4 == 0 ? UIColor.blackColor() : UIColor.darkGrayColor()
            let color = direction == 0 ? UIColor.redColor() : blackColor
            
            drawLabel(text, at: p, color: color, small: direction % 4 != 0)
        }
        
        let contextRef = UIGraphicsGetCurrentContext()
        CGContextSetRGBFillColor(contextRef, 0, 0, 0, 1);
        let rect = CGRect(center: origin, size: CGSize(width: 2, height: 2))
        CGContextFillEllipseInRect(contextRef, rect)

        newMarker(Polar(r: windSpeed, phi: windDirection.radians))
        drawMarkers(markers, rotation: compassDirection.radians)
    }
    
    let bandWidth: CGFloat = 25
    let bandDarkening: CGFloat = 0.02
    
    func drawCircles(rect: CGRect, scaling: CGFloat) {
        let width = scaling*bandWidth
        let diagonal = dist(bounds.center, bounds.upperRight)
        let diagonalDirection = (1/diagonal)*(bounds.upperRight - bounds.center)
        let n = Int(floor(diagonal/width))
        
        let textColor = UIColor.lightGrayColor()
        
        for i in 0...n - 2 {
            let band = n - i
            let blackness = CGFloat(band)*bandDarkening
            
            UIColor(white: 1 - blackness, alpha: 1).setFill()
            
            let r = CGFloat(band)*width
            UIBezierPath(ovalInRect: CGRect(center: rect.center, size: CGSize(width: 2*r, height: 2*r))).fill()
            
            drawLabel("\(band)", at:bounds.center + r*diagonalDirection, color: textColor, small: true)
        }
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
    
    func drawLabel(string: String, at p: CGPoint, color: UIColor, small: Bool) {
        let text: NSString = string
        
        let attributes = [NSForegroundColorAttributeName : color, NSFontAttributeName : small ? smallFont : font]
        
        let size = text.sizeWithAttributes(attributes)
        let origin = CGPoint(x: p.x - size.width/2, y: p.y - size.height/2)
        
        text.drawInRect(CGRect(origin: origin, size: size), withAttributes: attributes)
    }
}

