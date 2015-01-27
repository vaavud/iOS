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
    
    let pageCount = 3
    
    override func viewDidLoad() {
        scrollView.contentSize = CGSize(width: CGFloat(pageCount)*scrollView.bounds.width, height: scrollView.bounds.height)
        
//        let vc = UIStoryboard(name: "MainStoryboard", bundle: nil).instantiateViewControllerWithIdentifier("UpgradingUserPages") as UIViewController
//        
//        presentViewController(vc, animated: false, completion: nil)
//        vc.view.frame = scrollView.bounds
//        
//        scrollView.addSubview(vc.view)
        
        if let v = NSBundle.mainBundle().loadNibNamed("UpgradingUserPagesView", owner: nil, options: nil).first as? UIView {
            v.frame.size = scrollView.contentSize
            scrollView.addSubview(v)
        }
        
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        pager.currentPage = Int(round(scrollView.contentOffset.x/scrollView.bounds.width))
    }
}