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
    
    @IBAction func changedSelection(sender: UISegmentedControl) {
        historyContainer.hidden = sender.selectedSegmentIndex != 0
        notificationContainer.hidden = sender.selectedSegmentIndex != 1
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


