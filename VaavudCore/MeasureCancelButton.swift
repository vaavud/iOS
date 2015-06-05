//
//  MeasureCancelButton.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 03/06/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

enum MeasureState {
    case CountingDown(Int)
    case Cancellable(Int)
    case Stoppable
}

class MeasureCancelButton: UIView {
    let pieView = PieView()
    let label = UILabel()
    
    func setup() {
        addSubview(pieView)
        pieView.backgroundColor = UIColor.clearColor()
        backgroundColor = UIColor.clearColor()
    }
    
    override func layoutSubviews() {
        pieView.frame = bounds
    }
    
//    func startCountdown(t: Int) {
//        period = t
//        state = .CountingDown(period)
//        timeLeft = CGFloat(period)
//        tick(0)
//    }
//    
//    func startMeasure(t: Int) {
//        period = t
//        state = .Cancellable(period)
//        timeLeft = CGFloat(period)
//        tick(0)
//    }
//
//    func startMeasure() {
//        period = 0
//        state = .Stoppable
//        timeLeft = 0
//        tick(0)
//    }
    
    func update(var timeLeft: CGFloat, state: MeasureState) {
        if timeLeft < 0 { timeLeft = 0 }
        
        switch state {
        case let .Cancellable(period):
            pieView.start = 1 - timeLeft/CGFloat(period)
            pieView.end = 1
        case let .CountingDown(period):
            pieView.start = (1 + cos(π*(timeLeft % 1)))/2
            pieView.end = pieView.start + (1 + cos(2*π*(timeLeft/2 % 1)))/2
        case .Stoppable:
            pieView.start = 0
            pieView.end = 1
        }
    }
}

class PieView: UIView {
    var start: CGFloat = 0.3 { didSet { if start != oldValue { setNeedsDisplay() } } }
    var end: CGFloat = 0.7 { didSet { if end != oldValue { setNeedsDisplay() } } }
    var lineWidth: CGFloat = 3
    var strokeColor = UIColor.vaavudBlueColor()

    override func drawRect(rect: CGRect) {
        strokeColor.setStroke()
        
        let radius = bounds.width/2 - lineWidth/2
        let startAngle = 2*π*start - π/2
        let endAngle = 2*π*end - π/2
        let path = UIBezierPath(arcCenter: bounds.center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        path.lineWidth = lineWidth
        path.lineCapStyle = kCGLineCapRound
        
        path.stroke()
    }
}



