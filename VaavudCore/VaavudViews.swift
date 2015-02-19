//
//  VaavudViews.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 01/02/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import Foundation

class DynamicReadingItem: NSObject, UIDynamicItem {
    let readingView: ReadingView
    var bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
    var center: CGPoint = CGPoint() { didSet { readingView.reading = center.x/100 } }
    var transform = CGAffineTransformIdentity
    
    init(readingView: ReadingView) {
        self.readingView = readingView
        super.init()
    }
}

class ReadingView: UIView {
    @IBInspectable var reading: CGFloat = 0.0 { didSet { setNeedsDisplay() } }
}

@IBDesignable class TemperatureView: ReadingView {
    override func drawRect(rect: CGRect) {
        VaavudStyle.drawVaavudTemperature(height: bounds.height, reading: reading)
    }
}

@IBDesignable class PressureView: ReadingView {
    override func drawRect(rect: CGRect) {
        VaavudStyle.drawVaavudPressure(height: bounds.height, reading: reading)
    }
}

@IBDesignable class WindchillView: ReadingView {
    override func drawRect(rect: CGRect) {
        VaavudStyle.drawVaavudWindchill(height: bounds.height, reading: reading)
    }
}

@IBDesignable class GustinessView: ReadingView {
    override func drawRect(rect: CGRect) {
        VaavudStyle.drawVaavudGustiness(height: bounds.height, reading: reading)
    }
}

class DynamicOffsetItem: NSObject, UIDynamicItem {
    let offsetView: OffsetView
    var bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
    var center: CGPoint = CGPoint() { didSet { offsetView.offsetX = center.x/100; offsetView.offsetY = center.y/100; } }
    var transform = CGAffineTransformIdentity
    
    init(offsetView: OffsetView) {
        self.offsetView = offsetView
        super.init()
    }
}

@IBDesignable class ArrowView: UIView {
    @IBInspectable var strokeWidth: CGFloat = 3.0 { didSet { setNeedsDisplay() } }
    @IBInspectable var strokeColor: UIColor = UIColor.blackColor() { didSet { setNeedsDisplay() } }
    
    override func drawRect(rect: CGRect) {
        let rect = CGRect(x: 0, y: 0, width: bounds.height, height: bounds.height)
        VaavudStyle.drawCompassArrow(frame: rect, strokeColor: strokeColor, strokeWidth: strokeWidth)
    }
}

@IBDesignable class SleipnirView: UIView {
    @IBInspectable var strokeWidth: CGFloat = 3.0 { didSet { setNeedsDisplay() } }
    @IBInspectable var detailStrokeWidth: CGFloat = 1.0 { didSet { setNeedsDisplay() } }
    @IBInspectable var strokeColor: UIColor = UIColor.blackColor() { didSet { setNeedsDisplay() } }
    
    override func drawRect(rect: CGRect) {
        let rect = CGRect(x: 0, y: 0, width: bounds.height, height: bounds.height)
        
        VaavudStyle.drawSleipnirCompass(frame: rect, strokeColor: strokeColor, strokeWidth: strokeWidth, detailStrokeWidth: detailStrokeWidth)
    }
}


class OffsetView: UIView {
    @IBInspectable var offsetX: CGFloat = 0.0 { didSet { setNeedsDisplay() } }
    @IBInspectable var offsetY: CGFloat = 0.0 { didSet { setNeedsDisplay() } }
}
