//
//  NotificationDetailsViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 05/10/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class NotificationDetailsViewController: UIViewController {
    @IBOutlet weak var directionSelector: DirectionSelector!

    
}

struct Directions: OptionSetType, CustomStringConvertible {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }
    init(angle: CGFloat) { self = Directions.number(Int(round(CGFloat(Directions.count)*angle/(2*π)))) }
    
    static let None = Directions(rawValue: 0)
    static let N = Directions(rawValue: 1)
    static let NW = Directions(rawValue: 2)
    static let W = Directions(rawValue: 4)
    static let SW = Directions(rawValue: 8)
    static let S = Directions(rawValue: 16)
    static let SE = Directions(rawValue: 32)
    static let E = Directions(rawValue: 64)
    static let NE = Directions(rawValue: 128)
    
    static let ordered: [Directions] = [.N, .NW, .W, .SW, .S, .SE, .E, .NE]
    static let count = Directions.ordered.count
    static func number(i: Int) -> Directions { return ordered[mod(i, 8)] }
    
    var index: Int { return Directions.ordered.indexOf(self)! }
    
    var description: String {
        return ["N", "NW", "W", "SW", "S", "SE", "E", "NE"][index]
    }
}

func sectorBezierPath(total: Int)(direction: Directions) -> UIBezierPath {
    let phi = 2*π/CGFloat(total)
    let path = UIBezierPath()
    path.moveToPoint(CGPoint())
    path.addLineToPoint(CGPoint(r: 0.5, phi: -phi/2))
    path.addArcWithCenter(CGPoint(), radius: 0.5, startAngle: -phi/2, endAngle: phi/2, clockwise: true)
    path.closePath()
    
    path.applyTransform(Affine.rotation(-π/2 - CGFloat(direction.index)*phi))
    path.applyTransform(Affine.translation(0.5, 0.5))
    return path
}

class DirectionSelector: UIControl {
    enum State {
        case Adding, Removing, Default
    }
    
    let lineWidth: CGFloat = 1
    
    var selection: Directions = [.N, .SW, .E]
    let paths = Directions.ordered.map(sectorBezierPath(Directions.count))
    var laidOut = false
    var touchState = State.Default
    
    override func layoutSubviews() {
        if laidOut { return }

        let scaling = Affine.scaling(frame.width - lineWidth, frame.height - lineWidth)
        let translation = Affine.translation(lineWidth/2, lineWidth/2)
        for path in paths {
            path.lineWidth = lineWidth
            path.applyTransform(scaling)
            path.applyTransform(translation)
        }
        
        laidOut = true
    }
    
    func updateSelection(direction: Directions) {
        if touchState == .Adding {
            selection.insert(direction)
        }
        else {
            selection.remove(direction)
        }
        
        setNeedsDisplay()
    }
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        if let current = direction(at: touch.locationInView(self)) {
            touchState = selection.contains(current) ? .Removing : .Adding
            updateSelection(current)

            return true
        }
        
        return false
    }
    
    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        if let current = direction(at: touch.locationInView(self)) {
            updateSelection(current)
        }
        
        return true
    }
    
    override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        touchState = .Default
    }
    
    func direction(at point: CGPoint) -> Directions? {
        if (point - bounds.center).polar.r > bounds.width/2 {
            return nil
        }
        return Directions(angle: -π/2 - (point - bounds.center).polar.phi)
    }
    
    override func drawRect(rect: CGRect) {
        UIColor.vaavudBlueColor().setStroke()
        UIColor.vaavudBlueColor().setFill()
        
        for (i, direction) in Directions.ordered.enumerate() {
            paths[i].stroke()
        
            if selection.contains(direction) {
                paths[i].fill()
            }
        }
    }
}
