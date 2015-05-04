//
//  MeasurementViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 04/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class Ruler : UIView {
    var offset: CGFloat = 0 { didSet { setNeedsDisplay() } }
    var pointsPerTick: CGFloat = 20

    override func drawRect(rect: CGRect) {
        let halfWidth = bounds.width/2

        let fromTick = Int(ceil(offset - halfWidth/pointsPerTick))
        let toTick = Int(floor(offset + halfWidth/pointsPerTick))
        
        let path = UIBezierPath()
        println("from: \(fromTick) to \(toTick)")
        
        for tick in fromTick...toTick {
            let x = pointsPerTick*(CGFloat(tick) - offset) + halfWidth
            
            path.moveToPoint(CGPoint(x: x, y: 0))
            path.addLineToPoint(CGPoint(x: x, y: (tick % 5 == 0 ? 80 : 50) + (tick == 0 ? 20 : 0) ))
        }
        
        UIColor.redColor().setStroke()
        path.lineWidth = 3
        path.stroke()
    }
}

class MeasurementViewController : UIViewController {
    @IBOutlet weak var ruler: Ruler!
 
    override func viewDidLoad() {
        super.viewDidLoad()
        ruler.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "changeOffset:"))
    }
    
    func changeOffset(sender: UIPanGestureRecognizer) {
        ruler.offset -= sender.translationInView(ruler).x/ruler.pointsPerTick
        sender.setTranslation(CGPoint(), inView: ruler)
    }
    
}