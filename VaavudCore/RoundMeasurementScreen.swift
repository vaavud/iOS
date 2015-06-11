//
//  SemiCircleMeasurementScreen.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 12/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class RoundMeasurementViewController : UIViewController, MeasurementConsumer {
    @IBOutlet weak var background: RoundBackground!
    @IBOutlet weak var ruler: RoundRuler!
    @IBOutlet weak var speedLabel: UILabel!
    
    private var latestHeading: CGFloat = 0
    private var latestWindDirection: CGFloat = 0
    private var latestSpeed: CGFloat = 0
    
    var interval: CGFloat = 30
    
    var weight: CGFloat = 0.1
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        println("Created Round")
    }
    
    deinit {
        println("Removed Round")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func tick() {
        ruler.compassDirection = weight*latestHeading + (1 - weight)*ruler.compassDirection
        ruler.windDirection = weight*latestWindDirection + (1 - weight)*ruler.windDirection
        ruler.windSpeed = weight*latestSpeed + (1 - weight)*ruler.windSpeed
        ruler.newDot()
    }
    
    // MARK: New readings from root
    func newWindDirection(windDirection: CGFloat) {
        latestWindDirection += distanceOnCircle(from: latestWindDirection, to: CGFloat(windDirection))
    }
    
    func newSpeed(speed: CGFloat) {
        speedLabel.text = String(format: "%.1f", speed)
        latestSpeed = speed
    }
    
    func newHeading(heading: CGFloat) {
        if !lockNorth {
            latestHeading += distanceOnCircle(from: latestHeading, to: heading)
        }
    }
    
    var lockNorth = false
    
    @IBAction func lockNorthChanged(sender: UISwitch) {
        lockNorth = sender.on
        
        if lockNorth {
            latestHeading = 0
        }
    }
}

class RoundBackground : UIView {
    var scaling: CGFloat = 1 { didSet { setNeedsDisplay() } }
    
    let bandWidth: CGFloat = 25
    let bandDarkening: CGFloat = 0.02
    
    override func drawRect(rect: CGRect) {
        let width = scaling*bandWidth
        let diagonal = dist(bounds.center, bounds.upperRight)
        let diagonalDirection = (1/diagonal)*(bounds.upperRight - bounds.center)
        let n = Int(floor(diagonal/width))
        
        let textColor = UIColor.lightGrayColor()
        
        for i in 0...n - 2 {
            let band = n - i
            let blackness = CGFloat(band)*bandDarkening
            
//            CGContextSetRGBFillColor(contextRef, 0.3, 0.3, 0.3, 1 - gray);
//            let corner = origin + CGPoint(r: 10*m.r, phi: m.phi - rotation - π/2) + offset
//            let rect = CGRect(origin: corner, size: size)
//            CGContextFillEllipseInRect(contextRef, CGRect(origin: corner, size: size))

            UIColor(white: 1 - blackness, alpha: 1).setFill()
            
            let r = CGFloat(band)*width
            UIBezierPath(ovalInRect: CGRect(center: rect.center, size: CGSize(width: 2*r, height: 2*r))).fill()
            
//            drawLabel("\(band)", at:bounds.center + r*diagonalDirection, color: textColor, small: true)
        }
    }
}

class RoundRuler : UIView {
    var compassDirection: CGFloat = 0
    var windDirection: CGFloat = 0
    var windSpeed: CGFloat = 0

    var scaling: CGFloat = 1
    
//    var compassDirection: CGFloat = 0 { didSet { setNeedsDisplay() } }
//    var windDirection: CGFloat = 0 { didSet { setNeedsDisplay() } }
//    var windSpeed: CGFloat = 0 { didSet { setNeedsDisplay() } }
//    
//    var scaling: CGFloat = 1 { didSet { setNeedsDisplay() } }

    
    private var dotCount = 300
    private var markers = [Polar]()
    private var dots = [CAShapeLayer]()
    
    private let cardinalDirections = 16
    
    private var font = UIFont(name: "Roboto", size: 20)!
    private var smallFont = UIFont(name: "Roboto", size: 12)!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clearColor()
        
        for i in 0..<dotCount {
            let dot = CAShapeLayer()
            let hue = CGFloat(i)/CGFloat(dotCount)
            dot.fillColor = UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1).CGColor
            dot.strokeColor = nil
            dot.bounds.size = CGSize(width: 5, height: 5)
            dot.path = UIBezierPath(ovalInRect: dot.bounds).CGPath
            layer.addSublayer(dot)
            dots.append(dot)
        }
    }
    
    func newDot() {
        let p = Polar(r: windSpeed, phi: windDirection.radians)
        newMarker(p)
        
        let start = max(0, markers.count - dotCount)
        
        CATransaction.setDisableActions(true)
        for i in start..<markers.count {
            let m = markers[i]
            dots[i - start].position = bounds.center + CGPoint(r: 10*m.r, phi: m.phi - compassDirection.radians - π/2)
        }
        
//        for (i, m) in enumerate(markers) {
//            dots[i].position = bounds.center + CGPoint(r: 10*m.r, phi: m.phi - compassDirection.radians - π/2)
//        }
    }
    
    func newMarker(polar: Polar) {
        markers.append(polar)
//        if markers.count > dotCount {
//            markers.removeAtIndex(0)
//        }
    }
    
    
    //        println("========================")
    //        for m in markers { print(String(format: "%.1f ", m.r)) }
    //        println()
    //
    //        newMarker(p)
    //        for m in markers { print(String(format: "%.1f ", m.r)) }
    //        println()

    
//    override func drawRect(rect: CGRect) {
//        let cardinalAngle = 360/CGFloat(cardinalDirections)
//        
//        let toCardinal = cardinalDirections - 1
//
//        let path = UIBezierPath()
//        let innerRadius = bounds.width/2 - 20
//        let origin = bounds.center
//        
//        for cardinal in 0...toCardinal {
//            if cardinal % 2 != 0 {
//                continue
//            }
//            
//            let phi = (CGFloat(cardinal)*cardinalAngle - compassDirection - 90).radians
//            
//            let direction = mod(cardinal, cardinalDirections)
//            let text = VaavudFormatter.localizedCardinal(direction)
//            let p = origin + CGPoint(r: innerRadius, phi: phi)
//
//            let blackColor = direction % 4 == 0 ? UIColor.blackColor() : UIColor.darkGrayColor()
//            let color = direction == 0 ? UIColor.redColor() : blackColor
//            
//            drawLabel(text, at: p, color: color, small: direction % 4 != 0)
//        }
////        newMarker(Polar(r: windSpeed, phi: windDirection.radians))
//
////        drawMarkers(markers, rotation: compassDirection.radians)
//    }
    
    func drawMarkers(ms: [Polar], rotation: CGFloat) {
        let radius: CGFloat = 3
        let origin = CGPoint(x: bounds.midX, y: bounds.midY)
        let offset = CGPoint(x: -radius, y: -radius)
        let size = CGSize(width: 2*radius, height: 2*radius)
        
        let contextRef = UIGraphicsGetCurrentContext()
        
        for (i, m) in enumerate(ms) {
            let age = 1 - CGFloat(i)/CGFloat(dotCount)
            let gray = 0.5 + 0.5*age
            
            UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1 - gray).setStroke()
            
            CGContextSetRGBFillColor(contextRef, 0.3, 0.3, 0.3, 1 - gray);

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

