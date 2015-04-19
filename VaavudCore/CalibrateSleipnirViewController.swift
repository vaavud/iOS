//
//  CalibrateSleipnirViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 25/02/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import AudioToolbox
import SceneKit
import CoreMotion

class CalibrateSleipnirViewController: UIViewController, VaavudElectronicWindDelegate {
    var done = false

    var timer: NSTimer!
    
    var speed: CGFloat = 0
    var progress: CGFloat = 0

    @IBOutlet weak var upperLabel: UILabel!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var calibrationCircle: CalibrationCircle!
    
    let sdk = VEVaavudElectronicSDK.sharedVaavudElectronic()
    
    let manager = CMMotionManager()
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sdk.addListener(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideVolumeHUD()
        
        timer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "showFirstText", userInfo: nil, repeats: false)

        sdk.startCalibration()
        sdk.start()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calibrationCircle.setup()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        calibrationCircle.launch()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        sdk.stop()
    }
    
    func showFirstText() {
        timer.invalidate()
        changeMessage("CALIBRATION_STRING_FIRST")
    }
    
    func changeMessage(key: String, color: UIColor = UIColor.vaavudBlueColor(), delay: Double = 0) {
        let text = NSLocalizedString(key, comment: "")
        upperLabel.text = text
        
        UIView.animateWithDuration(0.7, delay: delay, options: nil, animations: {
            self.upperLabel.alpha = 0
            self.upperLabel.textColor = color
            self.upperLabel.text = text
            self.upperLabel.alpha = 1
            
            }, completion: nil)
    }
    
    @IBAction func pressedCancel(sender: AnyObject) {
        sdk.resetCalibration()
    }
    
    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.rawValue)
    }
    
    // MARK: VaavudElectronicWindDelegate
    
    func newSpeed(value: NSNumber!) {
        if done {
            return
        }
        
        if timer.valid {
            timer.invalidate()
        }

        let low: CGFloat = 2.9
        let high: CGFloat = 7.4
        
        let newSpeed = CGFloat(value.doubleValue)
        calibrationCircle.speed = max(min((newSpeed - low)/(high - low), 1), 0)
        
        if speed <= high && newSpeed > high {
            changeMessage("CALIBRATION_STRING_1")
            calibrationCircle.blowing = false
        }
        else if speed >= low && newSpeed < low {
            changeMessage("CALIBRATION_STRING_0")
            calibrationCircle.blowing = true
        }
        
        speed = newSpeed
    }
    
    func calibrationPercentageComplete(percentage: NSNumber!) {
        if done {
            return
        }
        
        let newProgress = CGFloat(percentage.floatValue)
        
        if round(1000*(newProgress - progress)) > 0 {
            //            calibrationCircle.blowing = false
            calibrationCircle.progress = newProgress
        }
        progress = newProgress
        
        if percentage.floatValue > 0.9999 {
            done = true
            calibrationCircle.done()
            
            changeMessage("CALIBRATION_STRING_DONE", color: UIColor.vaavudGreenColor())
            
            Property.setAsBoolean(true, forKey: "hasCalibrated")
            
            UIView.animateWithDuration(0.5) {
                self.cancelButton.alpha = 0
            }
            
            var timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "dismiss", userInfo: nil, repeats: false)
        }
    }
}

//@IBDesignable
class CalibrationCircle: UIView {
    let progressLayer = CAShapeLayer()
    let strengthLayer = CAShapeLayer()
    let checkLayer = CAShapeLayer()
    
    let lineWidth: CGFloat = 8
    
    var speed: CGFloat = 0 { didSet { setTheSpeed(speed) } }
    var progress: CGFloat = 0 { didSet { setTheProgress(progress) } }
    var blowing: Bool = true { didSet { setIsBlowing(blowing) } }
    
    var hasSetup = false
    
    override func prepareForInterfaceBuilder() {
        setup()
        progress = 0.7
    }
    
    func setup() {
        if hasSetup {
            return
        }
        hasSetup = true
        
        strengthLayer.frame = bounds
        strengthLayer.path = UIBezierPath(ovalInRect: CGRectInset(bounds, 2*lineWidth, 2*lineWidth)).CGPath
        strengthLayer.fillColor = UIColor.vaavudLightGreyColor().CGColor
        layer.addSublayer(strengthLayer)
        
        var progressPath = UIBezierPath(ovalInRect: CGRectInset(bounds, lineWidth/2, lineWidth/2))
        var t = CGAffineTransformIdentity
        t = CGAffineTransformTranslate(t, bounds.midX, bounds.midY)
        t = CGAffineTransformRotate(t, -π/2)
        t = CGAffineTransformTranslate(t, -bounds.midX, -bounds.midY)
        progressPath.applyTransform(t)

        progressLayer.frame = bounds
        progressLayer.path = progressPath.CGPath
        progressLayer.strokeColor = UIColor.vaavudBlueColor().CGColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = kCALineCapRound
        progressLayer.fillColor = nil
        layer.addSublayer(progressLayer)
        
        var checkPath = UIBezierPath()
        checkPath.moveToPoint(CGPoint(x: 0.279, y: 0.495))
        checkPath.addLineToPoint(CGPoint(x: 0.422, y: 0.638))
        checkPath.addLineToPoint(CGPoint(x: 0.719, y: 0.341))
        checkPath.applyTransform(CGAffineTransformMakeScale(bounds.width, bounds.height))
        
        checkLayer.frame = bounds
        checkLayer.path = checkPath.CGPath
        checkLayer.strokeColor = UIColor.vaavudGreenColor().CGColor
        checkLayer.lineWidth = lineWidth
        checkLayer.lineCap = kCALineCapRound
        checkLayer.lineJoin = kCALineJoinRound
        checkLayer.fillColor = nil
        checkLayer.strokeEnd = 0
        layer.addSublayer(checkLayer)
        
        progress = 0
        speed = 0
        blowing = true
    }
    
    func setTheSpeed(strength: CGFloat, animated: Bool = false) {
        let radius = max(0, strength + 4*lineWidth/bounds.width*(1 - strength))
        strengthLayer.transform = CATransform3DMakeScale(radius, radius, 1)
    }
    
    func setTheProgress(progress: CGFloat) {
        progressLayer.removeAnimationForKey("progressStroke")
        progressLayer.strokeEnd = progress
    }
    
    func setIsBlowing(blowing: Bool) {
        CATransaction.setAnimationDuration(0.3)
        strengthLayer.fillColor = UIColor.vaavudBlueColor().colorWithAlpha(blowing ? 0.2 : 1).CGColor
    }
    
    func launch() {
        let anim1 = CAKeyframeAnimation(keyPath: "strokeEnd")
        anim1.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        anim1.values = [0, 1]
        anim1.keyTimes = [0, 0.7]

        let anim2 = CAKeyframeAnimation(keyPath: "strokeStart")
        anim2.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        anim2.values = [0, 1]
        anim2.keyTimes = [0.3, 1]
        
        let anim3 = CABasicAnimation(keyPath: "transform.rotation")
        anim3.fromValue = 0
        anim3.toValue = 2*π
        
        let anim = CAAnimationGroup()
        anim.animations = [anim1, anim2, anim3]
        anim.duration = 1
        
        progressLayer.strokeStart = 0
        progressLayer.strokeEnd = 0
        progressLayer.addAnimation(anim, forKey: "progressStroke")
        
        CATransaction.setCompletionBlock {
            self.setTheSpeed(0, animated: true)
        }
        
        setTheSpeed(1, animated: true)
    }
    
    func done() {
        progress = 1
        CATransaction.setAnimationDuration(0.25)
        CATransaction.setCompletionBlock {
            let anim = CABasicAnimation(keyPath: "strokeEnd")
            anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            anim.fromValue = 0
            anim.toValue = 1
            anim.duration = 0.25
            
            self.checkLayer.strokeEnd = 1
            self.checkLayer.addAnimation(anim, forKey: "checkStroke")
            
            self.progressLayer.strokeColor = UIColor.vaavudGreenColor().CGColor
        }
        
        setTheSpeed(-1, animated: true)
    }

}


