//
//  LoginTutorialViewController.swift
//  Vaavud
//
//  Created by Diego R on 11/25/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class LoginTutorialViewController: UIViewController,UIScrollViewDelegate {

    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView){
        let pageWidth: CGFloat = CGRectGetWidth(scrollView.frame)
        let currentPage: CGFloat = floor((scrollView.contentOffset.x - pageWidth/2) / pageWidth) + 1
        self.pageControl.currentPage = Int(currentPage)
    }

}
