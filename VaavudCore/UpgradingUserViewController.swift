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
        println("scrollView.contentSize: \(scrollView.contentSize)")
        
        if let content = NSBundle.mainBundle().loadNibNamed("UpgradingUserPagesView", owner: nil, options: nil).first as? UIView {
            content.frame.size = scrollView.contentSize
            scrollView.addSubview(content)
            
            println("w: \(view.bounds.width) - h: \(view.bounds.height)")
            
            if view.bounds.height < 568 {
                println("--- iphone 4")
            }
            else if view.bounds.width < 375 {
                println("--- iphone 5")
            }
            else if view.bounds.width < 414 {
                println("--- iphone 6")
            }
            else if view.bounds.width < 768 {
                println("--- iphone 6+")
            }
            else {
                println("--- ipad")
            }
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
        
        phoneScrollView.contentOffset.x = min(page, 1)*phoneScrollView.bounds.width
        
        let cappedOffset = max(scrollView.contentOffset.x, scrollView.bounds.width)
        
        phoneOffset.constant = scrollView.bounds.width - cappedOffset
        laterButtonConstraint.constant = cappedOffset - 2*scrollView.bounds.width
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

@IBDesignable class ArrowView: UIView {
    @IBInspectable var direction: CGFloat = 0 { didSet { setNeedsDisplay() } }

    override func drawRect(rect: CGRect) {
        VaavudStyle.drawVaavudArrow(height: bounds.height, windDirection: direction)
    }
}





