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

class RoundMeasurementViewController : UIViewController, MeasurementConsumer {
    @IBOutlet weak var background: RoundBackground!
    @IBOutlet weak var ruler: RoundRuler!
    @IBOutlet weak var speedLabel: UILabel!
    
    private var latestHeading: CGFloat = 0
    private var latestWindDirection: CGFloat = 0
    private var latestSpeed: CGFloat = 3
    
    var interval: CGFloat = 30
    
    var weight: CGFloat = 0.1
    
    let bandWidth: CGFloat = 30
    var logScale: CGFloat = 0 { didSet { changedScale() } }
    
    var targetLogScale: CGFloat = 0
    var animatingScale = false
    
    var animator: UIDynamicAnimator!
    var scaleItem: DynamicItem!

    var hasLaidOutSubviews = false
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        println("Created Round")
    }
    
    deinit {
        println("Removed Round")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        animator = UIDynamicAnimator(referenceView: view)
        scaleItem = DynamicItem(centerCallback: {
            self.logScale = $0.y/20000
        })
        
        scaleItem.center = CGPoint(x: 0, y: logScale*20000)
        background.setup()
    }
    
    override func viewDidLayoutSubviews() {
        if !hasLaidOutSubviews {
            hasLaidOutSubviews = true
            setupLayoutRelated()
        }
    }
    
    func setupLayoutRelated() {
        background.layout()
        background.changedScale()
        
        ruler.layout()
    }
    
    func tick() {
        let scale = bandWidth/pow(2, logScale)
        let widthFactor = 2*scale*ruler.windSpeed/ruler.bounds.width

        if abs(targetLogScale - logScale) < 0.01 {
            animatingScale = false
            animator.removeAllBehaviors()
            logScale = targetLogScale
        }
        
        if !animatingScale {
            if widthFactor > 1 {
                animateLogScale(logScale + 1)
            }
            else if widthFactor < 0.2 && logScale >= 1 {
                animateLogScale(logScale - 1)
            }
        }
        
        ruler.compassDirection = weight*latestHeading + (1 - weight)*ruler.compassDirection
        ruler.windDirection = weight*latestWindDirection + (1 - weight)*ruler.windDirection
        ruler.windSpeed = weight*latestSpeed + (1 - weight)*ruler.windSpeed
        ruler.update()
    }
    
    func animateLogScale(newLogScale: CGFloat) {
        targetLogScale = newLogScale
        animatingScale = true
        animator.addBehavior(UISnapBehavior(item: scaleItem, snapToPoint: CGPoint(x: 0, y: newLogScale*20000)))
    }
    
    func changedScale() {
        if logScale < 0 {
            logScale = 0
        }
        
        ruler.scale = bandWidth/pow(2, logScale)
        background.logScale = logScale
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
    var logScale: CGFloat = 0 { didSet { if logScale != oldValue { changedScale() } } }
    let bandWidth: CGFloat = 30
    
    private let textColor = UIColor.lightGrayColor()

    private let banded1 = BandedView()
    private let banded2 = BandedView()
    
    private var labels = [UILabel]()
    private var labelLogScale = -1
    
    func setup() {
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
        
        let diagonal = dist(frame.center, frame.upperRight)
        banded1.n = Int(ceil(diagonal/banded1.bandWidth))
        banded2.n = Int(ceil(diagonal/banded2.bandWidth))
        
        for i in 2..<banded1.n {
            let label = UILabel()
            label.font = UIFont(name: "Roboto", size: 22)
            label.textAlignment = .Center
            label.text = "9999"
            label.sizeToFit()
            addSubview(label)
            labels.append(label)
        }
    }
    
    func changedScale() {
        let modScale = logScale % 1
        
        banded2.alpha = modScale
        
        let scale = 1/(1 + modScale)
        let t = Affine.scaling(scale)
        banded1.transform = t
        banded2.transform = t
        
        let diagonal = (bounds.upperRight - bounds.center).unit

        for (i, label) in enumerate(labels) {
            label.center = bounds.center + CGFloat(i + 2)*scale*bandWidth*diagonal
            label.alpha = ((i + 2) % 2 == 0 && i != 0) ? 1 : 1 - modScale
        }
        
        let intScale = Int(floor(logScale))

        if labelLogScale != intScale {
            labelLogScale = intScale
            
            for (i, label) in enumerate(labels) {
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
            let black = CGFloat(band)*bandDarkening
            
            let contextRef = UIGraphicsGetCurrentContext()
            let r = CGFloat(band)*bandWidth
            let rect = CGRect(center: rect.center, size: CGSize(width: 2*r, height: 2*r))
            CGContextSetRGBFillColor(contextRef, 1 - black, 1 - black, 1 - black, 1)
            CGContextFillEllipseInRect(contextRef, rect)
        }
    }
}

class RoundRuler : UIView {
    var compassDirection: CGFloat = 0
    var windDirection: CGFloat = 0
    var windSpeed: CGFloat = 0

    var scale: CGFloat = 0
    
    private let dotCount = 400
    private var dotPositions = [Polar]()
    private var dots = [CAShapeLayer]()
    
    private let cardinalDirections = 16
    private var cardinalPositions = [Polar]()
    private var cardinalLabels = [UILabel]()
    
    private let font = UIFont(name: "Roboto", size: 20)!
    private let smallFont = UIFont(name: "Roboto", size: 12)!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clearColor()
        
        for i in 0..<dotCount {
            let dot = CAShapeLayer()
            dot.strokeColor = nil
            if i == dotCount - 1 {
                dot.fillColor = UIColor.vaavudBlueColor().CGColor
                dot.bounds.size = CGSize(width: 10, height: 10)
            }
            else {
                let size = 7*ease(CGFloat(i)/CGFloat(dotCount))
                dot.bounds.size = CGSize(width: size, height: size)
                dot.fillColor = UIColor.vaavudDarkGreyColor().CGColor
            }
            dot.path = UIBezierPath(ovalInRect: dot.bounds).CGPath
            newDotPosition(bounds.center.polar)
            
            layer.addSublayer(dot)
            dots.append(dot)
        }
    }
    
    func layout() {
        let r = bounds.width/2 - 28
        
        for cardinal in 0..<cardinalDirections {
            if cardinal % 2 != 0 {
                continue
            }
            
            let phi = (360*CGFloat(cardinal)/CGFloat(cardinalDirections) - 90).radians
            cardinalPositions.append(Polar(r: r, phi: phi))
            
            let label = UILabel()
            label.text = VaavudFormatter.localizedCardinal(mod(cardinal, cardinalDirections))
            label.font = cardinal % 4 == 0 ? font : smallFont
            label.textColor = colorForCardinal(cardinal)
            label.sizeToFit()
            
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

        return UIColor.vaavudLightGreyColor()
    }
    
    func update() {
        newDotPosition(Polar(r: windSpeed, phi: windDirection.radians))
        
        CATransaction.setDisableActions(true)
        
        let easing = ease(1.5*scale, 2*scale)
        
        for (dot, p) in Zip2(dots, dotPositions) {
            dot.position = (p*Polar(r: scale, phi: -compassDirection.radians - π/2)).cartesian(bounds.center)
            dot.opacity = Float(easing(x: dist(dot.position, bounds.center)))
        }

        for (label, p) in Zip2(cardinalLabels, cardinalPositions) {
            label.center = p.rotated(-compassDirection.radians).cartesian(bounds.center)
        }
    }
    
    func newDotPosition(polar: Polar) {
        dotPositions.append(polar)
        if dotPositions.count > dotCount {
            dotPositions.removeAtIndex(0)
        }
    }
}

