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
    
    private let logHelper = LogHelper(.Login)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        logHelper.log("Selector")
        
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
        
        FBSDKLoginManager().logOut()
        facebookView.delegate = self
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if error != nil {
            print(error)
            logHelper.log("Error", properties: ["type" : "facebook"])
            VaavudInteractions().showLocalAlert("LOGIN_ERROR_TITLE", messageKey: LoginError.Facebook.key, otherKey: "BUTTON_OK", action: {}, on: self)
        }
        else if result.isCancelled {
            logHelper.log("Cancel", properties: ["type" : "facebook"])
        }
        else {
            logHelper.log("Success", properties: ["type" : "facebook"])
            
            bg.alpha = 1
            spinner.show()
            
            LogHelper.log(.App, event: "Open")
            
            AuthorizationController.shared.loginWithFacebook(self)
        }
    }
    
    func loginButtonWillLogin(loginButton: FBSDKLoginButton!) -> Bool {
        logHelper.log("Facebook")
        return true
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) { }
    
    func onSuccess(showActivitySelector: Bool) {
        if showActivitySelector, let vc = storyboard?.instantiateViewControllerWithIdentifier("activityVC") {
            navigationController?.pushViewController(vc, animated: true)
        }
        else {
            gotoAppFrom(navigationController!, inside: view.window!.rootViewController!)
        }
    }
    
    func onError(error: LoginError) {
        bg.alpha = 0
        spinner.hide()
        
        dispatch_async(dispatch_get_main_queue()) {
            VaavudInteractions().showLocalAlert("LOGIN_ERROR_TITLE", messageKey: error.key, otherKey: "BUTTON_OK", action: {}, on: self)
        }
    }
}