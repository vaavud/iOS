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

    var suppressLogging = false
    var groupName = ""
    private var logHelper: LogHelper?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !suppressLogging {
            logHelper = LogHelper(LogGroup(rawValue: groupName) ?? .Activities, counters: "scrolled")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("Create ComingSoonViewController")
    }
    
    
    deinit {
        print("Destroy ComingSoonViewController")
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        topConstraint.constant = -scrollView.contentOffset.y/3
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        logHelper?.increase("scrolled")
    }
    
    override func viewDidAppear(animated: Bool) {
        logHelper?.began()
    }
    
    override func viewDidDisappear(animated: Bool) {
        logHelper?.ended()
    }
}