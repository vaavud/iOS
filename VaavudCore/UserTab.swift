//
//  UserTab.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 01/10/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import Foundation

class UserTabViewController : UIViewController, UINavigationControllerDelegate {
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var historyContainer: UIView!
    @IBOutlet weak var notificationContainer: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("User tab created")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cs = storyboard!.instantiateViewControllerWithIdentifier("ComingSoonNavigationController")
        addChildViewController(cs)
        cs.view.frame = notificationContainer.bounds
        notificationContainer.addSubview(cs.view)
        cs.didMoveToParentViewController(self)
        
        for child in childViewControllers {
            if let nav = child as? UINavigationController {
                nav.delegate = self
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        LogHelper.log(segmentedControl.selectedSegmentIndex == 1 ? .Notifications : .History, event: "Began")
    }
    
    override func viewDidDisappear(animated: Bool) {
        LogHelper.log(segmentedControl.selectedSegmentIndex == 1 ? .Notifications : .History, event: "Ended")
    }
    
    deinit {
        print("User tab destroyed")
    }
    
    @IBAction func changedSelection(sender: UISegmentedControl) {
        let showNotifications = sender.selectedSegmentIndex == 1
        
        LogHelper.log(.Notifications, event: showNotifications ? "Began" : "Ended")
        LogHelper.log(.History, event: !showNotifications ? "Began" : "Ended")
        
        if !showNotifications {
            LogHelper.increaseUserProperty("Use-History-Count")
        }
        
        historyContainer.hidden = showNotifications
        notificationContainer.hidden = !historyContainer.hidden
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .All
    }
    
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if navigationController.childViewControllers.count > 1, let sv = navigationController.view.superview where !sv.hidden {
            UIView.animateWithDuration(0.1) {
                self.segmentedControl.alpha = 0
            }
        }
    }
    
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        if navigationController.childViewControllers.count == 1, let sv = navigationController.view.superview where !sv.hidden {
            UIView.animateWithDuration(0.1) {
                self.segmentedControl.alpha = 1
            }
        }
    }
}


