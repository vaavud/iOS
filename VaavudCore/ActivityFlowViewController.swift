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

    var groupName = ""
    private var logHelper: LogHelper!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logHelper = LogHelper(LogGroup(rawValue: groupName) ?? .Activities)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        topConstraint.constant = -scrollView.contentOffset.y/3
    }
    
    override func viewDidAppear(animated: Bool) {
        logHelper.began()
    }
    
    override func viewDidDisappear(animated: Bool) {
        logHelper.ended()
    }
}