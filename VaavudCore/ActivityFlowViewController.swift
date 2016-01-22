//
//  ComingSoonViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 03/08/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class ComingSoonViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var topConstraint: NSLayoutConstraint!

    private let logHelper = LogHelper(.Activities, counters: "scrolled")
        
    func scrollViewDidScroll(scrollView: UIScrollView) {
        topConstraint.constant = -scrollView.contentOffset.y/3
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        logHelper.increase("scrolled")
    }
    
    override func viewDidAppear(animated: Bool) {
        logHelper.began()
    }
    
    override func viewDidDisappear(animated: Bool) {
        logHelper.ended()
    }
}