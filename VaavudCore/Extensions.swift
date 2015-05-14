//
//  Extensions.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 10/02/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import Foundation
import MediaPlayer

extension UIViewController {
    func hideVolumeHUD() {
        view.addSubview(MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 100, height: 100)))
    }
}

func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func + (lhs: Polar, rhs: Polar) -> Polar {
    return Polar(r: lhs.r + rhs.r, phi: lhs.phi + rhs.phi)
}

struct Polar {
    var r: CGFloat
    var phi: CGFloat
    
    var cartesian: CGPoint {
        return CGPoint(x: r*cos(phi), y: r*sin(phi))
    }
}

extension CGFloat {
    var radians: CGFloat {
        return self*π/180
    }
    
    var degrees: CGFloat {
        return self*180/π
    }
}

extension CGPoint {
    var length: CGFloat {
        return sqrt(x*x + y*y)
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
}

func mod(i: Int, n: Int) -> Int {
    return ((i % n) + n) % n
}

func mod(i: CGFloat, n: CGFloat) -> CGFloat {
    return ((i % n) + n) % n
}

extension CGRect {
    var mid: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}
