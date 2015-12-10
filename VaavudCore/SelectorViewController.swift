//
//  SelectorViewController.swift
//  Vaavud
//
//  Created by Diego R on 11/20/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class SelectorViewController: UIViewController,FBSDKLoginButtonDelegate, LoginDelegate {
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var facebookView: FBSDKLoginButton!
    
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
        
        facebookView.delegate = self
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("User Logged In")
        
        if error != nil || result.isCancelled {
            showAlert("Facebook error", message: "We couldn't reach your information.", callback: nil)
        }
        else {
            AuthorizationController.shared.loginWithFacebook(self)
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out") //TODO
    }
    
    
    func onSuccess(showActivitySelector: Bool) {
        if showActivitySelector {
            if let vc = storyboard?.instantiateViewControllerWithIdentifier("activityVC") {
                navigationController?.pushViewController(vc, animated: true)
            }
        }
        else {
            print("next screen")
        }
    }
    
    func onError(error: LoginError) {
        //        showAlert(title,message: message, callback: nil)
    }
    
    private func showAlert(title: String, message: String , callback: ((UIAlertAction) -> Void)? ){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment: ""), style: .Default, handler: callback))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
  
    
}
