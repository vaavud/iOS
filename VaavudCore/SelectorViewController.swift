//
//  SelectorViewController.swift
//  Vaavud
//
//  Created by Diego R on 11/20/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class SelectorViewController: UIViewController,FBSDKLoginButtonDelegate, LoginCoreDelegate{

    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var facebookView: FBSDKLoginButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.translucent = true
        self.navigationController!.view.backgroundColor = UIColor.clearColor()
       
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
    
    func onSuccess() {
        print("next screen")
    }
    
    func onError(title: String, message: String) {
        showAlert(title,message: message,callback: nil)
    }
    
    func missingActivity(){
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("activityVC") as! ActivityViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showAlert(title: String, message: String , callback: ((UIAlertAction) -> Void)? ){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment: ""), style: .Default, handler: callback))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
  
    
}
