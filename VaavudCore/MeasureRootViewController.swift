//
//  MeasureRootViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 30/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class MeasureRootViewController: UIViewController, UIPageViewControllerDataSource {
    
    var pageController: UIPageViewController!
    var viewControllers: [UIViewController]!
    private var displayLink: CADisplayLink!

    @IBOutlet weak var cancelButton: MeasureCancelButton!
    var state = MeasureState.CountingDown(5, true)
    var timeLeft: CGFloat = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageController = storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as? UIPageViewController
        pageController.dataSource = self
        pageController.view.frame = view.bounds
        
        let vcsNames = ["FlatMeasureViewController", "RoundMeasureViewController", "MapMeasureViewController"]
        viewControllers = vcsNames.map { self.storyboard!.instantiateViewControllerWithIdentifier($0) as! UIViewController }
        pageController.setViewControllers([viewControllers[0]], direction: .Forward, animated: false, completion: nil)
        pageController.view.backgroundColor = UIColor.redColor()
        
        addChildViewController(pageController)
        view.addSubview(pageController.view)
        pageController.didMoveToParentViewController(self)
        
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
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return viewControllers.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
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
            let previous = mod(current + 1, viewControllers.count)
            return viewControllers[previous]
        }
        
        return nil
    }
}
