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

class TimeGauge : UIView {
    var complete: CGFloat = 0.5
    var backColor = UIColor.vaavudLightGreyColor().colorWithAlpha(0.2)
    var completeColor = UIColor.vaavudBlueColor()
    
    private var border: CGFloat = 14
    private var width: CGFloat = 8
    
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
    
    private var displayLink: CADisplayLink!
    private var latestHeading: CGFloat = 0
    
    var weight: CGFloat = 0.1
    
    let sdk = VEVaavudElectronicSDK.sharedVaavudElectronic()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayLink = CADisplayLink(target: self, selector: Selector("tick:"))
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)

        for fam in UIFont.familyNames() as! [String] {
            println("====" + fam + "===")
            let names = UIFont.fontNamesForFamilyName(fam) as! [String]
            for name in names {
                println(name)
            }
        }
        
        ruler.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "changeOffset:"))

        sdk.addListener(self)
        sdk.start()
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
    }
    
    func newHeading(heading: NSNumber!) {
        var newHeading = CGFloat(heading.floatValue)

        while newHeading - latestHeading < -180 {
            newHeading += 360
        }
        while newHeading - latestHeading > 180 {
            newHeading -= 360
        }
        
        latestHeading = newHeading
    }
    
    @IBOutlet weak var label: UILabel!
    
    func changeOffset(sender: UIPanGestureRecognizer) {
        weight += sender.translationInView(ruler).x/1000
        label.text = NSString(format: "%.2f", weight) as String
        sender.setTranslation(CGPoint(), inView: ruler)
    }
    
    @IBAction func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}


