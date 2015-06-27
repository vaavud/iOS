//
//  MeasurementViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 04/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

class MeasurementViewController : UIViewController, MeasurementConsumer {
    @IBOutlet weak var ruler: Ruler!
    @IBOutlet weak var graph: Graph!
    
    @IBOutlet weak var speedLabel: UILabel!
    
    let formatter = VaavudFormatter()
    
    private var latestHeading: CGFloat = 0
    private var latestWindDirection: CGFloat = 0
    private var latestSpeed: CGFloat = 0
    
    var interval: CGFloat = 30
    
    var weight: CGFloat = 0.1
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.rawValue)
    }
    
    deinit {
    }
    
    // MARK: Callbacks
    
    func tick() {
        ruler.compassDirection = weight*latestHeading + (1 - weight)*ruler.compassDirection
        ruler.windDirection = weight*latestWindDirection + (1 - weight)*ruler.windDirection
        graph.reading = weight*latestSpeed + (1 - weight)*graph.reading
    }
    
    func newWindDirection(windDirection: CGFloat) {
        latestWindDirection += distanceOnCircle(from: latestWindDirection, to: windDirection)
    }
    
    func newSpeed(speed: CGFloat) {
        speedLabel.text = formatter.localizedWindspeed(Float(speed), digits: 3)
        latestSpeed = speed
    }
    
    func newHeading(heading: CGFloat) {
        latestHeading += distanceOnCircle(from: latestHeading, to: heading)
    }
    
    func changedSpeedUnit(unit: SpeedUnit) {
        formatter.readUnits()
    }

    @IBOutlet weak var label: UILabel!
}



enum NeedleState {
    case Left
    case Inside
    case Right
}

class Ruler : UIView {
    var compassDirection: CGFloat = 0 { didSet { setNeedsDisplay() } }
    var windDirection: CGFloat = 0 { didSet { setNeedsDisplay() } }
    var pointsPerTick: CGFloat = 15
    
    private let shortTickLength: CGFloat = 0.3
    private let longTickLength: CGFloat = 0.6
    
    private let longTickPeriod = 10
    
    private let cardinalPeriod = 45
    private let cardinalMajorPeriod = 90
    
    private let tickWidth: CGFloat = 2
    
    private let needle = UIImageView()
    private let needleState = NeedleState.Inside
    
    private var font: UIFont!
    private var smallFont: UIFont!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        needle.image = UIImage(named: "Needle")

        let fontSize = frame.size.height*0.33
        font = UIFont(name: "BebasNeueRegular", size: frame.size.height*0.33)!
        smallFont = UIFont(name: "BebasNeueRegular", size: frame.size.height*0.20)!

        let height: CGFloat = frame.size.height*longTickLength
        if let w = needle.image?.size.width, h = needle.image?.size.height {
            needle.frame.size = CGSize(width: height*w/h, height: height)
        }
        addSubview(needle)
    }
    
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
            
            let y = bounds.height*(isLongTick ? longTickLength : shortTickLength)
            
            if isTick {
                if pointsPerTick > 5 || isLongTick {
                    path.moveToPoint(CGPoint(x: x, y: 0))
                    path.addLineToPoint(CGPoint(x: x, y: y))
                }
            }
            
            let p = CGPoint(x: x, y: y + 7)
            if halfTick % cardinalPeriod == 0 {
                let isMainCardinal = halfTick % (2*cardinalMajorPeriod) == 0
                
                if pointsPerTick > 12 || (pointsPerTick > 11 && isMajorCardinal) || isMainCardinal {
                    drawLabel(VaavudFormatter.localizedCardinal(Float(tick)), at: p, red: tick == 0, small: !isMajorCardinal)
                }
            }
            else if isLongTick {
                let doDraw: Bool
                
                if pointsPerTick < 2 {
                    doDraw = false
                }
                else if pointsPerTick < 6 {
                    doDraw = tick % 30 == 0
                }
                else if pointsPerTick < 12 {
                    doDraw = tick % 10 == 0
                }
                else {
                    doDraw = true
                }
                if doDraw {
                    drawLabel(NSString(format: "%d°", tick) as String, at: p, isDegree: true)
                }
            }
        }
        
        println()
        
        UIColor.vaavudDarkGreyColor().setStroke()
        path.lineWidth = tickWidth
        path.stroke()
        
        let needleDirection = compassDirection + distanceOnCircle(from: compassDirection, to: windDirection)
        moveNeedle(pointsPerTick*needleDirection + halfWidth - padding)
    }
    
    func moveNeedle(var x: CGFloat) {
        let base: CGFloat = 20
        let height: CGFloat = 35
        
//        switch x {
//        case CGFloat.min..<0:
//            println("left")
//        case bounds.width..<CGFloat.max:
//            println("right")
//        default:
//            println("in")
//        }
        
        let outside = x < 0 || x > bounds.width
        
        if outside {
            x = min(max(x, 0), bounds.width)
        }
        
        needle.frame.origin.y = 0
        needle.center.x = x
    }
    
    func drawLabel(string: String, at p: CGPoint, isDegree: Bool = false, red: Bool = false, small: Bool = false) {
        let text: NSString = string
        let alignmentString = isDegree ? text.substringWithRange(NSRange(location: 0, length: text.length - 1)) : text
        
        let fieldColor = red ? UIColor.vaavudRedColor() : UIColor.darkGrayColor()
        let fieldFont = small ? smallFont : font
        let attributes = [NSForegroundColorAttributeName : fieldColor, NSFontAttributeName : fieldFont]

        let offset = alignmentString.sizeWithAttributes(attributes).width/2
        let size = text.sizeWithAttributes(attributes)
        let origin = CGPoint(x: p.x - offset, y: p.y)
        
        text.drawInRect(CGRect(origin: origin, size: size), withAttributes: attributes)
    }
}

class Graph : UIView {
    var lowY: CGFloat = 0
    var highY: CGFloat = 50
    var n = 100
    
    var readings = [CGFloat()]
    var reading: CGFloat = 0 { didSet { addReading(reading) } }
    
    let lineWidth: CGFloat = 6
    let lineColor = UIColor.vaavudBlueColor()
    let upperColor = UIColor(red: CGFloat(153)/255, green: CGFloat(217)/255, blue: CGFloat(243)/255, alpha: 1)
    let lowerColor = UIColor(red: CGFloat(242)/255, green: CGFloat(250)/255, blue: CGFloat(253)/255, alpha: 1)
    
    let gradient = CAGradientLayer()
    let shape = CAShapeLayer()
    let mask = CAShapeLayer()
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        gradient.colors = [upperColor.CGColor, lowerColor.CGColor]
        layer.addSublayer(gradient)
        gradient.mask = mask
        
        shape.lineWidth = lineWidth
        shape.strokeColor = lineColor.CGColor
        shape.fillColor = nil
        shape.lineJoin = kCALineJoinRound
        
        layer.addSublayer(shape)
    }

    func addReading(value: CGFloat) {
        readings.append(value)

        func yValue(reading: CGFloat) -> CGFloat {
            return bounds.height*(highY - reading)/(highY - lowY) - lineWidth/2
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
        
        shape.path = path.CGPath
        
        let clippingPath = path.copy() as! UIBezierPath
        clippingPath.addLineToPoint(CGPoint(x: bounds.maxX, y: bounds.maxY))
        clippingPath.addLineToPoint(CGPoint(x: bounds.minX, y: bounds.maxY))
        clippingPath.closePath()

        mask.path = clippingPath.CGPath
    }
    
    override func layoutSubviews() {
        gradient.frame = bounds
        shape.frame = bounds
        mask.frame = bounds
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

func testDist(a: CGFloat, b: CGFloat) {
    println("from: \(a) to \(b): \(distanceOnCircle(from: a, to: b))")
}

func distanceOnCircle(from angle: CGFloat, to otherAngle: CGFloat) -> CGFloat {
    let dist = (otherAngle - angle) % 360
    
    if dist <= -180 {
        return dist + 360
    }
    if dist > 180 {
        return dist - 360
    }
    
    return dist
}

