//
//  SemiCircleMeasurementScreen.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 12/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class DynamicItem: NSObject, UIDynamicItem {
    var bounds: CGRect { return CGRect(x: 0, y: 0, width: 10000, height: 10000) }
    var center = CGPoint() { didSet { centerCallback(center) } }
    var transform = CGAffineTransformIdentity { didSet { transformCallback(transform) } }
    
    var animating = false
    
    let centerCallback: CGPoint -> ()
    let transformCallback: CGAffineTransform -> ()
    
    init(centerCallback: CGPoint -> (), transformCallback: CGAffineTransform -> () = { x in }) {
        self.centerCallback = centerCallback
        self.transformCallback = transformCallback
        super.init()
    }
}

class RoundMeasureViewController : UIViewController, MeasurementConsumer {
    var name: String { return "RoundMeasureViewController" }

    @IBOutlet weak var background: RoundBackground!
    @IBOutlet weak var ruler: RoundRuler!
    @IBOutlet weak var speedLabel: UILabel!
    
    @IBOutlet weak var speedLabelOffset: NSLayoutConstraint!
    let speedLabelFont = UIFont(name: "BebasNeueBold", size: Interface.choose(100, 200))
    
    @IBOutlet weak var lockNorthDistance: NSLayoutConstraint!
    
    @IBOutlet weak var lockNorthButton: UIButton!

    private var latestHeading: Double = 0
    private var latestWindDirection: Double = 0
    private var latestSpeed: Double = 0
    
    private var hasHeading = false
    private var hasDirection = false
    
    private var lockNorth = false
    
    var weight: Double = 0.1

    let bandWidth: CGFloat = Interface.choose(30, 60)
    var logScale: CGFloat = 0 { didSet { changedScale() } }
    var logScaleOffset: CGFloat = 0
    
    var targetLogScale: CGFloat = 0
    var animatingScale = false
    
    var animator: UIDynamicAnimator!
    var scaleItem: DynamicItem!

    var hasLaidOutSubviews = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        speedLabel.font = speedLabelFont
        speedLabelOffset.constant = Interface.choose(-10, -20)
        
        animator = UIDynamicAnimator(referenceView: view)
        scaleItem = DynamicItem(centerCallback: { [unowned self] in
            self.logScale = $0.y/20000
            })
        
        scaleItem.center = CGPoint(x: 0, y: logScale*20000)
        background.setup(bandWidth)
    }
    
    override func viewDidLayoutSubviews() {
        if !hasLaidOutSubviews {
            hasLaidOutSubviews = true
            setupLayoutRelated()
        }
    }
    
    func setupLayoutRelated() {
        lockNorthDistance.constant = view.bounds.width/2 + 20
        
        background.layout()
        background.changedScale()
        
        ruler.setup(bandWidth)
        ruler.layout()
    }
    
    var scaledSpeed: Double {
        return VaavudFormatter.shared.speedUnit.fromBase(latestSpeed)
    }
    
    // MARK - Measurement Consumer
    
    func tick() {
        ruler.compassDirection = weight*latestHeading + (1 - weight)*ruler.compassDirection
        ruler.windDirection = weight*latestWindDirection + (1 - weight)*ruler.windDirection
        ruler.windSpeed = weight*scaledSpeed + (1 - weight)*ruler.windSpeed

        if abs(targetLogScale - logScale) < 0.01 {
            animatingScale = false
            animator.removeAllBehaviors()
            logScale = targetLogScale
        }
        
        let inside = ruler.insideFactor
        
        if !animatingScale && VaavudFormatter.shared.speedUnit != .Bft {
            if inside > 0.95 {
                animateLogScale(logScale + 1)
            }
            else if inside < 0.2 && logScale >= 1 {
                animateLogScale(logScale - 1)
            }
        }
        
        ruler.update()
    }
    
    func useMjolnir() { }

    func newWindSpeedMax(max: Double) { }

    func newWindSpeed(speed: Double) {
        latestSpeed = speed
        speedLabel.text = VaavudFormatter.shared.localizedSpeed(speed, digits: 3)
    }

    func newTrueWindSpeed(speed: Double) { }
    
    func newWindDirection(windDirection: Double) {
        hasDirection = true
        latestWindDirection += distanceOnCircle(from: latestWindDirection, to: windDirection)
        updateHeadingAndDirection()
    }

    func newTrueWindDirection(windDirection: Double) { }
    
    func newHeading(heading: Double) {
        hasHeading = true
        if !lockNorth {
            latestHeading += distanceOnCircle(from: latestHeading, to: heading)
        }
        updateHeadingAndDirection()
    }

    func newVelocity(course: Double, speed: Double) { }
    
    func newTemperature(temperature: Double) {}
    
    func changedSpeedUnit(unit: SpeedUnit) {
        newWindSpeed(latestSpeed)
        
        if VaavudFormatter.shared.speedUnit == .Bft {
            animateLogScale(0)
        }
    }
    
    func toggleVariant() {}
    
    
    // MARK - Convenience

    func animateLogScale(newLogScale: CGFloat) {
        animator.removeAllBehaviors()
        targetLogScale = newLogScale
        animatingScale = true
        animator.addBehavior(UISnapBehavior(item: scaleItem, snapToPoint: CGPoint(x: 0, y: newLogScale*20000)))
    }
    
    func changedScale() {
        if logScale < 0 {
            logScale = 0
        }
        
        ruler.scale = CGFloat(bandWidth/pow(2, logScale))
        background.logScale = logScale
    }
    
    func updateHeadingAndDirection() {
        if hasHeading && hasDirection {
            ruler.hasDirectionAndCompass = true
        }
    }
    
    // MARK - User Actions
    
    @IBAction func lockNorthChanged(sender: UIButton) {
        lockNorth = !lockNorth
        sender.selected = lockNorth
        
        LogHelper.log(.Measure, event: "Radar-Toggled-North-Lock", properties: ["on" : lockNorth])
        
        if lockNorth {
            ruler.compassDirection = distanceOnCircle(from: 0, to: latestHeading)
            latestHeading = 0
        }
    }
}

class RoundBackground : UIView {
    var logScale: CGFloat = 0 { didSet { if logScale != oldValue { changedScale() } } }
    var bandWidth: CGFloat!
    
    private let textColor = UIColor.darkGrayColor().colorWithAlpha(0.5)

    private let banded1 = BandedView()
    private let banded2 = BandedView()
    
    private var labels = [UILabel]()
    private var labelLogScale = -1
    
    func setup(bandWidth: CGFloat) {
        self.bandWidth = bandWidth
        
        banded1.bandWidth = bandWidth
        banded1.layer.shouldRasterize = true
        addSubview(banded1)
        
        banded2.bandWidth = 2*bandWidth
        banded2.layer.shouldRasterize = true
        addSubview(banded2)
        
        clipsToBounds = true
    }
    
    func layout() {
        let frame = CGRect(center: bounds.center, size: 2*bounds.size)
        banded1.frame = frame
        banded2.frame = frame
        
        let diagonal = dist(frame.center, q: frame.upperRight)
        banded1.n = Int(ceil(diagonal/banded1.bandWidth))
        banded2.n = Int(ceil(diagonal/banded2.bandWidth))
        
        for _ in 2..<banded1.n {
            let label = UILabel()
            label.font = UIFont(name: "Roboto", size: Interface.choose(16, 20))
            label.textAlignment = .Center
            label.text = "9999"
            label.textColor = textColor
            label.sizeToFit()
            addSubview(label)
            labels.append(label)
        }
    }
    
    func changedScale() {
        let modScale = logScale % 1
        
        banded2.alpha = CGFloat(modScale)
        
        let scale = 1 - modScale/2
        let t = Affine.scaling(scale)
        banded1.transform = t
        banded2.transform = t
        
        let diagonal = (bounds.upperRight - bounds.center).unit

        for (i, label) in labels.enumerate() {
            label.center = bounds.center + (CGFloat(i + 2)*scale*bandWidth - 10)*diagonal
            label.alpha = ((i + 2) % 2 == 0 && i != 0) ? 1 : 1 - modScale
        }
        
        let intScale = Int(floor(logScale))

        if labelLogScale != intScale {
            labelLogScale = intScale
            
            for (i, label) in labels.enumerate() {
                let j = (i + 2)*Int(pow(2, Float(labelLogScale)))
                label.text = String(j)
            }
        }
    }
}

class BandedView: UIView {
    var n = 0
    var bandWidth: CGFloat = 0
    
    private let bandDarkening: CGFloat = 0.04
    
    override func drawRect(rect: CGRect) {
        for i in 0...n - 2 {
            let band = n - i
            let r = CGFloat(band)*bandWidth
            let w = 1 - CGFloat(band - 2)*bandDarkening
            
            let contextRef = UIGraphicsGetCurrentContext()
            let rect = CGRect(center: rect.center, size: CGSize(width: 2*r, height: 2*r))
            CGContextSetRGBFillColor(contextRef!, w, w, w, 1)
            CGContextFillEllipseInRect(contextRef!, rect)
        }
    }
}

class RoundRuler : UIView {
    var compassDirection: Double = 0
    var windDirection: Double = 0
    var windSpeed: Double = 0

    var hasDirectionAndCompass = false { didSet { updateLabelVisibility() } }
    
    var scale: CGFloat = 0
    var bandWidth: CGFloat = 0
    
    private let blueDotSize: CGFloat = 20
    private let dotSize: CGFloat = 15
    private let dotCount = 400
    private var dotPositions = [Polar]()
    private var dots = [CAShapeLayer]()
    
    private let cardinalDirections = 16
    private var cardinalPositions = [Polar]()
    private var cardinalLabels = [UILabel]()
    
    private let font = UIFont(name: "Roboto-Bold", size: Interface.choose(25, 50))!
    private let smallFont = UIFont(name: "Roboto-Bold", size: Interface.choose(15, 30))!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clearColor()
        
        for i in 0..<dotCount {
            let dot = CAShapeLayer()
            dot.strokeColor = nil
            if i == dotCount - 1 {
                dot.fillColor = UIColor.vaavudBlueColor().CGColor
                dot.bounds.size = CGSize(width: blueDotSize, height: blueDotSize)
            }
            else {
                let size = dotSize*ease(CGFloat(i)/CGFloat(dotCount))
                dot.bounds.size = CGSize(width: size, height: size)
                dot.fillColor = UIColor.grayColor().CGColor
            }
            dot.path = UIBezierPath(ovalInRect: dot.bounds).CGPath
            newDotPosition(bounds.center.polar)
            
            layer.addSublayer(dot)
            dots.append(dot)
        }
    }
    
    func setup(bandWidth: CGFloat) {
        self.bandWidth = bandWidth
    }
    
    func layout() {
        for cardinal in 0..<cardinalDirections {
            if cardinal % 2 != 0 {
                continue
            }
            let r = bandWidth*(floor(0.5*bounds.width/bandWidth) - 0.5)
            let phi = (360*CGFloat(cardinal)/CGFloat(cardinalDirections) - 90).radians
            cardinalPositions.append(Polar(r: r, phi: phi))
            
            let label = UILabel()
//            label.text = VaavudFormatter.localizedCardinalFromDirection(mod(cardinal, cardinalDirections)) // Fixme: what is this?
            label.font = cardinal % 4 == 0 ? font : smallFont
            label.textColor = colorForCardinal(cardinal)
            label.sizeToFit()
            label.hidden = true
            
            cardinalLabels.append(label)
            addSubview(label)
        }
    }
    
    func colorForCardinal(cardinal: Int) -> UIColor {
        if cardinal == 0 {
            return UIColor.vaavudRedColor()
        }
        else if cardinal % 4 == 0 {
            return UIColor.vaavudDarkGreyColor()
        }

        return UIColor.vaavudDarkGreyColor().colorWithAlpha(0.5)
    }
    
    func update() {
        newDotPosition(Polar(r: windSpeed, phi: windDirection.radians))
        
        CATransaction.setDisableActions(true)
        
        let easing = ease(1.2*scale, to: 3.0*scale,x: 0)
        
        let basePolar = Polar(r: scale, phi: CGFloat(-compassDirection.radians) - π/2)
        
        for (dot, p) in zip(dots, dotPositions) {
            dot.position = (p*basePolar).cartesian(bounds.center)
            //dot.opacity = Float(easing(x: dist(dot.position, q: bounds.center)))
        }
        
        dots[dots.count - 1].opacity = 0.7*dots[dots.count - 1].opacity + 0.3
        
        for (label, p) in zip(cardinalLabels, cardinalPositions) {
            label.center = p.rotated(-compassDirection.radians).cartesian(bounds.center)
        }
    }
    
    func updateLabelVisibility() {
        UIView.animateWithDuration(0.3) {
            for label in self.cardinalLabels {
                label.hidden = !self.hasDirectionAndCompass
            }
        }
    }
    
    func newDotPosition(polar: Polar) {
        dotPositions.append(polar)
        if dotPositions.count > dotCount {
            dotPositions.removeAtIndex(0)
        }
    }
    
    var insideFactor: CGFloat {
        let radially = 2*CGFloat(windSpeed)*scale/frame.height
        let horizontally = abs(CGPoint(r: 2*CGFloat(windSpeed)*scale/frame.width, phi: CGFloat(windDirection.radians) - π/2).x)
        
        return radially > 0.5 ? max(radially, horizontally) : min(radially, horizontally)
    }
}

