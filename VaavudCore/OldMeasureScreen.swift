//
//  OldMeasureViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 26/06/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class OldMeasureViewController : UIViewController, MeasurementConsumer {
    var name: String { return "OldMeasureViewController" }
    @IBOutlet weak var graph: OldGraph!
    
    @IBOutlet weak var arrowView: UIImageView!
    
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var speedUnitLabel: UILabel!
    @IBOutlet weak var maxSpeedLabel: UILabel!

    @IBOutlet weak var directionLabel: UILabel!
    @IBOutlet weak var avgSpeedLabel: UILabel!
    
    var arrowScale: CGFloat = 1
    
    private var latestDirection: CGFloat = 0
    private var smoothDirection: CGFloat = 0
    
    private var latestSpeed: CGFloat = 0
    private var smoothSpeed: CGFloat = 0

    private var avgSpeed: CGFloat = 0
    private var maxSpeed: CGFloat = 0

    private var animator: UIDynamicAnimator!
    private var scaleItem: DynamicItem!
    private var targetLogScale: CGFloat = 0
    private var animatingScale = false
    
    private var hasDirection = false
    
    var weight: CGFloat = 0.05 // todo: change
    var avgWeight: CGFloat = 0.01
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        speedUnitLabel.text = VaavudFormatter.shared.speedUnit.localizedString
        
        animator = UIDynamicAnimator(referenceView: view)
        scaleItem = DynamicItem(centerCallback: { [unowned self] in
            self.graph.logScale = $0.y/10000
        })
        
        scaleItem.center = CGPoint(x: 0, y: graph.logScale*10000)
        
        speedLabel.text = "-"
        maxSpeedLabel.text = "-"
        avgSpeedLabel.text = "-"
        
        arrowView.hidden = true
        directionLabel.text = "-"
    }
    
    override func viewDidLayoutSubviews() {
        graph.changedScale()
        
        let large, small: CGFloat
        
        if view.frame.width > 500 {
            large = 120
            small = 80
        }
        else if view.frame.width > 375 {
            large = 75
            small = 50
        }
        else if view.frame.width > 320 {
            large = 69
            small = 46
        }
        else {
            large = 60
            small = 40
        }
        
        let largeFont = UIFont(name: "BebasNeueBold", size: large)
        let smallFont = UIFont(name: "BebasNeueRegular", size: small)
        arrowScale = 1.5*large/100
        
        avgSpeedLabel.font = largeFont
        directionLabel.font = largeFont
        
        speedLabel.font = smallFont
        speedUnitLabel.font = smallFont
        maxSpeedLabel.font = smallFont
    }
    
    func animateLogScale(newLogScale: CGFloat) {
        animator.removeAllBehaviors()
        targetLogScale = newLogScale
        animatingScale = true
        animator.addBehavior(UISnapBehavior(item: scaleItem, snapToPoint: CGPoint(x: 0, y: newLogScale*10000)))
    }
    
    func toggleVariant() {}
    
    func newTemperature(temperature: CGFloat) {}

    // MARK: Callbacks
    func tick() {
        smoothSpeed = weight*latestSpeed + (1 - weight)*smoothSpeed
        graph.reading = VaavudFormatter.shared.speedUnit.fromBase(smoothSpeed)
        
        maxSpeed = max(smoothSpeed, maxSpeed)
        maxSpeedLabel.text = VaavudFormatter.shared.localizedSpeed(Float(maxSpeed), digits: 3)

        if hasDirection {
            smoothDirection = weight*latestDirection + (1 - weight)*smoothDirection
            arrowView.transform = Affine.rotation(smoothDirection.radians).scale(arrowScale)
            directionLabel.text = VaavudFormatter.shared.localizedDirection(Float(mod(smoothDirection, 360)))
        }
        
        avgSpeed = avgWeight*latestSpeed + (1 - avgWeight)*avgSpeed
        
        graph.average = VaavudFormatter.shared.speedUnit.fromBase(avgSpeed)
        avgSpeedLabel.text = VaavudFormatter.shared.localizedSpeed(Float(avgSpeed), digits: 3)
        
        if abs(targetLogScale - graph.logScale) < 0.01 {
            animatingScale = false
            animator.removeAllBehaviors()
            graph.logScale = targetLogScale
        }
        
        if !animatingScale {
            if graph.insideFactor > 1 {
                animateLogScale(graph.logScale + 1)
            }
            else if graph.insideFactor < 0.2 && graph.logScale >= 1 {
                animateLogScale(graph.logScale - 1)
            }
        }
    }

    func useMjolnir() { }

    func newWindDirection(windDirection: CGFloat) {
        hasDirection = true
        arrowView.hidden = false
        latestDirection += distanceOnCircle(from: latestDirection, to: windDirection)
    }
    
    func newSpeed(speed: CGFloat) {
        latestSpeed = speed
        speedLabel.text = VaavudFormatter.shared.localizedSpeed(Float(speed), digits: 3)
    }
    
    func newHeading(heading: CGFloat) {/* latestHeading += distanceOnCircle(from: latestHeading, to: heading) */ }
    
    func changedSpeedUnit(unit: SpeedUnit) {
        speedUnitLabel.text = VaavudFormatter.shared.speedUnit.localizedString
        newSpeed(latestSpeed)
    }
}

class OldGraph : UIView {
    let lowY: CGFloat = 0
    let highY: CGFloat = 10
    let n = 100
    
    var readings = [CGFloat()]
    var reading: CGFloat = 0 { didSet { addReading(reading) } }
    var average: CGFloat = 0 { didSet { newAverage(average) } }
    var logScale: CGFloat = 0 { didSet { if logScale != oldValue { changedScale() } } }

    private var lineWidth: CGFloat = 3
    private let graphColor = UIColor.vaavudBlueColor()
    private let avgColor = UIColor.vaavudRedColor()
    private let textColor = UIColor.darkGrayColor().colorWithAlpha(0.5)
    
    private let graphShape = CAShapeLayer()
    private let avgShape = CAShapeLayer()
    private var labels = [UILabel]()
    private var labelLogScale = -1
    
    private var factor: CGFloat = 1

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        graphShape.strokeColor = graphColor.CGColor
        graphShape.fillColor = nil
        graphShape.lineJoin = kCALineJoinRound
        layer.addSublayer(graphShape)

        avgShape.anchorPoint = CGPoint(x: 0, y: 0.5)
        avgShape.strokeColor = avgColor.CGColor
        avgShape.fillColor = nil
        
        layer.addSublayer(avgShape)
        
        for _ in 0...10 {
            let label = UILabel()
            label.font = UIFont(name: "Roboto", size: 14)
            label.textAlignment = .Center
            label.text = "9999"
            label.textColor = textColor
            label.sizeToFit()
            addSubview(label)
            labels.append(label)
        }
        
        changedScale()
    }
    
    var insideFactor: CGFloat {
        return reading/(factor*highY)
    }

    func changedScale() {
        factor = pow(2, logScale)

        let modScale = logScale % 1
        let scale = 2/((1 + modScale)*CGFloat(labels.count - 1))
        let outside = ease(0, to: -20)
        
        for (i, label) in labels.enumerate() {
            label.center.y = bounds.height*(1 - CGFloat(i)*scale)
            label.alpha = min(i % 2 == 0 ? 1 : 1 - modScale, 1 - outside(x: label.center.y))
        }
        
        let intScale = Int(floor(logScale))
        
        if labelLogScale != intScale {
            labelLogScale = intScale
            
            for (i, label) in labels.enumerate() {
                let j = 2*i*Int(pow(2, Float(labelLogScale)))
                label.text = String(j)
            }
        }
    }

    func newAverage(value: CGFloat) {
        CATransaction.setDisableActions(true)
        avgShape.position.y = yValue(value)
    }
    
    func addReading(value: CGFloat) {
        readings.append(value)
        
        let path = UIBezierPath()
        
        let iEnd = readings.count
        let iStart = max(iEnd - n, 0)
        
        path.moveToPoint(CGPoint(x: 0, y: yValue(readings[iStart])))
        
        for i in (iStart + 1)..<iEnd {
            path.addLineToPoint(CGPoint(x: xValue(i), y: yValue(readings[i])))
        }
        
        graphShape.path = path.CGPath
    }
    
    func yValue(reading: CGFloat) -> CGFloat {
        let y = (highY - reading/factor)/(highY - lowY)
        return max(bounds.height*y - lineWidth/2, 0)
    }
    
    func xValue(i: Int) -> CGFloat {
        return bounds.width*CGFloat(i + n - readings.count)/CGFloat(n - 1)
    }
    
    override func layoutSubviews() {
        if bounds.width > 400 {
            lineWidth = 5
        }
        
        avgShape.bounds.size.height = 2*lineWidth
        graphShape.lineWidth = lineWidth
        avgShape.lineWidth = lineWidth

        graphShape.frame = bounds
        avgShape.frame.size.width = bounds.width
        
        let path = UIBezierPath()
        path.moveToPoint(avgShape.bounds.midLeft)
        path.addLineToPoint(avgShape.bounds.midRight)

        avgShape.path = path.CGPath
    }
}

