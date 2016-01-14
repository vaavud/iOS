//
//  SelectorViewController.swift
//  Vaavud
//
//  Created by Diego R on 11/20/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import Firebase

class SelectorViewController: UIViewController, FBSDKLoginButtonDelegate, LoginDelegate {
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var facebookView: FBSDKLoginButton!
    private let spinner = MjolnirSpinner(frame: CGRectMake(0, 0, 100, 100))
    private let bg = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let nc = navigationController {
            nc.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
            nc.navigationBar.shadowImage = UIImage()
            nc.navigationBar.translucent = true
            nc.view.backgroundColor = UIColor.clearColor()
        }
        
        signupButton.layer.borderWidth = 2
        signupButton.layer.borderColor = UIColor.clearColor().CGColor
        signupButton.layer.cornerRadius = 3
        
        bg.frame = view.bounds
        bg.backgroundColor = UIColor.whiteColor()
        bg.alpha = 0
        
        spinner.alpha = 0.4
        spinner.center = view.bounds.moveY(-64).center
        
        
        view.addSubview(bg)
        view.addSubview(spinner)
        
        
        facebookView.delegate = self
    }
    
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("User Logged In")
        
        if error != nil || result.isCancelled {
            //VaavudInteractions().showLocalAlert("LOGIN_ERROR_TITLE", messageKey: LoginError.Facebook.rawValue, otherKey: "BUTTON_OK", action: {}, on: self)
        }
        else {
            
            
            bg.alpha = 1
            spinner.show()
            
            AuthorizationController.shared.loginWithFacebook(self)
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out") // fixme: TODO
    }
    
    func onSuccess(showActivitySelector: Bool) {
        if showActivitySelector {
            if let vc = storyboard?.instantiateViewControllerWithIdentifier("activityVC") {
                navigationController?.pushViewController(vc, animated: true)
            }
        }
        else {
            gotoAppFrom(navigationController!, inside: view.window!.rootViewController!)
        }
    }
    
    func onError(error: LoginError) {
        bg.alpha = 0
        spinner.hide()

        dispatch_async(dispatch_get_main_queue()) {
            VaavudInteractions().showLocalAlert("LOGIN_ERROR_TITLE", messageKey: error.rawValue, otherKey: "BUTTON_OK", action: {}, on: self)
        }
    }
}
