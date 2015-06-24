//
//  FlatMeasurementController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 14/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class FlatMeasurementViewController : UIViewController, MeasurementConsumer {
    @IBOutlet weak var ruler: FlatRuler!
    @IBOutlet weak var graph: FlatGraph!
    
    @IBOutlet weak var speedLabel: UILabel!
    
    private var latestHeading: CGFloat = 0
    private var latestWindDirection: CGFloat = 0
    private var latestSpeed: CGFloat = 0
    
    var interval: CGFloat = 30
    
    var weight: CGFloat = 0.1
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
        
    func tick() {
        ruler.compassDirection = weight*latestHeading + (1 - weight)*ruler.compassDirection
        ruler.windDirection = weight*latestWindDirection + (1 - weight)*ruler.windDirection
        ruler.tick()
        
        graph.reading = weight*latestSpeed + (1 - weight)*graph.reading
    }
    
    // MARK: SDK Callbacks
    func newWindDirection(windDirection: CGFloat) {
        latestWindDirection += distanceOnCircle(from: latestWindDirection, to: windDirection)
    }
    
    func newSpeed(speed: CGFloat) {
        speedLabel.text = NSString(format: "%.1f", speed) as String
        latestSpeed = speed
    }
    
    func newHeading(heading: CGFloat) {
        latestHeading += distanceOnCircle(from: latestHeading, to: heading)
    }
    
    func newReading(reading: String) {
        
    }

    func changedSpeedUnit(unit: SpeedUnit) {
    }
    
    @IBOutlet weak var label: UILabel!
}

enum ArrowPosition: Int {
    case Left = -1
    case Inside = 0
    case Right = 1
}

class FlatRuler : UIView {
    var compassDirection: CGFloat = 0
    var windDirection: CGFloat = 0
    let arrow = FlatDirectionArrow(frame: CGRect(x: 0, y: 0, width: 50, height: 80))
    let padding: CGFloat = 10
    
    var angleSpan: CGFloat = 30
    
    let rate: CGFloat = 0.25
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func tick() {
        let angleDelta = moveArrow(windDirection - compassDirection)

        let targetAngle: CGFloat
        
        if angleDelta > 0 {
            targetAngle = -π/2
        }
        else if angleDelta < 0 {
            targetAngle = π/2
        }
        else {
            targetAngle = 0
        }

        arrow.angle = (1 - rate)*arrow.angle + rate*targetAngle
        arrow.blinkSpeed = 100/(99 + 3*abs(angleDelta))
        arrow.tick()
    }
    
    func setup() {
        addSubview(arrow)
        arrow.frame.origin.y = padding
    }
    
    func moveArrow(angle: CGFloat) -> CGFloat {
        let newCenter = bounds.midX + angle*bounds.width/angleSpan
        let margin = padding + max(arrow.bounds.height, arrow.bounds.width)/2
        let adjustedCenter = min(bounds.width - margin, max(margin, newCenter))
        
        arrow.center.x = adjustedCenter
        
        return newCenter - adjustedCenter
    }
}

class FlatDirectionArrow : UIView {
    var angle: CGFloat = 0 { didSet { transform = Affine.rotation(angle) } }
    var blinkSpeed: CGFloat = 0
    private var alphaIncreasing = false
    
    override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }

    var shape: CAShapeLayer { return layer as! CAShapeLayer }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func setup() {
        shape.fillColor = UIColor.vaavudGreenColor().CGColor
        let path = UIBezierPath()
        path.moveToPoint(bounds.upperLeft)
        path.addLineToPoint(bounds.upperMid.approach(bounds.lowerMid, by: 0.2))
        path.addLineToPoint(bounds.upperRight)
        path.addLineToPoint(bounds.lowerMid)
        path.closePath()
        
        shape.path = path.CGPath
    }
    
    func tick() {
        if alpha < 0.95 || blinkSpeed < 1 {
            let rate = max(blinkSpeed/2, 0.2)
            alpha = (1 - rate)*alpha + rate*(alphaIncreasing ? 1 : 0)
            
            if alpha < 0.01 {
                alphaIncreasing = true
            }
            else if alpha > 0.99 {
                alphaIncreasing = false
            }
        }
    }
}

class FlatDirectionArrowMorph: UIView {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
//    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
//    }
    
    var shape: CAShapeLayer { return layer as! CAShapeLayer }
    
    func setup() {
        shape.fillColor = UIColor.vaavudGreyColor().CGColor
        shape.path = UIBezierPath(ovalInRect: bounds).CGPath
    }
    
    func showLeftArrow() {
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: bounds.maxX, y: bounds.midY))
        path.addLineToPoint(CGPoint(x: bounds.maxX, y: bounds.maxY))
        path.addLineToPoint(CGPoint(x: bounds.minX, y: bounds.midY))
        path.addLineToPoint(CGPoint(x: bounds.maxX, y: bounds.minY))
        path.closePath()
        
        let anim = CABasicAnimation(keyPath: "path")
        anim.toValue = path
        shape.addAnimation(anim, forKey: "PathAnim")
        
        shape.path = path.CGPath
    }
    
    func showRightArrow() {
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: bounds.maxX, y: bounds.midY))
        path.addLineToPoint(CGPoint(x: bounds.minX, y: bounds.maxY))
        path.addLineToPoint(CGPoint(x: bounds.minX, y: bounds.midY))
        path.addLineToPoint(CGPoint(x: bounds.minX, y: bounds.minY))
        path.closePath()
        
        let anim = CABasicAnimation(keyPath: "path")
        anim.toValue = path
        shape.addAnimation(anim, forKey: "PathAnim")
        
        shape.path = path.CGPath
    }
    
    func showCentered() {
        let path = UIBezierPath(ovalInRect: bounds)
        
        let anim = CABasicAnimation(keyPath: "path")
        anim.toValue = path
        
        println(path.currentPoint)
        
        shape.addAnimation(anim, forKey: "PathAnim")
        
        shape.path = path.CGPath
    }
    
    override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
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

