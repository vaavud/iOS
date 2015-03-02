//
//  CoreEmptyHistoryViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 24/02/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class CoreEmptyHistoryViewController: UIViewController {
    @IBOutlet weak var arrow: EmptyHistoryArrow!
    
    override func viewDidLayoutSubviews() {
        arrow.setup()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        arrow.animate()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        arrow.reset()
    }
}

@IBDesignable class EmptyHistoryArrow: UIView {
    var isSetup = false
    
    override func prepareForInterfaceBuilder() {
        setup()
    }
    
    override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }
    
    func setup() {
        if !isSetup {
            let arrowWidth: CGFloat = 6
            let arrowHeight: CGFloat = 6
            let arrowEndPoint = CGPoint(x: 16, y: 95)
            
            var bezierPath = UIBezierPath()
            bezierPath.moveToPoint(CGPointMake(50, 3.5))
            bezierPath.addCurveToPoint(arrowEndPoint, controlPoint1: CGPointMake(24.29, 5.86), controlPoint2: arrowEndPoint + CGPoint(x: 0, y: -50))
            bezierPath.moveToPoint(arrowEndPoint + CGPoint(x: -arrowWidth, y: -arrowHeight))
            bezierPath.addLineToPoint(arrowEndPoint)
            bezierPath.moveToPoint(arrowEndPoint + CGPoint(x: arrowWidth, y: -arrowHeight))
            bezierPath.addLineToPoint(arrowEndPoint)
            bezierPath.applyTransform(CGAffineTransformMakeScale(frame.width/100, frame.height/100))
            
            let shapeLayer = layer as CAShapeLayer
            shapeLayer.path = bezierPath.CGPath
            shapeLayer.strokeColor = UIColor.vaavudBlueColor().CGColor
            shapeLayer.lineWidth = 2
            shapeLayer.fillColor = nil
            shapeLayer.lineDashPattern = [10, 10]
            shapeLayer.strokeEnd = 0
            
            isSetup = true
        }
    }
    
    func reset() {
        let shapeLayer = layer as CAShapeLayer
        CATransaction.setDisableActions(true)
        shapeLayer.strokeEnd = 0
        CATransaction.setDisableActions(false)
    }
    
    func animate() {
        let shapeLayer = layer as CAShapeLayer
        
        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.duration = 0.8
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        anim.fromValue = 0
        anim.toValue = 1
        shapeLayer.addAnimation(anim, forKey: "stroke")
        shapeLayer.strokeEnd = 1
    }
}




