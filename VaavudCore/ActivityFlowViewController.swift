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
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        topConstraint.constant = -scrollView.contentOffset.y/3
    }
}
