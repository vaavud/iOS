//
//  VLoginViewController.swift
//  Vaavud
//
//  Created by Diego R on 11/17/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit

class VLoginViewController: UIViewController, FBSDKLoginButtonDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var basicInputView: UIView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var facebookView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let loginView = FBSDKLoginButton()
        loginView.frame = facebookView.frame
        self.view.addSubview(loginView)
        
        loginView.readPermissions = ["public_profile", "email", "user_friends"]
        loginView.delegate = self
        facebookView.layer.cornerRadius = 3
        
        
        if FBSDKAccessToken.currentAccessToken() != nil {
            returnUserData()
        }
        
        refreshLoginButton()
    }
    
    @IBAction func doneButtonPushed(sender: UIBarButtonItem) {
        let activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 20, 20))
        activityIndicator.activityIndicatorViewStyle = .Gray
        
        let oldBarButtonItem = navigationItem.rightBarButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        
        activityIndicator.startAnimating()
        
        let callback = { (success : Bool, uid : String) in
        
            if success {
                print("Login Correct")
                
                let callbackUser = { (data: FDataSnapshot) in
                    print(data.value)
                    self.navigationItem.rightBarButtonItem = oldBarButtonItem
                    
                    let deviceModel : [String : AnyObject] = [
                        "appVersion" : "0.0.0.02",
                        "model" : "IPhone 3gs",
                        "vendor" : "Iphone",
                        "osVersion" : "0.0.02"
                        //"uid" : User.sharedInstance.uid!
                    ]
                    
                    let deviceId = FirebaseService.sharedInstance.pushItem("device", items: deviceModel)
                    
                    //User.sharedInstance.name = data.value["firstName"] as? String
                    //User.sharedInstance.lastName = data.value["lastName"] as? String
                    //User.sharedInstance.email = data.value["email"] as? String
                    //User.sharedInstance.uid = uid
                    //User.sharedInstance.deviceId = deviceId
                    
                }
                
                FirebaseService.sharedInstance.getRow("user", key: uid, callback: callbackUser)
            }
            else{
                print("Incorrect")
            }
        }
        
        FirebaseService.sharedInstance.login(emailTextField.text!, password: passwordTextField.text!, callback: callback)
    }
    
    
    @IBAction func textFieldDidChange(sender: UITextField) {
        refreshLoginButton()
    }
    
    
    func refreshLoginButton(){
        navigationItem.rightBarButtonItem?.enabled = !emailTextField.text!.isEmpty && !passwordTextField.text!.isEmpty
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("User Logged In")
        
        if ((error) != nil)
        {
            // Process error
        }
        else if result.isCancelled {
            // Handle cancellations
        }
        else {
            self.returnUserData()
        }
        
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out")
    }
    
    func returnUserData()
    {
        let graphRequest  = FBSDKGraphRequest(graphPath: "me", parameters:["fields" : "first_name, last_name, picture.type(large), email, name, id, gender"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) in
            
            if error != nil
            {
                // Process error
                print("Error: \(error)")
            }
            else {
                let userName = result.valueForKey("first_name") as! String
                let userEmail = result.valueForKey("email") as! String
                let lastName = result.valueForKey("last_name") as! String
                
                let callback = { (success : Bool, uid : String) in
                    if success {
                        
                        let userModel : [String:AnyObject] = [
                            "created"  : 1447405235188,
                            "email" : userEmail,
                            "country" : "US",
                            "firstName" :  userName,
                            "language" : "EN",
                            "lastName" : lastName
                        ]
                        
                        let deviceModel : [String:AnyObject] = [
                            "appVersion" : "0.0.0.02",
                            "model" : "IPhone 3gs",
                            "vendor" : "Iphone",
                            "osVersion" : "0.0.02",
                            "uid" : uid
                        ]
                        
                        FirebaseService.sharedInstance.pushItemByKey("user", key: uid, items: userModel)
                        
                        let deviceid = FirebaseService.sharedInstance.pushItem("device", items: deviceModel)
                        
                        
                        print(deviceid)
                    }
                    else {
                        //TODO
                    }
                }
                
                FirebaseService.sharedInstance.authWithFacebook(FBSDKAccessToken.currentAccessToken().tokenString,callback: callback)
            }
        })
    }

    
    
    
}
