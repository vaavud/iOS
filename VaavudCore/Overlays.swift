//
//  File.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 15/09/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class RadialOverlay: UIView {
    let position: CGPoint
    var didTap = false
    let radius: CGFloat
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, position: CGPoint, text: String, icon: UIImage?, radius: CGFloat) {
        self.position = CGPoint(x: frame.width*position.x, y: frame.height*position.y)
        self.radius = radius
        
        super.init(frame: frame)
        
        let textLabel = UILabel()
        textLabel.textColor = UIColor.whiteColor()
        textLabel.font = UIFont(name: "Roboto-Light", size: 24)
        textLabel.text = text
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .Center
        textLabel.frame.size.width = frame.width - 40
        textLabel.sizeToFit()
        textLabel.center.x = bounds.midX
        textLabel.frame.origin.y = bounds.center.y
        addSubview(textLabel)
        
        if let icon = icon {
            let iv = UIImageView(image: icon)
            iv.center.x = bounds.midX
            iv.frame.origin.y = textLabel.frame.minY - 30 - iv.frame.height
            addSubview(iv)
        }
        
        if position.y > 0 {
            backgroundColor = UIColor.clearColor()
        }
        else {
            backgroundColor = UIColor.vaavudDarkGreyColor().colorWithAlpha(0.85)
        }
        
        alpha = 0
    }
        
    override func didMoveToWindow() {
        UIView.animateWithDuration(0.2) { self.alpha = 1 }
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let inFocus = dist(position, q: point) < 25
        
        if inFocus {
            removeFromSuperview()
        }
        else {
            didTap = true
        }
        
        return !inFocus
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if didTap {
            UIView.animateWithDuration(0.25, animations: { self.alpha = 0 }, completion: { _ in self.removeFromSuperview() })
        }
    }
    
    override func drawRect(rect: CGRect) {
        if position.y > 0 {
            let context = UIGraphicsGetCurrentContext()
            let innerColor = UIColor.vaavudDarkGreyColor().colorWithAlpha(0)
            let outerColor = UIColor.vaavudDarkGreyColor().colorWithAlpha(0.85)
            
            let gradient1 = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [innerColor.CGColor, outerColor.CGColor], [0, 0.9])!
            let gradient2 = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [outerColor.CGColor, outerColor.CGColor], [0, 1])!
            
            CGContextSaveGState(context)
            
            UIBezierPath(rect: bounds).addClip()
            
            CGContextDrawRadialGradient(context, gradient1, position, 25, position, radius, [])
            CGContextDrawRadialGradient(context, gradient2, position, radius, position, 1200, [])
            
            CGContextRestoreGState(context)
        }
    }
}

