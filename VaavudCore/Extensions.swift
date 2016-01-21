//
//  Extensions.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 10/02/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import Foundation
import MediaPlayer

class RotatableNavigationController: UINavigationController {
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .All
    }
}

class RotatableViewController: UIViewController {
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait, .PortraitUpsideDown]
    }
}

class Plot: UIView {
    let f: CGFloat -> CGFloat
    let n: Int
    let range: (CGFloat, CGFloat)
    let color = UIColor.darkGrayColor()
    
    init(frame: CGRect, f: CGFloat -> CGFloat, range: (CGFloat, CGFloat) = (0, 1), n: Int = 10) {
        self.f = f
        self.range = range
        self.n = n
        super.init(frame: frame)
        backgroundColor = UIColor.lightGrayColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(rect: CGRect) {
        color.setFill()
        
        let path = UIBezierPath()
        path.moveToPoint(bounds.lowerLeft)
        for i in 0...n {
            let x = range.0 + (CGFloat(i)/CGFloat(n))*(range.1 - range.0)
            path.addLineToPoint(CGPoint(x: bounds.minX + x*bounds.width, y: bounds.maxY - f(x)*bounds.height))
        }
        path.addLineToPoint(bounds.lowerRight)
        path.closePath()
        path.fill()
    }
}

extension Array {
    func divide(n: Int) -> [[Element]] {
        var out = [[Element]]()
        let days = count/n + (count % n > 0 ? 1 : 0)
        for i in 0..<days { out.append(Array(self[i*n..<min((i + 1)*n, count)])) }
        
        return out
    }
    
    func divide(n: Int, first: Int) -> [[Element]] {
        precondition(first < n, "First must be smaller than n")
        
        var out = [[Element]]()
        let offset = min(first, count)
        if offset > 0 {
            out.append(Array(self[0..<offset]))
        }
        
        let countLeft = count - offset
        
        let daysLeft = countLeft/n + (countLeft % n > 0 ? 1 : 0)
        
        for i in 0..<daysLeft {
            out.append(Array(self[offset + i*n..<min(offset + (i + 1)*n, count)]))
        }
        
        return out
    }
}

func divide<T>(data: [T], condition: T -> Bool) -> [[T]] {
    var out = [[T]]()
    var latest = [T]()
    
    for dataPoint in data {
        if condition(dataPoint) {
            if !latest.isEmpty { out.append(latest) }
            latest = [T]()
        }
        
        latest.append(dataPoint)
    }
    out.append(latest)
    
    return out
}

func stackHorizontally(left: CGFloat = 0, margin: CGFloat = 0, views: [UIView]) -> CGFloat {
    var x = left
    
    for view in views {
        view.frame.origin.x = x
        x += view.frame.width + margin
    }
    
    return x - margin
}

func stackVertically(top: CGFloat = 0, margin: CGFloat = 0, views: [UIView]) -> CGFloat {
    var y = top
    
    for view in views {
        view.frame.origin.y = y
        y += view.frame.height + margin
    }
    
    return y - margin
}

func sigmoid(x: CGFloat) -> CGFloat {
    return 1/(1 + exp(-x))
}

func ease(x: CGFloat) -> CGFloat {
    return x < 0.5 ? 4*pow(x, 3) : pow(2*x - 2, 3)/2 + 1
}

func ease(from: CGFloat, to: CGFloat)(x: CGFloat) -> CGFloat {
    return ease(clamp((x - from)/(to - from)))
}

func clamp(x: CGFloat) -> CGFloat {
    if x < 0 {
        return 0
    }
    else if x > 1 {
        return 1
    }
    
    return x
}

extension UIImage {
    class func image(color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRectMake(0, 0, 100, 100))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIViewController {
    func hideVolumeHUD() {
        view.addSubview(MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 100, height: 100)))
    }
}

// MARK: CGAffineTransform

typealias Affine = CGAffineTransform

extension CGAffineTransform {
    static var id: CGAffineTransform { return CGAffineTransformIdentity }
    
    init() {
        self = CGAffineTransform.id
    }
    
    func translate(x: CGFloat, _ y: CGFloat) -> CGAffineTransform {
        return CGAffineTransformTranslate(self, x, y)
    }
    
    func rotate(angle: CGFloat) -> CGAffineTransform {
        return CGAffineTransformRotate(self, angle)
    }
    
    func scale(x: CGFloat, _ y: CGFloat) -> CGAffineTransform {
        return CGAffineTransformScale(self, x, y)
    }
    
    func scale(r: CGFloat) -> CGAffineTransform {
        return scale(r, r)
    }
    
    func apply(rect: CGRect) -> CGRect {
        return CGRectApplyAffineTransform(rect, self)
    }
    
    func apply(point: CGPoint) -> CGPoint {
        return CGPointApplyAffineTransform(point, self)
    }
    
    var inverse: CGAffineTransform {
        return CGAffineTransformInvert(self)
    }

    static func translation(x: CGFloat, _ y: CGFloat) -> CGAffineTransform {
        return CGAffineTransformMakeTranslation(x, y)
    }
    
    static func rotation(angle: CGFloat) -> CGAffineTransform {
        return CGAffineTransformMakeRotation(angle)
    }
    
    static func scaling(sx: CGFloat, _ sy: CGFloat) -> CGAffineTransform {
        return CGAffineTransformMakeScale(sx, sy)
    }
    
    static func scaling(r: CGFloat) -> CGAffineTransform {
        return self.scaling(r, r)
    }
}

func *(lhs: Affine, rhs: Affine) -> Affine {
    return CGAffineTransformConcat(lhs, rhs)
}


// MARK: Points

func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func * (lhs: CGFloat, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs*rhs.x, y: lhs*rhs.y)
}

func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func * (lhs: Polar, rhs: Polar) -> Polar {
    return Polar(r: lhs.r*rhs.r, phi: lhs.phi + rhs.phi)
}

func dist(p: CGPoint, q: CGPoint) -> CGFloat {
    return (p - q).length
}

// CGSize

func * (lhs: CGFloat, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs*rhs.width, height: lhs*rhs.height)
}

struct Polar {
    var r: CGFloat
    var phi: CGFloat
    
    init(r: Double, phi: Double) {
        self.r = CGFloat(r)
        self.phi = CGFloat(phi)
    }
    
    init(r: CGFloat, phi: CGFloat) {
        self.r = r
        self.phi = phi
    }

    var cartesian: CGPoint {
        return CGPoint(x: r*cos(phi), y: r*sin(phi))
    }
    
    func cartesian(center: CGPoint) -> CGPoint {
        return CGPoint(x: center.x + r*cos(phi), y: center.y + r*sin(phi))
    }

    func rotated(phi: CGFloat) -> Polar {
        return self*Polar(r: 1, phi: phi)
    }
    
    func rotated(phi: Double) -> Polar {
        return self*Polar(r: 1, phi: phi)
    }
}

func rotate(phi: CGFloat)(p: Polar) -> Polar {
    return p*Polar(r: 1, phi: phi)
}

extension CGFloat {
    var radians: CGFloat {
        return self*π/180
    }
    
    var degrees: CGFloat {
        return self*180/π
    }
}

extension Double {
    var radians: Double {
        return self*Double(π)/180
    }
    
    var degrees: Double {
        return self*180/Double(π)
    }
}

extension CGPoint {
    var length: CGFloat {
        return sqrt(x*x + y*y)
    }
    
    var unit: CGPoint {
        return (1/length)*self
    }

    var polar: Polar {
        return Polar(r: length, phi: atan2(y, x))
    }
    
    init(polar: Polar) {
        x = polar.cartesian.x
        y = polar.cartesian.y
    }
    
    init(r: CGFloat, phi: CGFloat) {
        self.init(polar: Polar(r: r, phi: phi))
    }
    
    func approach(goal: CGPoint, by factor: CGFloat) -> CGPoint {
        return (1 - factor)*self + factor*goal
    }
}

extension CGSize {
    func expandX(value: CGFloat) -> CGSize {
        return CGSize(width: width + value, height: height)
    }

    func expandY(value: CGFloat) -> CGSize {
        return CGSize(width: width, height: height + value)
    }
    
    var point: CGPoint { return CGPoint(x: width, y: height) }
}

func mod(i: Int, _ n: Int) -> Int {
    return ((i % n) + n) % n
}

func mod(i: CGFloat, _ n: CGFloat) -> CGFloat {
    return ((i % n) + n) % n
}

func mod(i: Double, _ n: Double) -> Double {
    return ((i % n) + n) % n
}

extension CGRect {
    init(center: CGPoint, size: CGSize) {
        self.init(origin: CGPoint(x: center.x - size.width/2, y: center.y - size.height/2), size: size)
    }

    func grow(delta: CGFloat) -> CGRect {
        let dw = delta*width
        let dh = delta*height
        
        return CGRect(x: origin.x - dw, y: origin.y - dh, width: width + 2*dw, height: height + 2*dh)
    }
    
    var center: CGPoint { return CGPoint(x: midX, y: midY) }
    
    var lowerRight: CGPoint { return CGPoint(x: maxX, y: maxY) }
    
    var lowerMid: CGPoint { return CGPoint(x: midX, y: maxY) }
    
    var lowerLeft: CGPoint { return CGPoint(x: minX, y: maxY) }
    
    var midLeft: CGPoint { return CGPoint(x: minX, y: midY) }
    
    var upperRight: CGPoint { return CGPoint(x: maxX, y: minY) }
    
    var upperMid: CGPoint { return CGPoint(x: midX, y: minY) }

    var upperLeft: CGPoint { return CGPoint(x: minX, y: minY) }
    
    var midRight: CGPoint { return CGPoint(x: maxX, y: midY) }

    func insetX(dx: CGFloat) -> CGRect {
        return CGRect(x: origin.x + dx, y: origin.y, width: width - 2*dx, height: height)
    }
    
    func insetY(dy: CGFloat) -> CGRect {
        return CGRect(x: origin.x, y: origin.y + dy, width: width, height: height - 2*dy)
    }
    
    func move(dr: CGPoint) -> CGRect {
        return CGRect(origin: origin + dr, size: size)
    }
    
    func moveX(value: CGFloat) -> CGRect {
        return CGRect(origin: origin + CGPoint(x: value, y: 0), size: size)
    }

    func moveY(value: CGFloat) -> CGRect {
        return CGRect(origin: origin + CGPoint(x: 0, y: value), size: size)
    }
    
    func width(value: CGFloat) -> CGRect {
        return CGRect(origin: origin, size: CGSize(width: value, height: height))
    }
    
    func height(value: CGFloat) -> CGRect {
        return CGRect(origin: origin, size: CGSize(width: width, height: value))
    }
}

func distanceOnCircle(from angle: CGFloat, to otherAngle: CGFloat) -> CGFloat {
    return CGFloat(distanceOnCircle(from: Double(angle), to: Double(otherAngle)))
}

func distanceOnCircle(from angle: Double, to otherAngle: Double) -> Double {
    let dist = (otherAngle - angle) % 360
    
    if dist <= -180 {
        return dist + 360
    }
    if dist > 180 {
        return dist - 360
    }
    
    return dist
}

