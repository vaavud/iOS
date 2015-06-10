//
//  MeasureRootViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 30/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class MeasureRootViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var pageController: UIPageViewController!
    var viewControllers: [UIViewController]!
    private var displayLink: CADisplayLink!

    @IBOutlet weak var pager: UIPageControl!
    
    @IBOutlet weak var unitButton: UIButton!
    @IBOutlet weak var readingTypeButton: UIButton!
    @IBOutlet weak var cancelButton: MeasureCancelButton!
    
    var state = MeasureState.CountingDown(5, true)
    var timeLeft: CGFloat = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let vcsNames = ["FlatMeasureViewController", "RoundMeasureViewController", "MapMeasurementViewController"]
        viewControllers = vcsNames.map { self.storyboard!.instantiateViewControllerWithIdentifier($0) as! UIViewController }

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
    }
    
    @IBAction func tappedCancel(sender: MeasureCancelButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tick(link: CADisplayLink) {
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

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.rawValue)
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
        
        if let vc = pageViewController.viewControllers.last as? UIViewController {
            if let current = find(viewControllers, vc) {
                pager.currentPage = current
            }
            
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
    }
}








