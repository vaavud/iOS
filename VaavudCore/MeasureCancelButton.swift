//
//  MeasureCancelButton.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 03/06/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

enum MeasureState {
    case CountingDown(Int, Bool) // true = unlimited
    case Limited(Int)
    case Unlimited
    case Done
    
    var running: Bool {
        switch self {
        case .Limited, .Unlimited: return true
        default: return false
        }
    }
}

class MeasureCancelButton: UIButton {
    let pieView = PieView()
    let label = UILabel()
    var timerDigit = 0
    
    override var highlighted: Bool { didSet { pieView.highlighted = highlighted; label.highlighted = highlighted } }
    
    func setup() {
        addSubview(pieView)
        pieView.backgroundColor = UIColor.clearColor()
        pieView.userInteractionEnabled = false
        backgroundColor = UIColor.clearColor()
        
        label.font = UIFont(name: "BebasNeueRegular", size: 50)
        label.textAlignment = .Center
        label.textColor = UIColor.vaavudBlueColor()
        label.highlightedTextColor = UIColor.vaavudBlueColor().colorWithAlpha(0.3)
        label.userInteractionEnabled = false
        addSubview(label)
    }
    
    override func layoutSubviews() {
        pieView.frame = bounds
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        return isInsideCircle(point, rect: bounds)
    }
    
    func update(var timeLeft: CGFloat, state: MeasureState) {
        if timeLeft < 0 { timeLeft = 0 }
        
        let showCross: CGFloat
        let showSquare: CGFloat
        
        switch state {
        case let .CountingDown(period, _):
            pieView.start = (1 + cos(π*(timeLeft % 1)))/2
            pieView.end = pieView.start + (1 + cos(2*π*(timeLeft/2 % 1)))/2
            showCross = 0
            showSquare = 0
            
            let digit = Int(ceil(timeLeft))
            if timerDigit != digit && digit > 0 {
                timerDigit = digit
                label.text = String(timerDigit)
                label.sizeToFit()
                label.frame.size.width = bounds.width
                label.center = bounds.center + CGPoint(x: 0, y: 5)
            }
            
            label.alpha = min(4*(timeLeft % 1), 1)
            label.transform = Affine.scaling(max(min(2*(1 - (timeLeft % 1)), 1), 0.01))
            
        case let .Limited(period):
            pieView.start = 1 - timeLeft/CGFloat(period)
            pieView.end = 1
            label.alpha = 0
            showCross = 1
            showSquare = 0
        case .Unlimited:
            pieView.start = 0
            pieView.end = 1
            label.alpha = 0
            showCross = 0
            showSquare = 1
        case .Done:
            showCross = pieView.showCross
            showSquare = pieView.showSquare
        }
        
        pieView.showCross = min(pieView.showCross + 0.05, showCross)
        pieView.showSquare = min(pieView.showSquare + 0.05, showSquare)
    }
    
    // MARK: Pure
    func isInsideCircle(point: CGPoint, rect: CGRect) -> Bool {
        return dist(point, rect.center) < rect.width/2
    }
}

class PieView: UIView {
    var start: CGFloat = 0.3 { didSet { if start != oldValue { setNeedsDisplay() } } }
    var end: CGFloat = 0.7 { didSet { if end != oldValue { setNeedsDisplay() } } }

    var showCross: CGFloat = 0 { didSet { if showCross != oldValue { setNeedsDisplay() } } }
    var showSquare: CGFloat = 0 { didSet { if showSquare != oldValue { setNeedsDisplay() } } }
    
    var highlighted = false { didSet { setNeedsDisplay() } }
    
    let lineWidth: CGFloat = 3
    let strokeColor = UIColor.vaavudBlueColor()
    let highlightedStrokeColor = UIColor.vaavudBlueColor().colorWithAlpha(0.3)

    override func drawRect(rect: CGRect) {
        UIColor.vaavudBlueColor().colorWithAlpha(0.1).setFill()
        let backPath = UIBezierPath(ovalInRect: bounds)
        backPath.fill()
        
        strokeColor.setStroke()
        
        let radius = bounds.width/2 - lineWidth/2
        let startAngle = 2*π*start - π/2
        let endAngle = 2*π*end - π/2
        let arcPath = UIBezierPath(arcCenter: bounds.center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        arcPath.lineWidth = lineWidth
        arcPath.lineCapStyle = kCGLineCapRound
        arcPath.lineJoinStyle = kCGLineJoinRound
        arcPath.stroke()
        
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = kCGLineCapRound
        path.lineJoinStyle = kCGLineJoinRound

        let buttonBounds = CGRect(center: bounds.center, size: CGSize(width: 32, height: 32))

        if showCross > 0 {
            path.moveToPoint(buttonBounds.upperLeft)
            path.addLineToPoint(buttonBounds.upperLeft.approach(buttonBounds.lowerRight, by: min(2*showCross, 1)))
        }

        if showCross > 0.5 {
            path.moveToPoint(buttonBounds.upperRight)
            path.addLineToPoint(buttonBounds.upperRight.approach(buttonBounds.lowerLeft, by: min(2*showCross - 1, 1)))
        }
        
        if showSquare > 0 {
            path.moveToPoint(buttonBounds.upperLeft)
            path.addLineToPoint(buttonBounds.upperLeft.approach(buttonBounds.lowerLeft, by: min(4*showSquare, 1)))
        }
        
        if showSquare > 0.25 {
            path.moveToPoint(buttonBounds.upperLeft)
            path.addLineToPoint(buttonBounds.upperLeft.approach(buttonBounds.upperRight, by: min(4*showSquare - 1, 1)))
        }
        
        if showSquare > 0.5 {
            path.addLineToPoint(buttonBounds.upperRight.approach(buttonBounds.lowerRight, by: min(4*showSquare - 2, 1)))
        }
        
        if showSquare > 0.75 {
            path.moveToPoint(buttonBounds.lowerLeft)
            path.addLineToPoint(buttonBounds.lowerLeft.approach(buttonBounds.lowerRight, by: min(4*showSquare - 3, 1)))
        }

        (highlighted ? highlightedStrokeColor : strokeColor).setStroke()
        
        path.stroke()
    }
}



