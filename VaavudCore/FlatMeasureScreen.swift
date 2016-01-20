//
//  FlatMeasurementController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 14/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class FlatMeasureViewController : UIViewController, MeasurementConsumer {
    var name: String { return "FlatMeasureViewController" }

    @IBOutlet weak var ruler: FlatRuler!
    @IBOutlet weak var graph: FlatGraph!
    
    @IBOutlet weak var speedHeading: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    
    @IBOutlet weak var gustsView: UIView!
    @IBOutlet weak var windchillView: UIView!
    
    @IBOutlet weak var gustLabel: UILabel!
    @IBOutlet weak var windchillLabel: UILabel!
    @IBOutlet weak var windchillUnitLabel: UILabel!
    
    @IBOutlet weak var speedLabelOffsetY: NSLayoutConstraint!
    @IBOutlet weak var gustsOffsetX: NSLayoutConstraint!
    @IBOutlet weak var gustsOffsetY: NSLayoutConstraint!

    @IBOutlet weak var windchillOffsetX: NSLayoutConstraint!
    
    private var smoothWindSpeed: Double = 0
    private var verySmoothWindSpeed: Double = 0
    
    private var latestHeading: Double?
    private var latestWindDirection: Double?
    private var latestSpeed: Double = 0
    
    private var temperature: Double?
    
    private var variant = 0 { didSet { updateVariant() } }
    
    var weight: Double = 0.1 // fixme: change
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ruler.hidden = true
        
        speedLabel.font = UIFont(name: "BebasNeueBold", size: Interface.choose(200, 200, 240, 280, 400, 400))
        let smallFont = UIFont(name: "BebasNeueBold", size: Interface.choose(105, 105, 125, 150, 220, 220))
        gustLabel.font = smallFont
        windchillLabel.font = smallFont

        windchillUnitLabel.text = VaavudFormatter.shared.temperatureUnit.localizedString
        
        gustsOffsetY.constant = Interface.choose(70, 80, 100, 125, 150, 150)
        
        updateVariant()
        newWindSpeed(0)
    }
    
    var scaledSpeed: Double {
        return VaavudFormatter.shared.speedUnit.fromBase(latestSpeed)
    }

    func updateVariant() {
        if variant == 0 {
            ruler.alpha = 1
            speedHeading.alpha = 0
            speedLabelOffsetY.constant = 0
            windchillOffsetX.constant = Interface.choose(200, 300)
            windchillView.alpha = 0
            gustsView.alpha = 0
        }
        else {
            ruler.alpha = Interface.choose(0, 1)
            speedHeading.alpha = 1
            speedLabelOffsetY.constant = gustsOffsetY.constant
            windchillOffsetX.constant = 0
            windchillView.alpha = 1
            gustsView.alpha = 1
        }
        gustsOffsetX.constant = -windchillOffsetX.constant
    }
    
    // MARK - SDK Callbacks

    func tick() {
        if let heading = latestHeading, windDirection = latestWindDirection {
            ruler.compassDirection = weight*heading + (1 - weight)*ruler.compassDirection
            ruler.windDirection = weight*windDirection + (1 - weight)*ruler.windDirection
            ruler.tick()
        }

        smoothWindSpeed = weight*latestSpeed + (1 - weight)*smoothWindSpeed
        graph.reading = smoothWindSpeed
        
        verySmoothWindSpeed = 0.3*weight*latestSpeed + (1 - 0.3*weight)*verySmoothWindSpeed
    }
    
    func useMjolnir() { }
    
    func newWindSpeedMax(max: Double) {
        gustLabel.text = VaavudFormatter.shared.localizedSpeed(max, digits: 2)
    }

    func newWindSpeed(speed: Double) {
        latestSpeed = speed
        speedLabel.text = VaavudFormatter.shared.localizedSpeed(speed, digits: 3)
//        gustLabel.text = VaavudFormatter.shared.localizedSpeed(gusts, digits: 2) // fixme: check
        updateWindChill()
    }
    
    func newTrueWindSpeed(speed: Double) { }
    
    func newWindDirection(windDirection: Double) {
        let latest = latestWindDirection ?? 0
        latestWindDirection = latest + distanceOnCircle(from: latest, to: windDirection)
        refreshRuler()
    }
    
    func newTrueWindDirection(windDirection: Double) { }
    
    func newHeading(newHeading: Double) {
        let heading = latestHeading ?? 0
        latestHeading = heading + distanceOnCircle(from: heading, to: newHeading)
        
        refreshRuler()
    }
    
    func newVelocity(course: Double, speed: Double) { }
    
    func newTemperature(temperature: Double) {
        self.temperature = temperature
        updateWindChill()
    }

    func changedSpeedUnit(unit: SpeedUnit) {
        newWindSpeed(latestSpeed)
    }

    func toggleVariant() {
        view.layoutIfNeeded()
        
        let animations = {
            self.variant = mod(self.variant + 1, 2)
            self.view.layoutIfNeeded()
        }
        
        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: animations, completion: nil)
    }

    // MARK - Convenience
    
    func updateWindChill() {        
        if let temperature = temperature, chill = windchill(temperature, verySmoothWindSpeed) {
            windchillLabel.text =  VaavudFormatter.shared.localizedWindchill(chill)
            windchillUnitLabel.alpha = 1
        }
        else {
            windchillLabel.text = "-"
            windchillUnitLabel.alpha = 0
        }
    }

    func refreshRuler() {
        ruler.hidden = latestHeading == nil || latestWindDirection == nil
    }
}

enum ArrowPosition: Int {
    case Left = -1
    case Inside = 0
    case Right = 1
}

class FlatRuler : UIView {
    var compassDirection: Double = 0
    var windDirection: Double = 0
    let arrow = FlatDirectionArrow(frame: CGRect(x: 0, y: 0, width: 50, height: 80))
    let padding: CGFloat = 10
    
    var angleSpan: CGFloat = 30
    
    let rate = 0.25
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func tick() {
        let angleDelta = moveArrow(CGFloat(distanceOnCircle(from: compassDirection, to: windDirection)))
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

        arrow.angle = (1 - CGFloat(rate))*arrow.angle + CGFloat(rate)*targetAngle
        arrow.blinkSpeed = 100/(99 + 3*abs(Double(angleDelta)))
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
    var blinkSpeed: Double = 0
    private var alphaIncreasing = false
    
    override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }

    var shape: CAShapeLayer { return layer as! CAShapeLayer }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func setup() {
        shape.fillColor = UIColor.vaavudBlueColor().CGColor
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
            let rate = CGFloat(max(blinkSpeed/2, 0.2))
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
//
//class FlatDirectionArrowMorph: UIView {
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        setup()
//    }
//    
////    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
////    }
//    
//    var shape: CAShapeLayer { return layer as! CAShapeLayer }
//    
//    func setup() {
//        shape.fillColor = UIColor.vaavudGreyColor().CGColor
//        shape.path = UIBezierPath(ovalInRect: bounds).CGPath
//    }
//    
//    func showLeftArrow() {
//        let path = UIBezierPath()
//        path.moveToPoint(CGPoint(x: bounds.maxX, y: bounds.midY))
//        path.addLineToPoint(CGPoint(x: bounds.maxX, y: bounds.maxY))
//        path.addLineToPoint(CGPoint(x: bounds.minX, y: bounds.midY))
//        path.addLineToPoint(CGPoint(x: bounds.maxX, y: bounds.minY))
//        path.closePath()
//        
//        let anim = CABasicAnimation(keyPath: "path")
//        anim.toValue = path
//        shape.addAnimation(anim, forKey: "PathAnim")
//        
//        shape.path = path.CGPath
//    }
//    
//    func showRightArrow() {
//        let path = UIBezierPath()
//        path.moveToPoint(CGPoint(x: bounds.maxX, y: bounds.midY))
//        path.addLineToPoint(CGPoint(x: bounds.minX, y: bounds.maxY))
//        path.addLineToPoint(CGPoint(x: bounds.minX, y: bounds.midY))
//        path.addLineToPoint(CGPoint(x: bounds.minX, y: bounds.minY))
//        path.closePath()
//        
//        let anim = CABasicAnimation(keyPath: "path")
//        anim.toValue = path
//        shape.addAnimation(anim, forKey: "PathAnim")
//        
//        shape.path = path.CGPath
//    }
//    
//    func showCentered() {
//        let path = UIBezierPath(ovalInRect: bounds)
//        
//        let anim = CABasicAnimation(keyPath: "path")
//        anim.toValue = path
//        
//        print(path.currentPoint)
//        
//        shape.addAnimation(anim, forKey: "PathAnim")
//        
//        shape.path = path.CGPath
//    }
//    
//    override class func layerClass() -> AnyClass {
//        return CAShapeLayer.self
//    }
//}

class FlatGraph : UIView {
    var lowY: CGFloat = 0
    var highY: CGFloat = 40
    var n = 100
    
    var readings = [CGFloat()]
    var reading: Double = 0 { didSet { addReading(reading) } }
    
    let graphColor = UIColor.vaavudGreyColor()
    let shape = CAShapeLayer()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        shape.strokeColor = nil
        shape.fillColor = graphColor.CGColor
        shape.lineJoin = kCALineJoinRound
        
        layer.addSublayer(shape)
    }
    
    func addReading(value: Double) {
        readings.append(CGFloat(value))
        
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

