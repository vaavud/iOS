//
//  OldMeasureViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 26/06/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class OldMeasureViewController : UIViewController, MeasurementConsumer {
    @IBOutlet weak var graph: OldGraph!
    
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var speedUnitLabel: UILabel!
    @IBOutlet weak var directionLabel: UILabel!
    @IBOutlet weak var maxSpeedLabel: UILabel!
    @IBOutlet weak var avgSpeedLabel: UILabel!
    
    let formatter = VaavudFormatter()
    
    private var latestHeading: CGFloat = 0
    private var latestWindDirection: CGFloat = 0
    private var latestSpeed: CGFloat = 0
    private var smoothSpeed: CGFloat = 0

    private var avgSpeed: CGFloat = 0
    private var maxSpeed: CGFloat = 0

    var weight: CGFloat = 0.1
    var avgWeight: CGFloat = 0.01
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    deinit {
    }
    
    // MARK: Callbacks
    
    func tick() {
        smoothSpeed = weight*latestSpeed + (1 - weight)*smoothSpeed
        graph.reading = smoothSpeed
        
        avgSpeed = avgWeight*latestSpeed + (1 - avgWeight)*avgSpeed
        graph.average = avgSpeed
        avgSpeedLabel.text = formatter.localizedWindspeed(Float(avgSpeed), digits: 3)
    }
    
    func newWindDirection(windDirection: CGFloat) {
        latestWindDirection += distanceOnCircle(from: latestWindDirection, to: windDirection)
        directionLabel.text = formatter.localizedDirection(Float(latestWindDirection))
    }
    
    func newSpeed(speed: CGFloat) {
        latestSpeed = speed
        speedLabel.text = formatter.localizedWindspeed(Float(speed), digits: 3)
        
        maxSpeed = max(latestSpeed, maxSpeed)
        maxSpeedLabel.text = formatter.localizedWindspeed(Float(maxSpeed), digits: 3)
    }
    
    func newHeading(heading: CGFloat) {
        latestHeading += distanceOnCircle(from: latestHeading, to: heading)
    }
    
    func changedSpeedUnit(unit: SpeedUnit) {
        formatter.readUnits()
        speedUnitLabel.text = formatter.windSpeedUnit.localizedString
        newSpeed(latestSpeed)
    }
}

class OldGraph : UIView {
    var lowY: CGFloat = 0
    var highY: CGFloat = 50
    var n = 100
    
    var readings = [CGFloat()]
    var reading: CGFloat = 0 { didSet { addReading(reading) } }
    var average: CGFloat = 0 { didSet { newAverage(average) } }
    
    let lineWidth: CGFloat = 6
    let graphColor = UIColor.vaavudBlueColor()
    let avgColor = UIColor.vaavudRedColor()
    
    let graphShape = CAShapeLayer()
    let avgShape = CAShapeLayer()
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        graphShape.lineWidth = lineWidth
        graphShape.strokeColor = graphColor.CGColor
        graphShape.fillColor = nil
        graphShape.lineJoin = kCALineJoinRound
        layer.addSublayer(graphShape)

        avgShape.bounds.size.height = 2*lineWidth
        avgShape.anchorPoint = CGPoint(x: 0, y: 0.5)
        avgShape.lineWidth = lineWidth
        avgShape.strokeColor = avgColor.CGColor
        avgShape.fillColor = nil
        
        layer.addSublayer(avgShape)
    }
    
    func newAverage(value: CGFloat) {
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
        return bounds.height*(highY - reading)/(highY - lowY) - lineWidth/2
    }
    
    func xValue(i: Int) -> CGFloat {
        return bounds.width*CGFloat(i + n - readings.count)/CGFloat(n - 1)
    }
    
    override func layoutSubviews() {
        graphShape.frame = bounds
        avgShape.frame.size.width = bounds.width
        
        let path = UIBezierPath()
        path.moveToPoint(avgShape.bounds.midLeft)
        path.addLineToPoint(avgShape.bounds.midRight)

        avgShape.path = path.CGPath
    }
}

