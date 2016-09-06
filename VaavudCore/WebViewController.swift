//
//  WebViewController.swift
//  Vaavud
//
//  Created by Diego Galindo on 8/26/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import UIKit

class WebMarketingViewController: UIViewController {

    
    @IBOutlet weak var webView: UIWebView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = NSURL (string: "https://vaavud.com/promotion/ios")
        let requestObj = NSURLRequest(URL: url!)
        webView.loadRequest(requestObj)

    }
}
