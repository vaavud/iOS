//
//  PreLoginViewController.swift
//  Vaavud
//
//  Created by Diego Galindo on 8/5/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import UIKit

class PreLoginViewController: UIViewController {

    var parentView: UIViewController!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func onCancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onLogin() {
        dismissViewControllerAnimated(false, completion: nil)
        gotoLoginFrom(parentView, inside: view.window!.rootViewController!)
    }
}
