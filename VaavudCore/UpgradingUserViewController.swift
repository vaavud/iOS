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
    
    @IBOutlet weak var laterButtonConstraint: NSLayoutConstraint!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        scrollView.contentSize = CGSize(width: CGFloat(pager.numberOfPages)*scrollView.bounds.width, height: scrollView.bounds.height)
        
        if let content = NSBundle.mainBundle().loadNibNamed("UpgradingUserPagesView", owner: nil, options: nil).first as? UIView {
            content.frame.size = scrollView.contentSize
            scrollView.addSubview(content)
        }
        
        phoneScrollView.contentSize = CGSize(width: 2*phoneScrollView.bounds.width, height: phoneScrollView.bounds.height)

        if let content = NSBundle.mainBundle().loadNibNamed("UpgradingUserPhonePages", owner: nil, options: nil).first as? UIView {
            content.frame.size = phoneScrollView.contentSize
            phoneScrollView.addSubview(content)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let page = scrollView.contentOffset.x/scrollView.bounds.width
        pager.currentPage = Int(round(page))
        
        if page < 1 {
            phoneScrollView.contentOffset.x = page*phoneScrollView.bounds.width
        }
        else {
            phoneOffset.constant = scrollView.bounds.width - scrollView.contentOffset.x
            laterButtonConstraint.constant = scrollView.contentOffset.x - 2*scrollView.bounds.width
        }
    }
}

@IBDesignable class GradientView: UIView {
    @IBInspectable var startColor: UIColor = UIColor.clearColor() { didSet { update() } }
    @IBInspectable var endColor: UIColor = UIColor.vaavudLightGreyColor() { didSet { update() } }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        update()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        update()
    }
    
    override class func layerClass() -> AnyClass {
        return CAGradientLayer.self
    }
    
    func update() {
        (layer as CAGradientLayer).colors = [startColor.CGColor, endColor.CGColor]
        setNeedsDisplay()
    }
}



