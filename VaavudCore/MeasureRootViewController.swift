//
//  MeasureRootViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 30/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

protocol MeasurementConsumer {
    func tick()
    
    func newWindDirection(windDirection: CGFloat)
    func newSpeed(speed: CGFloat)
    func newHeading(heading: CGFloat)

    func changedSpeedUnit(unit: SpeedUnit)
}

class MeasureRootViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, VaavudElectronicWindDelegate {
    private var pageController: UIPageViewController!
    private var viewControllers: [UIViewController]!
    private var displayLink: CADisplayLink!

    private let sdk = VEVaavudElectronicSDK.sharedVaavudElectronic()

    private var formatter = VaavudFormatter()

    @IBOutlet weak var pager: UIPageControl!
    
    @IBOutlet weak var unitButton: UIButton!
    @IBOutlet weak var readingTypeButton: UIButton!
    @IBOutlet weak var cancelButton: MeasureCancelButton!
    
    var currentConsumer: MeasurementConsumer!
    
    private var latestHeading: CGFloat = 0
    private var latestWindDirection: CGFloat = 0
    private var latestSpeed: CGFloat = 0

    var state = MeasureState.CountingDown(5, true)
    var timeLeft: CGFloat = 5
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        println("CREATED ROOT")
    }

    deinit {
        println("REMOVED ROOT")
        sdk.stop()
        displayLink.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        hideVolumeHUD()

        sdk.addListener(self)
        sdk.start()
        
        let vcsNames = ["RoundMeasureViewController", "FlatMeasureViewController", "OldMeasureViewController"]
        viewControllers = vcsNames.map { self.storyboard!.instantiateViewControllerWithIdentifier($0) as! UIViewController }
        currentConsumer = viewControllers.first as! MeasurementConsumer
        
        pager.numberOfPages = viewControllers.count
        
        pageController = storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as? UIPageViewController
        pageController.dataSource = self
        pageController.delegate = self
        pageController.view.frame = view.bounds
        pageController.setViewControllers([viewControllers[0]], direction: .Forward, animated: false, completion: nil)
        
        addChildViewController(pageController)
        view.addSubview(pageController.view)
        pageController.didMoveToParentViewController(self)
        
        view.bringSubviewToFront(pager)
        view.bringSubviewToFront(unitButton)
        view.bringSubviewToFront(readingTypeButton)
        view.bringSubviewToFront(cancelButton)
        
        cancelButton.setup()
        
        displayLink = CADisplayLink(target: self, selector: Selector("tick:"))
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        
        unitButton.setTitle(formatter.windSpeedUnit.localizedString, forState: .Normal)
    }
    
    @IBAction func tappedUnit(sender: UIButton) {
        formatter.windSpeedUnit = formatter.windSpeedUnit.next
        unitButton.setTitle(formatter.windSpeedUnit.localizedString, forState: .Normal)
        currentConsumer.changedSpeedUnit(formatter.windSpeedUnit)
    }
    
    @IBAction func tappedCancel(sender: MeasureCancelButton) {
        sdk.removeListener(self)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tick(link: CADisplayLink) {
        currentConsumer.tick()
        
        switch state {
        case let .CountingDown(_, stoppable):
            if timeLeft < 0 {
                if stoppable {
                    state = .Stoppable
                }
                else {
                    state = .Cancellable(30)
                    timeLeft = 30
                }
            }
            else {
                timeLeft -= CGFloat(link.duration)
            }
        case .Cancellable:
            if timeLeft < 0 {
                timeLeft = 0
            }
            else {
                timeLeft -= CGFloat(link.duration)
            }
        default:
            timeLeft = 0
        }

        cancelButton.update(timeLeft, state: state)
    }

    // MARK: SDK Callbacks
    func newWindDirection(windDirection: NSNumber!) {
        latestWindDirection = CGFloat(windDirection.floatValue)
        currentConsumer.newWindDirection(latestWindDirection)
    }
    
    func newSpeed(speed: NSNumber!) {
        latestSpeed = CGFloat(speed.floatValue)
        currentConsumer.newSpeed(latestSpeed)
    }
    
    func newHeading(heading: NSNumber!) {
        latestHeading = CGFloat(heading.floatValue)
        currentConsumer.newHeading(latestHeading)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.rawValue)
    }
    
    func changeConsumer(mc: MeasurementConsumer) {
        currentConsumer = mc
        currentConsumer.newSpeed(latestSpeed)
        currentConsumer.newWindDirection(latestWindDirection)
        currentConsumer.newHeading(latestHeading)
        currentConsumer.changedSpeedUnit(formatter.windSpeedUnit)
    }
    
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [AnyObject]) {
        
        if let vc = pendingViewControllers.last as? UIViewController, mc = vc as? MeasurementConsumer {
            changeConsumer(mc)
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
        
        if let vc = pageViewController.viewControllers.last as? UIViewController, mc = vc as? MeasurementConsumer {
            if let current = find(viewControllers, vc) {
                pager.currentPage = current
            }
            changeConsumer(mc)
            
            let alpha: CGFloat = vc is MapMeasurementViewController ? 0 : 1
            UIView.animateWithDuration(0.3) {
                self.readingTypeButton.alpha = alpha
                self.unitButton.alpha = alpha
            }
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        if let current = find(viewControllers, viewController) {
            let next = mod(current + 1, viewControllers.count)
            return viewControllers[next]
        }
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {

        if let current = find(viewControllers, viewController) {
            let previous = mod(current - 1, viewControllers.count)
            return viewControllers[previous]
        }
        
        return nil
    }
    
    // MARK: Debug
    
    @IBAction func debugPanned(sender: UIPanGestureRecognizer) {
        let y = sender.locationInView(view).y
        let x = view.bounds.midX - sender.locationInView(view).x
        let dx = sender.translationInView(view).x/2
        let dy = sender.translationInView(view).y/20
        
        newWindDirection(latestWindDirection + dx)
        newSpeed(max(0, latestSpeed - dy))
        
        sender.setTranslation(CGPoint(), inView: view)
    }
}








