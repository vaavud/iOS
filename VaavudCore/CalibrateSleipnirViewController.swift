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
    
    @IBOutlet weak var sceneView: SCNView!

    let scene = SCNScene()
    
    var timer: NSTimer!
    
    @IBOutlet weak var upperLabel: UILabel!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var calibrationCircle: CalibrationCircle!
    
    let sdk = VEVaavudElectronicSDK.sharedVaavudElectronic()
    
    let particleSystem = SCNParticleSystem(named: "WindParticles", inDirectory: nil)
    let manager = CMMotionManager()
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sdk.addListener(self)
    }
    
    override  func viewDidLoad() {
        hideVolumeHUD()
        
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        
        
        let text = SCNText(string: "7.8", extrusionDepth: 0)
        let textNode  = SCNNode(geometry: text)
//        textNode.scale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
        scene.rootNode.addChildNode(textNode)

        particleSystem.emitterShape = text
        particleSystem.birthLocation = .Surface
        
//        scene.addParticleSystem(particleSystem, withTransform: SCNMatrix4MakeTranslation(5, 5, 0))
        scene.addParticleSystem(particleSystem, withTransform: SCNMatrix4Identity)
        
        timer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "showFirstText", userInfo: nil, repeats: false)

        sdk.startCalibration()
        sdk.start()
        
//        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
//        effectView.frame = view.bounds
//        view.insertSubview(effectView, atIndex: 0)
//        view.backgroundColor = UIColor.clearColor()
        
        
        manager.gyroUpdateInterval = 0.1

        
        if manager.deviceMotionAvailable {
            manager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) {
                [weak self] (data: CMDeviceMotion!, error: NSError!) in
                
                let q = data.attitude.quaternion
                
                self?.particleSystem.emittingDirection = SCNVector3(x: Float(2*q.y), y: Float(2*q.z), z: Float(2*q.x))
                
                
//                println("\(round(1000*q.x)) \(round(1000*q.y)) \(round(1000*q.z))")
            }
        }

        
    }
    
    // Eftyeo,;45
    
    
    
    
    func showFirstText() {
        timer.invalidate()
        changeMessage("CALIBRATION_STRING_FIRST")
    }
    
    override func viewDidLayoutSubviews() {
        calibrationCircle.setup()
    }
    
    override func viewDidAppear(animated: Bool) {
        calibrationCircle.launch()
    }
    
    @IBAction func strengthChanged(sender: UISlider) {
        if done {
            return
        }
        let strength = CGFloat(sender.value)
        let change = strength - calibrationCircle.strength
        calibrationCircle.strength = strength
        
        if strength > 0.99 && calibrationCircle.blowing {
            timer.invalidate()
            calibrationCircle.blowing = false
            changeMessage("CALIBRATION_STRING_1")
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        else if strength < 0.01 && !calibrationCircle.blowing {
            calibrationCircle.blowing = true
            changeMessage("CALIBRATION_STRING_0")
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        
        if !calibrationCircle.blowing && change < 0 {
            calibrationCircle.progress -= change/2.5
        }
        
        if calibrationCircle.progress >= 1 {
            done = true
            calibrationCircle.done()
            
            changeMessage("CALIBRATION_STRING_DONE", color: UIColor.vaavudGreenColor())

            UIView.animateWithDuration(0.5) {
                self.cancelButton.alpha = 0
            }
            
            var timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "dismiss", userInfo: nil, repeats: false)
        }
    }
    
    func changeMessage(key: String, color: UIColor = UIColor.vaavudBlueColor(), delay: Double = 0) {
        upperLabel.text = NSLocalizedString(key, comment: "")
        
        UIView.animateWithDuration(0.7, delay: delay, options: nil, animations: {
            self.upperLabel.alpha = 0
            self.upperLabel.textColor = color
            self.upperLabel.text = NSLocalizedString(key, comment: "")
            self.upperLabel.alpha = 1
            
            }, completion: nil)
    }
    
    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.rawValue)
    }
    
    // MARK: - VaavudElectronicWindDelegate
    
    func newSpeed(speed: NSNumber!) {
        let low = 2.9
        let high = 7.4
        
        let strength = max(min((speed.doubleValue - low)/(high - low), 1), 0)
        calibrationCircle.strength = CGFloat(strength)
    }
    
    func calibrationPercentageComplete(percentage: NSNumber!) {
        if done {
            return
        }
        
        calibrationCircle.progress = CGFloat(percentage.floatValue)
        
        if percentage.floatValue > 0.9999 {
            done = true
            calibrationCircle.done()
            
            changeMessage("CALIBRATION_STRING_DONE", color: UIColor.vaavudGreenColor())
            
            UIView.animateWithDuration(0.5) {
                self.cancelButton.alpha = 0
            }
            
            var timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "dismiss", userInfo: nil, repeats: false)
        }
    }
}

@IBDesignable class CalibrationCircle: UIView {
    let progressLayer = CAShapeLayer()
    let strengthLayer = CAShapeLayer()
    let checkLayer = CAShapeLayer()
    
    let lineWidth: CGFloat = 8
    
    var strength: CGFloat = 0 { didSet { setStrength(strength) } }
    var progress: CGFloat = 0 { didSet { setProgress(progress) } }
    var blowing: Bool = true { didSet { setBlowing(blowing) } }
    
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
        strength = 0
        blowing = true
    }
    
    func setStrength(strength: CGFloat, animated: Bool = false) {
        CATransaction.setDisableActions(!animated)
        
        let radius = max(0, strength + 4*lineWidth/bounds.width*(1 - strength))
        strengthLayer.transform = CATransform3DMakeScale(radius, radius, 1)
    }
    
    func setProgress(progress: CGFloat, animated: Bool = true) {
        progressLayer.removeAnimationForKey("progressStroke")
        CATransaction.setDisableActions(!animated)
        progressLayer.strokeEnd = progress
    }
    
    func setBlowing(blowing: Bool) {
        CATransaction.setDisableActions(false)
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
            self.setStrength(0, animated: true)
        }
        
        setStrength(1, animated: true)
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
        
        setStrength(-1, animated: true)
    }

}


