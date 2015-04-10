//
//  EmptyHistoryArrow.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 24/02/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

@IBDesignable class EmptyHistoryArrow: UIView {
    var isSetup = false
    
    override func prepareForInterfaceBuilder() {
        setup()
        (layer as! CAShapeLayer).strokeEnd = 1
    }
    
    override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }
    
    func forceSetup() {
        isSetup = false
        setup()
    }
    
    func setup() {
        var x: CGFloat
        
        if frame.width < 760 {
            x = 0
        }
        else if frame.width < 1000 {
            x = 217
        }
        else {
            x = 346
        }

        let width = frame.width - 2*x
        
        if !isSetup {
            let arrowWidth: CGFloat = 20*100/width
            let arrowHeight: CGFloat = 20*100/frame.height
            let arrowEndPoint = CGPoint(x: 16, y: 100)
            
            var bezierPath = UIBezierPath()
            bezierPath.moveToPoint(CGPointMake(50, 3.5))
            bezierPath.addCurveToPoint(arrowEndPoint, controlPoint1: CGPointMake(24.29, 5.86), controlPoint2: arrowEndPoint + CGPoint(x: 0, y: -50))
            bezierPath.moveToPoint(arrowEndPoint + CGPoint(x: -arrowWidth, y: -arrowHeight))
            bezierPath.addLineToPoint(arrowEndPoint)
            bezierPath.moveToPoint(arrowEndPoint + CGPoint(x: arrowWidth, y: -arrowHeight))
            bezierPath.addLineToPoint(arrowEndPoint)
            let s = CGAffineTransformMakeScale(width/100, frame.height/100)
            let t = CGAffineTransformMakeTranslation(x, 0)
            bezierPath.applyTransform(CGAffineTransformConcat(s, t))
            
            let shapeLayer = layer as! CAShapeLayer
            shapeLayer.path = bezierPath.CGPath
            shapeLayer.strokeColor = UIColor.vaavudBlueColor().CGColor
            shapeLayer.lineWidth = 2
            shapeLayer.fillColor = nil
            shapeLayer.lineDashPattern = [10, 10]
            
            isSetup = true
        }
    }
    
    func reset() {
        let shapeLayer = layer as! CAShapeLayer
        CATransaction.setDisableActions(true)
        shapeLayer.strokeEnd = 0
        CATransaction.setDisableActions(false)
    }
    
    func animate() {
        let shapeLayer = layer as! CAShapeLayer
        shapeLayer.removeAllAnimations()
        
        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.duration = 0.8
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        anim.fromValue = shapeLayer.strokeEnd
        anim.toValue = 1
        shapeLayer.addAnimation(anim, forKey: "stroke")
        shapeLayer.strokeEnd = 1
    }
}




