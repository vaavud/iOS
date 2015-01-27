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
    
    let pageCount = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        scrollView.contentSize = CGSize(width: CGFloat(pageCount)*scrollView.bounds.width, height: scrollView.bounds.height)
        
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
        
        if page > 1 {
            phoneOffset.constant = scrollView.bounds.width - scrollView.contentOffset.x
        }
        else {
            phoneScrollView.contentOffset.x = page*phoneScrollView.bounds.width
        }
    }
}
