//
//  UpgradingUserViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 27/01/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class UpgradingUserViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pager: UIPageControl!
    
    @IBOutlet weak var phoneOffset: NSLayoutConstraint!
    @IBOutlet weak var phoneScrollView: UIScrollView!
    
    @IBOutlet weak var topPhoneOffset: NSLayoutConstraint!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        pager.transform = Affine.scaling(0.5)
        
        if view.frame.height < 500 {
            topPhoneOffset.constant = 40
        }
        else if view.frame.height > 1000 {
            topPhoneOffset.constant = -180
        }

        scrollView.contentSize = CGSize(width: CGFloat(pager.numberOfPages)*scrollView.bounds.width, height: scrollView.bounds.height)
        
        Mixpanel.sharedInstance().track("Upgade Sleipnir Flow")
        
        let nibName = "UpgradingUserPagesView"
        if let content = NSBundle.mainBundle().loadNibNamed(nibName, owner: self, options: nil).first as? UIView {
            content.frame.origin = CGPoint()
            content.frame.size = scrollView.contentSize
            scrollView.addSubview(content)
        }
        
        phoneScrollView.contentSize = CGSize(width: 3*phoneScrollView.bounds.width, height: phoneScrollView.bounds.height)

        if let content = NSBundle.mainBundle().loadNibNamed("UpgradingUserPhonePages", owner: nil, options: nil).first as? UIView {
            content.frame.size = phoneScrollView.contentSize
            content.frame.origin = CGPoint()
            phoneScrollView.addSubview(content)
        }
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue) | Int(UIInterfaceOrientationMask.PortraitUpsideDown.rawValue)
    }
    
    @IBAction func openBuyDevice() { // Close
        Property.setAsBoolean(true, forKey: KEY_HAS_SEEN_TRISCREEN_FLOW);
        
        Mixpanel.sharedInstance().track("Triscreen Flow - Dismiss")
        
        if let tabBarController = storyboard?.instantiateViewControllerWithIdentifier("TabBarController") as? TabBarController {
            if let window = UIApplication.sharedApplication().delegate?.window {
                window?.rootViewController = tabBarController

                if AccountManager.sharedInstance().isLoggedIn() {
                    ServerUploadManager.sharedInstance().syncHistory(2, ignoreGracePeriod: true, success: nil, failure: nil)
                }
                
                if !Property.getAsBoolean(KEY_USER_HAS_WIND_METER, defaultValue: false) {
                    tabBarController.selectedIndex = 1
                }
            }
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let page = scrollView.contentOffset.x/scrollView.bounds.width
        pager.currentPage = Int(round(page))
        phoneScrollView.contentOffset.x = page*phoneScrollView.bounds.width
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true;
    }
}

//@IBDesignable 
class SimpleGradientView: UIView {
    @IBInspectable var startColor: UIColor = UIColor.clearColor() { didSet { update() } }
    @IBInspectable var endColor: UIColor = UIColor.vaavudLightGreyColor() { didSet { update() } }
    
    override class func layerClass() -> AnyClass {
        return CAGradientLayer.self
    }
    
    func update() {
        (layer as! CAGradientLayer).colors = [startColor.CGColor, endColor.CGColor]
    }
}





