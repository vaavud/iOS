//
//  File.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 15/09/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

//class RadialOverlay: UIView {
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        backgroundColor = UIColor.clearColor()
//    }
//
//    required init(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func drawRect(rect: CGRect) {
//        let context = UIGraphicsGetCurrentContext()
//        let innerColor = UIColor.vaavudDarkGreyColor()
//        let outerColor = UIColor(white: 0.5, alpha: 0.6)
//        
//        let gradient1 = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [innerColor.CGColor, outerColor.CGColor], [0, 0.9])!
//        let gradient2 = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [outerColor.CGColor, outerColor.CGColor], [0, 1])!
//        
//        CGContextSaveGState(context)
//        
//        CGContextDrawRadialGradient(context, gradient1,
//            CGPointMake(104.71, 108.64), 25,
//            CGPointMake(104.71, 108.64), 75, 0)
//        
//        CGContextDrawRadialGradient(context, gradient2,
//            CGPointMake(104.71, 108.64), 75,
//            CGPointMake(104.71, 108.64), 1000, 0)
//
//        CGContextRestoreGState(context)
//    }
//}

